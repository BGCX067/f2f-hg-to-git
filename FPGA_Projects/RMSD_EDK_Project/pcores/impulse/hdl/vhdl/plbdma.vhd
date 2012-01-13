--------------------------------------------------------------------------
-- Copyright (c) 2002-2007 by Impulse Accelerated Technologies, Inc.    --
-- All rights reserved.                                                 --
--                                                                      --
-- This source file may be used and redistributed without charge        --
-- subject to the provisions of the IMPULSE ACCELERATED TECHNOLOGIES,   --
-- INC. REDISTRIBUTABLE IP LICENSE AGREEMENT, and provided that this    --
-- copyright statement is not removed from the file, and that any       --
-- derivative work contains this copyright notice.                      –-
--------------------------------------------------------------------------
--
-- Copyright (c) 2007 by Green Mountain Computing Systems, Inc.
-- All rights reserved.
--
-- You MAY NOT copy, distribute, or make available on any public network
--   this design in the source-code form.
-- You MAY use, distribute, and incorporate without restriction this
--   this design in the object-code (i.e. synthsized) form.
-- This design is provided as is without any warranty of any kind.
--
-- plbdma.vhd: Implements a DMA controller the Xilinx flavor PLB
--
-- Change History
-- --------------
-- 04/30/2007 - Scott Thibault
--   Initial design
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity plb_dma is
  generic (
    PRIORITY : std_logic_vector(0 to 1) := "10"
    );
  port (
    PLB_Rst : in std_logic;
    PLB_Clk : in std_logic; 
    PLB_MAddrAck : in  std_logic;
    PLB_MSSize : in  std_logic_vector(0 to 1);
    PLB_MRearbitrate : in  std_logic;
    PLB_MBusy : in  std_logic;
    PLB_MErr : in  std_logic;
    PLB_MWrDAck : in  std_logic;
    PLB_MRdDBus : in  std_logic_vector(0 to 63);
    PLB_MRdWdAddr : in  std_logic_vector(0 to 3);
    PLB_MRdDAck : in  std_logic;
    PLB_MRdBTerm : in  std_logic;
    PLB_MWrBTerm : in  std_logic;
    M_request : out std_logic;
    M_priority : out std_logic_vector(0 to 1);
    M_buslock : out std_logic;
    M_RNW : out std_logic;
    M_BE : out std_logic_vector(0 to 7);
    M_MSize : out std_logic_vector(0 to 1);
    M_size : out std_logic_vector(0 to 3);
    M_type : out std_logic_vector(0 to 2);
    M_compress : out std_logic;
    M_guarded : out std_logic;
    M_ordered : out std_logic;
    M_lockErr : out std_logic;
    M_abort : out std_logic;
    M_ABus : out std_logic_vector(0 to 31);
    M_wrDBus : out std_logic_vector(0 to 63);
    M_wrBurst : out std_logic;
    M_rdBurst : out std_logic;
    ICidata : out std_ulogic_vector (63 downto 0);
    ICaddr : out std_ulogic_vector (31 downto 0);
    ICnextaddr : out std_ulogic_vector (31 downto 0);
    ICwri : out std_ulogic;
    ICre : out std_ulogic;
    ICodata : in std_ulogic_vector (63 downto 0);
    ICack : out std_ulogic;
    ICreq : in std_ulogic;
    ICblock : in std_ulogic;
    ICslice : in std_ulogic;
    ICmode : in std_ulogic;
    ICbase : in std_ulogic_vector (31 downto 0);
    ICsize : in std_ulogic_vector (3 downto 0);
    ICchunk : in std_ulogic_vector(31 downto 0);
    ICstride : in std_ulogic_vector(31 downto 0);
    ICstart : in std_ulogic_vector(31 downto 0);
    ICcount : in std_ulogic_vector (31 downto 0)
    );  
end plb_dma;

architecture a1 of plb_dma is
  function minus_one(v : std_ulogic_vector) return std_ulogic_vector is
    variable num : unsigned(v'length-1 downto 0);
  begin
    num:=unsigned(v);
    num:=num-1;
    return std_ulogic_vector(num);
  end function;

  function demux (addr : unsigned(31 downto 0);
                  size : std_ulogic_vector(3 downto 0))
  return std_logic_vector is
    variable be : std_logic_vector(7 downto 0);
  begin
    case size is
      when "0001" =>
        case addr(2 downto 0) is
          when "000" =>  be := "10000000";
          when "001" =>  be := "01000000";
          when "010" =>  be := "00100000";
          when "011" =>  be := "00010000";
          when "100" =>  be := "00001000";
          when "101" =>  be := "00000100";
          when "110" =>  be := "00000010";
          when others => be := "00000001";
        end case;
      when "0010" =>
        case addr(2 downto 1) is
          when "00" =>   be := "11000000";
          when "01" =>   be := "00110000";
          when "10" =>   be := "00001100";
          when others => be := "00000011";
        end case;
      when "0100" =>
        case addr(2 downto 2) is
          when "0" =>    be := "11110000";
          when others => be := "00001111";
        end case;
      when others => be := "11111111";
    end case;
    return be;
  end function;

  type transaction_state is (IDLE, PREFETCH, REQUEST, XFER, ACK, SLICEOP);
  signal state, next_state : transaction_state;

  signal burst_next, req_abort : std_ulogic;
  signal req_nextindx : unsigned(31 downto 0);
  signal req_nextaddr, req_nextaddr_0 : unsigned(31 downto 0);
  signal step_be, burst_be : std_logic_vector(7 downto 0);
  signal burst_m_size : std_logic_vector(3 downto 0);
  signal req_nextsize : unsigned(4 downto 0);
  signal req_nextsize_b : unsigned(8 downto 0);

  signal new_slice, final_slice : std_ulogic;
  signal slice_base, elements : unsigned(31 downto 0);
  signal next_slice_indx, slice_indx : unsigned(31 downto 0);
  signal chunk_size_b, stride_b : unsigned(31 downto 0);

  signal xfer_addr, xfer_addr_1 : unsigned(31 downto 0);
  signal xfer_indx, xfer_indx_1 : unsigned(31 downto 0);
  signal count : unsigned(4 downto 0);
  signal burst_mode, final, pending_burst_error: std_ulogic;
  signal got_term, inpipe, new_req : std_ulogic;
  signal xfer_end_word : std_ulogic;
  signal xfer_end_cycle : std_ulogic;
  signal req_remaining, req_next_remaining : unsigned(31 downto 0);
  signal start_xfer : std_ulogic;
  signal burst_error, req_recovery : std_ulogic;

  signal ic_prime : std_ulogic;
  signal ICnextaddr_out : std_ulogic_vector (31 downto 0);
begin
  -- REQUEST SIGNALS
  M_request <= not (final or inpipe or start_xfer) when state /= IDLE and state /= PREFETCH and state /= SLICEOP else '0';
  M_abort <= req_abort;

  M_RNW <= not ICmode;

  M_ABus <= std_logic_vector(req_nextaddr);
  M_size <= "0000" when burst_next = '0' else burst_m_size;
  M_BE <= step_be when burst_next = '0' else burst_be;
  M_type <= "000";
  
  -- XFER SIGNALS
  M_wrBurst <= burst_mode when state=XFER and xfer_end_word='0' and ICmode='1' and got_term='0' else '0';
  M_rdBurst <= burst_mode when state=XFER and xfer_end_word='0' and ICmode='0' and got_term='0' else '0';

  M_wrDBus <= std_logic_vector(ICodata);


  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (PLB_Rst = '1') then
        state <= IDLE;
      else
        state <= next_state;
      end if;
    end if;
  end process;

  process (state,ICslice,ICreq,ICmode,PLB_MAddrAck,xfer_end_cycle,inpipe,final,final_slice)
  begin
    case state is
    when IDLE =>
      if (ICreq='1') then
        if (ICslice='1') then
          next_state <= SLICEOP;
        elsif (ICmode='0' or ICblock='0') then
          next_state <= REQUEST;
        else
          next_state <= PREFETCH;
        end if;
      else
        next_state <= IDLE;
      end if;
    when PREFETCH =>
      next_state <= REQUEST;
    when REQUEST =>
      if (PLB_MAddrAck = '1') then
        next_state <= XFER;
      else
        next_state <= REQUEST;
      end if;
    when XFER =>
      if (xfer_end_cycle = '1' and inpipe = '0') then
        if (final = '1') then
          if (ICslice = '1' and final_slice = '0') then
            next_state <= SLICEOP;
          else
            next_state <= ACK;
          end if;
        elsif (PLB_MAddrAck = '0') then
          next_state <= REQUEST;
        else
          next_state <= XFER;
        end if;
      else
        next_state <= XFER;
      end if;
    when ACK =>
      next_state <= IDLE;
    when SLICEOP =>
      if (ICmode='0') then
        next_state <= REQUEST;
      else
        next_state <= PREFETCH;
      end if;
    end case;
  end process;
  
  start_xfer <=
    PLB_MAddrAck when (state = REQUEST) else
    '1' when xfer_end_cycle = '1' and (inpipe = '1' or PLB_MAddrAck = '1') else
    '0';
  xfer_end_word <= '0' when burst_mode='1' and (count /= unsigned'("0001")) else '1';
  xfer_end_cycle <= (got_term or xfer_end_word) and (PLB_MRdDAck or PLB_MWrDAck);
  burst_error <= got_term and not xfer_end_word and not pending_burst_error;

  xfer_addr_1 <= xfer_addr + unsigned(ICsize);

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (start_xfer = '1') then
        xfer_addr <= req_nextaddr;
      elsif burst_error = '0' and (PLB_MRdDAck = '1' or PLB_MWrDAck = '1') then
        xfer_addr <= xfer_addr_1;
      end if;
    end if;
  end process;

  xfer_indx_1 <= xfer_indx + unsigned(ICsize);

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (start_xfer = '1') then
        xfer_indx <= req_nextindx;
      elsif burst_error = '0' and (PLB_MRdDAck = '1' or PLB_MWrDAck = '1') then
        xfer_indx <= xfer_indx_1;
      end if;
    end if;
  end process;

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (start_xfer = '1') then
        burst_mode <= burst_next;
      end if;
    end if;
  end process;

  final <= '1' when inpipe = '0' and pending_burst_error = '0' and req_remaining = unsigned'(X"00000000") else '0';

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (start_xfer = '1') then
        count <= req_nextsize;
      elsif burst_error = '0' and (PLB_MRdDAck = '1' or PLB_MWrDAck = '1') then
        count <= count - 1;
      end if;
    end if;
  end process;

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (PLB_Rst = '1' or xfer_end_cycle = '1') then
        got_term <= '0';
      else
        got_term <= PLB_MRdBTerm or PLB_MWrBTerm;
      end if;
    end if;
  end process;
  
  process (PLB_Clk)
  begin  -- process
    if (PLB_Clk'event and PLB_Clk='1') then
      if (PLB_Rst = '1' or xfer_end_cycle = '1') then
        inpipe <= '0';
      elsif (PLB_MAddrAck = '1' and state /= REQUEST) then
        inpipe <= '1';
      end if;
    end if;
  end process;

  new_req <= start_xfer or req_abort or new_slice;

  req_abort <= pending_burst_error when state = REQUEST else '0';
  req_recovery <= req_abort or burst_error;

  req_next_remaining <=
    unsigned(ICchunk) when state = SLICEOP else
    (req_remaining + count) - 1 when req_recovery = '1' else
    req_remaining - unsigned(req_nextsize);

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        req_remaining <= unsigned(ICcount);
      elsif (new_req = '1') then
        req_remaining <= req_next_remaining;
      end if;
    end if;
  end process;
    
  process (PLB_Clk)
  begin  -- process
    if (PLB_Clk'event and PLB_Clk='1') then
      case ICsize is
        when "0001" => burst_m_size <= "1000";
        when "0010" => burst_m_size <= "1001";
        when "0100" => burst_m_size <= "1010";
        when others => burst_m_size <= "1011";
      end case;
    end if;    
  end process;

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        if (unsigned(ICcount) > 1) then
          burst_next <= '1';
        else
          burst_next <= '0';
        end if;
      elsif (new_req = '1') then
        if (req_next_remaining > 1) then
          burst_next <= '1';
        else
          burst_next <= '0';
        end if;
      end if;
    end if;
  end process;
  
  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        if (ICcount(31 downto 4) /= X"0000000") then
          req_nextsize <= "10000";
        else
          req_nextsize <= '0' & unsigned(ICcount(3 downto 0));
        end if;
      elsif (new_req = '1') then
        if (req_next_remaining(31 downto 4) /= unsigned'(X"0000000")) then
          req_nextsize <= "10000";
        else
          req_nextsize <= '0' & req_next_remaining(3 downto 0);
        end if;
      end if;
    end if;
  end process;

  req_nextsize_b <= req_nextsize * unsigned(ICsize);

  req_nextaddr_0 <=
    slice_base when state = SLICEOP else
    xfer_addr_1 when req_recovery = '1' else
    req_nextaddr + req_nextsize_b;

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        req_nextaddr <= unsigned(ICbase);
      elsif (new_req = '1') then
        req_nextaddr <= req_nextaddr_0;
      end if;
    end if;
  end process;
  
  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        req_nextindx <= unsigned(ICstart);
      elsif (state = SLICEOP) then
        req_nextindx <= slice_indx;
      elsif (new_req = '1') then
        if (req_recovery = '1') then
          req_nextindx <= xfer_indx_1;
        else
          req_nextindx <= req_nextindx + req_nextsize_b;
        end if;
      end if;
    end if;
  end process;

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        if (ICcount(31 downto 4) /= X"0000000") then
          burst_be <= "11110000";
        else
          burst_be <= std_logic_vector(minus_one(ICcount(3 downto 0))) & "0000";
        end if;
      elsif (new_req = '1') then
        if (req_next_remaining(31 downto 4) /= unsigned'(X"0000000")) then
          burst_be <= "11110000";
        else
          burst_be <= (req_next_remaining(3 downto 0)-1) & "0000";
        end if;
      end if;
    end if;
  end process;
      
  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        step_be <= demux(unsigned(ICbase),ICsize);
      elsif (new_req = '1') then
        step_be <= demux(req_nextaddr_0,ICsize);
      end if;
    end if;
  end process;
      
  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state /= XFER) then
        pending_burst_error <= '0';
      elsif (xfer_end_cycle = '1') then
        pending_burst_error <= not xfer_end_word and not pending_burst_error;
      end if;
    end if;
  end process;

  ICack <= '1' when state = ACK else '0';

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      ICwri <= PLB_MRdDAck;
    end if;
  end process;

  ic_prime <=
    '1' when state /= XFER else
    '1' when state = XFER and xfer_end_cycle='1' else
    '0';

  ICre <= PLB_MWrDAck;
  ICnextaddr_out <=
    std_ulogic_vector(req_nextindx) when ic_prime='1' else
    std_ulogic_vector(xfer_indx_1) when PLB_MWrDAck = '1' else
    std_ulogic_vector(xfer_indx);

  ICnextaddr <= ICnextaddr_out;

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (ICmode = '0') then
        ICaddr <= std_ulogic_vector(xfer_indx);
      else
        ICaddr <= ICnextaddr_out;
      end if;
    end if;
  end process;

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      ICidata <= std_ulogic_vector(PLB_MRdDBus);
    end if;
  end process;

  -- Slice operation logic
  
  new_slice <= '1' when state = SLICEOP else '0';
  
  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        slice_base <= unsigned(ICbase);
      elsif (xfer_end_cycle = '1' and final = '1') then
        slice_base <= slice_base + unsigned(ICstride);
      end if;
    end if;
  end process;

  chunk_size_b <= unsigned(ICchunk(27 downto 0)) * unsigned(ICsize);
  next_slice_indx <= slice_indx + chunk_size_b;
  
  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        slice_indx <= unsigned(ICstart);
      elsif (xfer_end_cycle = '1' and final = '1') then
        slice_indx <= next_slice_indx;
      end if;
    end if;
  end process;

    process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        slice_base <= unsigned(ICbase);
      elsif (xfer_end_cycle = '1' and final = '1') then
        slice_base <= slice_base + unsigned(ICstride);
      end if;
    end if;
  end process;

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      if (state = IDLE) then
        elements <= X"00000000";
      elsif (state = SLICEOP) then
        elements <= elements + unsigned(ICchunk);
      end if;
    end if;
  end process;

  final_slice <= '1' when elements = unsigned(ICcount) else '0';
  
  -- Fixed/unused signals;
  M_busLock <= '0';
  M_compress<='0';
  M_guarded<='0';
  M_lockErr<='0';
  M_MSize<="01";
  M_ordered<='0';
  M_priority<=PRIORITY;
end a1;

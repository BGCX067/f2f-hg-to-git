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
--                                                                      --
-- opb_if.vhd: Xilinx OPB Input Stream Interface                        --
--                                                                      --
-- Change History
-- --------------
-- 11/6/2003 - Scott Thibault
--   File created.
-- 5/12/2004 - Scott Thibault
--   Pipeplined OPB_dma to achieve 100MHz.
-- 12/2/2004 - Scott Thibault
--   Fixed OPB_dma/counter_1 bug for retries during first transaction
-- 12/21/2004 - Scott Thibault
--   Qualify OPB_dma/OPB_MGrant to account for bus parking
--   Eliminate OPB_dma/counter_2
-- 03/15/2006 - Scott Thibault
--   Add load/store support to OPB_dma
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity opb_to_stream is
  generic (
    datawidth : positive := 8
  );
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    stream_en : out std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : out std_ulogic;
    stream_data : out std_ulogic_vector (datawidth-1 downto 0)
  );
end opb_to_stream;

architecture rtl of opb_to_stream is
  signal error, write_addr : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
begin
  write_addr <=
    '1' when opb_addr = "00" else
    '1' when opb_addr = "10" else
    '0';

  -- Write to stream
  stream_en <= stream_rdy and opb_ce and opb_write and write_addr;
  stream_eos <= '1' when opb_addr = "10" else '0';
  stream_data <= std_ulogic_vector(opb_wdata(datawidth-1 downto 0));

  -- Error detection
  check: process (opb_reset, clk)
  begin
    if (opb_reset = '1') then
      error <= '0';
    elsif (clk'event and clk='1') then
      if (opb_ce = '1' and opb_write = '1' and write_addr = '1') then
        error <= not stream_rdy;
      end if;
    end if;
  end process;
  
  -- Status register
  status(0) <= stream_rdy;
  status(1) <= '0';
  status(2) <= '0';
  status(3) <= error;
  status(31 downto 4) <= "0000000000000000000000000000";

  opb_rdata <=
    std_logic_vector(status) when opb_addr = "01" else
    X"00000000";
end rtl;

library ieee;
use ieee.std_logic_1164.all;

entity stream_to_opb is
  generic (
    datawidth : positive := 8
  );
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    stream_en : out std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : in std_ulogic;
    stream_data : in std_ulogic_vector (datawidth-1 downto 0)
  );
end stream_to_opb;

architecture rtl of stream_to_opb is
  signal accept, valid, eos, error, address_stream : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
  signal data : std_ulogic_vector (31 downto 0);
  signal extended_data : std_ulogic_vector (31 downto 0);
begin
  address_stream <= '1' when opb_addr = "00" else '0';
  -- Read register
  accept <= (not valid or (opb_ce and opb_read and address_stream));

--  extended_data(31 downto datawidth) <= (others => '0');
  extended_data(datawidth - 1 downto 0) <= stream_data;

  read_stream: process (opb_reset, clk)
  begin
    if (opb_reset = '1') then
      valid <= '0';
      eos <= '0';
    elsif (clk'event and clk='1') then
      if (stream_rdy = '1' and accept = '1') then
        data <= extended_data;
        eos <= stream_eos;
        valid <= '1';
      elsif (opb_ce = '1' and opb_read = '1' and address_stream = '1') then
        valid <= '0';
      end if;
    end if;
  end process;

  stream_en <= accept;

  -- Error detection
  check: process (opb_reset, clk)
  begin
    if (opb_reset = '1') then
      error <= '0';
    elsif (clk'event and clk='1') then
      if (opb_ce = '1' and opb_read = '1' and address_stream = '1') then
        error <= not valid;
      end if;
    end if;
  end process;
  
  -- Status register
  status(0) <= valid;
  status(1) <= eos;
  status(2) <= '0';
  status(3) <= error;
  status(31 downto 4) <= "0000000000000000000000000000";

  opb_rdata <=
    std_logic_vector(data) when opb_addr = "00" else
    std_logic_vector(status) when opb_addr = "01" else
    X"00000000";
end rtl;

library ieee;
use ieee.std_logic_1164.all;

entity opb_to_signal is
  generic (
    datawidth : positive := 32
  );
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    signal_en : out std_ulogic;
    signal_data : out std_ulogic_vector (datawidth-1 downto 0)
  );
end opb_to_signal;

architecture rtl of opb_to_signal is
  signal error, write_addr : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
begin
  write_addr <= '1' when opb_addr = "00" else '0';

  -- Write to stream
  signal_en <= opb_ce and opb_write and write_addr;
  signal_data <= std_ulogic_vector(opb_wdata(datawidth-1 downto 0));

  -- Status register
  status <= X"00000001"; -- Always ready/no errors.

  opb_rdata <=
    std_logic_vector(status) when opb_addr = "01" else
    X"00000000";
end rtl;

library ieee;
use ieee.std_logic_1164.all;

entity signal_to_opb is
  generic (
    datawidth : positive := 32
  );
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    signal_en : out std_ulogic;
    signal_rdy : in std_ulogic;
    signal_data : in std_ulogic_vector (datawidth-1 downto 0)
  );
end signal_to_opb;

architecture rtl of signal_to_opb is
  signal accept, valid, eos, error, address_signal : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
  signal data : std_ulogic_vector (31 downto 0);
  signal extended_data : std_ulogic_vector (31 downto 0);
begin
  address_signal <= '1' when opb_addr = "00" else '0';
  -- Read register
  accept <= '1';

--  extended_data(31 downto datawidth) <= (others => '0');
  extended_data(datawidth - 1 downto 0) <= signal_data;

  read_stream: process (opb_reset, clk)
  begin
    if (opb_reset = '1') then
      valid <= '0';
      eos <= '0';
    elsif (clk'event and clk='1') then
      if (signal_rdy = '1' and accept = '1') then
        data <= extended_data;
        valid <= '1';
      elsif (opb_ce = '1' and opb_read = '1' and address_signal = '1') then
        valid <= '0';
      end if;
    end if;
  end process;

  signal_en <= accept;

  -- Error detection
  check: process (opb_reset, clk)
  begin
    if (opb_reset = '1') then
      error <= '0';
    elsif (clk'event and clk='1') then
      if (opb_ce = '1' and opb_read = '1' and address_signal = '1') then
        error <= not valid;
      end if;
    end if;
  end process;
  
  -- Status register
  status(0) <= valid;
  status(1) <= '0';
  status(2) <= '0';
  status(3) <= error;
  status(31 downto 4) <= "0000000000000000000000000000";

  opb_rdata <=
    std_logic_vector(data) when opb_addr = "00" else
    std_logic_vector(status) when opb_addr = "01" else
    X"00000000";
end rtl;

library ieee;
use ieee.std_logic_1164.all;

entity opb_to_register is
  generic (
    datawidth : positive := 32
  );
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    register_en : out std_ulogic;
    register_data : out std_ulogic_vector (datawidth-1 downto 0)
  );
end opb_to_register;

architecture rtl of opb_to_register is
  signal write_addr : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
begin
  write_addr <= '1' when opb_addr = "00" else '0';

  -- Write to stream
  register_en <= opb_ce and opb_write and write_addr;
  register_data <= std_ulogic_vector(opb_wdata(datawidth-1 downto 0));

  -- Status register
  status <= X"00000001"; -- Always ready/no errors.

  opb_rdata <=
    std_logic_vector(status) when opb_addr = "01" else
    X"00000000";
end rtl;

library ieee;
use ieee.std_logic_1164.all;

entity register_to_opb is
  generic (
    datawidth : positive := 32
  );
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    register_value : in std_ulogic_vector (datawidth-1 downto 0)
  );
end register_to_opb;

architecture rtl of register_to_opb is
  signal address_signal : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
  signal extended_data : std_ulogic_vector (31 downto 0);
begin
  address_signal <= '1' when opb_addr = "00" else '0';

--  extended_data(31 downto datawidth) <= (others => '0');
  extended_data(datawidth - 1 downto 0) <= register_value;

  -- Status register
  status <= X"00000001"; -- Always ready/no errors.

  opb_rdata <=
    std_logic_vector(extended_data) when opb_addr = "00" else
    std_logic_vector(status) when opb_addr = "01" else
    X"00000000";
end rtl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity opb_dma is
  port (
    reset, sclk, clk : in std_ulogic;
    Mn_ABus           : out std_logic_vector(0 to 31);
    Mn_DBus           : out std_logic_vector(0 to 31);
    Mn_request        : out std_logic;
    Mn_busLock        : out std_logic;
    Mn_select         : out std_logic;
    Mn_RNW            : out std_logic;
    Mn_BE             : out std_logic_vector(0 to 3);
    Mn_seqAddr        : out std_logic;
    OPB_DBus          : in  std_logic_vector(0 to 31) := (others => '0');
    OPB_MGrant        : in  std_logic := '0';
    OPB_xferAck       : in  std_logic := '0';
    OPB_errAck        : in  std_logic := '0';
    OPB_retry         : in  std_logic := '0';
    OPB_timeout       : in  std_logic := '0';
    ICidata : out std_ulogic_vector (31 downto 0);
    ICaddr : out std_ulogic_vector (31 downto 0);
    ICnextaddr : out std_ulogic_vector (31 downto 0);
    ICwri : out std_ulogic;
    ICodata : in std_ulogic_vector (31 downto 0);
    ICack : out std_ulogic;
    ICreq : in std_ulogic;
    ICblock : in std_ulogic;
    ICmode : in std_ulogic;
    ICbase : in std_ulogic_vector (31 downto 0);
    ICsize : in std_ulogic_vector (2 downto 0);
    ICcount : in std_ulogic_vector (31 downto 0)
  );
end opb_dma;

architecture rtl of opb_dma is
  type stateType is (idle,init,running,restart,single);
  signal thisState, nextState : stateType;
  signal retry, grant_i : std_ulogic;
  signal address_0, address_1 : unsigned(31 downto 0);
  signal counter_0, counter_1, counterNext : unsigned(31 downto 0);
  signal done, done_0, done_1, done_2, done_3 : std_ulogic;
  signal ben : std_logic_vector(3 downto 0);
  signal stall_0, stall_1, stall_2, opb_transfer, opb_done, drive_opb : std_ulogic;
  signal stage : std_ulogic_vector(0 to 3);
begin
  -- Doc says timeout may come at same time as ack, and should be ignored in
  -- that case.  Also, these are shared signals so we and with opb_transfer to
  -- determine that it is our transaction.
  retry <= (OPB_retry or (OPB_timeout and not OPB_xferAck) or OPB_errAck) and
           opb_transfer;

  -- State machine

  process (reset,clk)
  begin
    if (reset='1') then
      thisState <= idle;
    elsif (clk'event and clk='1') then
      thisState <= nextState;
    end if;
  end process;

  process (thisState, ICreq, ICblock, retry, done, done_3, stage)
  begin
    case thisState is
    when idle =>
      if (ICreq='1') then
        if (ICblock='1') then
          nextState <= init;
        else
          nextState <= single;
        end if;
      else
        nextState <= idle;
      end if;
    when init =>
      if (done = '0') then
        nextState <= running;
      else
        nextState <= idle;
      end if;
    when restart =>
      nextState <= running;
    when running =>
      if (retry = '1') then
        nextState <= restart;
      elsif (done_3 = '1') then
        nextState <= idle;
      else
        nextState <= running;
      end if;      
    when single =>
      if (retry = '1') then
        nextState <= restart;
      elsif (stage(3) = '1') then
        nextState <= idle;
      else
        nextState <= single;
      end if;      
    end case;
  end process;
    
  -- TRANSFER PIPELINE
  -- Stage 0: Address Calculation
  -- Stage 1: OPB request and Read BRAM, iff BRAM -> OPB transfer (i.e., ICmode = '0')
  -- Stage 2: OPB transfer
  -- Stage 3: Write BRAM, iff OPB -> BRAM transfer (i.e., ICmode = '1')

  stall_2 <= stage(2) and not opb_done;
  -- if stall_2 is high, then we can't get a MGrant so stage(1) will stall
  stall_1 <= stage(1) and not OPB_MGrant;
  stall_0 <= stall_1;

  process (thisState, done, ICreq, ICblock)
  begin
    case thisState is
    when idle =>
      stage(0) <= ICreq and not ICblock;
    when init | running | restart =>
      stage(0) <= not done;
    when others =>
      stage(0) <= '0';
    end case;
  end process;

  process (reset, retry, clk)
  begin
    if (clk'event and clk='1') then
      if (reset = '1' or retry = '1') then
        stage(1) <= '0';
        stage(2) <= '0';
        stage(3) <= '0';
      else
        if (stall_1 = '0') then
          stage(1) <= stage(0);
        end if;
        if (stall_2 = '0') then
          stage(2) <= stage(1) and OPB_MGrant;
        end if;
        stage(3) <= stage(2) and not stall_2;
      end if;
    end if;
  end process;

  -- Address generation
  process (thisState, counter_0)
  begin
    if (thisState = init or thisState = restart) then
      counterNext <= counter_0;
    else
      counterNext <= counter_0 + 1;
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk='1') then
      if (thisState = idle) then
        counter_0 <= X"00000000";
      else
        if (retry = '1') then
          counter_0 <= counter_1;
        elsif (stage(0) = '1' and stall_0 = '0') then
          counter_0 <= counterNext;
        end if;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk='1') then
      if (thisState = init) then
        -- Don't propagate old value to counter_1 in case of retry
        -- since it holds the end value of the previous transaction
        -- or undefined at init.
        counter_1 <= X"00000000";
      else
        if (stall_1 = '0') then
          counter_1 <= counter_0;
        end if;
      end if;
    end if;
  end process;

  -- OPB_MGrant may be high when we did not request it due to parking
  grant_i <= stage(1) and OPB_MGrant;
  
  process (clk)
  begin
    if (clk'event and clk = '1') then
      case thisState is
      when init | idle | single =>
        address_0 <= unsigned(ICbase);
      when running =>
        if (retry = '1') then
          address_0 <= address_1;
        elsif (grant_i = '1') then
          address_0 <= address_0 + unsigned(ICsize);
        end if;
      when restart =>
        address_0 <= address_0;
      end case;
    end if;
  end process;

  done <=
    '1' when ICblock = '0' else
    '1' when counterNext = unsigned(ICcount) else
    '0';

  process (reset, retry, clk)
  begin
    if (reset = '1' or retry = '1') then
      done_0 <= '0';
      done_1 <= '0';
      done_2 <= '0';
      done_3 <= '0';
    elsif (clk'event and clk='1') then
      if (stall_0 = '0') then
        done_0 <= done and stage(1);
      end if;
      done_1 <= done_0 or (done_1 and stall_2);
      if (stall_2 = '0') then
        done_2 <= done_1;
      end if;
      done_3 <= done_2;
    end if;
  end process;

  -- Avalon Master Port signals

  -- ben is an output of stage 1
  ben <=
    "1000" when ICsize = "001" and address_0(1 downto 0) = "00" else
    "0100" when ICsize = "001" and address_0(1 downto 0) = "01" else
    "0010" when ICsize = "001" and address_0(1 downto 0) = "10" else
    "0001" when ICsize = "001" and address_0(1 downto 0) = "11" else
    "1100" when ICsize = "010" and address_0(1) = '0' else
    "0011" when ICsize = "010" and address_0(1) = '1' else
    "1111";

  process (reset, clk)
  begin
    if (reset = '1') then
      opb_transfer <= '0';
    elsif (clk'event and clk='1') then
      if (grant_i = '1') then
        opb_transfer <= '1';
      elsif (OPB_xferAck = '1' or OPB_retry = '1' or OPB_timeout = '1' or OPB_errAck = '1') then
        opb_transfer <= '0';
      end if;
    end if;
  end process;

  drive_opb <= (grant_i and not retry) or (opb_transfer and not opb_done);

  opb_done <= OPB_xferAck or OPB_retry or OPB_timeout or OPB_errAck;

  Mn_busLock <= '0';
  Mn_request <= stage(1);

  process (clk)
  begin
    if (clk'event and clk='1') then
      if (drive_opb = '1') then
        if (OPB_MGrant = '1') then
          address_1 <= address_0;
        end if;
      else
        address_1 <= X"00000000";
      end if;
    end if;
  end process;

  Mn_ABus <= std_logic_vector(address_1);

  process (clk)
  begin
    if (clk'event and clk='1') then
      if (drive_opb = '1') then
        if (OPB_MGrant = '1') then
          Mn_BE <= ben;
        end if;
      else
        Mn_BE <= "0000";
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk='1') then
      if (drive_opb = '1') then
        Mn_RNW <= not ICmode;
      else
        Mn_RNW <= '0';
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk='1') then
      if (drive_opb = '1' and ICMode = '1') then
        if (OPB_MGrant = '1') then
          -- ICodata is valid in stage 1, and output here in Mn_DBus for stage 2 write.
          Mn_DBus <= std_logic_vector(ICodata);
        end if;
      else
        Mn_DBus <= X"00000000";
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk='1') then
      Mn_select <= drive_opb;
    end if;
  end process;

-- Mn_seqAddr must be used in conjunction with busLock in order to
-- insure that there are no intervening bus cycles.
--  process (clk)
--  begin
--    if (clk'event and clk='1') then
--      if (drive_opb = '1') then
--        if (OPB_MGrant = '0') then
--          Mn_seqAddr <= stage(2) and not done;
--        end if;
--      else
        Mn_seqAddr <= '0';
--      end if;
--    end if;
--  end process;

  -- Impulse C component signals

  -- OPB_DBus is valid after stage 2, and output here in ICidata for stage 3 write.
  process (clk)
  begin
    if (clk'event and clk='1') then
      ICidata <= std_ulogic_vector(OPB_DBus);
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk='1') then
      ICwri <= not ICmode and stage(2) and not stall_2;
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk='1') then
      if (thisState = init and done = '1' and ICblock = '0') then
        ICack <= '1';
      elsif (thisState = single) then
        ICack <= stage(2) and not stall_2;
      else
        ICack <= done_2;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk='1') then
      if (ICmode = '0') then
        -- If writing to local RAM then write occurs in stage 3.
        ICaddr <= std_ulogic_vector(counter_1);
      elsif (stall_1 = '0') then
        -- If read from local RAM then read occurs in stage 1.
        ICaddr <= std_ulogic_vector(counterNext);
      end if;
    end if;
  end process;

  -- ICnextaddr is only used in local reads so they are output from stage 0
  ICnextaddr <= std_ulogic_vector(counterNext) when stall_1 = '0' else std_ulogic_vector(counter_0);

end rtl;

library IEEE;
use IEEE.std_logic_1164.all;

package opb_if is

  component opb_to_stream is
  generic (datawidth : positive := 8);
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    stream_en : out std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : out std_ulogic;
    stream_data : out std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component stream_to_opb is
  generic (datawidth : positive := 8);
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    stream_en : out std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : in std_ulogic;
    stream_data : in std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component opb_to_signal is
  generic (datawidth : positive := 32);
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    signal_en : out std_ulogic;
    signal_data : out std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component signal_to_opb is
  generic (datawidth : positive := 32);
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    signal_en : out std_ulogic;
    signal_rdy : in std_ulogic;
    signal_data : in std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component opb_to_register is
  generic (datawidth : positive := 32);
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    register_en : out std_ulogic;
    register_data : out std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component register_to_opb is
  generic (datawidth : positive := 32);
  port (
    clk : in std_logic;
    opb_addr : in std_logic_vector (1 downto 0);
    opb_ce : in std_logic;
    opb_read : in std_logic;
    opb_reset : in std_logic;
    opb_write : in std_logic;
    opb_wdata : in std_logic_vector (31 downto 0);
    opb_rdata : out std_logic_vector (31 downto 0);
    register_value : in std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component opb_dma is
  port (
    reset, sclk, clk : in std_ulogic;
    Mn_ABus           : out std_logic_vector(0 to 31);
    Mn_DBus           : out std_logic_vector(0 to 31);
    Mn_request        : out std_logic;
    Mn_busLock        : out std_logic;
    Mn_select         : out std_logic;
    Mn_RNW            : out std_logic;
    Mn_BE             : out std_logic_vector(0 to 3);
    Mn_seqAddr        : out std_logic;
    OPB_DBus          : in  std_logic_vector(0 to 31) := (others => '0');
    OPB_MGrant        : in  std_logic := '0';
    OPB_xferAck       : in  std_logic := '0';
    OPB_errAck        : in  std_logic := '0';
    OPB_retry         : in  std_logic := '0';
    OPB_timeout       : in  std_logic := '0';
    ICidata : out std_ulogic_vector (31 downto 0);
    ICaddr : out std_ulogic_vector (31 downto 0);
    ICnextaddr : out std_ulogic_vector (31 downto 0);
    ICwri : out std_ulogic;
    ICodata : in std_ulogic_vector (31 downto 0);
    ICack : out std_ulogic;
    ICreq : in std_ulogic;
    ICblock : in std_ulogic;
    ICmode : in std_ulogic;
    ICbase : in std_ulogic_vector (31 downto 0);
    ICsize : in std_ulogic_vector (2 downto 0);
    ICcount : in std_ulogic_vector (31 downto 0)
  );
  end component;

end;


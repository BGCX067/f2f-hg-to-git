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
-- fcm_if.vhd: Xilinx APU Input Stream Interface
--
-- Change History
-- --------------
-- 5/17/2005 - Scott Thibault
--   File created.
--
-- gme:
-- added happy_xst_slicing_wire since xst didn't like the way some stuff
--   was sliced and joined in a case statement
-- in stream_to_apu, only set stream_en if grabbing the data addr (0)
-- should we use apufcmce? wouldn't apufcminstrvalid be better since it's
-- derived from it?
-- note: ldst_size is the number of words to be transferred MINUS ONE!
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity apu_to_stream is
  generic (
    datawidth : positive := 8
  );
  port (
    reset, clk : in std_logic;
    apufcmce : std_logic;
    apufcminstruction : std_logic_vector(0 to 31);
    apufcminstrvalid : std_logic;
    apufcmradata : std_logic_vector(0 to 31);
    apufcmrbdata : std_logic_vector(0 to 31);
    apufcmoperandvalid : std_logic;
    apufcmflush : std_logic;
    apufcmwritebackok : std_logic;
    apufcmloaddata : std_logic_vector(0 to 31);
    apufcmloaddvalid : std_logic;
    apufcmloadbyteen : std_logic_vector(0 to 3);
    apufcmendian : std_logic;
    apufcmxerca : std_logic;
    apufcmdecoded : std_logic;
    apufcmdecudi : std_logic_vector(0 to 2);
    apufcmdecudivalid : std_logic;
    fcmapuresult : out std_logic_vector(0 to 31);
    fcmapudone : inout std_logic;       -- added "in"
    fcmapusleepnotready : out std_logic;
    fcmapuloadwait : inout std_logic;-- added "in"
    fcmapuresultvalid : inout std_logic;-- added "in"
    stream_en : inout std_ulogic;       -- added "in"
    stream_rdy : in std_ulogic; 
    stream_eos : inout std_ulogic;        -- added "in"
    stream_data : out std_ulogic_vector (datawidth-1 downto 0)
  );
end apu_to_stream;

architecture rtl of apu_to_stream is
  type stateType is (STATE_IDLE, STATE_LOAD, STATE_STORE);
--  alias target : std_logic_vector(4 downto 0) is apufcminstruction(6 to 10);
  signal curr_state, next_state : stateType;
  signal stream_we : std_ulogic;
  signal error, write_addr : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
  signal instrreg_we, ldst_size_counter_we, store_or_loadn : std_logic;
  signal ldst_size, ldst_size_counter, ldst_size_reg : unsigned(1 downto 0);

  signal happy_xst_slicing_wire : std_logic_vector(0 to 2);
  signal instr_reg : std_logic_vector(0 to 31);
  signal target : std_logic_vector(4 downto 0);
  signal valid_instr, more_data : std_logic;
begin

  instrreg_we <= '1' when curr_state = STATE_IDLE else '0';
  happy_xst_slicing_wire <= apufcminstruction(22) & apufcminstruction(24 to 25);
  target <= instr_reg(6 to 10);
    
  process (happy_xst_slicing_wire)
  begin
    case happy_xst_slicing_wire is
    when "100" =>
      ldst_size <= "01";
    when "011" =>
      ldst_size <= "11";
    when "111" =>
      ldst_size <= "11";
    when others =>
      ldst_size <= "00";
    end case;
  end process;

  process (reset, clk)
  begin
    if (reset = '1') then
      ldst_size_reg <= "00";
    elsif (clk'event and clk='1') then
      if (instrreg_we = '1') then
        ldst_size_reg <= ldst_size;
        instr_reg <= apufcminstruction;
      end if;
    end if;
  end process;

  ldst_size_counter_we <=
    '1' when (((curr_state = STATE_LOAD) and (APUFCMLOADDVALID = '1')) or
              (curr_state = STATE_STORE) or
              ((curr_state = STATE_IDLE) and (valid_instr = '1') and (APUFCMLOADDVALID = '1'))) else
    '0';

  process (reset, clk)
  begin
    if (reset = '1') then
      ldst_size_counter <= "00";
    elsif (clk'event and clk='1') then
      if (instrreg_we = '1') then
        ldst_size_counter <= "00";
      elsif (ldst_size_counter_we = '1') then
        ldst_size_counter <= ldst_size_counter + "01";
      end if;
    end if;
  end process;

  process (reset, clk)
  begin
    if (reset = '1') then
      curr_state <= STATE_IDLE;
    elsif (clk'event and clk='1') then
      curr_state <= next_state;
    end if;
  end process;

  store_or_loadn <= APUFCMINSTRUCTION(23);
  valid_instr <= apufcminstrvalid and apufcmdecoded and not apufcmflush;
  more_data <= '1' when ((curr_state = STATE_IDLE) and (ldst_size /= unsigned'("00"))) or ((curr_state /= STATE_IDLE) and (ldst_size_counter < ldst_size_reg)) else '0';
  
  process (curr_state,valid_instr,apufcmflush,apufcmloaddvalid,store_or_loadn,more_data)
  begin
    case curr_state is
    when STATE_IDLE =>
      if (valid_instr = '1') then
        if (store_or_loadn = '1') then
          next_state <= STATE_STORE;
        else
          if ((apufcmloaddvalid = '1') and (more_data = '0')) then
            next_state <= STATE_IDLE;
          else
            next_state <= STATE_LOAD;
          end if;
        end if;
      else
        next_state <= STATE_IDLE;
      end if;
    when STATE_LOAD =>
      if ((apufcmloaddvalid = '1' and more_data = '0') or
          (apufcmflush = '1')) then
        next_state <= STATE_IDLE;
      else
        next_state <= STATE_LOAD;
      end if;
    when STATE_STORE =>
      if (more_data = '0') then
        next_state <= STATE_IDLE;
      else
        next_state <= STATE_STORE;
      end if;
    end case;
  end process;
  
  write_addr <=
    '1' when target(1 downto 0) = "00" else
    '1' when target(1 downto 0) = "10" else
    '0';

  stream_we <= apufcmloaddvalid and not apufcmflush
               when (curr_state = STATE_LOAD) or ((curr_state = STATE_IDLE) and (valid_instr = '1'))
               else '0';

  -- Write to stream
  stream_en <= stream_rdy and stream_we and write_addr;
  stream_eos <= '1' when target(1 downto 0) = "10" else '0';
  stream_data <= std_ulogic_vector(apufcmloaddata(0 to datawidth-1));

  -- Error detection
  check: process (reset, clk)
  begin
    if (reset = '1') then
      error <= '0';
    elsif (clk'event and clk='1') then
      if (stream_we = '1' and write_addr = '1' and stream_rdy = '0') then
        error <= '1';
      end if;
    end if;
  end process;
  
  -- Status register
  status(0) <= stream_rdy;
  status(1) <= '0';
  status(2) <= '0';
  status(3) <= error;
  status(31 downto 4) <= "0000000000000000000000000000";

  fcmapusleepnotready <= '0' when curr_state = STATE_IDLE else '1';
  fcmapuresult <= std_logic_vector(status) when curr_state = STATE_STORE else X"00000000";
  fcmapuresultvalid <= '1' when curr_state = STATE_STORE else '0';
  fcmapuloadwait <= '0';
  FCMAPUDONE <= ldst_size_counter_we when more_data = '0' else '0';
end rtl;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity stream_to_apu is
  generic (
    datawidth : positive := 8
  );
  port (
    reset, clk : in std_logic;
    apufcmce : std_logic;
    apufcminstruction : std_logic_vector(0 to 31);
    apufcminstrvalid : std_logic;
    apufcmradata : std_logic_vector(0 to 31);
    apufcmrbdata : std_logic_vector(0 to 31);
    apufcmoperandvalid : std_logic;
    apufcmflush : std_logic;
    apufcmwritebackok : std_logic;
    apufcmloaddata : std_logic_vector(0 to 31);
    apufcmloaddvalid : std_logic;
    apufcmloadbyteen : std_logic_vector(0 to 3);
    apufcmendian : std_logic;
    apufcmxerca : std_logic;
    apufcmdecoded : std_logic;
    apufcmdecudi : std_logic_vector(0 to 2);
    apufcmdecudivalid : std_logic;
    fcmapuresult : out std_logic_vector(0 to 31);
    fcmapudone : inout std_logic;
    fcmapusleepnotready : out std_logic;
    fcmapuloadwait : inout std_logic;
    fcmapuresultvalid : inout std_logic;
    stream_en : inout std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : in std_ulogic;
    stream_data : in std_ulogic_vector (datawidth-1 downto 0)
  );
end stream_to_apu;

architecture rtl of stream_to_apu is
  type stateType is (STATE_IDLE, STATE_LOAD, STATE_STORE);  
--  alias target : std_logic_vector(4 downto 0) is fcmapuinstruction(6 to 10);
  signal curr_state, next_state : stateType;
  signal instrreg_we, ldst_size_counter_we, store_or_loadn : std_logic;
  signal ldst_size, ldst_size_counter, ldst_size_reg : unsigned(1 downto 0);
  signal status, extended_data : std_ulogic_vector (31 downto 0);

  signal happy_xst_slicing_wire : std_logic_vector(0 to 2);
  signal instr_reg : std_logic_vector(0 to 31);
  signal target : std_logic_vector(4 downto 0);
  signal valid_instr, more_data, store_rdy : std_logic;
begin

  instrreg_we <= '1' when curr_state = STATE_IDLE else '0';
  happy_xst_slicing_wire <= apufcminstruction(22) & apufcminstruction(24 to 25);
  target <= instr_reg(6 to 10);

  process (happy_xst_slicing_wire)
  begin
    case happy_xst_slicing_wire is
    when "100" =>
      ldst_size <= "01";
    when "011" =>
      ldst_size <= "11";
    when "111" =>
      ldst_size <= "11";
    when others =>
      ldst_size <= "00";
    end case;
  end process;

  process (reset, clk)
  begin
    if (reset = '1') then
      ldst_size_reg <= "00";
    elsif (clk'event and clk='1') then
      if (instrreg_we = '1') then
        ldst_size_reg <= ldst_size;
        -- gme's additions
        instr_reg <= apufcminstruction;
      end if;
    end if;
  end process;

  ldst_size_counter_we <=
    '1' when (((curr_state = STATE_LOAD) and (APUFCMLOADDVALID = '1')) or
              ((curr_state = STATE_STORE) and (store_rdy = '1')) or
              ((curr_state = STATE_IDLE) and (valid_instr = '1') and (APUFCMLOADDVALID = '1'))) else
    '0';

  process (reset, clk)
  begin
    if (reset = '1') then
      ldst_size_counter <= "00";
    elsif (clk'event and clk='1') then
      if (instrreg_we = '1') then
        ldst_size_counter <= "00";
      elsif (ldst_size_counter_we = '1') then
        ldst_size_counter <= ldst_size_counter + "01";
      end if;
    end if;
  end process;

  process (reset, clk)
  begin
    if (reset = '1') then
      curr_state <= STATE_IDLE;
    elsif (clk'event and clk='1') then
      curr_state <= next_state;
    end if;
  end process;

  store_or_loadn <= APUFCMINSTRUCTION(23);
  valid_instr <= apufcminstrvalid and apufcmdecoded and not apufcmflush;
  more_data <= '1' when ((curr_state = STATE_IDLE) and (ldst_size /= unsigned'("00"))) or ((curr_state /= STATE_IDLE) and (ldst_size_counter < ldst_size_reg)) else '0';
  store_rdy <= stream_rdy when target(1 downto 0) = "00" else '1';
  
  process (curr_state,valid_instr,apufcmloaddvalid,more_data,apufcmflush,store_or_loadn,store_rdy)
  begin
    case curr_state is
    when STATE_IDLE =>
      if (valid_instr = '1') then
        if (store_or_loadn = '1') then
          next_state <= STATE_STORE;
        else
          if ((apufcmloaddvalid = '1') and (more_data = '0')) then
            next_state <= STATE_IDLE;
          else
            next_state <= STATE_LOAD;
          end if;
        end if;
      else
        next_state <= STATE_IDLE;
      end if;
    when STATE_LOAD =>
      if ((apufcmloaddvalid = '1' and more_data = '0') or
          (apufcmflush = '1')) then
        next_state <= STATE_IDLE;
      else
        next_state <= STATE_LOAD;
      end if;
    when STATE_STORE =>
      if (more_data = '0' and store_rdy = '1') then
        next_state <= STATE_IDLE;
      else
        next_state <= STATE_STORE;
      end if;
    end case;
  end process;
  
--  extended_data(31 downto datawidth) <= (others => '0');
  extended_data(datawidth - 1 downto 0) <= stream_data;

  -- Status register
  status(0) <= stream_rdy;
  status(1) <= stream_eos;
  status(2) <= '0';
  status(3) <= '0';
  status(31 downto 4) <= "0000000000000000000000000000";

  stream_en <= stream_rdy
               when curr_state = STATE_STORE and target(1 downto 0) = "00"
               else '0';

  fcmapusleepnotready <= '0' when curr_state = STATE_IDLE else '1';
  -- gme: the constant at addr 01 is just for debugging
  fcmapuresult <=
    std_logic_vector(extended_data) when curr_state = STATE_STORE and target(1 downto 0) = "00" else
    X"12345678" when curr_state = STATE_STORE and target(1 downto 0) = "01" else
    std_logic_vector(status) when curr_state = STATE_STORE else
    X"00000000";
  fcmapuresultvalid <= '1' when ((curr_state = STATE_STORE) and (store_rdy = '1')) else '0';
  fcmapuloadwait <= '0';

  FCMAPUDONE <= ldst_size_counter_we when more_data = '0' else '0';
end rtl;


library ieee;
use ieee.std_logic_1164.all;

package apu_if is

  component apu_to_stream is
  generic (
    datawidth : positive := 8
  );
  port (
    reset, clk : in std_logic;
    apufcmce : std_logic;
    apufcminstruction : std_logic_vector(0 to 31);
    apufcminstrvalid : std_logic;
    apufcmradata : std_logic_vector(0 to 31);
    apufcmrbdata : std_logic_vector(0 to 31);
    apufcmoperandvalid : std_logic;
    apufcmflush : std_logic;
    apufcmwritebackok : std_logic;
    apufcmloaddata : std_logic_vector(0 to 31);
    apufcmloaddvalid : std_logic;
    apufcmloadbyteen : std_logic_vector(0 to 3);
    apufcmendian : std_logic;
    apufcmxerca : std_logic;
    apufcmdecoded : std_logic;
    apufcmdecudi : std_logic_vector(0 to 2);
    apufcmdecudivalid : std_logic;
    fcmapuresult : out std_logic_vector(0 to 31);
    fcmapudone : inout std_logic;
    fcmapusleepnotready : out std_logic;
    fcmapuloadwait : inout std_logic;
    fcmapuresultvalid : inout std_logic;
    stream_en : inout std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : inout std_ulogic;
    stream_data : out std_ulogic_vector (datawidth-1 downto 0)
  );
  end component;

  component stream_to_apu is
  generic (
    datawidth : positive := 8
  );
  port (
    reset, clk : in std_logic;
    apufcmce : std_logic;
    apufcminstruction : std_logic_vector(0 to 31);
    apufcminstrvalid : std_logic;
    apufcmradata : std_logic_vector(0 to 31);
    apufcmrbdata : std_logic_vector(0 to 31);
    apufcmoperandvalid : std_logic;
    apufcmflush : std_logic;
    apufcmwritebackok : std_logic;
    apufcmloaddata : std_logic_vector(0 to 31);
    apufcmloaddvalid : std_logic;
    apufcmloadbyteen : std_logic_vector(0 to 3);
    apufcmendian : std_logic;
    apufcmxerca : std_logic;
    apufcmdecoded : std_logic;
    apufcmdecudi : std_logic_vector(0 to 2);
    apufcmdecudivalid : std_logic;
    fcmapuresult : out std_logic_vector(0 to 31);
    fcmapudone : inout std_logic;
    fcmapusleepnotready : out std_logic;
    fcmapuloadwait : inout std_logic;
    fcmapuresultvalid : inout std_logic;
    stream_en : inout std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : in std_ulogic;
    stream_data : in std_ulogic_vector (datawidth-1 downto 0)
  );
  end component;
end package;


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
-- plb_if.vhd: PLB interface components                                 --
--                                                                      --
-- Change History
-- --------------
-- 7/7/2004 - Scott Thibault
--   File created.
--
--------------------------------------------------------------------------

-----------------------------------------------------------------------
-- impulse_plb_ipif
--   This component handles the PLB slave interface and presents
--   a simplified interface to the other PLB <-> impulse components.
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity impulse_plb_ipif is
  generic
  (
    C_BASEADDR : std_logic_vector(0 to 31) := X"FFFFFFFF";
    C_HIGHADDR : std_logic_vector(0 to 31) := X"00000000";
    C_PLB_NUM_MASTERS : integer := 8;
    C_PLB_MID_WIDTH   : integer := 3;
    C_PLB_AWIDTH      : integer := 32;
    C_PLB_DWIDTH      : integer := 64;
    C_IPIF_AWIDTH     : integer := 32
  );
  port
  (
    PLB_Clk : in std_logic;
    PLB_Rst : in std_logic;
    PLB_abort : in std_logic;
    PLB_masterID : in  std_logic_vector(0 to C_PLB_MID_WIDTH-1);
    PLB_PAValid : in std_logic;
    PLB_RNW : in std_logic;
    PLB_ABus : in std_logic_vector(0 to C_PLB_AWIDTH-1);
    PLB_wrDBus : in std_logic_vector(0 to C_PLB_DWIDTH-1);
    Sl_MBusy : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
    Sl_MErr : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
    Sl_rearbitrate : out std_logic;
    Sl_wait : out std_logic;
    Sl_SSize : out std_logic_vector(0 to 1);
    Sl_addrAck : out std_logic;
    Sl_rdBTerm : out std_logic;
    Sl_rdComp : out std_logic;
    Sl_rdDAck : out std_logic;
    Sl_rdWdAddr : out std_logic_vector(0 to 3) ;
    Sl_rdDBus : out std_logic_vector(0 to C_PLB_DWIDTH-1);
    Sl_wrBTerm : out std_logic;
    Sl_wrComp : out std_logic;
    Sl_wrDAck : out std_logic;
    IP2Bus_data : in std_logic_vector (C_PLB_DWIDTH-1 downto 0);
    Bus2IP_Reset : out std_logic;
    Bus2IP_Clk : out std_logic;
    Bus2IP_CS : out std_logic;
    Bus2IP_RdCE : out std_logic;
    Bus2IP_WrCE : out std_logic;
    Bus2IP_raddr : out std_logic_vector (C_IPIF_AWIDTH-1 downto 0);
    Bus2IP_waddr : out std_logic_vector (C_IPIF_AWIDTH-1 downto 0);
    Bus2IP_data : out std_logic_vector (C_PLB_DWIDTH-1 downto 0)
  );
end;

architecture imp of impulse_plb_ipif is
  signal CS0 : std_ulogic;
  signal RdCe1, RdCe2 : std_ulogic;
  signal WrCe0, WrCe1 : std_ulogic;
  signal MasterId : integer range 0 to C_PLB_NUM_MASTERS-1;
  signal MasterMask0, MasterMask1, MasterMask2 : std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
  signal Sl_Mbusy_i : std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
  signal ClearMbusy, SetMbusy : std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
begin
  --
  -- Local signals
  --

  -- Cycle 0 chip select
  CS0 <= PLB_PAValid when PLB_ABus(0 to 31-C_IPIF_AWIDTH) = C_BASEADDR(0 to 31-C_IPIF_AWIDTH) else '0';

  MasterId <= CONV_INTEGER(PLB_masterId);

  process (MasterId)
  begin
    MasterMask0 <= (0 to C_PLB_NUM_MASTERS-1 => '0');
    MasterMask0(MasterId) <= '1';
  end process;

  process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      MasterMask1 <= MasterMask0;
      MasterMask2 <= MasterMask1;
    end if;
  end process;

  process (PLB_Clk, PLB_Rst)
  begin
    if (PLB_Rst = '1') then
      RdCe1 <= '0';
      RdCe2 <= '0';
    elsif (PLB_Clk'event and PLB_Clk='1') then
      RdCe1 <= CS0 and PLB_RNW and not PLB_abort;
      RdCe2 <= RdCe1;
    end if;
  end process;

  WrCe0 <= CS0 and not PLB_RNW;
  process (PLB_Clk, PLB_Rst)
  begin
    if (PLB_Rst = '1') then
      WrCe1 <= '0';
    elsif (PLB_Clk'event and PLB_Clk='1') then
      WrCe1 <= WrCe0 and not PLB_abort;
    end if;
  end process;

  --
  -- Bus Side
  --

  -- Common signals
  Sl_wait <= '0';
  Sl_rearbitrate <= '0';
  Sl_SSize <= "00";
  Sl_addrAck <= CS0;
  Sl_MErr <= (0 to C_PLB_NUM_MASTERS-1 => '0');

  SetMBusy <= MasterMask0 when CS0 = '1' else (0 to C_PLB_NUM_MASTERS-1 => '0');

  process (RdCe2, WrCe1, MasterMask2, MasterMask1)
    variable clear : std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
  begin
    clear := (0 to C_PLB_NUM_MASTERS-1 => '0');
    if (RdCe2 = '1') then
      clear := clear or MasterMask2;
    end if;
    if (WrCe1 = '1') then
      clear := clear or MasterMask1;
    end if;
    ClearMBusy <= clear;
  end process;

  busy_reg : process (PLB_Clk, PLB_Rst)
  begin
    if (PLB_Rst = '1') then
      Sl_MBusy_i <= (0 to C_PLB_NUM_MASTERS-1 => '0');
    elsif (PLB_Clk'event and PLB_Clk='1') then
      Sl_MBusy_i <= (Sl_MBusy_i and not ClearMBusy) or SetMBusy;
    end if;    
  end process;

  Sl_MBusy <= Sl_MBusy_i;

  -- Read signals
  latch_result : process (PLB_Clk, PLB_Rst)
  begin
    if (PLB_Rst = '1') then
      Sl_rdDbus <= (0 to C_PLB_DWIDTH-1 => '0');
    elsif (PLB_Clk'event and PLB_Clk='1') then
      if (RdCe1 = '1') then
        Sl_rdDBus <= IP2Bus_data;
      else
        Sl_rdDbus <= (0 to C_PLB_DWIDTH-1 => '0');
      end if;
    end if;
  end process;
  Sl_rdComp <= RdCe1;
  Sl_rdDAck <= RdCe2;
  Sl_rdWdAddr <= "0000";
  Sl_rdBTerm <= '0';

  -- Write signals
  Sl_wrComp <= WrCe0;
  Sl_wrDAck <= WrCe0;
  Sl_wrBTerm <= '0';
  
  --
  -- IP Side
  --

  -- Common signals
  Bus2IP_Reset <= PLB_Rst;
  Bus2IP_Clk <= PLB_Clk;
  Bus2IP_CS <= RdCe1 or (WrCe0 and not PLB_abort);

  -- Read signals
  Bus2IP_RdCe <= RdCe1;
  latch_read : process (PLB_Clk)
  begin
    if (PLB_Clk'event and PLB_Clk='1') then
      Bus2IP_raddr <= PLB_ABus(C_PLB_AWIDTH-C_IPIF_AWIDTH to C_PLB_AWIDTH-1);
    end if;
  end process;

  -- Write signals
  Bus2IP_data <= PLB_wrDBus;
  Bus2IP_WrCe <= WrCe0 and not PLB_abort;
  Bus2IP_waddr <= PLB_ABus(C_PLB_AWIDTH-C_IPIF_AWIDTH to C_PLB_AWIDTH-1);
end;


-----------------------------------------------------------------------
-- plb_to_stream
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity plb_to_stream is
  generic (
    datawidth : positive := 8
  );
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    stream_en : out std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : out std_ulogic;
    stream_data : out std_ulogic_vector (datawidth-1 downto 0)
  );
end plb_to_stream;

architecture rtl of plb_to_stream is
  signal error, write_addr : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
begin
  write_addr <=
    '1' when plb_waddr = "0" else
    '1' when plb_waddr = "1" else
    '0';

  -- Write to stream
  stream_en <= stream_rdy and plb_ce and plb_write and write_addr;
  stream_eos <= '1' when plb_waddr = "1" else '0';
  stream_data <= std_ulogic_vector(plb_wdata(datawidth-1 downto 0));

  -- Error detection
  check: process (plb_reset, clk)
  begin
    if (plb_reset = '1') then
      error <= '0';
    elsif (clk'event and clk='1') then
      if (plb_ce = '1' and plb_write = '1' and write_addr = '1') then
        error <= not stream_rdy;
      end if;
    end if;
  end process;
  
  -- Status register
  status(0) <= stream_rdy;
  status(1) <= '0';
  status(2) <= '0';
  status(3) <= error;
  status(31 downto 4) <= (31 downto 4 => '0');

  plb_rdata <=
    std_logic_vector(status) & X"00000000" when plb_raddr = "1" else
    X"0000000000000000";
end rtl;

-----------------------------------------------------------------------
-- stream_to_plb
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity stream_to_plb is
  generic (
    datawidth : positive := 8
  );
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    stream_en : out std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : in std_ulogic;
    stream_data : in std_ulogic_vector (datawidth-1 downto 0)
  );
end stream_to_plb;

architecture rtl of stream_to_plb is
  signal accept, valid, eos, error, address_stream : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
  signal data : std_ulogic_vector (31 downto 0);
  signal extended_data : std_ulogic_vector (31 downto 0);
begin
  address_stream <= '1' when plb_raddr = "0" else '0';
  -- Read register
  accept <= (not valid or (plb_ce and plb_read and address_stream));

  zext: if datawidth < 32 generate
    -- XST can't handle 31 downto 32.
    extended_data(31 downto datawidth) <= (others => '0');
  end generate;
  extended_data(datawidth - 1 downto 0) <= stream_data;

  read_stream: process (plb_reset, clk)
  begin
    if (plb_reset = '1') then
      valid <= '0';
      eos <= '0';
    elsif (clk'event and clk='1') then
      if (stream_rdy = '1' and accept = '1') then
        data <= extended_data;
        eos <= stream_eos;
        valid <= '1';
      elsif (plb_ce = '1' and plb_read = '1' and address_stream = '1') then
        valid <= '0';
      end if;
    end if;
  end process;

  stream_en <= accept;

  -- Error detection
  check: process (plb_reset, clk)
  begin
    if (plb_reset = '1') then
      error <= '0';
    elsif (clk'event and clk='1') then
      if (plb_ce = '1' and plb_read = '1' and address_stream = '1') then
        error <= not valid;
      end if;
    end if;
  end process;
  
  -- Status register
  status(0) <= valid;
  status(1) <= eos;
  status(2) <= '0';
  status(3) <= error;
  status(31 downto 4) <= (31 downto 4 => '0');

  plb_rdata <=
    std_logic_vector(data) & X"00000000" when plb_raddr = "0" else
    std_logic_vector(status) & X"00000000" when plb_raddr = "1" else
    X"0000000000000000";
end rtl;


-----------------------------------------------------------------------
-- plb_to_signal
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity plb_to_signal is
  generic (
    datawidth : positive := 32
  );
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    signal_en : out std_ulogic;
    signal_data : out std_ulogic_vector (datawidth-1 downto 0)
  );
end plb_to_signal;

architecture rtl of plb_to_signal is
  signal error, write_addr : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
begin
  write_addr <= '1' when plb_waddr = "0" else '0';

  -- Write to stream
  signal_en <= plb_ce and plb_write and write_addr;
  signal_data <= std_ulogic_vector(plb_wdata(datawidth-1 downto 0));

  -- Status register
  status <= X"00000001"; -- Always ready/no errors.

  plb_rdata <=
    std_logic_vector(status) & X"00000000" when plb_raddr = "1" else
    X"0000000000000000";
end rtl;

-----------------------------------------------------------------------
-- signal_to_plb
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity signal_to_plb is
  generic (
    datawidth : positive := 32
  );
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    signal_en : out std_ulogic;
    signal_rdy : in std_ulogic;
    signal_data : in std_ulogic_vector (datawidth-1 downto 0)
  );
end signal_to_plb;

architecture rtl of signal_to_plb is
  signal accept, valid, eos, error, address_signal : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
  signal data : std_ulogic_vector (31 downto 0);
  signal extended_data : std_ulogic_vector (31 downto 0);
begin
  address_signal <= '1' when plb_raddr = "0" else '0';
  -- Read register
  accept <= '1';

  zext : if datawidth < 32 generate
    extended_data(31 downto datawidth) <= (others => '0');
  end generate;
  extended_data(datawidth - 1 downto 0) <= signal_data;

  read_stream: process (plb_reset, clk)
  begin
    if (plb_reset = '1') then
      valid <= '0';
      eos <= '0';
    elsif (clk'event and clk='1') then
      if (signal_rdy = '1' and accept = '1') then
        data <= extended_data;
        valid <= '1';
      elsif (plb_ce = '1' and plb_read = '1' and address_signal = '1') then
        valid <= '0';
      end if;
    end if;
  end process;

  signal_en <= accept;

  -- Error detection
  check: process (plb_reset, clk)
  begin
    if (plb_reset = '1') then
      error <= '0';
    elsif (clk'event and clk='1') then
      if (plb_ce = '1' and plb_read = '1' and address_signal = '1') then
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

  plb_rdata <=
    std_logic_vector(data) & X"00000000" when plb_raddr = "0" else
    std_logic_vector(status) & X"00000000" when plb_raddr = "1" else
    X"0000000000000000";
end rtl;

-----------------------------------------------------------------------
-- plb_to_register
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity plb_to_register is
  generic (
    datawidth : positive := 32
  );
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    register_en : out std_ulogic;
    register_data : out std_ulogic_vector (datawidth-1 downto 0)
  );
end plb_to_register;

architecture rtl of plb_to_register is
  signal write_addr : std_ulogic;
  signal status : std_ulogic_vector (31 downto 0);
begin
  write_addr <= '1' when plb_waddr = "0" else '0';

  -- Write to register
  register_en <= plb_ce and plb_write and write_addr;
  register_data <= std_ulogic_vector(plb_wdata(datawidth-1 downto 0));

  -- Status register
  status <= X"00000001"; -- Always ready/no errors.

  plb_rdata <=
    std_logic_vector(status) & X"00000000" when plb_raddr = "1" else
    X"0000000000000000";
end rtl;

-----------------------------------------------------------------------
-- register_to_plb
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity register_to_plb is
  generic (
    datawidth : positive := 32
  );
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    register_value : in std_ulogic_vector (datawidth-1 downto 0)
  );
end register_to_plb;

architecture rtl of register_to_plb is
  signal status : std_ulogic_vector (31 downto 0);
  signal extended_data : std_ulogic_vector (31 downto 0);
begin
  zext: if datawidth < 32 generate
    extended_data(31 downto datawidth) <= (others => '0');
  end generate;
  extended_data(datawidth - 1 downto 0) <= register_value;

  -- Status register
  status <= X"00000001"; -- Always ready/no errors.

  plb_rdata <=
    std_logic_vector(extended_data) & X"00000000" when plb_raddr = "0" else
    std_logic_vector(status) & X"00000000" when plb_raddr = "1" else
    X"0000000000000000";
end rtl;

-----------------------------------------------------------------------
-- plb_if package
-----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package plb_if is
  component impulse_plb_ipif is
  generic
  (
    C_BASEADDR : std_logic_vector(0 to 31) := X"FFFFFFFF";
    C_HIGHADDR : std_logic_vector(0 to 31) := X"00000000";
    C_PLB_NUM_MASTERS : integer := 8;
    C_PLB_MID_WIDTH   : integer := 3;
    C_PLB_AWIDTH      : integer := 32;
    C_PLB_DWIDTH      : integer := 64;
    C_IPIF_AWIDTH     : integer := 32
  );
  port
  (
    PLB_Clk : in std_logic;
    PLB_Rst : in std_logic;
    PLB_abort : in std_logic;
    PLB_masterID : in  std_logic_vector(0 to C_PLB_MID_WIDTH-1);
    PLB_PAValid : in std_logic;
    PLB_RNW : in std_logic;
    PLB_ABus : in std_logic_vector(0 to C_PLB_AWIDTH-1);
    PLB_wrDBus : in std_logic_vector(0 to C_PLB_DWIDTH-1);
    Sl_MBusy : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
    Sl_MErr : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
    Sl_rearbitrate : out std_logic;
    Sl_wait : out std_logic;
    Sl_SSize : out std_logic_vector(0 to 1);
    Sl_addrAck : out std_logic;
    Sl_rdBTerm : out std_logic;
    Sl_rdComp : out std_logic;
    Sl_rdDAck : out std_logic;
    Sl_rdWdAddr : out std_logic_vector(0 to 3) ;
    Sl_rdDBus : out std_logic_vector(0 to C_PLB_DWIDTH-1);
    Sl_wrBTerm : out std_logic;
    Sl_wrComp : out std_logic;
    Sl_wrDAck : out std_logic;
    IP2Bus_data : in std_logic_vector (C_PLB_DWIDTH-1 downto 0);
    Bus2IP_Reset : out std_logic;
    Bus2IP_Clk : out std_logic;
    Bus2IP_CS : out std_logic;
    Bus2IP_RdCE : out std_logic;
    Bus2IP_WrCE : out std_logic;
    Bus2IP_raddr : out std_logic_vector (C_IPIF_AWIDTH-1 downto 0);
    Bus2IP_waddr : out std_logic_vector (C_IPIF_AWIDTH-1 downto 0);
    Bus2IP_data : out std_logic_vector (C_PLB_DWIDTH-1 downto 0)
  );
  end component;

  component plb_to_signal is
  generic (datawidth : positive := 32);
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    signal_en : out std_ulogic;
    signal_data : out std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component signal_to_plb is
  generic (datawidth : positive := 32);
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    signal_en : out std_ulogic;
    signal_rdy : in std_ulogic;
    signal_data : in std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component plb_to_register is
  generic (datawidth : positive := 32);
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    register_en : out std_ulogic;
    register_data : out std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component register_to_plb is
  generic (datawidth : positive := 32);
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    register_value : in std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component plb_to_stream is
  generic (datawidth : positive := 8);
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    stream_en : out std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : out std_ulogic;
    stream_data : out std_ulogic_vector (datawidth-1 downto 0));
  end component;

  component stream_to_plb is
  generic (datawidth : positive := 8);
  port (
    clk : in std_logic;
    plb_raddr : in std_logic_vector (0 downto 0);
    plb_waddr : in std_logic_vector (0 downto 0);
    plb_ce : in std_logic;
    plb_read : in std_logic;
    plb_reset : in std_logic;
    plb_write : in std_logic;
    plb_wdata : in std_logic_vector (63 downto 0);
    plb_rdata : out std_logic_vector (63 downto 0);
    stream_en : out std_ulogic;
    stream_rdy : in std_ulogic;
    stream_eos : in std_ulogic;
    stream_data : in std_ulogic_vector (datawidth-1 downto 0));
  end component;

component plb_dma is
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
end component;
end;


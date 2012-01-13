-- 
-- Copyright (c) 2002-2009 by Impulse Accelerated Technologies, Inc.
-- All rights reserved.
-- 
-- This source file may be used and redistributed without charge
-- subject to the provisions of the IMPULSE ACCELERATED TECHNOLOGIES,
-- INC. REDISTRIBUTABLE IP LICENSE AGREEMENT, and provided that this
-- copyright statement is not removed from the file, and that any
-- derivative work contains this copyright notice.
-- 
library ieee;
use ieee.std_logic_1164.all;

library impulse;
use impulse.apu_if.all;

library apu_FPGA_arch_v1_00_a;
use apu_FPGA_arch_v1_00_a.all;


entity apu_FPGA_arch is
  generic (
    C_FAMILY           : string                    := "virtex4"  );
  port (
    -- apu ports
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
    fcmapuinstrack : out std_logic;
    fcmapuresult : out std_logic_vector(0 to 31);
    fcmapudone : out std_logic;
    fcmapusleepnotready : out std_logic;
    fcmapudecodebusy : out std_logic;
    fcmapudcdgprwrite : out std_logic;
    fcmapudcdraen : out std_logic;
    fcmapudcdrben : out std_logic;
    fcmapudcdprivop : out std_logic;
    fcmapudcdforcealign : out std_logic;
    fcmapudcdxeroven : out std_logic;
    fcmapudcdxercaen : out std_logic;
    fcmapudcdcren : out std_logic;
    fcmapuexecrfield : out std_logic_vector(0 to 2);
    fcmapudcdload : out std_logic;
    fcmapudcdstore : out std_logic;
    fcmapudcdupdate : out std_logic;
    fcmapudcdldstbyte : out std_logic;
    fcmapudcdldsthw : out std_logic;
    fcmapudcdldstwd : out std_logic;
    fcmapudcdldstdw : out std_logic;
    fcmapudcdldstqw : out std_logic;
    fcmapudcdtraple : out std_logic;
    fcmapudcdtrapbe : out std_logic;
    fcmapudcdforcebesteering : out std_logic;
    fcmapudcdfpuop : out std_logic;
    fcmapuexeblockingmco : out std_logic;
    fcmapuexenonblockingmco : out std_logic;
    fcmapuloadwait : out std_logic;
    fcmapuresultvalid : out std_logic;
    fcmapuxerov : out std_logic;
    fcmapuxerca : out std_logic;
    fcmapucr : out std_logic_vector(0 to 3);
    fcmapuexception : out std_logic;
    apu_clk, reset : in std_logic;
    co_clk : in std_logic
    );
end apu_FPGA_arch;

architecture impl of apu_FPGA_arch is
  component FPGA_arch is
    port (
    reset : in std_ulogic;
    sclk : in std_ulogic;
    clk : in std_ulogic;
    p_Producer_input_en : in std_ulogic;
    p_Producer_input_eos : in std_ulogic;
    p_Producer_input_data : in std_ulogic_vector (31 downto 0);
    p_Producer_input_rdy : out std_ulogic;
    p_Consumer_output_en : in std_ulogic;
    p_Consumer_output_data : out std_ulogic_vector (31 downto 0);
    p_Consumer_output_eos : out std_ulogic;
    p_Consumer_output_rdy : out std_ulogic
    );
  end component;

  signal p_Producer_input_rdy : std_ulogic;
  signal p_Producer_input_en : std_ulogic;
  signal p_Producer_input_eos : std_ulogic;
  signal p_Producer_input_idata : std_ulogic_vector (31 downto 0);
  signal p_Consumer_output_rdy : std_ulogic;
  signal p_Consumer_output_en : std_ulogic;
  signal p_Consumer_output_eos : std_ulogic;
  signal p_Consumer_output_idata : std_ulogic_vector (31 downto 0);

  signal p_Producer_input_result : std_logic_vector(0 to 31);
  signal p_Producer_input_done : std_logic;
  signal p_Producer_input_sleepnotready : std_logic;
  signal p_Producer_input_loadwait : std_logic;
  signal p_Producer_input_resultvalid : std_logic;
  signal p_Producer_input_cs : std_logic;
  signal p_Producer_input_instrvalid : std_logic;
  signal p_Consumer_output_result : std_logic_vector(0 to 31);
  signal p_Consumer_output_done : std_logic;
  signal p_Consumer_output_sleepnotready : std_logic;
  signal p_Consumer_output_loadwait : std_logic;
  signal p_Consumer_output_resultvalid : std_logic;
  signal p_Consumer_output_cs : std_logic;
  signal p_Consumer_output_instrvalid : std_logic;

  -- apu signals
  signal apusel : std_logic_vector(0 to 0);
  signal apufcmdecfpuop : std_logic;
  -- end apu signals
begin
apusel <= apufcminstruction(8 to 8);
  apufcmdecfpuop <= '1' when apufcminstruction(0)='1' or apufcminstruction(26)='1' else '0';
  p_Producer_input_cs <= '1' when apusel = "0" else '0';
  p_Producer_input_instrvalid <= '1' when (apufcminstrvalid = '1') and (p_Producer_input_cs = '1') and apufcmdecfpuop = '0' else '0';
  p_Producer_input_if: apu_to_stream
    generic map (
      datawidth => 32
    )
    port map (
      reset, apu_clk,
      p_Producer_input_cs,
      apufcminstruction,
      p_Producer_input_instrvalid,
      apufcmradata,
      apufcmrbdata,
      apufcmoperandvalid,
      apufcmflush,
      apufcmwritebackok,
      apufcmloaddata,
      apufcmloaddvalid,
      apufcmloadbyteen,
      apufcmendian,
      apufcmxerca,
      apufcmdecoded,
      apufcmdecudi,
      apufcmdecudivalid,
      p_Producer_input_result,
      p_Producer_input_done,
      p_Producer_input_sleepnotready,
      p_Producer_input_loadwait,
      p_Producer_input_resultvalid,
      p_Producer_input_en,
      p_Producer_input_rdy,
      p_Producer_input_eos,
      p_Producer_input_idata
    );

  p_Consumer_output_cs <= '1' when apusel = "1" else '0';
  p_Consumer_output_instrvalid <= '1' when (apufcminstrvalid = '1') and (p_Consumer_output_cs = '1') and apufcmdecfpuop = '0' else '0';
  p_Consumer_output_if: stream_to_apu
    generic map (
      datawidth => 32
    )
    port map (
      reset, apu_clk,
      p_Consumer_output_cs,
      apufcminstruction,
      p_Consumer_output_instrvalid,
      apufcmradata,
      apufcmrbdata,
      apufcmoperandvalid,
      apufcmflush,
      apufcmwritebackok,
      apufcmloaddata,
      apufcmloaddvalid,
      apufcmloadbyteen,
      apufcmendian,
      apufcmxerca,
      apufcmdecoded,
      apufcmdecudi,
      apufcmdecudivalid,
      p_Consumer_output_result,
      p_Consumer_output_done,
      p_Consumer_output_sleepnotready,
      p_Consumer_output_loadwait,
      p_Consumer_output_resultvalid,
      p_Consumer_output_en,
      p_Consumer_output_rdy,
      p_Consumer_output_eos,
      p_Consumer_output_idata
    );

  fcmapuresult <= p_Producer_input_result or p_Consumer_output_result;
  fcmapudone <= p_Producer_input_done or p_Consumer_output_done;
  fcmapusleepnotready <= p_Producer_input_sleepnotready or p_Consumer_output_sleepnotready;
  fcmapuloadwait <= p_Producer_input_loadwait or p_Consumer_output_loadwait;
  fcmapuresultvalid <= p_Producer_input_resultvalid or p_Consumer_output_resultvalid;

  -- unused signals
  FCMAPUINSTRACK <= '0';
  FCMAPUDECODEBUSY <= '0';
  FCMAPUDCDGPRWRITE <= '0';
  FCMAPUDCDRAEN <= '0';
  FCMAPUDCDRBEN <= '0';
  FCMAPUDCDPRIVOP <= '0';
  FCMAPUDCDFORCEALIGN <= '0';
  FCMAPUDCDXEROVEN <= '0';
  FCMAPUDCDXERCAEN <= '0';
  FCMAPUDCDCREN <= '0';
  FCMAPUEXECRFIELD <= "000";
  FCMAPUDCDLOAD <= '0';
  FCMAPUDCDSTORE <= '0';
  FCMAPUDCDUPDATE <= '0';
  FCMAPUDCDLDSTBYTE <= '0';
  FCMAPUDCDLDSTHW <= '0';
  FCMAPUDCDLDSTWD <= '0';
  FCMAPUDCDLDSTDW <= '0';
  FCMAPUDCDLDSTQW <= '0';
  FCMAPUDCDTRAPLE <= '0';
  FCMAPUDCDTRAPBE <= '0';
  FCMAPUDCDFORCEBESTEERING <= '0';
  FCMAPUDCDFPUOP <= '0';
  FCMAPUEXEBLOCKINGMCO <= '0';
  FCMAPUEXENONBLOCKINGMCO <= '0';
  FCMAPUXEROV <= '0';
  FCMAPUXERCA <= '0';
  FCMAPUCR <= "0000";
  FCMAPUEXCEPTION <= '0';

  FPGA_arch_0: FPGA_arch
    port map (
      reset,
      apu_clk,
      co_clk,
      p_Producer_input_en,
      p_Producer_input_eos,
      p_Producer_input_idata,
      p_Producer_input_rdy,
      p_Consumer_output_en,
      p_Consumer_output_idata,
      p_Consumer_output_eos,
      p_Consumer_output_rdy);

end;


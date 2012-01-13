-----------------------------------------------------------------------
-- Copyright (c) 2007, Green Mountain Computing Systems
-- All Rights Reserved.
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

package autoip is
  attribute ccs_op : string;

  function conv_integer(arg: std_ulogic_vector) return natural;
  
  function ai_neg(v1 : std_ulogic_vector) return std_ulogic_vector;
  attribute ccs_op of ai_neg : function is  "-";

  function ai_add(v1, v2 : std_ulogic_vector) return std_ulogic_vector;
  attribute ccs_op of ai_add : function is  "+";

  function ai_sub(v1, v2 : std_ulogic_vector) return std_ulogic_vector;
  attribute ccs_op of ai_sub : function is  "-";

  function ai_muls(v1, v2 : std_ulogic_vector) return std_ulogic_vector;
  attribute ccs_op of ai_muls : function is  "s*";

  function ai_mulu(v1, v2 : std_ulogic_vector) return std_ulogic_vector;
  attribute ccs_op of ai_mulu : function is  "u*";

  function ai_eq(v1, v2 : std_ulogic_vector) return boolean;
  attribute ccs_op of ai_eq : function is  "==";

  function ai_neq(v1, v2 : std_ulogic_vector) return boolean;
  attribute ccs_op of ai_neq : function is  "!=";

  function ai_not(v1 : std_ulogic_vector) return std_ulogic_vector;
  attribute ccs_op of ai_not : function is  "!";

  function ai_shl(arg: std_ulogic_vector; count: std_ulogic_vector) return std_ulogic_vector;
  attribute ccs_op of ai_shl : function is  "<<";

  function ai_lshr(arg: std_ulogic_vector; count: std_ulogic_vector) return std_ulogic_vector;
  attribute ccs_op of ai_lshr : function is  "u>>";

  function ai_ashr(arg: std_ulogic_vector; count: std_ulogic_vector) return std_ulogic_vector;
  attribute ccs_op of ai_ashr : function is  "s>>";
end package;

package body autoip is
  function conv_integer (arg: std_ulogic_vector) return natural is
    variable result: natural := 0;
  begin
    for I in arg'range loop
      result := result+result;
      if arg(I) = '1' then
        result := result + 1;
      end if;
    end loop;
    return result;
  end CONV_INTEGER;

    function ai_neg(v1 : std_ulogic_vector) return std_ulogic_vector is
    variable u1, res : unsigned (v1'length-1 downto 0);
    variable zero : unsigned (v1'length-1 downto 0) := (others => '0');
  begin
    u1 := unsigned(v1);
    res := zero - u1;
    return std_ulogic_vector(res);
  end function;

  function ai_add(v1, v2 : std_ulogic_vector) return std_ulogic_vector is
    variable u1, u2, res : unsigned (v1'length-1 downto 0);
  begin
    u1 := unsigned(v1);
    u2 := unsigned(v2);
    res := u1 + u2;
    return std_ulogic_vector(res);
  end function;

  function ai_sub(v1, v2 : std_ulogic_vector) return std_ulogic_vector is
    variable u1, u2, res : unsigned (v1'length-1 downto 0);
  begin
    u1 := unsigned(v1);
    u2 := unsigned(v2);
    res := u1 - u2;
    return std_ulogic_vector(res);
  end function;

  function ai_mulu(v1, v2 : std_ulogic_vector) return std_ulogic_vector is
    variable u1 : unsigned (v1'length-1 downto 0);
    variable u2 : unsigned (v2'length-1 downto 0);
    variable res : unsigned (v1'length+v2'length-1 downto 0);
  begin
    u1 := unsigned(v1);
    u2 := unsigned(v2);
    res := u1 * u2;
    return std_ulogic_vector(res);
  end function;

  function ai_muls(v1, v2 : std_ulogic_vector) return std_ulogic_vector is
    variable s1 : signed (v1'length-1 downto 0);
    variable s2 : signed (v2'length-1 downto 0);
    variable res : signed (v1'length+v2'length-1 downto 0);
  begin
    s1 := signed(v1);
    s2 := signed(v2);
    res := s1 * s2;
    return std_ulogic_vector(res);
  end function;
  
  function ai_eq(v1, v2 : std_ulogic_vector) return boolean is
  begin
    return v1 = v2;
  end function;

  function ai_neq(v1, v2 : std_ulogic_vector) return boolean is
  begin
    return v1 /= v2;
  end function;

  function ai_not(v1 : std_ulogic_vector) return std_ulogic_vector is
    variable v2 : std_ulogic_vector (v1'length - 1 downto 0) := (others => '0');
  begin
    if (v1 = v2) then
      return "1";
    else
      return "0";
    end if;
  end function;

  function ai_shl(arg: std_ulogic_vector; count: std_ulogic_vector) return std_ulogic_vector is
    variable res : unsigned (arg'length-1 downto 0);
  begin
    res:=shl(unsigned(arg),unsigned(count));
    return std_ulogic_vector(res);
  end function;
  
  function ai_lshr(arg: std_ulogic_vector; count: std_ulogic_vector) return std_ulogic_vector is
    variable res : unsigned (arg'length-1 downto 0);
  begin
    res:=shr(unsigned(arg),unsigned(count));
    return std_ulogic_vector(res);
  end function;
  
  function ai_ashr(arg: std_ulogic_vector; count: std_ulogic_vector) return std_ulogic_vector is
    variable res : signed (arg'length-1 downto 0);
  begin
    res:=shr(signed(arg),unsigned(count));
    return std_ulogic_vector(res);
  end function;
  
end package body;
library ieee;
use ieee.std_logic_1164.all;
use work.autoip.all;

entity mul2_s_0_0_0_1_32_32 is
  port (
    reset : in std_ulogic;
    clk : in std_ulogic;
    ce : in std_ulogic;
    sum : out std_ulogic_vector(63 downto 0);
    a : in std_ulogic_vector(31 downto 0);
    b : in std_ulogic_vector(31 downto 0));
end;

architecture a of mul2_s_0_0_0_1_32_32 is
begin
  sum <= ai_muls(a,b);
end;


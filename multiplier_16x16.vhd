LIBRARY ieee;
LIBRARY unisim;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE unisim.vcomponents.ALL;

ENTITY multiplier_16x16 IS
    PORT(clk:   IN std_logic;                           -- clock rising edge
         clken: IN std_logic;                           -- clock enable, high active
         swrst: IN std_logic;                           -- software reset, high active
         op1:   IN std_logic_vector(15 DOWNTO 0);       -- 1. operand
         op2:   IN std_logic_vector(15 DOWNTO 0);       -- 2. operand
         prod:  OUT std_logic_vector(35 DOWNTO 0));     -- resulting product
END multiplier_16x16;

ARCHITECTURE behavioral OF multiplier_16x16 IS

    COMPONENT MULT18X18S
    PORT(P:     OUT std_logic_vector (35 DOWNTO 0);
         A:     IN std_logic_vector (17 DOWNTO 0);
         B:     IN std_logic_vector (17 DOWNTO 0);
         C:     IN std_logic;
         CE:    IN std_logic;
         R:     IN std_logic);
    END COMPONENT;
    
    SIGNAL op1_tmp: std_logic_vector(17 DOWNTO 0);
    SIGNAL op2_tmp: std_logic_vector(17 DOWNTO 0);
BEGIN
    op1_tmp <= std_logic_vector(resize(signed(op1), 18));
    op2_tmp <= std_logic_vector(resize(signed(op2), 18));

    mul1: MULT18X18S
    PORT MAP(P => prod,
             A => op1_tmp,
             B => op2_tmp,
             C => clk,
             CE => clken,
             R => swrst);

END behavioral;
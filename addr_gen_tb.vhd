LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY addr_gen_test IS
   -- empty
END addr_gen_test;

ARCHITECTURE test OF addr_gen_test IS
    CONSTANT RSTDEF: std_ulogic := '1';
    CONSTANT tpd: time := 20 ns; -- 1/50 MHz

    COMPONENT addr_gen IS
    GENERIC(RSTDEF: std_logic := '0');
    PORT(rst:   IN  std_logic;                      -- reset,          RSTDEF active
         clk:   IN  std_logic;                      -- clock,          rising edge
         swrst: IN  std_logic;                      -- software reset, RSTDEF active
         en:    IN std_logic;                       -- enable,         high active
         addrA: OUT std_logic_vector(7 DOWNTO 0);
         addrB: OUT std_logic_vector(7 DOWNTO 0);
         done:  OUT std_logic);                     -- done if all addresses have been generated
    END COMPONENT;
    
    SIGNAL done_addr_gen: std_logic := '0';
    SIGNAL en_addr_gen: std_logic := '1';
    SIGNAL addrA: std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrB: std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL rst: std_logic := RSTDEF;

    SIGNAL clk: std_logic := '0';
    SIGNAL hlt: std_logic := '0';
   
BEGIN
    rst <= NOT RSTDEF;
    clk <= clk WHEN hlt='1' ELSE '1' AFTER tpd/2 WHEN clk='0' ELSE '0' AFTER tpd/2;
    
    en_addr_gen <= '0' WHEN done_addr_gen = '1' ELSE '1';

    addr_gen1: addr_gen
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(
        rst => rst,
        clk => clk,
        swrst => '0',
        en => en_addr_gen,
        addrA => addrA,
        addrB => addrB,
        done => done_addr_gen);

END test;
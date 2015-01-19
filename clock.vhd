LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY clock_tb IS
   -- empty
END clock_tb;

ARCHITECTURE test OF clock_tb IS
    CONSTANT RSTDEF: std_ulogic := '1';
    CONSTANT tpd: time := 20 ns; -- 1/50 MHz

    COMPONENT core IS
    GENERIC(RSTDEF: std_logic := '0');
    PORT(rst:   IN  std_logic;                      -- reset,          RSTDEF active
         clk:   IN  std_logic;                      -- clock,          rising edge
         swrst: IN  std_logic;                      -- software reset, RSTDEF active
         -- handshake signals
         strt:  IN  std_logic;                      -- start,          high active
         rdy:   OUT std_logic;                      -- ready,          high active
         -- address/data signals
         sw:    IN  std_logic_vector( 7 DOWNTO 0);  -- address input
         dout:  OUT std_logic_vector(15 DOWNTO 0)); -- result output
    END COMPONENT;
    
    SIGNAL strt: std_logic := '0';
    SIGNAL rdy: std_logic := '0';
    SIGNAL sw: std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL dout: std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL rst: std_logic := RSTDEF;
    SIGNAL swrst: std_logic := NOT RSTDEF;
    SIGNAL clk: std_logic := '0';
    SIGNAL hlt: std_logic := '0';
BEGIN
    rst <= RSTDEF, NOT RSTDEF AFTER 5 * tpd;
    strt <= '0', '1' AFTER 5 * tpd;
    clk <= clk WHEN hlt='1' ELSE '1' AFTER tpd/2 WHEN clk='0' ELSE '0' AFTER tpd/2;
    
    c: core
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
             clk => clk,
             swrst => swrst,
             strt => strt,
             rdy => rdy,
             sw => sw,
             dout => dout);
        
END test;
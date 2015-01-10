
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY core IS
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
END core;

ARCHITECTURE behavioral OF core IS
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
    
    SIGNAL done_addr_gen : std_logic := '0';
    SIGNAL en_addr_gen : std_logic := '0';
    SIGNAL addrA: std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrB: std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
BEGIN
    
    en_addr_gen <= NOT done_addr_gen;

    addr_gen1: addr_gen
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(
        rst => rst,
        clk => clk,
        swrst => swrst,
        en => en_addr_gen,
        addrA => addrA,
        addrB => addrB,
        done => done_addr_gen);
END behavioral;
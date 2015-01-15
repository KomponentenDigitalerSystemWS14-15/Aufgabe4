LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY core_control_test IS
   -- empty
END core_control_test;

ARCHITECTURE test OF core_control_test IS
    CONSTANT RSTDEF: std_ulogic := '1';
    CONSTANT tpd: time := 20 ns; -- 1/50 MHz

    COMPONENT core_control IS
    GENERIC(RSTDEF: std_logic := '0');
    PORT(rst:            IN  std_logic;                      -- reset,          RSTDEF active
         clk:            IN  std_logic;                      -- clock,          rising edge
         swrst:          IN  std_logic;                      -- software reset, RSTDEF active
         -- in control signals
         strt:           IN  std_logic;                      -- start,          high active
         done_addr_gen:  IN std_logic;                       -- done, high active when last address was generated
         newsp_addr_gen: IN std_logic;                       -- new scalar product, high when first address of next sp was generated
         -- out control signals
         en_addr_gen:    OUT std_logic;                      -- enable 
         en_rom:         OUT std_logic;
         en_mul:         OUT std_logic;
         en_acc:         OUT std_logic;
         wea_ram:        OUT std_logic;
         restart_acc:    OUT std_logic;
         swrst_all:      OUT std_logic;
         rdy:            OUT std_logic);                     -- ready,          high active
    END COMPONENT;
        
    SIGNAL hlt: std_logic := '0';
    
    SIGNAL rst: std_logic := RSTDEF;
    SIGNAL clk: std_logic := '0';
    SIGNAL swrst: std_logic := NOT RSTDEF;
    SIGNAL strt: std_logic := '0';
    
    SIGNAL done_addr_gen: std_logic := '0';
    SIGNAL newsp_addr_gen: std_logic := '0';
    SIGNAL en_addr_gen: std_logic := '0';
    SIGNAL en_rom: std_logic := '0';
    SIGNAL en_mul: std_logic := '0';
    SIGNAL en_acc: std_logic := '0';
    SIGNAL wea_ram: std_logic := '0';
    
    SIGNAL restart_acc: std_logic := '0';
    SIGNAL swrst_all: std_logic := '0';
    SIGNAL rdy: std_logic := '0';
    
BEGIN
    rst <= RSTDEF, NOT RSTDEF AFTER 5 * tpd;
    clk <= clk WHEN hlt='1' ELSE '1' AFTER tpd/2 WHEN clk='0' ELSE '0' AFTER tpd/2;

    corectrl1: core_control
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
             clk => clk,
             swrst => swrst,
             strt => strt,
             done_addr_gen => done_addr_gen,
             newsp_addr_gen => newsp_addr_gen,
             en_addr_gen => en_addr_gen,
             en_rom => en_rom,
             en_mul => en_mul,
             en_acc => en_acc,
             wea_ram => wea_ram,
             restart_acc => restart_acc,
             swrst_all => swrst_all,
             rdy => rdy);
        
    main: PROCESS
        CONSTANT N: natural := 16;
        
        -- waits until next rising edge
        PROCEDURE clock (n: natural) IS
        BEGIN
            FOR i IN 1 TO n LOOP
                WAIT UNTIL clk'EVENT AND clk='1';
            END LOOP;
        END PROCEDURE;
    BEGIN
        REPORT "core_control_test" SEVERITY note;
    
        -- wait for first clock without reset set
        WAIT UNTIL clk'EVENT AND clk='1' AND rst=(NOT RSTDEF);
        
        strt <= '1';
        clock(1);
        strt <= '0';
        
        FOR rowa IN 0 TO N-1 LOOP
            FOR colb IN 0 TO N-1 LOOP
                FOR el IN 0 TO N-1 LOOP
                    clock(1);
                    newsp_addr_gen <= '0';
                END LOOP;
                newsp_addr_gen <= '1';
            END LOOP;
        END LOOP;
        
        done_addr_gen <= '1';
        clock(1);
        
        REPORT "TEST SUCCEEDED" SEVERITY note;
        
        hlt <= '1';
        WAIT;
    END PROCESS;
END test;
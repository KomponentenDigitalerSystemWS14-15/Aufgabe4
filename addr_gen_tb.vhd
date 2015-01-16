LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY addr_gen_tb IS
   -- empty
END addr_gen_tb;

ARCHITECTURE test OF addr_gen_tb IS
    CONSTANT RSTDEF: std_ulogic := '1';
    CONSTANT tpd: time := 20 ns; -- 1/50 MHz

    COMPONENT addr_gen IS
    GENERIC(RSTDEF: std_logic := '0');
    PORT(rst:    IN  std_logic;                       -- reset,          RSTDEF active
         clk:    IN  std_logic;                       -- clock,          rising edge
         swrst:  IN  std_logic;                       -- software reset, RSTDEF active
         en:     IN  std_logic;                       -- enable,         high active
         addra:  OUT std_logic_vector(9 DOWNTO 0);
         addrb:  OUT std_logic_vector(9 DOWNTO 0));
    END COMPONENT;
    
    SIGNAL addra: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrb: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL rst: std_logic := RSTDEF;
    SIGNAL swrst: std_logic := NOT RSTDEF;
    SIGNAL clk: std_logic := '0';
    SIGNAL hlt: std_logic := '0';
   
BEGIN
    rst <= RSTDEF, NOT RSTDEF AFTER 5 * tpd;
    clk <= clk WHEN hlt='1' ELSE '1' AFTER tpd/2 WHEN clk='0' ELSE '0' AFTER tpd/2;

    addr_gen1: addr_gen
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
        clk => clk,
        swrst => swrst,
        en => '1',
        addra => addra,
        addrb => addrb);
        
    main: PROCESS
        CONSTANT N: natural := 16;
        
        -- waits until next rising edge
        PROCEDURE clock (n: natural) IS
        BEGIN
            FOR i IN 1 TO n LOOP
                WAIT UNTIL clk'EVENT AND clk='1';
            END LOOP;
        END PROCEDURE;
        
        -- one address generation step
        PROCEDURE step(rowa: natural; colb: natural; el: natural) IS
            VARIABLE addra_test: natural := 0;
            VARIABLE addrb_test: natural := 0;
            VARIABLE haderr: std_logic := '0';
        BEGIN
            addra_test := rowa * N + el;
            addrb_test := el * N + colb + 256;
            
            IF to_integer(unsigned(addra)) /= addra_test THEN
                REPORT "wrong result for addra is:" & integer'image(to_integer(unsigned(addra))) & ", exp:" & integer'image(addra_test)SEVERITY error;
                haderr := '1';
            END IF;
            
            IF to_integer(unsigned(addrb)) /= addrb_test THEN
                REPORT "wrong result for addrb is:" & integer'image(to_integer(unsigned(addrb))) & ", exp:" & integer'image(addrb_test)SEVERITY error;
                haderr := '1';
            END IF;
            
            IF haderr = '1' THEN
                REPORT "TEST FAILED" SEVERITY note;
                hlt <= '1';
                WAIT;
            END IF;
            
            -- next clock cycle
            clock(1);
        END PROCEDURE;
    BEGIN
        REPORT "addr_gen_test" SEVERITY note;
    
        -- wait for first clock without reset set
        WAIT UNTIL clk'EVENT AND clk='1' AND rst=(NOT RSTDEF);
        
        FOR rowa IN 0 TO N-1 LOOP
            FOR colb IN 0 TO N-1 LOOP
                FOR el IN 0 TO N-1 LOOP
                    step(rowa, colb, el);
                END LOOP;
            END LOOP;
        END LOOP;
        
        REPORT "TEST SUCCEEDED" SEVERITY note;
        
        hlt <= '1';
        WAIT;
    END PROCESS;
END test;
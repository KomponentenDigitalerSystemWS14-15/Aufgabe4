LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY addr_gen IS
   GENERIC(RSTDEF: std_logic := '0');
   PORT(rst:   IN  std_logic;                      -- reset,          RSTDEF active
        clk:   IN  std_logic;                      -- clock,          rising edge
        swrst: IN  std_logic;                      -- software reset, RSTDEF active
        en:    IN std_logic;                       -- enable,         high active
        addrA: OUT std_logic_vector(7 DOWNTO 0);
        addrB: OUT std_logic_vector(7 DOWNTO 0);
        done:  OUT std_logic);                     -- done if all addresses have been generated
END addr_gen;

ARCHITECTURE behavioral OF addr_gen IS
    SIGNAL addrA_start: unsigned(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrB_start: unsigned(7 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL a_offset: unsigned(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL b_offset: unsigned(7 DOWNTO 0) := (OTHERS => '0');
BEGIN
    addrA <= std_logic_vector(addrA_start + a_offset);
    addrB <= std_logic_vector(addrB_start + b_offset);

    PROCESS(rst, clk)
        VARIABLE a_offset_var: unsigned(4 DOWNTO 0) := (OTHERS => '0');
        VARIABLE addrA_start_var: unsigned(8 DOWNTO 0) := (OTHERS => '0');
        VARIABLE addrB_start_var: unsigned(8 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        IF rst = RSTDEF THEN
            addrA_start <= (OTHERS => '0');
            addrB_start <= (OTHERS => '0');
            a_offset <= (OTHERS => '0');
            b_offset <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF swrst = RSTDEF THEN
                addrA_start <= (OTHERS => '0');
                addrB_start <= (OTHERS => '0');
                a_offset <= (OTHERS => '0');
                b_offset <= (OTHERS => '0');
            ELSIF en = '1' THEN
                done <= '0';
                a_offset_var := ('0' & a_offset) + 1;
                a_offset <= a_offset_var(3 DOWNTO 0);
                b_offset <= b_offset + 16;
                
                -- finished one column of matrix B
                IF a_offset_var(4) = '1' THEN
                    addrB_start_var := ('0' & addrB_start) + 1;
                    addrB_start <= addrB_start_var(7 DOWNTO 0);
                    b_offset <= (OTHERS => '0');
                END IF;
                
                -- finished one row of matrix A
                IF addrB_start_var(8) = '1' THEN
                    addrA_start_var := ('0' & addrA_start) + 16;
                    addrA_start <= addrA_start_var(7 DOWNTO 0);
                    b_offset <= (OTHERS => '0');
                END IF;
                
                -- finished all matrices
                IF addrA_start_var(8) = '1' AND a_offset_var(4) = '1' THEN
                    done <= '1';
                    addrA_start <= (OTHERS => '0');
                    addrB_start <= (OTHERS => '0');
                    a_offset <= (OTHERS => '0');
                    b_offset <= (OTHERS => '0');
                END IF;
            END IF;
        END IF;
    END PROCESS;

END behavioral;
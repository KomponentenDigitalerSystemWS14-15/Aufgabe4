LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY accumulator IS
    GENERIC(N: natural := 8;
            N_in: natural := 8;
            RSTDEF: std_logic := '0');
    PORT(rst:   IN std_logic;                           -- reset, RSTDEF active
         clk:   IN std_logic;                           -- clock, rising edge
         swrst: IN std_logic;                           -- software reset, RSTDEF active
         en:    IN std_logic;                           -- enable, high active
         op:    IN std_logic_vector(N_in-1 DOWNTO 0);      			-- operand
         sum:   OUT std_logic_vector(N-1 DOWNTO 0));     			-- result
END accumulator;

ARCHITECTURE behavioral OF accumulator IS
    SIGNAL tmp_sum: signed(N-1 DOWNTO 0) := (OTHERS => '0');
BEGIN

    sum <= std_logic_vector(tmp_sum);
        
    PROCESS(rst, clk)
    BEGIN
        IF rst = RSTDEF THEN
            tmp_sum <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF swrst = RSTDEF THEN
                tmp_sum <= (OTHERS => '0');
            ELSIF en = '1' THEN
                -- only apply new value when enabled
                tmp_sum <= tmp_sum + signed(op);
            END IF;
        END IF;
    END PROCESS;

END behavioral;
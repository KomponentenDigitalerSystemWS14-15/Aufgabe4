LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY addr_gen IS
   GENERIC(RSTDEF: std_logic := '0');
   PORT(rst:    IN  std_logic;                       -- reset,          RSTDEF active
        clk:    IN  std_logic;                       -- clock,          rising edge
        swrst:  IN  std_logic;                       -- software reset, RSTDEF active
        en:     IN  std_logic;                       -- enable,         high active
        addra:  OUT std_logic_vector(9 DOWNTO 0);
        addrb:  OUT std_logic_vector(9 DOWNTO 0));
END addr_gen;

ARCHITECTURE behavioral OF addr_gen IS
    SIGNAL matr_addr: unsigned(11 DOWNTO 0) := (OTHERS => '0');
BEGIN
    addra <= std_logic_vector("00" & matr_addr(11 DOWNTO 8) & matr_addr(3 DOWNTO 0));
    addrb <= std_logic_vector("01" & matr_addr(3 DOWNTO 0) & matr_addr(7 DOWNTO 4));

    PROCESS(rst, clk)
    BEGIN
        IF rst = RSTDEF THEN
            matr_addr <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF swrst = RSTDEF THEN
                matr_addr <= (OTHERS => '0');
            ELSIF en = '1' THEN
               matr_addr <= matr_addr + 1;
            END IF;
        END IF;
    END PROCESS;

END behavioral;
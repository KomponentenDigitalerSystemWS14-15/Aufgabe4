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
    SIGNAL rowa: unsigned(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL cola: unsigned(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL rowb: unsigned(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL colb: unsigned(3 DOWNTO 0) := (OTHERS => '0');
BEGIN
    addra <= std_logic_vector("00" & rowa & cola);
    addrb <= std_logic_vector("01" & rowb & colb);

    PROCESS(rst, clk)
        VARIABLE rowb_var: unsigned(4 DOWNTO 0) := (OTHERS => '0');
        VARIABLE colb_var: unsigned(4 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        IF rst = RSTDEF THEN
            rowa <= (OTHERS => '0');
            cola <= (OTHERS => '0');
            rowb <= (OTHERS => '0');
            colb <= (OTHERS => '0');
            rowb_var := (OTHERS => '0');
            colb_var := (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF swrst = RSTDEF THEN
                rowa <= (OTHERS => '0');
                cola <= (OTHERS => '0');
                rowb <= (OTHERS => '0');
                colb <= (OTHERS => '0');
                rowb_var := (OTHERS => '0');
                colb_var := (OTHERS => '0');
            ELSIF en = '1' THEN
                
                rowb_var := ('0' & rowb) + 1;
                rowb <= rowb_var(3 DOWNTO 0);
                cola <= cola + 1;
                
                IF rowb_var(4) = '1' THEN
                    colb_var := ('0' & colb) + 1;
                    colb <= colb_var(3 DOWNTO 0);
                    
                    IF colb_var(4) = '1' THEN
                        rowa <= rowa + 1;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

END behavioral;
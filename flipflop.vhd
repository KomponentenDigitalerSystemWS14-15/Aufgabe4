LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY flipflop IS
    GENERIC(RSTDEF: std_logic := '1');
    PORT(rst: IN std_logic;
         clk: IN std_logic;
         swrst: IN std_logic;
         en: IN std_logic;
         d: IN std_logic;
         q: OUT std_logic);
END flipflop;

ARCHITECTURE behavioral OF flipflop IS
    SIGNAL dff: std_logic;
BEGIN

    q <= dff;
    
    PROCESS(rst, clk) IS
    BEGIN
        IF rst = RSTDEF THEN
            dff <= '0';
        ELSIF rising_edge(clk) THEN
              IF swrst = RSTDEF THEN
                dff <= '0';
              ELSIF en = '1' THEN
                dff <= d;
            END IF;
        END IF;
    END PROCESS;
    
END behavioral;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY aufgabe4 IS
   PORT(rst:  IN  std_logic;                     -- (BTN3) User Reset
        clk:  IN  std_logic;                     -- 50 MHz crystal oscillator clock source
        BTN0: IN  std_logic;                     -- start
        sw:   IN  std_logic_vector(7 DOWNTO 0);  -- 8 slide switches: SW7 SW6 SW5 SW4 SW3 SW2 SW1 SW0
        an:   OUT std_logic_vector(3 DOWNTO 0);  -- 4 digit enable (anode control) signals (active low)
        seg:  OUT std_logic_vector(7 DOWNTO 1);  -- 7 FPGA connections to seven-segment display (active low)
        dp:   OUT std_logic;                     -- 1 FPGA connection to digit doint (active low)
        LD0:  OUT std_logic);                    -- Done LED, 1 if done
END aufgabe4;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY sync_module IS
   GENERIC(RSTDEF: std_logic := '1');
   PORT(rst:   IN  std_logic;  -- reset, active RSTDEF
        clk:   IN  std_logic;  -- clock, risign edge
        swrst: IN  std_logic;  -- software reset, active RSTDEF
        BTN0:  IN  std_logic;  -- push button -> load
        BTN1:  IN  std_logic;  -- push button -> dec
        BTN2:  IN  std_logic;  -- push button -> inc
        load:  OUT std_logic;  -- load,      high active
        dec:   OUT std_logic;  -- decrement, high active
        inc:   OUT std_logic); -- increment, high active
END sync_module;

ARCHITECTURE behavioral OF sync_module IS
   
    COMPONENT sync_buffer IS
    GENERIC(RSTDEF:  std_logic);
    PORT(rst:    IN  std_logic;  -- reset, RSTDEF active
         clk:    IN  std_logic;  -- clock, rising edge
         en:     IN  std_logic;  -- enable, high active
         swrst:  IN  std_logic;  -- software reset, RSTDEF active
         din:    IN  std_logic;  -- data bit, input
         dout:   OUT std_logic;  -- data bit, output
         redge:  OUT std_logic;  -- rising  edge on din detected
         fedge:  OUT std_logic); -- falling edge on din detected
    END COMPONENT;

    CONSTANT CNTLEN : natural := 15;
    SIGNAL cnt : std_logic_vector(CNTLEN-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL cnt_tmp : std_logic_vector(CNTLEN DOWNTO 0) := (OTHERS => '0');
    SIGNAL cnt_en : std_logic;
    
BEGIN

    -- Frequenzteiler: Modulo 2^15
    
    cnt_en <= cnt_tmp(CNTLEN);
    cnt <= cnt_tmp(CNTLEN-1 DOWNTO 0);
    
    PROCESS (rst, clk)
    BEGIN
        IF rst = RSTDEF THEN
            cnt_tmp <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF swrst = RSTDEF THEN
                cnt_tmp <= (OTHERS => '0');
            ELSE
                cnt_tmp <= '0' & cnt + 1;
            END IF;
        END IF;
    END PROCESS;
    
    sbuf0 : sync_buffer
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            en => cnt_en,
            swrst => swrst,
            din => BTN0,
            dout => OPEN,
            redge => load,
            fedge => OPEN);
            
    sbuf1 : sync_buffer
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            en => cnt_en,
            swrst => swrst,
            din => BTN1,
            dout => OPEN,
            redge => OPEN,
            fedge => dec);
      
    sbuf2 : sync_buffer
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            en => cnt_en,
            swrst => swrst,
            din => BTN2,
            dout => OPEN,
            redge => OPEN,
            fedge => inc);

END behavioral;

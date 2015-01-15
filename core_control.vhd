LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY core_control IS
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
END core_control;

ARCHITECTURE behavioral OF core_control IS
    COMPONENT flipflop IS
    GENERIC(RSTDEF: std_logic);
    PORT(rst: IN std_logic;
         clk: IN std_logic;
         swrst: IN std_logic;
         en: IN std_logic;
         d: IN std_logic;
         q: OUT std_logic);
    END COMPONENT;
    
    SIGNAL running: std_logic := '0';
    SIGNAL stopping: std_logic := '0';
    
    -- enable signals
    SIGNAL en_addr_gen_pipe: std_logic := '0';
    SIGNAL en_rom_pipe: std_logic := '0';
    SIGNAL en_mul_pipe: std_logic := '0';
    SIGNAL en_acc_pipe: std_logic := '0';
    SIGNAL wea_ram_pipe: std_logic := '0';
    
    -- newsp signals
    SIGNAL newsp_rom: std_logic := '0';
    SIGNAL newsp_mul: std_logic := '0';
    
BEGIN
    
    -- enable signals
    en_addr_gen_pipe <= '0' WHEN done_addr_gen = '1'; --TODO Obacht! else?
    --en_addr_gen <= en_addr_gen_pipe;
    en_rom <= en_rom_pipe;
    en_mul <= en_mul_pipe;
    en_acc <= en_acc_pipe;
    
    -- newsp signals
    restart_acc <= newsp_mul;
    wea_ram_pipe <= newsp_mul;
    wea_ram <= wea_ram_pipe;
    
    PROCESS(rst, clk)
    BEGIN
        IF rst = RSTDEF THEN
            running <= '0';
            stopping <= '0';
            en_addr_gen_pipe <= '0';
            swrst_all <= NOT RSTDEF;
            rdy <= '0';
        ELSIF rising_edge(clk) THEN
            IF swrst = RSTDEF THEN
                running <= '0';
                stopping <= '0';
                en_addr_gen_pipe <= '0';
                swrst_all <= NOT RSTDEF;
                rdy <= '0'; 
            ELSE
                swrst_all <= NOT RSTDEF;
                -- S0 -> S1
                IF strt = '1' AND running = '0' THEN
                    en_addr_gen_pipe <= '1';
                    running <= '1';
                    rdy <= '0';
                END IF;
                
                -- S4 -> S5
                IF done_addr_gen = '1' THEN
                    stopping <= '1';
                END IF;
                
                -- S7 -> S11
                IF stopping = '1' AND wea_ram_pipe = '1' THEN
                    swrst_all <= RSTDEF;
                END IF;
                
                -- S11 -> S0
                IF stopping = '1' AND en_acc_pipe = '0' THEN
                    running <= '0';
                    rdy <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    enff1: flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
             clk => clk,
             swrst => swrst,
             en => '1',
             d => en_addr_gen_pipe,
             q => en_rom_pipe);
             
    enff2: flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
             clk => clk,
             swrst => swrst,
             en => '1',
             d => en_rom_pipe,
             q => en_mul_pipe);
             
    enff3: flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
             clk => clk,
             swrst => swrst,
             en => '1',
             d => en_mul_pipe,
             q => en_acc_pipe);
             
    newspff1: flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
             clk => clk,
             swrst => swrst,
             en => '1',
             d => newsp_addr_gen,
             q => newsp_rom);
             
    newspff2: flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
             clk => clk,
             swrst => swrst,
             en => '1',
             d => newsp_rom,
             q => newsp_mul);

END behavioral;
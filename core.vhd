LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY core IS
   GENERIC(RSTDEF: std_logic := '0');
   PORT(rst:   IN  std_logic;                      -- reset,          RSTDEF active
        clk:   IN  std_logic;                      -- clock,          rising edge
        swrst: IN  std_logic;                      -- software reset, RSTDEF active
        -- handshake signals
        strt:  IN  std_logic;                      -- start,          high active
        rdy:   OUT std_logic;                      -- ready,          high active
        -- address/data signals
        sw:    IN  std_logic_vector( 7 DOWNTO 0);  -- address input
        dout:  OUT std_logic_vector(15 DOWNTO 0)); -- result output
END core;

ARCHITECTURE behavioral OF core IS

    COMPONENT addr_gen IS
    GENERIC(RSTDEF: std_logic := '0');
    PORT(rst:    IN  std_logic;                       -- reset,          RSTDEF active
         clk:    IN  std_logic;                       -- clock,          rising edge
         swrst:  IN  std_logic;                       -- software reset, RSTDEF active
         en:     IN  std_logic;                       -- enable,         high active
         addra:  OUT std_logic_vector(9 DOWNTO 0);
         addrb:  OUT std_logic_vector(9 DOWNTO 0));
    END COMPONENT;

    COMPONENT rom_block IS
    PORT (addra: IN std_logic_VECTOR(9 DOWNTO 0);
          addrb: IN std_logic_VECTOR(9 DOWNTO 0);
          clka:  IN std_logic;
          clkb:  IN std_logic;
          douta: OUT std_logic_VECTOR(15 DOWNTO 0);
          doutb: OUT std_logic_VECTOR(15 DOWNTO 0);
          ena:   IN std_logic;
          enb:   IN std_logic);
    END COMPONENT;

    COMPONENT multiplier_16x16 IS
    PORT(clk:   IN std_logic;                           -- clock rising edge
         clken: IN std_logic;                           -- clock enable, high active
         swrst: IN std_logic;                           -- software reset, high active
         op1:   IN std_logic_vector(15 DOWNTO 0);       -- 1. operand
         op2:   IN std_logic_vector(15 DOWNTO 0);       -- 2. operand
         prod:  OUT std_logic_vector(35 DOWNTO 0));     -- resulting product
    END COMPONENT;

    COMPONENT accumulator IS
    GENERIC(N: natural := 8;
            N_in: natural := 8;
            RSTDEF: std_logic := '0');
    PORT(rst:     IN std_logic;                           -- reset, RSTDEF active
         clk:     IN std_logic;                           -- clock, rising edge
         swrst:   IN std_logic;                           -- software reset, RSTDEF active
         en:      IN std_logic;                           -- enable, high active
         op:      IN std_logic_vector(N_in-1 DOWNTO 0);   -- operand
         sum:     OUT std_logic_vector(N-1 DOWNTO 0));    -- result
    END COMPONENT;
    
    COMPONENT ram_block IS
    PORT (addra: IN  std_logic_VECTOR(9 DOWNTO 0);
          addrb: IN  std_logic_VECTOR(9 DOWNTO 0);
          clka:  IN  std_logic;
          clkb:  IN  std_logic;
          dina:  IN  std_logic_VECTOR(15 downto 0);
          douta: OUT std_logic_VECTOR(15 DOWNTO 0);
          doutb: OUT std_logic_VECTOR(15 DOWNTO 0);
          ena:   IN  std_logic;
          enb:   IN  std_logic;
          wea:   IN  std_logic);
    END COMPONENT;
    
    TYPE TState IS (S0, S1, S2, S3);
    
    SIGNAL addra: std_logic_vector(9 DOWNTO 0);
    SIGNAL addrb: std_logic_vector(9 DOWNTO 0);
    SIGNAL addrc: std_logic_vector(9 DOWNTO 0);
    SIGNAL en_store: std_logic_vector(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL next_store: std_logic_vector(4 DOWNTO 0) := (OTHERS => '0');
    SIGNAL state: TState := S0;
    
    SIGNAL vala: std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL valb: std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL swrst_done: std_logic := NOT RSTDEF;
    SIGNAL swrst_res: std_logic;
    
    SIGNAL wea_ram: std_logic := '0';
BEGIN
    
    swrst_res <= swrst WHEN swrst = RSTDEF ELSE swrst_done;
    
    PROCESS(rst, clk)
    BEGIN
        IF rst = RSTDEF THEN
        
        ELSIF rising_edge(clk) THEN
            IF swrst = RSTDEF THEN
            
            ELSE
                IF state = S0 AND strt = '1' THEN
                    state <= S1;
                    en_store(0) <= '1';
                    wea_ram <= '0';        
                ELSIF state = S1 THEN
                    -- shift enable signals
                    en_store <= en_store(en_store'high-1 DOWNTO 0) & '1';
                    IF en_store(2) = '1' THEN
                        state <= S2;
                    END IF;
                ELSIF state = S2 THEN
                    IF addra(3 DOWNTO 0) = "1111" THEN
                        next_store(0) <= '1';
                    END IF;
                    
                    -- shift next signals
                    IF next_store(0) = '1' THEN
                        next_store <= next_store(next_store'high-1 DOWNTO 0) & '1';
                    END IF;
                    
                    IF next_store(4) = '1' THEN
                        next_store <= (OTHERS => '0');
                        addrc <= addrc + 1;
                    END IF;
                    
                    -- finished all 
                    IF addra = "0011111111" THEN
                        state <= S3;
                        en_store(0) <= '1';
                    END IF;
                ELSIF state = S3 THEN
                    -- shift enable signals
                    en_store <= en_store(en_store'high-1 DOWNTO 0) & '0';
                    IF en_stor(2) = '0' THEN
                        swrst_done <= RSTDEF;
                    END IF;
                    
                    IF swrst_done = RSTDEF THEN
                        state = S0;
                        rdy = '1';
                        swrst_done = NOT RSTDEF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    addr1: addr_gen
    GENERIC MAP(RSTDEF => RSTDEF);
    PORT(rst => rst,
         clk => clk,
         swrst => swrst_res,
         en => en_store(0),
         addra => addra,
         addrb => addrb);
    
    rb1: rom_block
    PORT MAP(addra => addra,
             addrb => addrb,
             clka => clk,
             clkb => clk,
             douta => vala,
             doutb => valb,
             ena => en_store(1),
             enb => en_store(1));
             
    mul1: multiplier_16x16
    PORT MAP(clk => clk,
             clken => en_store(2),
             swrst => swrst_res,
             op1 => vala,
             op2 => valb,
             prod => prod);
             
    acc1: accumulator
    GENERIC MAP(N => ACC_LEN,
                N_in => ACC_IN_LEN,
                RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
             clk => clk,
             swrst => swrst_res,
             en => en_store(3),
             op => prod,
             sum => sum);
    
    rb2: ram_block
    PORT MAP(addra => addrc,
             addrb => "0000000000",
             clka => clk,
             clkb => clk,
             dina => sum,
             douta => OPEN,
             doutb => dout,
             ena => '1',
             enb => '1',
             wea => wea_ram);
             
END behavioral;
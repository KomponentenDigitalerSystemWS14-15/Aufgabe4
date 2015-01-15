
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

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
         addra:  OUT std_logic_vector(7 DOWNTO 0);
         addrb:  OUT std_logic_vector(7 DOWNTO 0);
         newSp: OUT std_logic;                       -- high active, when scalar product done
         done:   OUT std_logic);                      -- high active, if all addresses have been generated
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
         restart: IN std_logic;                           -- restart
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
    
    COMPONENT flipflop IS
    GENERIC(RSTDEF: std_logic);
    PORT(rst: IN std_logic;
         clk: IN std_logic;
         swrst: IN std_logic;
         en: IN std_logic;
         d: IN std_logic;
         q: OUT std_logic);
    END COMPONENT;
    
    CONSTANT ACC_LEN: natural := 44;
    CONSTANT ACC_IN_LEN: natural := 36;
    
    SIGNAL done_addr_gen: std_logic := '0';
    SIGNAL done_rom: std_logic := '0';
    SIGNAL done_mul: std_logic := '0';
    SIGNAL done_acc: std_logic := '0';
    SIGNAL done_ram: std_logic := '0';
    
    SIGNAL newSp_addr_gen: std_logic := '0';
    SIGNAL newSp_rom: std_logic := '0';
    SIGNAL newSp_mul: std_logic := '0';
    
    SIGNAL swrst_res: std_logic := NOT RSTDEF;
    SIGNAL swrst_done: std_logic := NOT RSTDEF;
    
    SIGNAL en_addr_gen: std_logic := '1';
    SIGNAL en_ff: std_logic := '1';
    SIGNAL en_rom: std_logic := '1';
    SIGNAL en_acc: std_logic := '1';
    SIGNAL wea_ram: std_logic := '0';
    
    SIGNAL addra_tmp: std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrb_tmp: std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrres_tmp: std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addra: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrb: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrres: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrout: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL vala: std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL valb: std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL prod: std_logic_vector(ACC_IN_LEN-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL sum: std_logic_vector(ACC_LEN-1 DOWNTO 0) := (OTHERS => '0');
BEGIN
    
    -- reset all components when accumulator is done,
    -- so they are ready for the next start signal
    -- after ram is written
    swrst_done <= RSTDEF WHEN done_acc = '1' ELSE NOT RSTDEF;
    swrst_res <= swrst WHEN swrst = RSTDEF ELSE swrst_done;
    rdy <= done_ram;
    
    -- disable writing when ram is done
    wea_ram <= newSp_mul;
    
    addr_gen1: addr_gen
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(
        rst => rst,
        clk => clk,
        swrst => swrst_res,
        en => en_addr_gen,
        addra => addra_tmp,
        addrb => addrb_tmp,
        newSp => newSp_addr_gen,
        done => done_addr_gen);
    
    addra <= "00" & addra_tmp;
    addrb <= "01" & addrb_tmp;
    
    rb1: rom_block
    PORT MAP(addra => addra,
             addrb => addrb,
             clka => clk,
             clkb => clk,
             douta => vala,
             doutb => valb,
             ena => en_rom,
             enb => en_rom);
             
    mul1: multiplier_16x16
    PORT MAP(clk => clk,
             clken => '1',
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
             en => en_acc,
             restart => newSp_mul,
             op => prod,
             sum => sum);
             
    PROCESS(clk, rst)
    BEGIN
        IF rst = RSTDEF THEN
            addrres_tmp := (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF swrst_res = RSTDEF THEN
                -- because of overflow, maybe unnecessary
                addrres_tmp := (OTHERS => '0');
            ELSE
                IF newSp_mul = '1' THEN
                    addrres_tmp := addrres_tmp + 1;
                END IF;
                
                IF start = '1' THEN
                    running <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    addrres <= "00" & addrres_tmp;
    addrout <= "00" & sw;
    
    rb2: ram_block
    PORT MAP(addra => addrres,
          addrb => addrout,
          clka => clk,
          clkb => clk,
          dina => sum,
          douta => OPEN,
          doutb => dout,
          ena => '1',
          enb => '1',
          wea => wea_ram);
          
    restartff1 : flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            swrst => swrst,
            en => en_ff,
            d => newSp_addr_gen,
            q => newSp_rom);
            
    restartff2 : flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            swrst => swrst,
            en => en_ff,
            d => newSp_rom,
            q => newSp_mul);
            
            
    doneff1 : flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            swrst => swrst,
            en => en_ff,
            d => done_addr_gen,
            q => done_rom);
            
    doneff2 : flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            swrst => swrst,
            en => en_ff,
            d => done_rom,
            q => done_mul);
            
    doneff3 : flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            swrst => swrst,
            en => en_ff,
            d => done_mul,
            q => done_acc);
            
    doneff4 : flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            swrst => swrst,
            en => en_ff,
            d => done_acc,
            q => done_ram);
             
END behavioral;
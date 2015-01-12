
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
         doneSp: OUT std_logic;                       -- high active, when scalar product done
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
    SIGNAL doneSp_addr_gen: std_logic := '0';
    SIGNAL restart1: std_logic := '0';
    SIGNAL restart2: std_logic := '0';
    
    SIGNAL en_addr_gen: std_logic := '1';
    SIGNAL en_ff: std_logic := '1';
    SIGNAL en_rom: std_logic := '1';
    
    SIGNAL addra_tmp: std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrb_tmp: std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addra: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrb: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL vala: std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL valb: std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL prod: std_logic_vector(ACC_IN_LEN-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL sum: std_logic_vector(ACC_LEN-1 DOWNTO 0) := (OTHERS => '0');
BEGIN

    addr_gen1: addr_gen
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(
        rst => rst,
        clk => clk,
        swrst => swrst,
        en => en_addr_gen,
        addra => addra_tmp,
        addrb => addrb_tmp,
        doneSp => doneSp_addr_gen,
        done => done_addr_gen);
    
    en_addr_gen <= '1' WHEN start = '1' ELSE NOT done_addr_gen;
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
             swrst => swrst,
             op1 => vala,
             op2 => valb,
             prod => prod);
             
    acc1: accumulator
    GENERIC MAP(N => ACC_LEN,
                N_in => ACC_IN_LEN,
                RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
             clk => clk,
             swrst => swrst,
             en => en_acc,
             restart => restart2,
             op => prod,
             sum => sum);
             
    rb2: ram_block
    PORT MAP(addra => ,
          addrb => ,
          clka => ,
          clkb => ,
          dina => ,
          douta => ,
          doutb => ,
          ena => ,
          enb => ,
          wea => ,);
          
    flipflop1 : flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            swrst => swrst,
            en => en_ff,
            d => doneSp_addr_gen,
            q => restart1);
            
    flipflop2 : flipflop
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
            clk => clk,
            swrst => swrst,
            en => en_ff,
            d => restart1,
            q => restart2);
             
END behavioral;
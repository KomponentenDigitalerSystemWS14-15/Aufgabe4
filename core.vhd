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
    
	TYPE TState IS (STOP, S0, S1, S2, S3, S4, S5, S6);
    CONSTANT ACC_LEN: natural := 44;
    CONSTANT ACC_IN_LEN: natural := 36;
    
	SIGNAL status: TState := STOP;
	
	-- ROM
    SIGNAL addra: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrb: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
	
	-- RAM
	SIGNAL addrc: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrd: std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
	
	-- Enables
	SIGNAL en_rom: std_logic := '0';
	SIGNAL en_mul: std_logic := '0';
	SIGNAL en_acc: std_logic := '0';
	SIGNAL en_ram: std_logic := '0';
	SIGNAL en_addr_gen: std_logic := '0';
    
	-- Resets
	SIGNAL swrst_acc: std_logic := '0';
	
    SIGNAL vala: std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL valb: std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
	
	SIGNAL running: std_logic := '0';
    
BEGIN
    
	en_rom <= running;
	en_addr_gen <= running;
	
    PROCESS(rst, clk)
    BEGIN
        IF rst = RSTDEF THEN
            
        ELSIF rising_edge(clk) THEN
            IF swrst = RSTDEF THEN
                
            ELSE
			    -- Start
				IF strt = '1' THEN
					running <= '1';
					rdy <= '0';
					status <= S0;
				END IF;
				
				IF status = S0 THEN
					en_mul <= '1';
					status <= S1;
				END IF;
				
				IF status = S1 THEN
					en_acc <= '1';
					status <= S2;
				END IF;
				
				-- Full pipe
				IF status = S2 THEN			
				    -- Reset accumulator + write to RAM
					-- signal at acc in is new sum, signal at acc out gets written
					IF addra(3 DOWNTO 0) = "0001" THEN -- ACHTUNG HIER
						swrst_acc <= '1';
						en_ram <= '1';
					ELSE
						swrst_acc <= '0';
						en_ram <= '0';
					END IF;
					
					-- Finished
					IF addra = "1111111111" THEN
						 running <= '0'; -- Stop addr_gen and ROM
						 status <= S3;
					END IF;
				END IF;
				
				-- End
				IF status = S3 THEN
					en_mul <= '0';
					status <= S4;
				END IF;
				
				IF status = S4 THEN
					en_mul <= '0';
					status <= S5;
				END IF;
				
				IF status = S5 THEN
					en_acc <= '0';
					swrst_acc <= '1';
					
					en_ram <= '1';
					status <= S5;
				END IF;
				
				IF status = S6 THEN
					swrst_acc <= '0';
					en_ram <= '0';
				
					running <= '0';
					rdy <= '1';
					status <= STOP;
				END IF;
            END IF;
        END IF;
    END PROCESS;

    addr1: addr_gen
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => rst,
             clk => clk,
             swrst => swrst, -- todo
             en => en_addr_gen,
             addra => addra,
             addrb => addrb);
    
 --  rb1: rom_block
 --  PORT MAP(addra => addra,
 --           addrb => addrb,
 --           clka => clk,
 --           clkb => clk,
 --           douta => vala,
 --           doutb => valb,
 --           ena => en_rom,
 --           enb => en_rom);
             
 --  mul1: multiplier_16x16
 --  PORT MAP(clk => clk,
 --           clken => en_store(1),
 --           swrst => swrst_res,
 --           op1 => vala,
 --           op2 => valb,
 --           prod => prod);
 --           
 --  acc1: accumulator
 --  GENERIC MAP(N => ACC_LEN,
 --              N_in => ACC_IN_LEN,
 --              RSTDEF => RSTDEF)
 --  PORT MAP(rst => rst,
 --           clk => clk,
 --           swrst => swrst_acc,
 --           en => en_store(2),
 --           op => prod,
 --           sum => sum);
 --  
 --  rb2: ram_block
 --  PORT MAP(addra => addrc,
 --           addrb => addrd,
 --           clka => clk,
 --           clkb => clk,
 --           dina => sum_save,
 --           douta => OPEN,
 --           doutb => dout,
 --           ena => '1',
 --           enb => '1',
 --           wea => next_store(2));
             
END behavioral;
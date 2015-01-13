LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY addr_gen IS
   GENERIC(RSTDEF: std_logic := '0');
   PORT(rst:    IN  std_logic;                       -- reset,          RSTDEF active
        clk:    IN  std_logic;                       -- clock,          rising edge
        swrst:  IN  std_logic;                       -- software reset, RSTDEF active
        en:     IN  std_logic;                       -- enable,         high active
        addra:  OUT std_logic_vector(7 DOWNTO 0);
        addrb:  OUT std_logic_vector(7 DOWNTO 0);
        doneSp: OUT std_logic;                       -- high active, when scalar product done
        done:   OUT std_logic);                      -- high active, if all addresses have been generated
END addr_gen;

ARCHITECTURE behavioral OF addr_gen IS
    SIGNAL addra_start: unsigned(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL addrb_start: unsigned(3 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL a_offset: unsigned(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL b_offset: unsigned(7 DOWNTO 0) := (OTHERS => '0');
BEGIN
    addra <= std_logic_vector(addra_start + a_offset);
    addrb <= std_logic_vector(addrb_start + b_offset);

    PROCESS(rst, clk)
        VARIABLE a_offset_var: unsigned(4 DOWNTO 0) := (OTHERS => '0');
        VARIABLE addra_start_var: unsigned(8 DOWNTO 0) := (OTHERS => '0');
        VARIABLE addrb_start_var: unsigned(4 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        IF rst = RSTDEF THEN
            done <= '0';
            doneSp <= '0';
            addra_start <= (OTHERS => '0');
            addrb_start <= (OTHERS => '0');
            a_offset <= (OTHERS => '0');
            b_offset <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF swrst = RSTDEF THEN
                done <= '0';
                doneSp <= '0';
                addra_start <= (OTHERS => '0');
                addrb_start <= (OTHERS => '0');
                a_offset <= (OTHERS => '0');
                b_offset <= (OTHERS => '0');
            ELSIF en = '1' THEN
                done <= '0';
                doneSp <= '0';
                a_offset_var := ('0' & a_offset) + 1;
                a_offset <= a_offset_var(3 DOWNTO 0);
                b_offset <= b_offset + 16;
                
                -- finished one column of matrix B
                IF a_offset_var(4) = '1' THEN
                    addrb_start_var := ('0' & addrb_start) + 1;
                    addrb_start <= addrb_start_var(3 DOWNTO 0);
                    doneSp <= '1';
                    
                    -- finished one row of matrix A
                    IF addrb_start_var(4) = '1' THEN
                        addra_start_var := ('0' & addra_start) + 16;
                        addra_start <= addra_start_var(7 DOWNTO 0);
                        
                        -- finished all matrices
                        IF addra_start_var(8) = '1' THEN
                            done <= '1';
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

END behavioral;
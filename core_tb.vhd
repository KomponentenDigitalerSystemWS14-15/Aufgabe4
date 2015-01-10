
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY core_tb IS
   -- empty
END core_tb;


ARCHITECTURE verhalten OF core_tb IS
   CONSTANT N: natural := 16;
   CONSTANT RSTDEF: std_ulogic := '1';
   CONSTANT tpd: time := 20 ns; -- 1/50 MHz

   COMPONENT core
      GENERIC(RSTDEF: std_logic);
      PORT(rst:   IN  std_logic;                      -- reset,          RSTDEF active
           clk:   IN  std_logic;                      -- clock,          rising edge
           swrst: IN  std_logic;                      -- software reset, RSTDEF active
           -- handshake signals
           strt:  IN  std_logic;                      -- start,          high active
           rdy:   OUT std_logic;                      -- ready,          high active
           -- address/data signals
           sw:    IN  std_logic_vector( 7 DOWNTO 0);  -- address input
           dout:  OUT std_logic_vector(15 DOWNTO 0)); -- result output
   END COMPONENT;

   SIGNAL rst:    std_logic := RSTDEF;
   SIGNAL clk:    std_logic := '0';
   SIGNAL hlt:    std_logic := '0';
   SIGNAL swrst:  std_logic := not RSTDEF;

   SIGNAL strt:   std_logic := '0';
   SIGNAL cnt:    integer   :=  0;
   SIGNAL rdy:    std_logic := '0';
   SIGNAL sw:     std_logic_vector( 7 DOWNTO 0) := (OTHERS => '0');
   SIGNAL dout:   std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
BEGIN

   rst <= RSTDEF, NOT RSTDEF AFTER 5*tpd;
   clk <= '1' AFTER tpd/2 WHEN clk='0' AND hlt='0' ELSE '0' AFTER tpd/2;

   u1: core
   GENERIC MAP(RSTDEF => RSTDEF)
   PORT MAP(rst   => rst,
            clk   => clk,
            swrst => swrst,
            strt  => strt,
            rdy   => rdy,
            sw    => sw,
            dout  => dout);

   main: PROCESS
      TYPE frames IS ARRAY(natural RANGE <>) OF integer;
      CONSTANT tab: frames(0 TO N*N-1) := (
          -9957,   17516,  -14375,   -8132,  -12934,    9606,    3638,     -10,
          -3935,    -575,   -9026,     529,  -26788,    7076,  -13984,    6019,
           6675,   13777,    -133,   12176,    9960,    1207,    -574,   14934,
          -8962,   -8238,    -814,  -18028,   -8003,  -11390,    3112,     712,
         -19266,   12557,    -298,  -13389,  -12919,  -13571,     946,   -3969,
           4625,  -18151,   -4242,   19249,   -9018,    1714,    4050,   -4353,
           1141,    3023,    8664,    7027,    3621,   13021,    2810,    2960,
          -9933,   13059,   -6253,   -7831,    7243,  -12928,    8327,    1247,
         -17746,   12080,   12016,   -6442,   -3451,    3746,  -21437,   -5054,
           9931,  -13647,   -2190,  -12272,   27768,    2719,   -1762,   14273,
          15261,  -15506,  -10612,   14469,   -5490,   -9686,   21759,    1213,
         -12742,   18904,   -5108,   11945,  -13441,     376,   -7725,   -1655,
         -15629,  -14882,  -10457,    6620,   22936,  -17808,    -233,   -5023,
         -11267,  -22610,   -9258,    1102,    3132,    -926,    3831,    3823,
           1080,    6772,   12353,  -19364,  -18682,    9300,   13350,   -3739,
          -8283,    9232,    2655,    4913,   -1563,   -5059,    7037,    7502,
          -4002,   -7691,  -18289,    1290,   -3846,  -14745,  -10101,    -548,
           2028,   -7310,    2931,     987,   -3348,   14908,  -19191,    4367,
          28152,    6274,   10420,    7549,    3653,   -8526,   11534,   -4355,
           7138,   26857,   13853,    3688,    2391,    4713,  -10803,   -7298,
          12756,   -6601,    6016,    4235,   25569,    6067,   11045,   -5243,
         -14526,   24146,   -4169,  -16283,    -981,  -22562,    9236,   -7283,
           3048,   -7193,   -6790,   -5009,   -5157,  -12031,   11397,     630,
         -16593,    2576,    2758,   -7689,  -10607,    -466,   -4772,   16521,
            865,    -486,   -1009,   14044,   -5637,  -23860,    1036,   13109,
           6135,  -11581,    4275,    2608,   -9429,   -3206,   -5534,  -13403,
           1662,  -19910,   -3723,    6773,   -3018,  -19200,   12794,     943,
           3824,  -23871,  -20002,    3463,    8825,    5336,  -11727,    3761,
           2517,   -7187,    2005,    8521,   -8251,   -4115,   11999,    6274,
         -12557,   15353,   -5811,    1379,    -575,  -22051,   10892,   -8045,
         -10026,  -24657,  -17768,   -2150,     791,   11227,    6548,  -10579,
         -23820,   10658,  -13079,    6763,   -9981,    6949,    1465,   20346
      );

      PROCEDURE clock (n: natural) IS
      BEGIN
         FOR i IN 1 TO n LOOP
            WAIT UNTIL clk'EVENT AND clk='1';
         END LOOP;
      END PROCEDURE;

   BEGIN

      hlt  <= '0';
      strt <= '0';
      WAIT UNTIL clk'EVENT AND clk='1' AND rst=(NOT RSTDEF);

      clock(10);
      strt <= '1';
      clock(1);
      strt <= '0';
      clock(5);
      WAIT UNTIL clk'EVENT AND clk='1' AND rdy='1';

      FOR i IN 0 TO N*N-1 LOOP
         sw <= conv_std_logic_vector(i, 8);
         clock(2);
         ASSERT conv_integer(signed(dout))=tab(i) REPORT "wrong value" SEVERITY error;
      END LOOP;

      clock(1);
      hlt <= '1';
      WAIT;
   END PROCESS;

   PROCESS
   BEGIN
      cnt <= 0;
      WAIT UNTIL clk'EVENT AND clk='1' AND strt='1';
      LOOP
         cnt <= cnt + 1;
         WAIT UNTIL clk'EVENT AND clk='1';
         EXIT WHEN rdy='1';
      END LOOP;
      WAIT;
   END PROCESS;

END verhalten;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY LogicalStep_Lab4_top IS
   PORT
	(
	Clk			: in	std_logic;
	pb_n			: in	std_logic_vector(3 downto 0);
 	sw   			: in  std_logic_vector(7 downto 0); 
	leds			: out std_logic_vector(7 downto 0);

------------------------------------------------------------------	
	xreg, yreg	: out std_logic_vector(3 downto 0);-- (for SIMULATION only)
	xPOS, yPOS	: out std_logic_vector(3 downto 0);-- (for SIMULATION only)
------------------------------------------------------------------	
   seg7_data 	: out std_logic_vector(6 downto 0); -- 7-bit outputs to a 7-segment display (for LogicalStep only)
	seg7_char1  : out	std_logic;				    		-- seg7 digit1 selector (for LogicalStep only)
	seg7_char2  : out	std_logic				    		-- seg7 digit2 selector (for LogicalStep only)
	
	);
END LogicalStep_Lab4_top;

ARCHITECTURE Circuit OF LogicalStep_Lab4_top IS

-------------------------------------------------------------------------------------
-- Provided Project Components Used for sevensegment output and clk sources		  --
------------------------------------------------------------------- -----------------
COMPONENT Clock_Source 	port (SIM_FLAG: in boolean;clk_input: in std_logic;clock_out: out std_logic);
END COMPONENT;

component SevenSegment
  port 
   (
      hex	   :  in  std_logic_vector(3 downto 0);   -- The 4 bit data to be displayed
      sevenseg :  out std_logic_vector(6 downto 0)    -- 7-bit outputs to a 7-segment
   ); 
end component SevenSegment;

component segment7_mux 
  port 
   (
      clk        : in  std_logic := '0';
		DIN2 		: in  std_logic_vector(6 downto 0);	
		DIN1 		: in  std_logic_vector(6 downto 0);
		DOUT			: out	std_logic_vector(6 downto 0);
		DIG2			: out	std_logic;
		DIG1			: out	std_logic
   );
end component segment7_mux;


------------------------------------------------------------------
-- 				Add  Other Components here								 --
------------------------------------------------------------------

component Bidir_shift_reg is port
	(
			CLK 				: in std_logic := '0';
			RESET 			: in std_logic := '0';
			CLK_EN			: in std_logic := '0';
			LEFT0_RIGHT1   : in std_logic := '0';
			REG_BITS 		: out std_logic_vector(3 downto 0)
	);
end component;

component U_D_Bin_Counter4bit is port
	( 
			CLK 				: in std_logic := '0';
			RESET  			: in std_logic := '0';
			CLK_EN			: in std_logic := '0';
			UP1_DOWN0		: in std_logic := '0';
			COUNTER_BITS 	: out std_logic_vector(3 downto 0)
	);
end component;

component Compx4 is port
	(
			A 					: in std_logic_vector(3 downto 0);		 
			B 					: in std_logic_vector(3 downto 0);		 
			AGTB, AEQB, ALTB : out std_logic
	);
end component;

component Extender is port
	(
		 CLK			 : in std_logic;
		 Reset	 	 : in std_logic;
		 Extender_en : in std_logic;
		 Extender	 : in std_logic;
		 ext_pos		 : in std_logic_vector(3 downto 0);
		 clk_en		 : out std_logic;		
		 left0_right1: out std_logic; 	
		 extender_out: out std_logic;		
		 grappler_en : out std_logic
	);
END component;

component Grappler is port
	(
		 CLK			: in std_logic;
		 Reset   	: in std_logic;
		 grappler	: in std_logic;	
		 grappler_en: in std_logic;	
		 grappler_on: out std_logic
	);	
END component;

component Inverter is port
	(
		pb_n3			: in std_logic;
		pb_n2			: in std_logic;
		pb_n1			: in std_logic;
		pb_n0			: in std_logic;
		AH_pb_n3		: out std_logic;
		AH_pb_n2		: out std_logic;
		AH_pb_n1		: out std_logic;
		AH_pb_n0		: out std_logic
	);
end component;

component Target_Register is port
	(
		CLK				: in std_logic;
		Reset				: in std_logic;
		Capture			: in std_logic;
		Target_Value	: in std_logic_vector  (3 downto 0);
		Reg_Value		: out std_logic_vector (3 downto 0)
	);
END component;

component XY_Motion is port
	(
		CLK				 : in std_logic;
		reset				 : in std_logic;
		X_GT			 	 : in std_logic;
		X_EQ			 	 : in std_logic;
		X_LT  		 	 : in std_logic;
		motion 		 	 : in std_logic;
		Y_GT 	 		 	 : in std_logic;
		Y_EQ 	 		 	 : in std_logic;
		Y_LT   		 	 : in std_logic;
		extender_out 	 : in std_logic;
		clk1_en		 	 : out std_logic;
		up1_down0_1     : out std_logic;
		clk2_en		 	 : out std_logic;
		up1_down0_2		 : out std_logic;
		error			 	 : out std_logic;
		Capture_XY   	 : out std_logic;
		extender_en		 : out std_logic
	);
end component;


------------------------------------------------------------------
-- 					provided signals
------------------------------------------------------------------
signal clk_in, clock	: std_logic;										 --
------------------------------------------------------------------	
constant SIM_FLAG : boolean := FALSE; -- set to FALSE when compiling for FPGA download to LogicalStep board
------------------------------------------------------------------	
------------------------------------------------------------------	
-- 					Declared Signals										 --
------------------------------------------------------------------

-- signals for inverter
signal reset				: std_logic;
signal motion 				: std_logic;
signal extender_in 		: std_logic;
signal grappler_in 		: std_logic;

-- signals for XY Motion
signal clk_enX		: std_logic;
signal clk_enY		: std_logic;
signal up_downX	: std_logic;
signal up_downY	: std_logic;
signal error		: std_logic;
signal Capture_XY		: std_logic;
signal extender_en   : std_logic;

-- signals for extender
signal clk_en_ext			: std_logic;
signal left_right 		: std_logic;
signal extender_out		: std_logic;
signal grappler_en 		: std_logic;

-- signals for grappler
signal grappler_on 	: std_logic;

-- signals for X COUNTER
signal X_pos 	: std_logic_vector(3 downto 0);

-- signals for Y COUNTER
signal Y_pos 	: std_logic_vector(3 downto 0);

-- signals for X Register
signal X_reg 	: std_logic_vector(3 downto 0);

-- signals for Y Register
signal Y_reg 	: std_logic_vector(3 downto 0);

-- signals for extender reg4
signal ext_pos 	: std_logic_vector(3 downto 0);

-- signals for X Compx4
signal X_GT  		: std_logic;
signal X_EQ			: std_logic;
signal X_LT			: std_logic;

-- signals for Y Compx4
signal Y_GT  		: std_logic;
signal Y_EQ			: std_logic;
signal Y_LT			: std_logic;

-- signal for X7Segdec
signal X_7seg		: std_logic_vector(6 downto 0);

-- signal for Y7Segdec
signal Y_7seg		: std_logic_vector(6 downto 0);

-- no need for extra clearification as all signals 
-- are defined in top entity part


------------------------------------------------------------------
--					  Declared signal ends									 --
------------------------------------------------------------------

BEGIN -- here the circuit begins
clk_in <= clk;

------------------------------------------------------------------
--				Clock_Selector Declared										 --
------------------------------------------------------------------
Clock_Selector: Clock_source port map(SIM_FLAG, clk_in, clock); --
------------------------------------------------------------------
--						Instances Begin										 --
------------------------------------------------------------------
inst0: Inverter port map(
		 pb_n(3),pb_n(2),pb_n(1),pb_n(0),
		 reset,motion,extender_in,grappler_in
		 );

inst1: XY_Motion port map(
		 clk_in,
		 reset,
		 X_GT,
		 X_EQ,
		 X_LT,
		 motion,
		 Y_GT,
		 Y_EQ,
		 Y_LT,
		 extender_out,
		 clk_enX,
		 up_downX,
		 clk_enY,
		 up_downY,
		 error,
		 Capture_XY,
		 extender_en
		 );
		 
		 leds(0) <= error;

inst2: Extender port map(
		 clk_in,
		 reset,
		 extender_en,
		 extender_in,
		 ext_pos,
		 clk_en_ext,
		 left_right,
		 extender_out,
		 grappler_en
		 );

inst3: Grappler port map(
		 clk_in,
		 reset,
		 grappler_in,
		 grappler_en,
		 grappler_on
		 );

		 leds(1) <= grappler_on;

		 
-- binary counter for x position
inst4: U_D_Bin_Counter4bit port map(
		 clk_in,
		 reset,
		 clk_enX,
		 up_downX,
		 X_pos-- (3 downto 0);
		 );
		 
		 Xpos(3 downto 0) <= X_pos;-- (3 downto 0);
		 
-- Register for X position
inst5: Target_Register port map(
		 clk_in,
		 reset,
		 Capture_XY,
		 sw(7 downto 4),
		 X_reg-- (3 downto 0)
		 );
		 
		 Xreg(3 downto 0) <= X_reg;--(3 downto 0);
		 
-- binary counter for y position
inst6: U_D_Bin_Counter4bit port map(
		 clk_in,
		 reset,
		 clk_enY,
		 up_downY,
		 Y_pos-- (3 downto 0);
		 );
		 
		 Ypos(3 downto 0) <= Y_pos;-- (3 downto 0);

-- Register for Y position
inst7: Target_Register port map(
		 clk_in,
		 reset,
		 Capture_XY,
		 sw(3 downto 0),
		 Y_reg-- (3 downto 0)
		 );
		 
		 Yreg(3 downto 0) <= Y_reg;--(3 downto 0);
-- Reg4 for extender
inst8: Bidir_shift_reg port map(
		 clk_in,
		 reset,
		 clk_en_ext,
		 left_right,
		 ext_pos
		 );
		 
		 leds(5 downto 2) <= ext_pos;

-- Compx4 for X position
inst9: Compx4 port map(
		 X_pos,
		 X_reg,
		 X_GT,
		 X_EQ,
		 X_LT
		 );

-- Compx4 for y position
inst10: Compx4 port map(
		 Y_pos,
		 Y_reg,
		 Y_GT,
		 Y_EQ,
		 Y_LT
		 );

-- Hex to 7seg for X		 
inst11: SevenSegment port map(
		 X_pos,
		 X_7seg
		 );

-- Hex to 7seg for Y		 
inst12: SevenSegment port map(
		 Y_pos,
		 Y_7seg
		 );
		 
inst13: segment7_mux port map(
		 clk_in,
		 X_7seg,
		 Y_7seg,
		 seg7_data (6 downto 0),
		 seg7_char2,
		 seg7_char1
		 );
		 
		 
END Circuit;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity XY_Motion is port
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
end XY_Motion;


-- 			HERE THE LOGIC BEGINS		--
Architecture XY_Logic of XY_Motion is


-- four stages--
  TYPE STATE_NAMES IS (S0, motion_pressed, moving, system_error);
  SIGNAL current_state, next_state	:  STATE_NAMES;
  SIGNAL motion_done, motion_not_done, s_error: std_logic;

BEGIN 
  motion_done <= Y_EQ AND X_EQ;
  motion_not_done <= not(Y_EQ AND X_EQ);
  s_error <= motion and extender_out;
	
Register_Section: PROCESS (CLK, reset, next_state)  -- this process synchronizes the activity to a clock
	BEGIN
		IF (reset = '1') THEN
			current_state <= S0;
		ELSIF(rising_edge(CLK)) THEN
			current_state <= next_state;
		END IF;
	END PROCESS;

TRANSITION_SECTION: Process (motion, motion_done, motion_not_done, extender_out)
	BEGIN
		  CASE current_state IS
			   
			-- S0 is the state where the x and y coordinate is not changing            
			-- in this case, we only detect if the motion button is being pressed      
			-- if motion is one, we go to motion pressed state, otherwise we no change 
			
				when S0 =>
				
					 if (motion = '1') then 					 
						next_state <= motion_pressed;
						
					 else					 
						next_state <= S0;
						
					 end if;
					 
			-- Motion_pressed state is used to detect whether go to s_error or moving state 		
			-- if extender out the s_error state occurs and everything's to be determined there 
			-- if not we check for the release of motion, when motion = 0 we go moving		  		
				when motion_pressed =>
				
					 if (s_error = '1') then
						next_state <= system_error; 
						
					 elsif (motion = '1') then
						next_state <= motion_pressed;
						
					 elsif (motion = '0') then
						next_state <= moving;
						
					 end if;
						
			-- moving state is when the RAC is moving, in this circumstances the extender would not be on
			-- we only care about whether the xy value matches the targeted xy
			-- if matches, go to S0 and system stop. If not, stay in this state
				when moving =>
				
					 if (motion_not_done = '1') then
						next_state <= moving;
						
					 elsif( motion_done = '1' ) then
						next_state <= S0;
						
					 end if;
					 
			-- system_error state is being used prevent xy from being changing
			-- to exit this state the extender_out must equal to zero, and it would be redirected back to S0
			-- if it is not zero we stay in this state no matter what
				when system_error =>
				
					 if ( extender_out = '1') then
						next_state <= system_error;
						
					 else 
						next_state <= S0;
						
					 end if;		
		  END CASE;
	END PROCESS;
		  
		  
-- It is a mealy machine
DECODER_SECTION: Process (current_state, X_GT, X_EQ, X_LT, Y_GT, Y_EQ, Y_LT)
	BEGIN
		  CASE current_state is
				
		  -- In S0 state nothing would change at all, the machine is at rest		
				when S0 =>
					 clk1_en		 <= '0';
					 up1_down0_1 <= '0';
					 clk2_en		 <= '0';
					 up1_down0_2 <= '0';
					 error		 <= '0';
					 Capture_XY	 <= '0';
					 extender_en <= '1';
		 	
		  -- purpose of this state is to check for s_error and capture xy value	 	
				when motion_pressed =>
					 clk1_en		 <= '0';
					 up1_down0_1 <= '0';
					 clk2_en		 <= '0';
					 up1_down0_2 <= '0';
					 error		 <= '0';
					 Capture_XY	 <= '1';
					 extender_en <= '0';
				
				
		  -- this is when machine goes mealy, x and y counters get individual inputs from 
		  -- xy motion block according to the compx4 value  
				when moving =>
					 clk1_en		 <=  NOT X_EQ;
					 up1_down0_1 <=  X_LT;
					 clk2_en		 <=  NOT Y_EQ;
					 up1_down0_2 <=  Y_LT;
					 error		 <= '0';
					 Capture_XY	 <= '0';
					 extender_en <= '0';
				
				
		  -- s_error state essentially gives nothing to the system but the error message, therefore
		  -- everything else is being stopped 
				when system_error =>
					 clk1_en		 <= '0';
					 up1_down0_1 <= '0';
					 clk2_en		 <= '0';
					 up1_down0_2 <= '0';
					 error		 <= '1';
					 Capture_XY	 <= '0';		  
					 extender_en <= '0';
		  
		  END CASE;
	
	END PROCESS;
END XY_Logic;

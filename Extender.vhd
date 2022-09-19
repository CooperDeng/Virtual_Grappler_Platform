library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY Extender is port
	(
		 CLK			 : in std_logic;
		 Reset	 	 : in std_logic;
		 Extender_en : in std_logic;
		 Extender	 : in std_logic;
		 ext_pos		 : in std_logic_vector(3 downto 0);
		 clk_en		 : out std_logic;		-- enables the usage of extender when is 1 and disables it when is 0
		 left0_right1: out std_logic; 	-- when 0 shift left, when 1 shift right
		 extender_out: out std_logic;		-- identify the out of extender
		 grappler_en : out std_logic
	);
END ENTITY;

ARCHITECTURE E_Logic of Extender is

 TYPE STATE_NAMES IS (S0, extender_pressed_S0, extending_state, extended_state,extender_pressed_extended, retracting_state);
 SIGNAL current_state, next_state	:  STATE_NAMES;

 
-- 				here the circuit begins 				-- 
BEGIN

REGISTER_SECTION : process(CLK, Reset, next_state)

	BEGIN
		  
		  if (Reset = '1') then
			  current_state <= S0;
		  elsif(rising_edge(CLK)) then
			  current_state <= next_state;
		  end if;

	END process;


TRANSITION_SECTION : process(Extender_en, Extender, ext_pos, current_state)
	BEGIN
	-- seperate cases by extender_en value
			if (Extender_en = '1') then
				
				CASE current_state is
				
				-- In S0 state the extender should be fully retracted
				-- If the extender input is 1, the state go to extender_pressed
				-- otherwise, the extender stays at fully retracted(S0) state

					when S0 =>
						 if (Extender = '1') then
						 
						   next_state <= extender_pressed_S0;
							
						 else
						 
							next_state <= S0;
							
						 end if;
				
				-- In extender_pressed state we mainly detect whether the extender button has been pressed & released
				-- If the button is released then we take ext_pos into account
				-- if ext_pos is not 1111, then the ext pos needs to be increased, otherwise it needs to be decreased
					when extender_pressed_S0 =>
						 if (Extender = '1') then
							
							next_state <= extender_pressed_S0;
						 
						 else
						 
							next_state <= extending_state;
						 
						 end if;

				-- in extending state the extender is still extending
				-- referring to the ext_pos, when it is not 1111, the extender is still extending
				-- if ext_pos = 1111 then it is fully extended, next_state goes to extended state

					when extending_state =>
						 if ( NOT(ext_pos = "1111")) then
						 
							 next_state <= extending_state;
							 
						 else
							 
							 next_state <= extended_state;
							 
						 end if;
					
				-- in extended state the extended has fully extended
				-- we only take the Extender input into consideration, when releasing, the extended would be retracting
				-- otherwise, the extender stays at this state forever
					
					when extended_state =>
						 if (Extender = '1') then
							
							next_state <= extender_pressed_extended;
						 
						 else
							
							next_state <= extended_state;
						 
						 end if;
						 
				-- in this state we pressed the button when the extender is done extending
				-- if we hold the button we stay in this state
				-- otherwise we go to retraction state
					when extender_pressed_extended =>
						 if( Extender = '1') then 
							
							next_state <= extender_pressed_extended;
						 
						 else
							
							next_state <= retracting_state;
						 
						 end if;
					
				-- in retracting state the extender is retracting
			   -- retracting would pursue until the FULL RETRACTION, that is, ext_pos = 0000
				-- when ext_pos = 0000, state gets redirected to S0
				-- otherwise, the state stays at retracting state
					
					when retracting_state =>						 
						 if (ext_pos = "0000") then
							
							next_state <= S0;
						 
						 else
						 
							next_state <= retracting_state;
						 
						 end if;
				end case;
				
	-- when extender_en != 1, the extender should be unable to move, 
	-- which means that it would be forced to stay
	-- at S0
			
			else	
			  
			  next_state <= S0;
			
			end if;
	END process;

	
-- Moore Machine, the output only depends on its current state -- 
DECODER_SECTION : process(current_state)
	BEGIN
		CASE current_state is
		
			 -- In S0 state, it is not moving and thus clk_en is 0
			 -- not shifting
			 -- grappler not allowed to move
			 when S0 =>
			   CLK_en		 <= '0';
				left0_right1 <= '0';
				grappler_en  <= '0';
				extender_out <= '0';
			
			-- transition state
			-- extender not moving, grappler not able to move
			 when extender_pressed_S0 =>
			   CLK_en		 <= '0';
				left0_right1 <= '0';
				grappler_en  <= '0';
				extender_out <= '0';
			 
			 -- In extending state, it is moving and clk_en is 1
			 -- shifting right
			 -- grappler not allowed to move
			 when extending_state =>
			   CLK_en 		 <= '1';
				left0_right1 <= '1';
				grappler_en  <= '0';
				extender_out <= '1';
			 
			 -- not moving, clk_en is 0
			 -- grappler is allowed to move
			 when extended_state =>
				CLK_en 		 <= '0';
				left0_right1 <= '0';
				grappler_en	 <= '1';
				extender_out <= '1';
			 
			 -- Transition state
			 -- extender not moving, grappler able to move
			 when extender_pressed_extended =>
				CLK_en		 <= '0';
				left0_right1 <= '0';
				grappler_en  <= '1';
				extender_out <= '1';
			 
			 -- moving, clk_en is 1
			 -- shifting to the left
			 -- grappler is not allowed to move
			 when retracting_state =>
				CLK_en		 <= '1';
				left0_right1 <= '0';
				grappler_en	 <= '0';
				extender_out <= '1';
		
		END CASE;
	END process;
END E_Logic;
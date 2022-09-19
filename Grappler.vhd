library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY Grappler is port
	(
		 CLK			: in std_logic;
		 Reset   	: in std_logic;
		 grappler	: in std_logic;	-- Grappler Toggle
		 grappler_en: in std_logic;	-- Coming from the extender, acting as a condition for toggling grappler
		 grappler_on: out std_logic
	);
	
END ENTITY;

ARCHITECTURE G_Logic of Grappler is

 TYPE STATE_NAMES is (S0, grappler_pressed_S0, open_state, grappler_pressed_open, closed_state);

 SIGNAL current_state, next_state	:  STATE_NAMES;

--			HERE THE CIRCUIT BEGINS			--
BEGIN


REGISTER_SECTION: process (CLK, Reset, next_state)
	 
	 BEGIN 
	 
	 		if (Reset = '1') then
	 			current_state <= S0;			
	 		elsif(rising_edge(CLK)) then
	 			current_state <= next_state;			
	 		end if;
	 
	 END PROCESS;

TRANSITION_SECTION: process (grappler, grappler_en, current_state)

	BEGIN
		  CASE current_state is
		  
		  -- the grappler is in its INITIAL STATE, which is OBVIOUSLY going to be closed!
		  -- grappler_en = 1 AND fallingedge(grappler) sends it into open state (allows it to open 
		  -- and input says open)
		  -- otherwise, the grappler stays at S0, which is initial state
				
				WHEN S0 =>
					 if (grappler_en = '1' AND grappler = '1') then
						 next_state <= grappler_pressed_S0;
					 else
						 next_state <= S0;
					 end if;
					 
		  -- this state is used to detect the press of button during S0 state,
		  -- if the button is being hold, stay, if not, go to open_state. 
		  
				WHEN grappler_pressed_S0 =>
				    if (grappler = '1') then
						next_state <= grappler_pressed_S0;
					 
					 else
					   next_state <= open_state;
					 
					 end if;
		 
		  -- the grappler is now in its OPEN STATE, which is again, OBVIOUSLY going to be opened!
		  -- in this case, the grappler is only changing when grappler_en = 1 AND grappler = 1
		  -- otherwise, the grappler stays open
			
			  WHEN open_state =>
				    if (grappler_en = '1' AND grappler = '1') then
						 next_state <= grappler_pressed_open;
					 else
						 next_state <= open_state;
					 end if;
					 
		  -- this state is used to detect the press of button when the grappler is open
		  -- if the button is being hold, stay, if not, go to closed_state 
		  
			  WHEN grappler_pressed_open =>
					 if ( grappler = '1') then 
						next_state <= grappler_pressed_open;
					 
					 else
						next_state <= closed_state;
					 
					 end if;
			
			-- just a rediretion to S0 because no state machine diagram is being shown
			-- (when there are only two states)
			  WHEN closed_state =>
					 next_state <= S0;
					 
					 
		 END CASE;		
	
	END PROCESS;

-- Moore Machine, the output only depends on its current state -- 
DECODER_SECTION: process(current_state)

	BEGIN 
		  -- when it is in its open state, the output is ZERO
		  -- when it is in its close state and S0, the output is ONE
		  CASE current_state is
				 WHEN S0 =>
				 
						grappler_on <= '1';
				 
				 WHEN grappler_pressed_S0 =>
						
						grappler_on <= '1';
						
				 WHEN open_state =>
				 
						grappler_on <= '0';
				 
				 WHEN grappler_pressed_open =>
				      
						grappler_on <= '0';
						
				 WHEN closed_state =>
						
						grappler_on <= '1';
						

		  END CASE;
		  
	END PROCESS;
END G_Logic;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity Target_Register is port
	(
		CLK				: in std_logic;
		Reset				: in std_logic;
		Capture			: in std_logic;
		Target_Value	: in std_logic_vector  (3 downto 0);
		Reg_Value		: out std_logic_vector (3 downto 0)
	);
END ENTITY;

Architecture R_Logic of Target_Register is


-- 			Here the Circuit Begins 		 --
BEGIN

	process (CLK, Reset, Capture) is
	BEGIN
		
		if (reset = '1') then
			Reg_Value <= "0000";
		elsif (Capture = '1' AND rising_edge(CLK)) then
			Reg_Value <= Target_Value;
		end if;
		
	end process;

END R_Logic;
--			 	Here everything ends			    --				
		
		
	
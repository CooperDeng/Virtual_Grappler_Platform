library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

Entity Bidir_shift_reg is port
	(
			CLK 				: in std_logic := '0';
			RESET 			: in std_logic := '0';
			CLK_EN			: in std_logic := '0';
			LEFT0_RIGHT1   : in std_logic := '0';
			REG_BITS 		: out std_logic_vector(3 downto 0)
	);
end Entity;


-- here the circuit begins				--
ARCHITECTURE one OF Bidir_shift_reg is

Signal sreg				: std_logic_vector(3 downto 0);


BEGIN

process (CLK, RESET) is
begin
	if (RESET = '1') then
				sreg <= "0000";
				
	elsif (rising_edge(CLK) AND (CLK_EN = '1')) then
	
			if (LEFT0_RIGHT1 = '1') then
				
				sreg (3 downto 0) <= '1' & sreg(3 downto 1);
			
			elsif (LEFT0_RIGHT1 = '0') then
			
				sreg (3 downto 0) <= sreg(2 downto 0) & '0';
			
			end if;
			
	end if;
	REG_BITS <= sreg;
	
end process;

END one;
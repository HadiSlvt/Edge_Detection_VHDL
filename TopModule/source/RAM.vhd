library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.MyPackage.all;

entity RAM is
    Generic(
           wordLength   : natural;
           cellNum      : natural
    );
    Port ( clk          : STD_LOGIC;
    
           wrData       : in STD_LOGIC_VECTOR (wordLength - 1 downto 0);
           wrAddress    : in unsigned (integer(ceil(log(real(cellNum)) / log(2.0))) - 1 downto 0);
           wrEn         : in STD_LOGIC;
		   
           rdAddress    : in unsigned (integer(ceil(log(real(cellNum)) / log(2.0))) - 1 downto 0);
           rdEn         : in STD_LOGIC;
		   
           rdData       : out STD_LOGIC_VECTOR (wordLength - 1 downto 0);
           rdDataRdy    : out STD_LOGIC
    );
end RAM;

architecture Behavioral of RAM is

    signal memory       : std_logic_vector_array(0 to cellNum - 1)(wrData'range);
    signal rdData_x     : std_logic_vector(wrData'range);
    signal rdDataRdy_x  : std_logic;
    
    attribute ram_style : string;
    attribute ram_style of memory : signal is "block"; -- "distributed" / "block" / "ultra"

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if wrEn = '1' then
                memory(to_integer(wrAddress)) <= wrData;
            end if;
            
            rdData_x    <= memory(to_integer(rdAddress));
            rdData	    <= rdData_x;
			
            rdDataRdy_x <= rdEn;
            rdDataRdy	<= rdDataRdy_x;
        end if;
    end process;

end Behavioral;

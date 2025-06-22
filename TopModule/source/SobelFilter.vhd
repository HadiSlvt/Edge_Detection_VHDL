library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

use work.MyPackage.all;

entity SobelFilter is
    Port ( 
		clk				: in STD_LOGIC;
		
		syncIn			: in STD_LOGIC;
			
		pixelIn			: in unsigned_matrix(1 to 3)(1 to 3)(8 - 1 downto 0);
		inputRdy		: in STD_LOGIC;
			
		pixelOut		: out unsigned(14 - 1 downto 0);
		outputRdy		: out STD_LOGIC
    );
end SobelFilter;


architecture Behavioral of SobelFilter is
	
	signal inputRdy_r	: std_logic_vector(4 - 1 downto 0);
	signal Gx			: signed_matrix(1 to 3)(1 to 2)(pixelIn(1)(1)'length + 2 - 1 downto 0);
	signal stagex1		: signed_array(1 to 3)(Gx(1)(1)'length + 3 - 1 downto 0);
	signal stagex2		: signed_array(1 to 2)(Gx(1)(1)'length + 3 - 1 downto 0);
	signal stagex3		: signed(Gx(1)(1)'length + 3 - 1 downto 0);
	signal GxAbs		: unsigned(stagex3'range);
	signal Gy			: signed_matrix(1 to 2)(1 to 3)(pixelIn(1)(1)'length + 2 - 1 downto 0);
	signal stagey1		: signed_array(1 to 3)(Gy(1)(1)'length + 3 - 1 downto 0);
	signal stagey2		: signed_array(1 to 2)(Gy(1)(1)'length + 3 - 1 downto 0);
	signal stagey3		: signed(Gy(1)(1)'length + 3 - 1 downto 0);
	signal GyAbs		: unsigned(stagey3'range);

begin

	Gx(1)(1) <= - signed(resize(pixelIn(1)(1), Gx(1)(1)'length)); 
	Gx(2)(1) <= - signed('0' & pixelIn(2)(1) & '0'); 
	Gx(3)(1) <= - signed(resize(pixelIn(3)(1), Gx(1)(1)'length)); 
	Gx(1)(2) <=  signed(resize(pixelIn(1)(3), Gx(1)(1)'length)); 
	Gx(2)(2) <=  signed('0' & pixelIn(2)(3) & '0'); 
	Gx(3)(2) <=  signed(resize(pixelIn(3)(3), Gx(1)(1)'length)); 
	
	process(clk)
	begin
		if rising_edge(clk) then		
			for i in Gx'range loop
				stagex1(i) <= resize(Gx(i)(1), stagex1(i)'length) + resize(Gx(i)(2), stagex1(i)'length);
			end loop;
			
			stagex2(1) <= stagex1(1) + stagex1(2);
			stagex2(2) <= stagex1(3);
			
			stagex3 <= stagex2(1) + stagex2(2);
			
			if stagex3 < 0 then
				GxAbs <= unsigned(-stagex3);
			else
				GxAbs <= unsigned(stagex3);
			end if;
		end if;
	end process;
	
	Gy(1)(1) <= - signed(resize( pixelIn(1)(1), Gy(1)(1)'length)); 
	Gy(1)(2) <= - signed('0' & pixelIn(1)(2) & '0'); 
	Gy(1)(3) <= - signed(resize( pixelIn(1)(3), Gy(1)(1)'length)); 
	Gy(2)(1) <=  signed(resize( pixelIn(3)(1), Gy(1)(1)'length)); 
	Gy(2)(2) <=  signed('0' & pixelIn(3)(2) & '0'); 
	Gy(2)(3) <=  signed(resize( pixelIn(3)(3), Gy(1)(1)'length)); 
	
	process(clk)
	begin
		if rising_edge(clk) then
			for i in Gy(1)'range loop
				stagey1(i) <= resize(Gy(1)(i), stagey1(i)'length) + resize(Gy(2)(i), stagey1(i)'length);
			end loop;
			
			stagey2(1) <= stagey1(1) + stagey1(2);
			stagey2(2) <= stagey1(3);
			
			stagey3 <= stagey2(1) + stagey2(2);
			
			if stagey3 < 0 then
				GyAbs <= unsigned(-stagey3);
			else
				GyAbs <= unsigned(stagey3);
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge(clk) then
			if syncIn = '1' then
				inputRdy_r <= (others => '0');
			else
				inputRdy_r <= inputRdy_r(inputRdy_r'left - 1 downto 0) & inputRdy;
			end if;
			
			pixelOut 	<= ('0' & GxAbs) + ('0' & GyAbs);
			outputRdy	<= inputRdy_r(inputRdy_r'left);
		end if;
	end process;
end Behavioral;

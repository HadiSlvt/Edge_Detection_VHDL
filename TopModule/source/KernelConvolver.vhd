library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

use work.MyPackage.all;

entity KernelConvolver is
	Generic (
		coefWidth		: natural
	);
    Port ( 
		clk				: in STD_LOGIC;
		
		coef			: in signed_matrix(1 to 3)(1 to 3)(coefWidth - 1 downto 0);
		inverse_divisor	: in unsigned(17 - 1 downto 0);
		syncIn			: in STD_LOGIC;
			
		pixelIn			: in unsigned_matrix(1 to 3)(1 to 3)(8 - 1 downto 0);
		inputRdy		: in STD_LOGIC;
			
		pixelOut		: out unsigned(8 - 1 downto 0);
		outputRdy		: out STD_LOGIC
    );
end KernelConvolver;


architecture Behavioral of KernelConvolver is

	component Multiplier is
		Port ( 
			clk			: in STD_LOGIC;
			
			A			: in signed(27 - 1 downto 0);
			B			: in signed(18 - 1 downto 0);
			C			: in signed(48 - 1 downto 0);
			inputRdy	: in STD_LOGIC;
			
			P			: out signed(48 - 1 downto 0);
			outputRdy	: out STD_LOGIC
		);
	end component;

	signal coef_r				: signed_matrix(coef'range)(coef(1)'range)(coef(1)(1)'range);
	signal inverse_divisor_r	: unsigned(inverse_divisor'range);
	signal multOut				: signed_matrix(coef'range)(coef(1)'range)(48 - 1 downto 0);
	signal adderTreeInput		: signed_matrix(multOut'range)(multOut(1)'range)(coef(1)(1)'length + pixelIn(1)(1)'length + 4 - 1 downto 0);
	signal multOutputRdy		: std_logic_vector(coef'length * coef(1)'length - 1 downto 0);
	
	signal stage1				: signed_array(1 to 5)(adderTreeInput(1)(1)'range);
	signal stage2				: signed_array(1 to 3)(adderTreeInput(1)(1)'range);
	signal stage3				: signed_array(1 to 2)(adderTreeInput(1)(1)'range);
	signal stage4				: signed(adderTreeInput(1)(1)'range);
	signal multOutputRdy_r		: std_logic_vector(4 - 1 downto 0);
	
	signal pixelOut_x			: signed(48 - 1 downto 0);
	signal outputRdy_x			: std_logic;

begin

	assert coefWidth <= 15 report "CoefWidth must be less than / equal to 15" severity failure;

	process(clk)
	begin
		if rising_edge(clk) then
			if syncIn = '1' then
				coef_r 				<= coef;
				inverse_divisor_r	<= inverse_divisor;
			end if;
		end if;
	end process;
	
	coefMultGen1 : for i in coef_r'range generate
		coefMultGen2 : for j in coef_r(i)'range generate
			coefMult : Multiplier
			Port Map( 
				clk			=> clk,
							
				A			=> resize(coef_r(i)(j), 27),
				B			=> signed(resize(pixelIn(i)(j), 18)),
				C			=> to_signed(0, 48),
				inputRdy	=> inputRdy,
				
				P			=> multOut(i)(j),
				outputRdy	=> multOutputRdy(3 * (i - 1) + j - 1)
			);
			
			adderTreeInput(i)(j) <= multOut(i)(j)(adderTreeInput(i)(j)'range);
		end generate;
	end generate;
	
	process(clk)
	begin
		if rising_edge(clk) then
			stage1(1)	<= adderTreeInput(1)(1) + adderTreeInput(1)(2);
			stage1(2)	<= adderTreeInput(2)(1) + adderTreeInput(2)(2);
			stage1(3)	<= adderTreeInput(3)(1) + adderTreeInput(3)(2);
			stage1(4)	<= adderTreeInput(1)(3) + adderTreeInput(2)(3);
			stage1(5)	<= adderTreeInput(3)(3);
			
			stage2(1)	<= stage1(1) + stage1(2);
			stage2(2)	<= stage1(3) + stage1(4);
			stage2(3)	<= stage1(5);
			
			stage3(1)	<= stage2(1) + stage2(2);
			stage3(2)	<= stage2(3);
			
			stage4		<= stage3(1) + stage3(2);
			
			multOutputRdy_r	<= multOutputRdy_r(multOutputRdy_r'left - 1 downto 0) & multOutputRdy(0);
		end if;
	end process;
	
	InvDivMult : Multiplier
	Port Map( 
		clk			=> clk,
					
		A			=> resize(stage4, 27),
		B			=> signed('0' & inverse_divisor_r),
		C			=> to_signed(0, 48),
		inputRdy	=> multOutputRdy_r(multOutputRdy_r'left),
		
		P			=> pixelOut_x,
		outputRdy	=> outputRdy_x
	);
	
	process(clk)
	begin
		if rising_edge(clk) then
			if pixelOut_x < 0 then
				pixelOut <= (others => '0');
			elsif pixelOut_x > 255 * 2 ** 16 then
				pixelOut <= to_unsigned(255, 8);
			else
				pixelOut <= unsigned(pixelOut_x(16 + 8 - 1 downto 16)) + unsigned(pixelOut_x(15 downto 15));
			end if;
			
			outputRdy <= outputRdy_x;
		end if;
	end process;
	
end Behavioral;

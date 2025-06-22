library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use work.MyPackage.all;
 
ENTITY TopModule_tb IS
	Generic (
		pictureWidth	: natural;
		pictureHeight	: natural;
		coefWidth		: natural
	);
END TopModule_tb;
 
ARCHITECTURE behavior OF TopModule_tb IS 
 
	component TopModule is
		Generic (
			pictureWidth	: natural;
			pictureHeight	: natural;
			coefWidth		: natural
		);
		Port ( 
			clk				: in STD_LOGIC;
			
			coef			: in signed_matrix(1 to 3)(1 to 3)(coefWidth - 1 downto 0);
			inverse_divisor	: in unsigned(17 - 1 downto 0);
			threshold		: in unsigned(14 - 1 downto 0);
			syncIn			: in STD_LOGIC;
				
			pixelIn			: in unsigned(8 - 1 downto 0);
			inputRdy		: in STD_LOGIC;
				
			pixelOut		: out STD_LOGIC;
			outputRdy		: out STD_LOGIC
		);
	end component;
    
   constant clk_period 			: time := 10 ns;

	signal clk					: std_logic;
	
	signal coef					: signed_matrix(1 to 3)(1 to 3)(coefWidth - 1 downto 0);
	signal inverse_divisor		: unsigned(17 - 1 downto 0);
	signal threshold			: unsigned(14 - 1 downto 0);
	signal syncIn				: STD_LOGIC;
	
	signal pixelIn				: unsigned(8 - 1 downto 0);
	signal inputRdy				: STD_LOGIC;
	
	signal pixelOut				: STD_LOGIC;
	signal outputRdy			: STD_LOGIC;
 
BEGIN
 
	TopModuleInst: TopModule
		Generic map(
			pictureWidth	=> pictureWidth,
			pictureHeight	=> pictureHeight,
			coefWidth		=> coefWidth
		)
		Port map( 
			clk				=> clk,
			
			coef			=> coef,
			inverse_divisor	=> inverse_divisor,
			threshold		=> threshold,
			syncIn			=> syncIn,
			
			pixelIn			=> pixelIn,
			inputRdy		=> inputRdy,
			
			pixelOut		=> pixelOut,
			outputRdy		=> outputRdy
		);

	clk_gen :process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
 
	process
		file input_file 	: text open read_mode is "../test/input_data.txt";
		variable dataLine 	: line;
		variable data	 	: integer;
	begin
		wait for 100 * clk_period;
	
		while not endfile(input_file) loop
            readline(input_file, dataLine);
			
			for i in coef'range loop
				for j in coef(i)'range loop
					read(dataLine, data);
					coef(i)(j)	<= to_signed(data, coef(i)(j)'length) after clk_period/8;
				end loop;
			end loop;
			
			read(dataLine, data);
			inverse_divisor	<= to_unsigned(data, inverse_divisor'length) after clk_period/8;
			
			read(dataLine, data);
			threshold		<= to_unsigned(data, threshold'length) after clk_period/8;
			
			read(dataLine, data);
			syncIn			<= to_unsigned(data, 1)(0) after clk_period/8;
			
			read(dataLine, data);
			pixelIn			<= to_unsigned(data, pixelIn'length) after clk_period/8;
			
            read(dataLine, data);
			inputRdy 		<= to_unsigned(data, 1)(0) after clk_period/8;
						
            wait for clk_period;
        end loop;
		
		wait;
	end process;
	
	process(clk)
		file output_file 	: text open write_mode is "../test/output_data.txt";
		variable dataLine 	: line;
	begin
		if rising_edge(clk) then
			if outputRdy = '1' then
				write(dataLine, pixelOut);
				writeline(output_file, dataLine);
			end if;
		end if;
	end process;

END;

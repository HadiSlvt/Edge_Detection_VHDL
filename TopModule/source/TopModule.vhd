library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

library UNISIM;
use UNISIM.VComponents.all;

use work.MyPackage.all;

entity TopModule is
    Generic (
		pictureWidth	: natural := 256;
		pictureHeight	: natural := 256;
		coefWidth		: natural := 8
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
end TopModule;


architecture Behavioral of TopModule is

----------------------------------------------
-- COMPONENTS
----------------------------------------------

	component RAM is
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
	end component;
	
	component KernelConvolver is
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
	end component;
	
	component SobelFilter is
		Port ( 
			clk				: in STD_LOGIC;
			
			syncIn			: in STD_LOGIC;
				
			pixelIn			: in unsigned_matrix(1 to 3)(1 to 3)(8 - 1 downto 0);
			inputRdy		: in STD_LOGIC;
				
			pixelOut		: out unsigned(14 - 1 downto 0);
			outputRdy		: out STD_LOGIC
		);
	end component;
	
----------------------------------------------
-- SIGNALS
----------------------------------------------
	function unsignedWidth(n : natural) return natural is
	begin
		return natural(ceil(log(real(n)) / log(2.0)));
	end function;
----------------------------------------------
-- SIGNALS
----------------------------------------------

	signal bffrNoiseRdAddr		: unsigned(unsignedWidth(pictureWidth) - 1 downto 0);
	signal bffrNoiseRdAddr_r	: unsigned(bffrNoiseRdAddr'range);
	signal bffrNoiseWrAddr		: unsigned(bffrNoiseRdAddr'range);
	signal bffrNoiseOut			: STD_LOGIC_VECTOR(2 * pixelIn'length - 1 downto 0);
	signal bffrNoiseRdy			: STD_LOGIC;
	signal bffrNoiseRowCnt		: unsigned(unsignedWidth(pictureHeight) - 1 downto 0);
	
	signal pixelIn_r1			: unsigned(pixelIn'range);
	signal pixelIn_r2			: unsigned(pixelIn'range);
	signal bffrNoiseRowCnt_r1	: unsigned(bffrNoiseRowCnt'range);
	signal bffrNoiseRowCnt_r2	: unsigned(bffrNoiseRowCnt'range);
		
	signal noiseFilterInput		: unsigned_matrix(1 to 3)(1 to 3)(pixelIn'range);
	signal noiseFilterInputRdy	: STD_LOGIC;
	signal noiseFilterOut		: unsigned(pixelIn'range);
	signal noiseFilterRdy		: STD_LOGIC;
	
	signal bffrEdgeRdAddr		: unsigned(unsignedWidth(pictureWidth - 2) - 1 downto 0);
	signal bffrEdgeRdAddr_r		: unsigned(bffrEdgeRdAddr'range);
	signal bffrEdgeWrAddr		: unsigned(bffrEdgeRdAddr'range);
	signal bffrEdgeOut			: STD_LOGIC_VECTOR(2 * noiseFilterOut'length - 1 downto 0);
	signal bffrEdgeRdy			: STD_LOGIC;
	
	signal bffrEdgeRowCnt		: unsigned(unsignedWidth(pictureHeight - 2) - 1 downto 0);
	signal bffrEdgeRowCnt_r1	: unsigned(bffrEdgeRowCnt'range);
	signal bffrEdgeRowCnt_r2	: unsigned(bffrEdgeRowCnt'range);
	signal noiseFilterOut_r1	: unsigned(noiseFilterOut'range);
	signal noiseFilterOut_r2	: unsigned(noiseFilterOut'range);
	
	signal edgeDetectorInput	: unsigned_matrix(1 to 3)(1 to 3)(noiseFilterOut'range);
	signal edgeDetectorInputRdy	: STD_LOGIC;
	signal edgeDetectorOut		: unsigned(threshold'range);
	signal edgeDetectorRdy		: STD_LOGIC;
	signal threshold_r			: unsigned(threshold'range);

begin
	process(clk)
	begin
		if rising_edge(clk) then
			if syncIn = '1' then
				bffrNoiseRdAddr	<= (others => '0');
				bffrNoiseRowCnt	<= (others => '0');
			else
				if inputRdy = '1' then
					bffrNoiseRdAddr <= bffrNoiseRdAddr + 1;
					if bffrNoiseRdAddr = pictureWidth - 1 then
						bffrNoiseRdAddr	<= (others => '0');
						bffrNoiseRowCnt	<= bffrNoiseRowCnt + 1;
						
						if bffrNoiseRowCnt = pictureHeight - 1 then
							bffrNoiseRowCnt	<= (others => '0');
						end if;
					end if;
				end if;
			end if;
			
			bffrNoiseRdAddr_r	<= bffrNoiseRdAddr;
			bffrNoiseWrAddr		<= bffrNoiseRdAddr_r;
			bffrNoiseRowCnt_r1	<= bffrNoiseRowCnt;
			bffrNoiseRowCnt_r2	<= bffrNoiseRowCnt_r1;
			pixelIn_r1			<= pixelIn;
			pixelIn_r2			<= pixelIn_r1;
		end if;
	end process;
	
	bffrNoise : RAM
		Generic map(
			wordLength  => 2 * pixelIn'length,
			cellNum     => pictureWidth
		)
		Port map( 
			clk       	=> clk,
						
			wrData      => STD_LOGIC_VECTOR(pixelIn_r2) & bffrNoiseOut(bffrNoiseOut'left downto pixelIn'length),
			wrAddress   => bffrNoiseWrAddr,
			wrEn        => bffrNoiseRdy,
						
			rdAddress   => bffrNoiseRdAddr,
			rdEn        => inputRdy,
						
			rdData      => bffrNoiseOut,
			rdDataRdy   => bffrNoiseRdy
		);
		
	process(clk)
	begin
		if rising_edge(clk) then
			if bffrNoiseWrAddr > 1 and bffrNoiseRowCnt_r2 > 1 then
				noiseFilterInputRdy <= bffrNoiseRdy;
			else
				noiseFilterInputRdy <= '0';
			end if;
			
			if bffrNoiseRdy = '1' then
				noiseFilterInput(1)	<=  noiseFilterInput(1)(2 to noiseFilterInput(1)'right) & unsigned(bffrNoiseOut(pixelIn'length - 1 downto 0));
				noiseFilterInput(2)	<=  noiseFilterInput(2)(2 to noiseFilterInput(2)'right) & unsigned(bffrNoiseOut(bffrNoiseOut'left downto pixelIn'length));
				noiseFilterInput(3)	<=  noiseFilterInput(3)(2 to noiseFilterInput(3)'right) & pixelIn_r2;
			end if;
		end if;
	end process;
	
	NoiseFilter : KernelConvolver 
		Generic map(
			coefWidth		=> coefWidth
		)
		Port map( 
			clk				=> clk,
			
			coef			=> coef,
			inverse_divisor	=> inverse_divisor,
			syncIn			=> syncIn,
			
			pixelIn			=> noiseFilterInput,
			inputRdy		=> noiseFilterInputRdy,
			pixelOut		=> noiseFilterOut,
			outputRdy		=> noiseFilterRdy
		);
		
	process(clk)
	begin
		if rising_edge(clk) then
			if syncIn = '1' then
				bffrEdgeRdAddr 	<= (others => '0');
				bffrEdgeRowCnt	<= (others => '0');
			else
				if noiseFilterRdy = '1' then
					bffrEdgeRdAddr <= bffrEdgeRdAddr + 1;
					if bffrEdgeRdAddr = pictureWidth - 3 then
						bffrEdgeRdAddr	<= (others => '0');	
						bffrEdgeRowCnt	<= bffrEdgeRowCnt + 1;
						
						if bffrEdgeRowCnt = pictureHeight - 3 then
							bffrEdgeRowCnt <= (others => '0');
						end if;
					end if;
				end if;
			end if;
			
			bffrEdgeRdAddr_r	<= bffrEdgeRdAddr;
			bffrEdgeWrAddr		<= bffrEdgeRdAddr_r;
			bffrEdgeRowCnt_r1	<= bffrEdgeRowCnt;
			bffrEdgeRowCnt_r2	<= bffrEdgeRowCnt_r1;
			noiseFilterOut_r1	<= noiseFilterOut;
			noiseFilterOut_r2	<= noiseFilterOut_r1;
		end if;
	end process;
	
	bffrEdge : RAM
		Generic map(
			wordLength  => 2 * noiseFilterOut'length,
			cellNum     => pictureWidth - 2
		)
		Port map( 
			clk       	=> clk,
						
			wrData      => STD_LOGIC_VECTOR(noiseFilterOut_r2) & bffrEdgeOut(bffrEdgeOut'left downto noiseFilterOut'length),
			wrAddress   => bffrEdgeWrAddr,
			wrEn        => bffrEdgeRdy,
						
			rdAddress   => bffrEdgeRdAddr,
			rdEn        => noiseFilterRdy,
						
			rdData      => bffrEdgeOut,
			rdDataRdy   => bffrEdgeRdy
		);
		
	process(clk)
	begin
		if rising_edge(clk) then
			if bffrEdgeWrAddr > 1 and bffrEdgeRowCnt_r2 > 1 then
				edgeDetectorInputRdy <= bffrEdgeRdy;
			else
				edgeDetectorInputRdy <= '0';
			end if;
			
			if bffrEdgeRdy = '1' then
				edgeDetectorInput(1)	<=  edgeDetectorInput(1)(2 to edgeDetectorInput(1)'right) & unsigned(bffrEdgeOut(noiseFilterOut'length - 1 downto 0));
				edgeDetectorInput(2)	<=  edgeDetectorInput(2)(2 to edgeDetectorInput(2)'right) & unsigned(bffrEdgeOut(bffrEdgeOut'left downto noiseFilterOut'length));
				edgeDetectorInput(3)	<=  edgeDetectorInput(3)(2 to edgeDetectorInput(3)'right) & noiseFilterOut_r2;
			end if;
		end if;
	end process;
	
	edgeDetector : SobelFilter
    Port map( 
		clk				=> clk,
		
		syncIn			=> syncIn,
		
		pixelIn			=> edgeDetectorInput,
		inputRdy		=> edgeDetectorInputRdy,
		
		pixelOut		=> edgeDetectorOut,
		outputRdy		=> edgeDetectorRdy
    );
	
	process(clk)
	begin
		if rising_edge(clk) then
			if syncIn = '1' then
				threshold_r <= threshold;
			end if;
			
			if edgeDetectorOut >= threshold_r then
				pixelOut <= '1';
			else
				pixelOut <= '0';
			end if;
			
			outputRdy <= edgeDetectorRdy;
		end if;
	end process;
end Behavioral;

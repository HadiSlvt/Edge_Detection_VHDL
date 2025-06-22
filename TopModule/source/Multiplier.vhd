library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity Multiplier is
    Port ( 
		clk			: in STD_LOGIC;
		
		A			: in signed(27 - 1 downto 0);
		B			: in signed(18 - 1 downto 0);
		C			: in signed(48 - 1 downto 0);
		inputRdy	: in STD_LOGIC;
		
		P			: out signed(48 - 1 downto 0);
		outputRdy	: out STD_LOGIC
    );
end Multiplier;


architecture Behavioral of multiplier is

	type signed_array is array (natural range <>) of signed;

	signal inputRdy_r	: STD_LOGIC_VECTOR(3 - 1 downto 0);
	signal C_r			: signed_array(1 to 2)(C'range);

begin	
	C_r <= C & C_r(1) when rising_edge(clk);

	DSP48E2_inst : DSP48E2
	generic map (
		AMULTSEL => "A",                    
		A_INPUT => "DIRECT",
		BMULTSEL => "B",                    
		B_INPUT => "DIRECT",               
		PREADDINSEL => "A",                
		RND => X"000000000000",            
		USE_MULT => "MULTIPLY",            
		USE_SIMD => "ONE48",               
		USE_WIDEXOR => "FALSE",            
		XORSIMD => "XOR24_48_96",          
		AUTORESET_PATDET => "NO_RESET",    
		AUTORESET_PRIORITY => "RESET",     
		MASK => X"3fffffffffff",           
		PATTERN => X"000000000000",        
		SEL_MASK => "MASK",                
		SEL_PATTERN => "PATTERN",          
		USE_PATTERN_DETECT => "NO_PATDET", 
		IS_ALUMODE_INVERTED => "0000",     
		IS_CARRYIN_INVERTED => '0',         
		IS_CLK_INVERTED => '0',             
		IS_INMODE_INVERTED => "00000",     
		IS_OPMODE_INVERTED => "000000000", 
		IS_RSTALLCARRYIN_INVERTED => '0',  
		IS_RSTALUMODE_INVERTED => '0',     
		IS_RSTA_INVERTED => '0',           
		IS_RSTB_INVERTED => '0',           
		IS_RSTCTRL_INVERTED => '0',        
		IS_RSTC_INVERTED => '0',           
		IS_RSTD_INVERTED => '0',           
		IS_RSTINMODE_INVERTED => '0',      
		IS_RSTM_INVERTED => '0',           
		IS_RSTP_INVERTED => '0',           
		ACASCREG => 2,     
		ADREG => 0,                        
		ALUMODEREG => 0,                   
		AREG => 2,                         
		BCASCREG => 2,      
		BREG => 2,                         
		CARRYINREG => 0,                   
		CARRYINSELREG => 0,                
		CREG => 1,                    
		DREG => 0,                         
		INMODEREG => 0,                    
		MREG => 1,                 
		OPMODEREG => 0,                    
		PREG => 1     
	)
	port map (
		ACOUT => open,
		BCOUT => open,
		CARRYCASCOUT => open,
		MULTSIGNOUT => open,
		PCOUT => open,
		OVERFLOW => open,
		PATTERNBDETECT => open,
		PATTERNDETECT => open,
		UNDERFLOW => open,
		CARRYOUT => open,
		signed(P) => P,
		XOROUT => open,
		ACIN => (others => '0'),
		BCIN => (others => '0'),
		CARRYCASCIN => '0',
		MULTSIGNIN => '0',
		PCIN => (others => '0'),
		ALUMODE => "0000",
		CARRYINSEL => "000",
		CLK => clk,
		INMODE => "00000",
		OPMODE => "000110101",  
		A => STD_LOGIC_VECTOR(resize(A, 30)),
		B => STD_LOGIC_VECTOR(B),
		C => STD_LOGIC_VECTOR(C_r(2)),
		CARRYIN => '0',
		D => (others => '0'),
		CEA1 => '1',
		CEA2 => '1',
		CEAD => '0',
		CEALUMODE => '0',
		CEB1 => '1',
		CEB2 => '1',
		CEC => '1',
		CECARRYIN => '0',
		CECTRL => '0',
		CED => '0',
		CEINMODE => '0',
		CEM => '1',
		CEP => '1',
		RSTA => '0',
		RSTALLCARRYIN => '0',
		RSTALUMODE => '0',
		RSTB => '0',
		RSTC => '0',
		RSTCTRL => '0',
		RSTD => '0',
		RSTINMODE => '0',
		RSTM => '0',
		RSTP => '0'
	);
	
	process(clk)
	begin
		if rising_edge(clk) then		
			inputRdy_r	<= inputRdy_r(inputRdy_r'left - 1 downto 0) & inputRdy;
			outputRdy	<= inputRdy_r(inputRdy_r'left);
		end if;
	end process;
end Behavioral;

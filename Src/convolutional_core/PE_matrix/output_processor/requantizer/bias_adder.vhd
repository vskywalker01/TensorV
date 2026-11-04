
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.adders.ALL;

entity bias_adder is
    Generic (
        -- dimension of the accumulations (from matrix core)
        DATA_SIZE: INTEGER := 20;       
        
        -- dimension of the bias (should be less or equal that the data_size)
        BIAS_SIZE: INTEGER := 8        
    );
    Port (
        -- control lines 
        clk: in STD_LOGIC; 
        reset: in STD_LOGIC; 
        enable: in STD_LOGIC; 
    
        -- data inputs 
        bias_in:    in STD_LOGIC_VECTOR(BIAS_SIZE-1 downto 0); 
        data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        
        -- outputs
        bias_valid_in:   in STD_LOGIC; 
        data_valid_in:   in STD_LOGIC;
        
        valid_out:  out STD_LOGIC;
        data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0)
        
    );
end bias_adder;

architecture Behavioral of bias_adder is
    signal bias: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    signal adder_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
begin
    -- using an Brent-kung adder 
    adder: bk_adder 
        generic map (
            DIM => DATA_SIZE
        )
        port map (             
            a => bias,
            b => data_in,
            c_in => '0',
            r => adder_out,
            c_out => open
        );

    -- if the bias size is lower than the accumulations, the sign of the bias is extended to match the output size
    bias_padding: if (DATA_SIZE > BIAS_SIZE) generate 
        bias(DATA_SIZE downto BIAS_SIZE) <= (others => bias_in(BIAS_SIZE-1))    when (bias_valid_in = '1') 
                                                                                else (others => '0');
    end generate; 
    
    -- The bias input is masked when there is not a valid bias.
    bias(BIAS_SIZE-1 downto 0) <= bias_in   when (bias_valid_in = '1') 
                                            else (others => '0');
    
    -- The output is valid only when the line is enabled and there is a valid data incoming 
    adder_process: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1') then 
                valid_out <= '0'; 
                data_out <= (others => '0');
            elsif (enable = '1' and data_valid_in = '1') then 
                valid_out <= '1'; 
                data_out <= adder_out;
            else 
                valid_out <= '0';
            end if; 
        end if; 
    end process; 
end Behavioral;

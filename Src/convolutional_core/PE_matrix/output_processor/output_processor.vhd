library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_matrix_parameters.ALL;

entity output_processor is
    Port (
        clk:            in STD_LOGIC; 
        reset:          in STD_LOGIC; 
        enable:         in STD_LOGIC; 
        
        bias_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
        data_in:    in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        shift_in:   in STD_LOGIC_VECTOR(REQUANTIZATION_SHIFT_BITS-1 downto 0);

        bias_valid_in:   in STD_LOGIC; 
        data_valid_in:   in STD_LOGIC;
                    
        data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
        valid_out:  out STD_LOGIC
        
    );
end output_processor;

architecture Behavioral of output_processor is
    component bias_adder is
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
    end component;

    component requantizer is
        Generic (
            DATA_SIZE:          INTEGER := 20; 
            OUTPUT_SIZE:        INTEGER := 8;
            SHIFT_VALUE_BITS:   INTEGER := 5
        );
        Port ( 
            clk:        in STD_LOGIC; 
            reset:      in STD_LOGIC; 
        
            data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            shift:      in STD_LOGIC_VECTOR(SHIFT_VALUE_BITS-1 downto 0);
            valid_in:   in STD_LOGIC;  
            
            data_out:   out STD_LOGIC_VECTOR(OUTPUT_SIZE-1 downto 0); 
            valid_out:  out STD_LOGIC
            
        );
    end component;
    
    signal accumulation_out: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal valid: STD_LOGIC;
    
begin
    bias_adder_stage: bias_adder 
        generic map (
            DATA_SIZE => ACCUMULATOR_SIZE, 
            BIAS_SIZE => DATA_SIZE
            
        )
        port map (
            clk => clk, 
            reset => reset, 
            enable => enable, 
            
            bias_in => bias_in, 
            data_in => data_in,
    
            bias_valid_in => bias_valid_in,
            data_valid_in => data_valid_in,
            
            valid_out => valid, 
            data_out => accumulation_out
        );
    requantizer_stage: requantizer 
        generic map (
            DATA_SIZE => ACCUMULATOR_SIZE, 
            OUTPUT_SIZE => DATA_SIZE,
            SHIFT_VALUE_BITS => REQUANTIZATION_SHIFT_BITS 
        )
        port map(
            clk => clk, 
            reset => reset, 

            data_in => accumulation_out, 
            valid_in => valid, 
            shift => shift_in,
            
            data_out => data_out, 
            valid_out => valid_out
        );

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.REGISTERS.ALL; 
use work.PE_MATRIX_PARAMETERS.ALL;

entity PE_stage1 is
    Port (
        clk:                        in STD_LOGIC;  
        reset:                      in STD_LOGIC;                 
        
        control_in:                 in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
        weight_in:                  in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
        activation_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
        accumulator_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        
        control_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
        weight_forward_out:         out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
        activation_forward_out:     out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
        accumulator_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        weight_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        weight_empty_out:           out STD_LOGIC;
        activation_empty_out:       out STD_LOGIC
        
    );
end PE_stage1;

architecture Behavioral of PE_stage1 is
    signal shift_weight, shift_activation, empty_weight, empty_activation:      STD_LOGIC;     
    
begin
    weight_queue: circular_queue 
        generic map ( 
            DATA_SIZE => DATA_SIZE, 
            REGISTERS => QUEUE_SIZE
        ) 
        port map (
            clk => clk, 
            reset => reset, 
            init => control_in(WEIGHT_INIT_BIT), 
            shift => shift_weight, 
            add => control_in(WEIGHT_VALID_BIT), 
            empty_out => weight_empty_out,
            data_in => weight_in, 
            data_out => weight_out
        );
    activation_queue: circular_queue 
        generic map ( 
            DATA_SIZE => DATA_SIZE, 
            REGISTERS => QUEUE_SIZE
        ) 
        port map (
            clk => clk, 
            reset => reset, 
            init => control_in(ACTIVATION_INIT_BIT), 
            shift => shift_activation, 
            add => control_in(ACTIVATION_VALID_BIT), 
            empty_out => activation_empty_out,
            data_in => activation_in, 
            data_out => activation_out
        );
    
    
    shift_activation <= control_in(ENABLE_BIT);
    shift_weight <= control_in(ENABLE_BIT) and not(control_in(ACCUMULATOR_VALID_BIT));
    

    stage1: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1') then 
                weight_forward_out <= (others => '0');
                activation_forward_out <= (others => '0');
                accumulator_out <= (others => '0');
                control_out <= (others => '0');
                
            else 
                weight_forward_out <= weight_in;
                activation_forward_out <= activation_in;
                accumulator_out <= accumulator_in;
                control_out <= control_in;
                
            end if;
        end if; 
    end process;

end Behavioral;

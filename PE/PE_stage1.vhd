library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.REGISTERS.ALL; 

entity PE_stage1 is
    Generic (
        DATA_SIZE: INTEGER := 8; 
        ACCUMULATOR_SIZE: INTEGER := 20; 
        QUEUE_SIZE: INTEGER := 8;
        ACTIVATION_INIT_BIT: INTEGER := 6; 
        WEIGHT_INIT_BIT: INTEGER := 5;
        ACCUMULATOR_INIT_BIT: INTEGER := 4;
        ACTIVATION_VALID_BIT: INTEGER := 3; 
        WEIGHT_VALID_BIT:   INTEGER := 2; 
        PROCESS_ELEMENT_BIT: INTEGER := 1; 
        PROCESS_ACCUMULATOR_BIT: INTEGER := 0
    );
    Port ( 
        clk:                        in STD_LOGIC;  
        reset:                      in STD_LOGIC;                 
        
        control_in:                 in STD_LOGIC_VECTOR(6 downto 0); 
        weight_in:                  in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
        activation_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
        accumulator_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        
        control_out:                out STD_LOGIC_VECTOR(6 downto 0);
        weight_forward_out:         out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
        activation_forward_out:     out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
        accumulator_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        weight_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0)
        
    );
end PE_stage1;

architecture Behavioral of PE_stage1 is
    signal shift_weight, shift_activation:      STD_LOGIC;     
    
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
            data_in => activation_in, 
            data_out => activation_out
        );
    
    shift_activation <= control_in(PROCESS_ACCUMULATOR_BIT) or control_in(PROCESS_ELEMENT_BIT);
    shift_weight <= control_in(PROCESS_ELEMENT_BIT);

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

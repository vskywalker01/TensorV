library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.REGISTERS.ALL; 
use work.PE_MATRIX_PARAMETERS.ALL;
use IEEE.NUMERIC_STD.all;

entity PE_stage1 is
    Port (
        clk:                        in STD_LOGIC;  
        reset:                      in STD_LOGIC;                 
        
        -- matrix forward lines
        
        control_forward_in:                 in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
        weight_forward_in:                  in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
        activation_forward_in:              in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_forward_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
       
        
        control_forward_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
        weight_forward_out:                 out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
        activation_forward_out:             out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
        accumulator_forward_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        -- Internal connections (From stage 1 to stage 2)
        
        accumulator_loopback_in:            in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        accumulator_loopback_valid_in:      in STD_LOGIC;
       
        -- Queue I/Os
        
        weight_queue_out:                   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_queue_out:               out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_queue_out:              out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        -- Queue Control signals 
        weight_empty_out:                   out STD_LOGIC;
        activation_empty_out:               out STD_LOGIC;
        row_done_out:                       out STD_LOGIC;
        accumulator_empty_out:              out STD_LOGIC
        
    );
end PE_stage1;

architecture Behavioral of PE_stage1 is
    signal shift_weight_queue, move_activation_queue, pop_accumulator_queue, row_done: STD_LOGIC;  
    
    signal weight_counter: UNSIGNED(QUEUE_COUNTERS_SIZE-1 downto 0); 
    signal row_size: UNSIGNED(QUEUE_COUNTERS_SIZE-1 downto 0);
    
begin

    weight_queue: circular_queue 
        generic map ( 
            DATA_SIZE => DATA_SIZE, 
            REGISTERS => QUEUE_SIZE,
            COUNTER_SIZE => QUEUE_COUNTERS_SIZE
        ) 
        port map (
            clk => clk, 
            reset => reset, 
            init => control_forward_in(WEIGHT_INIT_BIT), 
            shift => shift_weight_queue, 
            add => control_forward_in(WEIGHT_VALID_BIT), 
            empty_out => weight_empty_out,
            data_in => weight_forward_in, 
            data_out => weight_queue_out
        );
    activation_queue: convolutional_queue 
        generic map ( 
            DATA_SIZE => DATA_SIZE, 
            REGISTERS => QUEUE_SIZE,
            COUNTER_SIZE => QUEUE_COUNTERS_SIZE
        ) 
        port map (
            clk => clk, 
            reset => reset, 
            init => control_forward_in(ACTIVATION_INIT_BIT), 
            move => move_activation_queue, 
            add => control_forward_in(ACTIVATION_VALID_BIT), 
            empty_out => activation_empty_out,
            data_in => activation_forward_in, 
            data_out => activation_queue_out,
            done_out => row_done,
            size_in => control_forward_in(ACTIVATION_SIZE_MS_BIT downto ACTIVATION_SIZE_LS_BIT), 
            skip_in => control_forward_in(ACTIVATION_SKIP_MS_BIT downto ACTIVATION_SKIP_LS_BIT)
        );
    accumulations_queue: queue 
        generic map ( 
            DATA_SIZE => ACCUMULATOR_SIZE, 
            REGISTERS => QUEUE_SIZE,
            COUNTER_SIZE => QUEUE_COUNTERS_SIZE
        ) 
        port map (
            clk => clk, 
            reset => reset, 
            init => control_forward_in(ACCUMULATOR_INIT_BIT),
            pop => pop_accumulator_queue, 
            push => accumulator_loopback_valid_in,
            empty_out => accumulator_empty_out,
            data_in => accumulator_loopback_in, 
            data_out => accumulator_queue_out
        );
    
    -- The activation queue moves data when ENABLE = 1 and PROCESS_TYPE = 0
    move_activation_queue <= control_forward_in(ENABLE_BIT) and not(control_forward_in(PROCESS_TYPE_BIT));
    
    -- The weight queue moves data when ENABLE = 1, PROCESS_TYPE = 0 and row_done = 0 (the activation queue has not reaced the end of the row yet)
    shift_weight_queue <= '1' when control_forward_in(ENABLE_BIT)= '1' 
                                and control_forward_in(PROCESS_TYPE_BIT) = '0' 
                                and not (weight_counter = 0) else
                          '0';
        
    
    -- The accumulation queue pops data when ENABLE = 1 and PROCESS_TYPE = 1  
    pop_accumulator_queue <= control_forward_in(ENABLE_BIT) and control_forward_in(PROCESS_TYPE_BIT);
    row_done_out <= row_done;

    
    -- Pipeline registers process
    stage1: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1') then 
                weight_forward_out <= (others => '0');
                activation_forward_out <= (others => '0');
                accumulator_queue_out <= (others => '0');
                control_forward_out <= (others => '0');
                weight_counter <= (others => '0');
                row_size <= (others => '0');
            else 
                if (control_forward_in(ACTIVATION_INIT_BIT) = '1') then 
                    row_size <= UNSIGNED(control_forward_in(ACTIVATION_SIZE_MS_BIT downto ACTIVATION_SIZE_LS_BIT));
                    weight_counter <= UNSIGNED(control_forward_in(ACTIVATION_SIZE_MS_BIT downto ACTIVATION_SIZE_LS_BIT));
                elsif (control_forward_in(ENABLE_BIT)= '1' and control_forward_in(PROCESS_TYPE_BIT) = '0' and weight_counter > 0) then 
                    weight_counter <= weight_counter -1;
                elsif (weight_counter = 0) then
                    weight_counter <= row_size; 
                end if; 
                
                
                
                weight_forward_out <= weight_forward_in;
                activation_forward_out <= activation_forward_in;
                accumulator_forward_out <= accumulator_forward_in;
                control_forward_out <= control_forward_in;
            end if;
        end if; 
    end process;

end Behavioral;

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
        status_forward_in:                  in STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
        
        weight_forward_in:                  in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
        activation_forward_in:              in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_forward_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
       
        
        control_forward_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
        status_forward_out:                 out STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
        weight_forward_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
        activation_forward_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_forward_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        -- Internal connections (From stage 1 to stage 2)
        
        accumulator_loopback_in:            in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        accumulator_loopback_valid_in:      in STD_LOGIC;
       
        -- Queue I/Os
        
        weight_queue_out:                   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_queue_out:               out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_queue_out:              out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        -- Queue Control signals 
        queue_empty_out:                    out STD_LOGIC;
        row_done_out:                       out STD_LOGIC;
        accumulator_empty_out:              out STD_LOGIC
        
    );
end PE_stage1;

architecture Behavioral of PE_stage1 is
    signal move_data_queue, pop_accumulator_queue, row_done: STD_LOGIC;  
    signal data_queue_empty: STD_LOGIC;
begin

    data_queue: convolutional_queue 
        generic map ( 
            DATA_SIZE => DATA_SIZE, 
            REGISTERS => QUEUE_SIZE,
            COUNTER_SIZE => QUEUE_COUNTERS_SIZE
        ) 
        port map (
            clk => clk, 
            reset => reset, 
            init => control_forward_in(WEIGHT_INIT_BIT), 
            move => move_data_queue, 
            add_weight => control_forward_in(WEIGHT_VALID_BIT), 
            add_activation => control_forward_in(ACTIVATION_VALID_BIT),
            empty_out => queue_empty_out,
            weight_in => weight_forward_in, 
            weight_out => weight_queue_out,
            activation_in => activation_forward_in,
            activation_out => activation_queue_out,
            done_out => row_done, 
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
    
    -- The data queue moves data when ENABLE = 1, PROCESS_TYPE = 0 and there is not an incoming value from the past PE's accumulator lines
    move_data_queue <= control_forward_in(ENABLE_BIT) and not(control_forward_in(PROCESS_TYPE_BIT));
        
    
    -- The accumulation queue pops data when ENABLE = 1 and PROCESS_TYPE = 1 and there is a valid value from the past PE's accumulator lines
    pop_accumulator_queue <= control_forward_in(ENABLE_BIT) and control_forward_in(PROCESS_TYPE_BIT) and status_forward_in(ACCUMULATOR_VALID_BIT);
    row_done_out <= row_done;

    
    -- Pipeline registers process
    stage1: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1') then 
                weight_forward_out <= (others => '0');
                activation_forward_out <= (others => '0');
                accumulator_forward_out <= (others => '0');
                control_forward_out <= (others => '0');
            else 

                weight_forward_out <= weight_forward_in;
                activation_forward_out <= activation_forward_in;
                accumulator_forward_out <= accumulator_forward_in;
                control_forward_out <= control_forward_in;
                status_forward_out <= status_forward_in;
            end if;
        end if; 
    end process;

end Behavioral;

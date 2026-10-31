library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.REGISTERS.ALL; 
use work.PE_MATRIX_PARAMETERS.ALL;
use IEEE.NUMERIC_STD.all;

entity PE_stage1 is
    Port (
        clk:                        in STD_LOGIC;  
        reset:                      in STD_LOGIC;                 
        enable:                     in STD_LOGIC;       
        forward_enable:             in STD_LOGIC;     
        
        -- matrix forward lines
       
        control_forward_in:                 in PE_CONTROL_INTERFACE; 
        status_forward_in:                  in PE_STATUS_INTERFACE;
        
        weight_forward_in:                  in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
        activation_forward_in:              in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_forward_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
       
        
        control_forward_out:                out PE_CONTROL_INTERFACE;
        status_forward_out:                 out PE_STATUS_INTERFACE;
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
    signal process_counter: UNSIGNED(CONV_SHIFTS_BITS-1 downto 0);
    signal process_type:    STD_LOGIC;
begin

    data_queue: convolutional_queue 
        generic map ( 
            DATA_SIZE => DATA_SIZE, 
            WEIGHT_QUEUE_SIZE_BITS => WEIGHT_MATRIX_SIZE_BITS,
            ACTIVATION_QUEUE_SIZE_BITS => ACTIVATION_MATRIX_SIZE_BITS,
            CONV_SKIP_BITS => CONV_SKIP_BITS
        ) 
        port map (
            clk => clk, 
            reset => reset, 
            init_weight => control_forward_in(PE_WEIGHT_INIT), 
            init_activation => control_forward_in(PE_ACTIVATION_INIT),  
            move => move_data_queue, 
            add_weight => control_forward_in(PE_WEIGHT_VALID), 
            add_activation => control_forward_in(PE_ACTIVATION_VALID),
            empty_out => queue_empty_out,
            weight_in => weight_forward_in, 
            weight_out => weight_queue_out,
            activation_in => activation_forward_in,
            activation_out => activation_queue_out,
            done_out => row_done, 
            skip_in => control_forward_in(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB)
        );
    accumulations_queue: queue 
        generic map ( 
            DATA_SIZE => ACCUMULATOR_SIZE, 
            COUNTER_BITS => CONV_SHIFTS_BITS
        ) 
        port map (
            clk => clk, 
            reset => reset, 
            init => control_forward_in(PE_ACCUMULATOR_INIT),
            pop => pop_accumulator_queue, 
            push => accumulator_loopback_valid_in,
            empty_out => accumulator_empty_out,
            data_in => accumulator_loopback_in, 
            data_out => accumulator_queue_out
        );
    
    -- The data queue moves data when the PE is enabled (enable = '1'), there is a process going on (process_counter > 0), is processing a row (process_type = '0') 
    move_data_queue <= '1' when (enable = '1' and 
                                 process_counter > 0 and 
                                 process_type <= '0') 
                           else '0';
        
    -- The accumulation queue pops data when the PE is enabled (enable = '1') there is a process going on (process_counter > 0 and process_type = '1') and the 
    -- past PE sends a valid output (PE_OUTPUT_VALID = '1')
    pop_accumulator_queue <= '1' when (enable='1' and  
                                       process_type <= '1' and 
                                       status_forward_in(PE_OUTPUT_VALID) = '1') 
                                 else '0';
                                 
    -- propagation of the row_done signal to the next stage
    row_done_out <= row_done;

    
    -- PE process execution section 
    stage1: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1' or enable = '0') then 
                accumulator_forward_out <= (others => '0');
                control_forward_out <= (others => '0');
                process_counter <= (others => '0');
                
                -- if the PE is not active, the output status will consider always a valid output value (for the next accumulations)
                status_forward_out(PE_ACTIVE) <= '0';
                status_forward_out(PE_OUTPUT_VALID) <= '1';
                status_forward_out(PE_READY) <= '1';
                status_forward_out(PE_STATUS) <= '0';
                process_type <= '0';
                
            elsif (enable = '1') then
            
                -- If the PE receives a PROCESS_START signal, it sets the process_counter to the new value.
                -- If PE_PROCESS_TYPE = '0' -> the PE computes the convoluzion between the elements contained in the data_queue and saves the results from the 
                --                              stage 3 into the accumulation_queue
                -- If PE_PROCESS_TYPE = '1' -> the PE waits for a result from the past PE and sends a value from the accumulation queue to the next stage
                if (control_forward_in(PE_PROCESS_START)= '1') then 
                    process_counter <= UNSIGNED(control_forward_in(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB));
                    process_type <= control_forward_in(PE_PROCESS_TYPE);
                
                -- The process_counter is decremented always when a row is processed (process_type = '0') or a valid output is recieved (process_type = '1')
                elsif (process_counter > 0 and ((row_done = '1' and process_type = '0') or (status_forward_in(PE_OUTPUT_VALID) = '1' and process_type = '1'))) then 
                    process_counter <= process_counter -1;
                end if;
                
                -- If the counter reaches 0, the PE has terminated its execution
                if (process_counter = 0) then 
                    status_forward_out(PE_READY) <= '1';
                else 
                    status_forward_out(PE_READY) <= '0';
                end if;
                
                -- Propagation of the signals to the next stages
                status_forward_out(PE_STATUS) <= process_type;
                accumulator_forward_out <= accumulator_forward_in;
                control_forward_out <= control_forward_in;
                status_forward_out(PE_OUTPUT_VALID) <= status_forward_in(PE_OUTPUT_VALID);
                status_forward_out(PE_ACTIVE) <= '1';
                
            end if;
        end if; 
    end process;
    
    -- PE data forward section 
    stage1_forward: process(clk) is 
    begin 
        if (reset = '1') then 
            weight_forward_out <= (others => '0');
            activation_forward_out <= (others => '0');
            
        elsif (forward_enable = '1') then 
            weight_forward_out <= weight_forward_in;
            activation_forward_out <= activation_forward_in;
        end if; 
    end process; 

end Behavioral;

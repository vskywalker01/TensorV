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
        row_done_out:                       out STD_LOGIC
        
    );
end PE_stage1;

architecture Behavioral of PE_stage1 is
--    signal move_data_queue, pop_accumulator_queue, row_done: STD_LOGIC;  
--    signal data_queue_empty, accumulations_queue_empty: STD_LOGIC;
        
    constant WEIGHT_QUEUE_SIZE_BITS:         INTEGER := WEIGHT_MATRIX_SIZE_BITS;
    constant ACTIVATION_QUEUE_SIZE_BITS:     INTEGER := ACTIVATION_MATRIX_SIZE_BITS;
    constant OUTPUT_QUEUE_SIZE_BITS:         INTEGER := WEIGHT_MATRIX_SIZE_BITS;
    
    constant WEIGHT_REGISTERS:          INTEGER := 2 ** WEIGHT_QUEUE_SIZE_BITS; 
    constant ACTIVATION_REGISTERS:      INTEGER := 2 ** ACTIVATION_QUEUE_SIZE_BITS;
    constant OUTPUT_REGISTERS:          INTEGER := 2 ** OUTPUT_QUEUE_SIZE_BITS;
    
    type WEIGHT_REGISTER                is array (WEIGHT_REGISTERS-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type ACTIVATION_REGISTER            is array (ACTIVATION_REGISTERS-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type OUTPUT_REGISTER                is array (OUTPUT_REGISTERS-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    
    signal weight_register_file:        WEIGHT_REGISTER; 
    signal activation_register_file:    ACTIVATION_REGISTER; 
    signal output_register_file:        OUTPUT_REGISTER; 
    
    -- Queue registers 
    signal current_activation_head, activation_head, activation_tail:   UNSIGNED(ACTIVATION_QUEUE_SIZE_BITS downto 0);
    signal current_weight_head, current_weight_tail, weight_tail:       UNSIGNED(WEIGHT_QUEUE_SIZE_BITS downto 0); 
    signal output_head, output_tail:                                    UNSIGNED(OUTPUT_QUEUE_SIZE_BITS downto 0);
    signal current_skip, skip:                                          UNSIGNED(CONV_SKIP_BITS-1 downto 0);
    
    -- Queue status flags
    signal activation_empty, activation_full, activation_waiting:       STD_LOGIC; 
    signal weight_full, weight_empty:                                   STD_LOGIC; 
    signal output_full, output_empty:                                   STD_LOGIC; 

    -- Control registers
    signal process_counter:         UNSIGNED(CONV_SHIFTS_BITS-1 downto 0); 
    signal process_type:            STD_LOGIC; 

begin   
    weight_full <= '1'  when (weight_tail(WEIGHT_QUEUE_SIZE_BITS) = '1')
                        else '0'; 
                        
    weight_empty <= '1' when (weight_tail = 0) 
                        else '0'; 

    activation_full <= '1'  when (activation_head(ACTIVATION_QUEUE_SIZE_BITS-1 downto 0) = activation_tail(ACTIVATION_QUEUE_SIZE_BITS-1 downto 0) and 
                                not(activation_head(ACTIVATION_QUEUE_SIZE_BITS) = activation_tail(ACTIVATION_QUEUE_SIZE_BITS))) 
                            else '0';
                           
    activation_empty <= '1'     when (activation_head(ACTIVATION_QUEUE_SIZE_BITS-1 downto 0) = activation_tail(ACTIVATION_QUEUE_SIZE_BITS-1 downto 0) and 
                                    activation_head(ACTIVATION_QUEUE_SIZE_BITS) = activation_tail(ACTIVATION_QUEUE_SIZE_BITS)) 
                                else '0';
                                
    activation_waiting <= '1'   when (current_activation_head(ACTIVATION_QUEUE_SIZE_BITS-1 downto 0) = activation_tail(ACTIVATION_QUEUE_SIZE_BITS-1 downto 0) and 
                                    current_activation_head(ACTIVATION_QUEUE_SIZE_BITS) = activation_tail(ACTIVATION_QUEUE_SIZE_BITS)) 
                                else '0';
                                
    output_full <= '1'  when (output_head(OUTPUT_QUEUE_SIZE_BITS-1 downto 0) = output_tail(OUTPUT_QUEUE_SIZE_BITS-1 downto 0) and 
                            not(output_head(OUTPUT_QUEUE_SIZE_BITS) = output_tail(OUTPUT_QUEUE_SIZE_BITS))) 
                        else '0';
                        
    output_empty <= '1'     when (output_head(OUTPUT_QUEUE_SIZE_BITS-1 downto 0) = output_tail(OUTPUT_QUEUE_SIZE_BITS-1 downto 0) and 
                                output_head(OUTPUT_QUEUE_SIZE_BITS) = output_tail(OUTPUT_QUEUE_SIZE_BITS))
                            else '0';
    
    stage1_convolutional_control_unit: process(clk) is   
    begin   
        if (rising_edge(clk)) then 
            
            -- if PE_INIT = '1', all the internal registers are initialized 
            if (reset = '1' or (enable = '1' and control_forward_in(PE_INIT) = '1')) then 

                current_activation_head <= (others => '0');
                activation_head <= (others => '0');
                activation_tail <= (others => '0');
                
                current_weight_head <= (others => '0');
                current_weight_tail <= (others => '0');
                weight_tail <= (others => '0');
                
                current_skip <= (others => '0');
                skip <= (others => '0');
                process_counter <= (others => '0');
                process_type <= '0';
                
                output_tail <= (others => '0');
                output_head <= (others => '0');

            
            -- if PE_ACTIVATION_CLEAR = '1' only the activation queue is initialized
            elsif (enable = '1' and control_forward_in(PE_ACTIVATIONS_CLEAR)='1') then 
                current_activation_head <= (others => '0');
                activation_head <= (others => '0');
                activation_tail <= (others => '0');
                
            elsif (enable = '1') then
            
                -- if there is an output coming from the stage 3 and the output queue is not full,the new element is inserted in the register file.
                if (accumulator_loopback_valid_in = '1' and output_full <= '0') then 
                    output_tail <= output_tail +1; 
                    output_register_file(to_integer(output_tail(OUTPUT_QUEUE_SIZE_BITS - 1 downto 0))) <= accumulator_loopback_in;
                end if; 
            
                -- if there is a weight coming from the input lines (PE_WEIGHT_VALID = '1') and the queue is not full, the element is inserted into the regster file.
                if (control_forward_in(PE_WEIGHT_VALID) = '1' and weight_full = '0') then 
                    weight_tail <= weight_tail +1;
                    weight_register_file(to_integer(weight_tail(WEIGHT_QUEUE_SIZE_BITS-1 downto 0))) <= weight_forward_in; 
                end if; 
                
                -- if there is an activation coming from the input lines (PE_ACTIVATION_VALID = '1') and the queue is not full, the element is inserted in the register file 
                if (control_forward_in(PE_ACTIVATION_VALID) = '1' and activation_full = '0') then 
                    activation_tail <= activation_tail +1;
                    activation_register_file(to_integer(activation_tail(ACTIVATION_QUEUE_SIZE_BITS - 1 downto 0))) <= activation_forward_in;
                end if; 
                
                
                -- If the command lines signals the PE to start a new process, the process counter and the process type flag are updated
                if (control_forward_in(PE_PROCESS_START) = '1') then 
                    process_counter <= UNSIGNED(control_forward_in(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB));
                    process_type <= control_forward_in(PE_PROCESS_TYPE);
                    
                    -- The PE prepares the current queue registers for the convolutions
                    if (control_forward_in(PE_PROCESS_TYPE) = '0') then 
                        current_weight_tail <= weight_tail; 
                        current_activation_head <= activation_head; 
                        current_skip <= UNSIGNED(control_forward_in(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB));
                        skip <= UNSIGNED(control_forward_in(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB));
                    end if;
                    
                
                -- If the funtional unit has something to do (process counter > 0), the PE proceeds to compute another operations    
                elsif (process_counter > 0) then 
                
                    -- If the process type = 0, the PE should process a convolution between the elements stored in the weight and activation queues. 
                    if (process_type = '0') then 
                        
                        -- If the current_skip > 0 and current_weight_head > 0, the PE is in the convolutional phase with dropout: 
                        -- the PE reads one element from the weight queue and one element from the activation queue
                        -- the element obtained from the activation queue is also discarded because the striding (not required for the next kernel shift) 
                       
                        if (current_skip > 0 and current_weight_head < current_weight_tail and activation_waiting = '0') then 
                            activation_queue_out <= activation_register_file(to_integer(current_activation_head(ACTIVATION_QUEUE_SIZE_BITS - 1 downto 0))); 
                            weight_queue_out <= weight_register_file(to_integer(current_weight_head(WEIGHT_QUEUE_SIZE_BITS-1 downto 0)));
                            
                            current_activation_head <= current_activation_head + 1; 
                            activation_head <= activation_head + 1;
                            current_weight_head <= current_weight_head + 1;
                            current_skip <= current_skip - 1;
                        
                        -- If the current_skip > 0 and current_weight_head > 0, the PE is in the convolutional phase: 
                        -- the PE reads one element from the weight queue and one element from the activation queue
                        
                        elsif (current_skip = 0 and current_weight_head < current_weight_tail and activation_waiting = '0') then 
                            activation_queue_out <= activation_register_file(to_integer(current_activation_head(ACTIVATION_QUEUE_SIZE_BITS - 1 downto 0))); 
                            weight_queue_out <= weight_register_file(to_integer(current_weight_head(WEIGHT_QUEUE_SIZE_BITS-1 downto 0)));
                            current_activation_head <= current_activation_head + 1; 
                            current_weight_head <= current_weight_head + 1;
                        
                        -- if the current_skip = 0 and the current_weight_head = 0, the PE has filtered one part of the activation
                        -- The current process counter is decremented, the current_state registers are resetted in order to prepare for the next shift. 
                        elsif (current_weight_head = current_weight_tail) then 
                            process_counter <= process_counter - 1; 
                            current_activation_head <= activation_head; 
                            current_weight_head <= (others => '0');
                            current_skip <= skip; 
                            process_counter <= process_counter - 1;
                        end if; 
                     
                    -- if process_type = '1', the PE should remove one element from the output queue and send it to the next stage.
                    elsif (status_forward_in(PE_OUTPUT_VALID) = '1' and output_empty = '0') then 
                        process_counter <= process_counter-1; 
                        accumulator_queue_out <= output_register_file(to_integer(output_head(OUTPUT_QUEUE_SIZE_BITS - 1 downto 0))); 
                        output_head <= output_head + 1;  
                    end if; 
                end if; 
                
                -- If the counter reaches 0, the PE has terminated its execution
                if (process_counter = 0) then 
                    status_forward_out(PE_READY) <= '1';
                else 
                    status_forward_out(PE_READY) <= '0';
                end if;
                
                -- If there is a running process and the output queue or the activation queue is empty, the process is halted for missing data
                if (process_counter > 0 and ((process_type = '1' and output_empty = '1') or (process_type = '0' and activation_waiting = '1' and not(current_weight_head = current_weight_tail)))) then
                    status_forward_out(PE_STATUS_WAITING) <= '1';
                else 
                    status_forward_out(PE_STATUS_WAITING) <= '0'; 
                end if;
                
                -- At tach termination of a row, the 
                if (process_counter > 0 and process_type = '0' and current_weight_head = current_weight_tail) then 
                    row_done_out <= '1'; 
                else 
                    row_done_out <= '0';
                end if; 
                
                -- Propagation of the signals to the next stages

                accumulator_forward_out <= accumulator_forward_in;
                control_forward_out <= control_forward_in;
                

                status_forward_out(PE_STATUS_TYPE) <= process_type; 
                status_forward_out(PE_OUTPUT_VALID) <= status_forward_in(PE_OUTPUT_VALID);
                status_forward_out(PE_ACTIVE) <= '1';
               
            end if;              
        end if; 
    end process;
    
        


--    data_queue: convolutional_queue 
--        generic map ( 
--            DATA_SIZE => DATA_SIZE, 
--            WEIGHT_QUEUE_SIZE_BITS => WEIGHT_MATRIX_SIZE_BITS,
--            ACTIVATION_QUEUE_SIZE_BITS => ACTIVATION_MATRIX_SIZE_BITS,
--            CONV_SKIP_BITS => CONV_SKIP_BITS
--        ) 
--        port map (
--            clk => clk, 
--            reset => reset, 
--            init => control_forward_in(PE_WEIGHTS_INIT), 
--            restart => control_forward_in(PE_PROCESS_START),  
--            move => move_data_queue, 
--            add_weight => control_forward_in(PE_WEIGHT_VALID), 
--            add_activation => control_forward_in(PE_ACTIVATION_VALID),
--            empty_out => data_queue_empty,
--            weight_in => weight_forward_in, 
--            weight_out => weight_queue_out,
--            activation_in => activation_forward_in,
--            activation_out => activation_queue_out,
--            done_out => row_done, 
--            skip_in => control_forward_in(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB)
--        );
--    accumulations_queue: queue 
--        generic map ( 
--            DATA_SIZE => ACCUMULATOR_SIZE, 
--            COUNTER_BITS => CONV_SHIFTS_BITS
--        ) 
--        port map (
--            clk => clk, 
--            reset => reset, 
--            init => control_forward_in(PE_OUTPUTS_INIT),
--            pop => pop_accumulator_queue, 
--            push => accumulator_loopback_valid_in,
--            empty_out => accumulations_queue_empty,
--            data_in => accumulator_loopback_in, 
--            data_out => accumulator_queue_out
--        );
    
--    -- The data queue moves data when the PE is enabled (enable = '1'), there is a process going on (process_counter > 0), is processing a row (process_type = '0') 
--    move_data_queue <= '1' when (enable = '1' and 
--                                 process_counter > 0 and 
--                                 process_type = '0') 
--                           else '0';
        
--    -- The accumulation queue pops data when the PE is enabled (enable = '1') there is a process going on (process_counter > 0 and process_type = '1') and the 
--    -- past PE sends a valid output (PE_OUTPUT_VALID = '1')
--    pop_accumulator_queue <= '1' when (enable='1' and  
--                                       process_counter > 0 and
--                                       process_type = '1' and 
--                                       status_forward_in(PE_OUTPUT_VALID) = '1') 
--                                 else '0';
                                 
--    -- propagation of the signals to the next stage
--    row_done_out <= row_done;
--    accumulator_empty_out <= accumulations_queue_empty;
--    queue_empty_out <= data_queue_empty;
    
--    -- PE process execution section 
--    stage1: process(clk) is 
--    begin 
--        if (rising_edge(clk)) then 
--            if (reset = '1' or enable = '0') then 
--                accumulator_forward_out <= (others => '0');
--                control_forward_out <= (others => '0');
--                process_counter <= (others => '0');
                
--                -- if the PE is not active, the output status will consider always a valid output value (for the next accumulations)
--                status_forward_out(PE_ACTIVE) <= '0';
--                status_forward_out(PE_OUTPUT_VALID) <= '1';
--                status_forward_out(PE_READY) <= '1';
--                status_forward_out(PE_STATUS_TYPE) <= '0';
--                status_forward_out(PE_STATUS_WAITING) <= '0';
--                process_type <= '0';
                
--            elsif (enable = '1') then
            
--                -- If the PE receives a PROCESS_START signal, it sets the process_counter to the new value.
--                -- If PE_PROCESS_TYPE = '0' -> the PE computes the convoluzion between the elements contained in the data_queue and saves the results from the 
--                --                              stage 3 into the accumulation_queue
--                -- If PE_PROCESS_TYPE = '1' -> the PE waits for a result from the past PE and sends a value from the accumulation queue to the next stage
--                if (control_forward_in(PE_PROCESS_START)= '1') then 
--                    process_counter <= UNSIGNED(control_forward_in(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB));
--                    process_type <= control_forward_in(PE_PROCESS_TYPE);
                
--                -- The process_counter is decremented always when a row is processed (process_type = '0') or a valid output is recieved (process_type = '1')
--                elsif (process_counter > 0 and ((row_done = '1' and process_type = '0') or (status_forward_in(PE_OUTPUT_VALID) = '1' and process_type = '1'))) then 
--                    process_counter <= process_counter -1;
--                end if;
                
--                -- If the counter reaches 0, the PE has terminated its execution
--                if (process_counter = 0) then 
--                    status_forward_out(PE_READY) <= '1';
--                else 
--                    status_forward_out(PE_READY) <= '0';
--                end if;
                
--                -- Propagation of the signals to the next stages

--                accumulator_forward_out <= accumulator_forward_in;
--                control_forward_out <= control_forward_in;
                
--                if (process_counter > 0 and ((process_type = '1' and accumulations_queue_empty = '1') or (process_type = '0' and data_queue_empty = '1'))) then
--                    status_forward_out(PE_STATUS_WAITING) <= '1';
--                else 
--                    status_forward_out(PE_STATUS_WAITING) <= '0'; 
--                end if;
--                status_forward_out(PE_STATUS_TYPE) <= process_type; 
--                status_forward_out(PE_OUTPUT_VALID) <= status_forward_in(PE_OUTPUT_VALID);
--                status_forward_out(PE_ACTIVE) <= '1';
                
--            end if;
--        end if; 
--    end process;
    
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

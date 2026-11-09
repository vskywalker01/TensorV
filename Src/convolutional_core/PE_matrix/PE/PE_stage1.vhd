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
    signal row_done:                                                    STD_LOGIC;

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
    
    row_done <= '1' when (process_counter>0 and process_type = '0' and current_weight_head = current_weight_tail) 
                    else '0';
    
    -- The control process determines how the PE should handle te process requests from the control_forward_in line.
    -- Depending on the control lines, the PE is able to:
    --  * Process a certain number of convolution between an activation and a weight row contained in the data queues. 
    --      The PE is able to reuse the content of the data queues to process a certain number of convolution requested and reuse the data shared among
    --      more convolutions. At every convolution, the stage signals the next ones to save the accumulated result (stage 3) into the accumulation queues. 
    --  * Process the sum between a past accumulation and one contained in the accumulation queue.
    --      The PE, if necessary, waits for a valid data from the output line of the previous PE to forward a value contained in the accumulation queue. 
    --      The stage 2 and stage 3 will process then the sum between the value and the received one in order to forward the result to the next PE. 
 
    stage1_control_process: process(clk) is   
    begin   
        if (rising_edge(clk)) then 
            
            -- if PE_INIT = '1', all the internal registers are initialized 
            if (reset = '1' or control_forward_in(PE_INIT) = '1') then 

                -- if the PE is not active, the output status will consider always a valid output value (for the next accumulations)
                status_forward_out(PE_OUTPUT_VALID) <= '0';
                status_forward_out(PE_READY) <= '1';
                status_forward_out(PE_ACTIVE) <= '0';
                status_forward_out(PE_STATUS_TYPE) <= '0';
                status_forward_out(PE_STATUS_WAITING) <= '0';

                current_activation_head <= (others => '0');
                activation_head <= (others => '0');
                current_weight_head <= (others => '0');
                current_weight_tail <= (others => '0');
                
                current_skip <= (others => '0');
                skip <= (others => '0');
                process_counter <= (others => '0');
                process_type <= '0';
                
                output_tail <= (others => '0');
                output_head <= (others => '0');
                row_done_out <= '0'; 

            elsif (enable = '1') then 
                
                ----- accumulation queue management ------
                
                -- if there is an output coming from the stage 3 and the output queue is not full,the new element is inserted in the register file.
                if (accumulator_loopback_valid_in = '1' and output_full <= '0') then 
                    output_tail <= output_tail +1; 
                    output_register_file(to_integer(output_tail(OUTPUT_QUEUE_SIZE_BITS - 1 downto 0))) <= accumulator_loopback_in;
                end if; 
                
                -- if the PE receives an unloading command, the process counter is initialized with the number of accumulations to process. 
                if (control_forward_in(PE_PROCESS_START) = '1' and control_forward_in(PE_PROCESS_TYPE)= '1') then 
                    process_counter <= UNSIGNED(control_forward_in(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB));
                    process_type <= '1';
                
                
                -- if the PE is in an unloading phase, it waits for the accumulation from the past process. 
                elsif (process_counter > 0 and process_type = '1') then 
                
                    -- if the accumulation queue is not empty, the WAITING flag is resetted 
                    if (output_empty = '0') then 
                    
                        -- The process can continue if the past PE is not active or the flag OUTPUT_VALID = '1'
                        if ((status_forward_in(PE_OUTPUT_VALID) = '1' and status_forward_in(PE_ACTIVE)='1') or status_forward_in(PE_ACTIVE)='0') then 
                            process_counter <= process_counter-1; 
                            accumulator_queue_out <= output_register_file(to_integer(output_head(OUTPUT_QUEUE_SIZE_BITS - 1 downto 0))); 
                            output_head <= output_head + 1;  
                            status_forward_out(PE_OUTPUT_VALID) <= '1';
                        else 
                            status_forward_out(PE_OUTPUT_VALID) <= '0';
                        end if;

                        status_forward_out(PE_STATUS_WAITING) <= '0';
                    else 
                        status_forward_out(PE_OUTPUT_VALID) <= '0';
                        status_forward_out(PE_STATUS_WAITING) <= '1';
                    end if; 
                end if; 
                
                
                
                ----- convolutional queues management -----
                
                -- if the PE receives a process command, the process counter is initialized with the number of rows to compute 
                if (control_forward_in(PE_PROCESS_START) = '1' and control_forward_in(PE_PROCESS_TYPE)= '0') then 
                    process_counter <= UNSIGNED(control_forward_in(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB));
                    process_type <= '0';
                    
                    -- the temporary registers are initialized for the new process 
                    current_weight_tail <= weight_tail; 
                    current_activation_head <= activation_head; 
                    current_skip <= UNSIGNED(control_forward_in(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB));
                    skip <= UNSIGNED(control_forward_in(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB));
                    
                -- if the PE is processing a row, the queue temporary pointers are updated and two values are gathered from the data queues
                elsif (process_counter > 0 and process_type = '0') then 
                
                    -- A WEIGHTS_CLEAR/ACTIVATIONS_CLEAR flag halts the process execution 
                    if (control_forward_in(PE_WEIGHTS_CLEAR) = '1' or control_forward_in(PE_ACTIVATIONS_CLEAR)='1') then 
                        process_counter <= (others => '0');
                        status_forward_out(PE_STATUS_WAITING) <= '0';
                        -- if a WEIGHT_CLEAR command is received, the weight queue is cleared
                        if (control_forward_in(PE_WEIGHTS_CLEAR) = '1') then 
                            current_weight_head <= (others => '0');
                            current_weight_tail <= (others => '0');
                        end if;
                        
                        -- if an ACTIVATION_CLEAR command is received, the activation queue is cleared 
                        if (control_forward_in(PE_ACTIVATIONS_CLEAR)='1') then
                            current_activation_head <= (others => '0');  
                            activation_head <= (others => '0');
                        end if;
                        
                            
                    -- If the current_skip > 0 and current_weight_head > 0, the PE is in the convolutional phase with dropout: 
                    -- the PE reads one element from the weight queue and one element from the activation queue
                    -- the element obtained from the activation queue is also discarded because the striding (not required for the next kernel shift) 
                   
                    elsif (current_skip > 0 and current_weight_head < current_weight_tail and activation_waiting = '0') then 
                        activation_queue_out <= activation_register_file(to_integer(current_activation_head(ACTIVATION_QUEUE_SIZE_BITS - 1 downto 0))); 
                        weight_queue_out <= weight_register_file(to_integer(current_weight_head(WEIGHT_QUEUE_SIZE_BITS-1 downto 0)));
                        
                        current_activation_head <= current_activation_head + 1; 
                        activation_head <= activation_head + 1;
                        current_weight_head <= current_weight_head + 1;
                        current_skip <= current_skip - 1;
                        status_forward_out(PE_STATUS_WAITING) <= '0';
    
                    
                    -- If the current_skip > 0 and current_weight_head > 0, the PE is in the convolutional phase: 
                    -- the PE reads one element from the weight queue and one element from the activation queue
                    
                    elsif (current_skip = 0 and current_weight_head < current_weight_tail and activation_waiting = '0') then 
                        activation_queue_out <= activation_register_file(to_integer(current_activation_head(ACTIVATION_QUEUE_SIZE_BITS - 1 downto 0))); 
                        weight_queue_out <= weight_register_file(to_integer(current_weight_head(WEIGHT_QUEUE_SIZE_BITS-1 downto 0)));
                        current_activation_head <= current_activation_head + 1; 
                        current_weight_head <= current_weight_head + 1;
                        status_forward_out(PE_STATUS_WAITING) <= '0';
                    
                    -- if the current_skip = 0 and the current_weight_head = 0, the PE has filtered one part of the activation
                    -- The current process counter is decremented, the current_state registers are resetted in order to prepare for the next shift. 
                    elsif (current_weight_head = current_weight_tail) then 
                        process_counter <= process_counter - 1; 
                        current_activation_head <= activation_head; 
                        current_weight_head <= (others => '0');
                        current_skip <= skip; 
                        process_counter <= process_counter - 1;
                        status_forward_out(PE_STATUS_WAITING) <= '0';
                    else
                        
                        -- if the activation queue is empty, the WAITING flag is set  
                        status_forward_out(PE_STATUS_WAITING) <= '1';
                        
                    end if; 
                end if;
                
                -- propagation of the process type and the ACTIVE state 
                status_forward_out(PE_STATUS_TYPE) <= process_type; 
                status_forward_out(PE_ACTIVE) <= '1';
                
                -- If the counter reaches 0, the PE has terminated its execution
                if (process_counter = 0) then 
                    status_forward_out(PE_READY) <= '1';
                else 
                    status_forward_out(PE_READY) <= '0';
                end if;
                                

                -- Propagation of the signals to the next stages
                accumulator_forward_out <= accumulator_forward_in;
                control_forward_out <= control_forward_in;
                row_done_out <= row_done;
               
            end if;              
        end if; 
    end process;
    
    
    -- The forward process determines which data received from the input lines should be forwarded to the next PE and saved in the data queues 
    -- Everytime a valid activation/weight is received, they are saved in the redpective queues and forwarded to the next PE.
    stage1_forward_process: process(clk) is 
    begin 
        if (rising_edge(clk)) then
            if (reset = '1' or control_forward_in(PE_INIT) = '1') then 
                weight_forward_out <= (others => '0');
                activation_forward_out <= (others => '0');
                
                weight_tail <= (others => '0');
                activation_tail <= (others => '0');
                
            elsif (forward_enable = '1') then 
               
                -- if an ACTIVATION_CLEAR signal is received, the activation queue is cleared 
                if (control_forward_in(PE_ACTIVATIONS_CLEAR)='1') then  
                    activation_tail <= (others => '0');
                
                -- if a valid activation is received and forward_enable = '1', the PE inserts the new element in the activation queue and forwards it to the next PE
                elsif (control_forward_in(PE_ACTIVATION_VALID) = '1' and activation_full = '0') then 
                    activation_tail <= activation_tail +1;
                    activation_register_file(to_integer(activation_tail(ACTIVATION_QUEUE_SIZE_BITS - 1 downto 0))) <= activation_forward_in;
                    activation_forward_out <= activation_forward_in;
                end if; 
                
                if (control_forward_in(PE_WEIGHTS_CLEAR)='1') then 
                    weight_tail <= (others => '0');
                    
                -- if a valid weight is received and forward_enable = '1', the PE inserts the new element in the weight queue and forwards it to the next PE
                elsif (control_forward_in(PE_WEIGHT_VALID) = '1' and weight_full = '0') then 
                    weight_tail <= weight_tail +1;
                    weight_register_file(to_integer(weight_tail(WEIGHT_QUEUE_SIZE_BITS-1 downto 0))) <= weight_forward_in; 
                    weight_forward_out <= weight_forward_in;
                end if; 
        
            end if; 
        end if;
    end process; 

end Behavioral;

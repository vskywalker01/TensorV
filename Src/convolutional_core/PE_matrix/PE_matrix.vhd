library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.PE_MATRIX_PARAMETERS.ALL;
use work.registers.ALL;
use work.bit_reductors.ALL;

entity PE_matrix is 
    Port ( 
        clk:                    in STD_LOGIC;  
        reset:                  in STD_LOGIC;                 
        
        matrix_control_bus:              in MATRIX_CONTROL_INTERFACE;
        matrix_status_bus:               out MATRIX_STATUS_INTERFACE;
        
        matrix_buffers_control_bus:       in MATRIX_BUFFERS_CONTROL_INTERFACE; 
        matrix_buffers_status_bus:        out MATRIX_BUFFERS_STATUS_INTERFACE;
        
        weights_data_in:                 in MATRIX_WEIGHTS_DATA_INTERFACE; 
        activations_data_in:             in MATRIX_ACTIVATIONS_DATA_INTERFACE; 
        bias_data_in:                    in MATRIX_BIAS_DATA_INTERFACE; 
        outputs_data_out:                out MATRIX_OUTPUTS_DATA_INTERFACE
        
    );
end PE_matrix;

architecture Behavioral of PE_matrix is 
    
    -- matrix setting registers 
    signal matrix_current_requantization_shift: STD_LOGIC_VECTOR(REQUANTIZATION_SHIFT_BITS-1 downto 0);
    
    
    
    -- Input/Output signals for each PE in the matrix
    type MATRIX_INTERCONNECT_WEIGHT                         is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_ACTIVATION                     is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_CONTROL                        is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of PE_CONTROL_INTERFACE;
    type MATRIX_INTERCONNECT_STATUS                         is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of PE_STATUS_INTERFACE;
    type MATRIX_INTERCONNECT_ACCUMULATOR                    is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    
    signal weight_interconnect_ports:                                               MATRIX_INTERCONNECT_WEIGHT; 
    signal activation_interconnect_ports:                                           MATRIX_INTERCONNECT_ACTIVATION; 
    signal accumulator_interconnect_ports_in,accumulator_interconnect_ports_out:    MATRIX_INTERCONNECT_ACCUMULATOR;
    signal control_interconnect_ports:                                              MATRIX_INTERCONNECT_CONTROL; 
    signal status_interconnect_ports_in, status_interconnect_ports_out:             MATRIX_INTERCONNECT_STATUS;
    
    -- Input/output of internal connections between buffers, PE interconnect and output processors
    type MATRIX_INTERCONNECT_WEIGHT_PORTS                   is array (WEIGHT_LINES-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_WEIGHT_PORTS_VALID             is array (WEIGHT_LINES-1 downto 0) of STD_LOGIC;
    type MATRIX_INTERCONNECT_ACTIVATION_PORTS               is array (ACTIVATION_LINES-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_ACTIVATION_PORTS_VALID         is array (ACTIVATION_LINES-1 downto 0) of STD_LOGIC;
    type MATRIX_INTERCONNECT_CONTROL_PORTS                  is array (ACCUMULATION_LINES-1 downto 0) of PE_CONTROL_INTERFACE; 
    type MATRIX_INTERCONNECT_ACCUMULATOR_PORTS             is array (ACCUMULATION_LINES-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
    type MATRIX_INTERCONNECT_ACCUMULATOR_PORTS_VALID       is array (ACCUMULATION_LINES-1 downto 0) of STD_LOGIC;
    type MATRIX_INTERCONNECT_BIAS_PORTS                     is array (ACCUMULATION_LINES-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_BIAS_PORTS_VALID               is array (ACCUMULATION_LINES-1 downto 0) of STD_LOGIC; 
    type MATRIX_INTERCONNECT_OUTPUT_PORTS                   is array (ACCUMULATION_LINES-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    type MATRIX_INTERCONNECT_OUTPUT_PORTS_VALID             is array (ACCUMULATION_LINES-1 downto 0) of STD_LOGIC;

    signal control_ports:                                                           MATRIX_INTERCONNECT_CONTROL_PORTS;
    signal weight_data_ports:                                                       MATRIX_INTERCONNECT_WEIGHT_PORTS;
    signal weight_valid_ports:                                                      MATRIX_INTERCONNECT_WEIGHT_PORTS_VALID;
    signal activation_data_ports:                                                   MATRIX_INTERCONNECT_ACTIVATION_PORTS;
    signal activation_valid_ports:                                                  MATRIX_INTERCONNECT_ACTIVATION_PORTS_VALID;
    signal bias_data_ports:                                                         MATRIX_INTERCONNECT_BIAS_PORTS;
    signal bias_valid_ports:                                                        MATRIX_INTERCONNECT_BIAS_PORTS_VALID;
    signal output_processors_data_ports:                                            MATRIX_INTERCONNECT_OUTPUT_PORTS;
    signal output_processors_valid_ports:                                           MATRIX_INTERCONNECT_OUTPUT_PORTS_VALID; 
    signal accumulation_output_data_ports:                                          MATRIX_INTERCONNECT_ACCUMULATOR_PORTS;
    signal accumulation_output_valid_ports:                                         MATRIX_INTERCONNECT_ACCUMULATOR_PORTS_VALID;
    
    -- Signals used to control the buffers
    signal output_buffers_size_send:                                                STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
    signal weight_buffers_size_send:                                                STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
    signal activation_buffers_size_send:                                            STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
    signal bias_buffers_size_send:                                                  STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
    
        
    signal activation_buffers_send_lines:       STD_LOGIC_VECTOR(ACTIVATION_LINES-1 downto 0);
    signal weight_buffers_send_lines:           STD_LOGIC_VECTOR(WEIGHT_LINES-1 downto 0);
    signal bias_buffers_send_lines:             STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal output_buffers_send_lines:           STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal output_processor_bias_enable_lines:  STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    
    -- enable interconnect for each PE in the matrix 
    type PE_ENABLES_MATRIX                      is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC;
    
    signal enables_matrix:                      PE_ENABLES_MATRIX;
    
    -- combinatory signals used for decoding the PE and buffer enables from the dimension specified in each command 
    
    -- activation_enable_lines specifies which activation buffers should be enabled before sending the activations to the PE matrix
    signal activation_enable_lines:             STD_LOGIC_VECTOR(ACTIVATION_LINES-1 downto 0);
    
    -- weight_enable_lines specifies which weight buffers should be enabled before sending the weights to the PE matrix
    signal weight_enable_lines:                 STD_LOGIC_VECTOR(WEIGHT_LINES-1 downto 0); 
    
    -- column_enable_lines spefies which columns of the Pe matrix should be enabled (which PE accumulation line should be enabled for processing the data)
    signal column_enable_lines:                 STD_LOGIC_VECTOR(DEPTH-1 downto 0);

    
    -- status line interconnect (status output for each PE in the matrix) 
    type MATRIX_STATUS_BITS     is array (DEPTH-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal ready_bits:          MATRIX_STATUS_BITS;
    signal waiting_bits:        MATRIX_STATUS_BITS;
    signal active_bits:         MATRIX_STATUS_BITS;
    
    -- combinatory signals used to collect the ready, waiting and active status of each accumulation line 
    
    signal ready_lines:         STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal waiting_lines:       STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal active_lines:        STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    
    component PE is 
    Port ( 
            clk:                    in STD_LOGIC;  
            reset:                  in STD_LOGIC;     
            enable:                 in STD_LOGIC;             
            
            control_in:             in PE_CONTROL_INTERFACE; 
            status_in:              in PE_STATUS_INTERFACE;
            weight_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_in:          in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_in:         in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            
            
            status_out:             out PE_STATUS_INTERFACE;
            accumulator_out:        out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0)
        );
    end component;
    
    component output_processor is
        Port (
            clk: in STD_LOGIC; 
            reset: in STD_LOGIC; 
            enable: in STD_LOGIC; 
            
            bias_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
            data_in:    in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            shift_in:   in STD_LOGIC_VECTOR(REQUANTIZATION_SHIFT_BITS-1 downto 0);
    
            bias_valid_in:   in STD_LOGIC; 
            data_valid_in:   in STD_LOGIC;
                        
            data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
            valid_out:  out STD_LOGIC
            
        );
    end component;
    
begin
    matrix_rows: for r in 0 to (DEPTH-1) generate 
        matrix_columns: for c in 0 to (DEPTH-1) generate 
        
            -- each processing element is binded to the respective I/O lines
            pe_entity: PE 
                Port map (
                    clk => clk, 
                    reset => reset,       
                    enable => enables_matrix(r,c),
                    control_in => control_interconnect_ports(r,c),
                    status_in => status_interconnect_ports_in(r,c),
                    status_out => status_interconnect_ports_out(r,c),
                    weight_in => weight_interconnect_ports(r,c), 
                    activation_in => activation_interconnect_ports(r,c),
                    accumulator_in => accumulator_interconnect_ports_in(r,c),
                    accumulator_out => accumulator_interconnect_ports_out(r,c)
                );
            
            -- the status matrices are connected to the respective status bits of each PE 
            ready_bits(c)(r) <= status_interconnect_ports_out(r,c)(PE_READY);
            waiting_bits(c)(r) <= status_interconnect_ports_out(r,c)(PE_STATUS_WAITING);
            active_bits(c)(r) <= status_interconnect_ports_out(r,c)(PE_ACTIVE);
            
            -- each output line of the weight buffers is connected in broadcast for an entire row of the PE matrix
            weight_interconnect_ports(r,c) <= weight_data_ports(r);
            control_interconnect_ports(r,c)(PE_WEIGHT_VALID) <= weight_valid_ports(r); 
            
            -- each output line of the activation buffers is connected in broadcast for an entire diagonal of the PE (from left to right) 
            activation_interconnect_ports(r,c) <= activation_data_ports(r+c);
            control_interconnect_ports(r,c)(PE_ACTIVATION_VALID) <= activation_valid_ports(r+c);
            
            -- each control line is broadcasted to an entire column of the matrix 
            control_interconnect_ports(r,c)(PE_INIT) <= control_ports(c)(PE_INIT);
            control_interconnect_ports(r,c)(PE_ACTIVATIONS_CLEAR) <= control_ports(c)(PE_ACTIVATIONS_CLEAR);
            control_interconnect_ports(r,c)(PE_WEIGHTS_CLEAR) <= control_ports(c)(PE_WEIGHTS_CLEAR);
            control_interconnect_ports(r,c)(PE_PROCESS_START) <= control_ports(c)(PE_PROCESS_START);
            control_interconnect_ports(r,c)(PE_PROCESS_TYPE) <= control_ports(c)(PE_PROCESS_TYPE);
            control_interconnect_ports(r,c)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= control_ports(c)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB);
            control_interconnect_ports(r,c)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= control_ports(c)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB);
            
            -- The accumulator_in/out lines are shared among an entire column from the bottom to the top. 
            accumulators_routing: if (r>0) generate 
                accumulator_interconnect_ports_in(r-1,c) <= accumulator_interconnect_ports_out(r,c);
                status_interconnect_ports_in(r-1,c)(PE_OUTPUT_VALID)<= status_interconnect_ports_out(r,c)(PE_OUTPUT_VALID);
                status_interconnect_ports_in(r-1,c)(PE_ACTIVE)<= status_interconnect_ports_out(r,c)(PE_ACTIVE);
            end generate; 
            
            -- The last accumulation lines are connected to the output ports
            outputs_routing: if (r=0) generate 
                accumulation_output_data_ports(c) <= accumulator_interconnect_ports_out(r,c);
                accumulation_output_valid_ports(c) <= status_interconnect_ports_out(r,c)(PE_OUTPUT_VALID);
            end generate;
        end generate;
    end generate;
    
    output_interfaces_routing: for i in 0 to (ACCUMULATION_LINES-1) generate 
        -- for each accumulation line output, a bias buffer is connected to the output processor, which is connected to an output buffer 
        bias_buffer: buffer_unit
            Generic map (
                DATA_SIZE => DATA_SIZE,
                BUFFER_SIZE_BITS => BUFFER_SIZE_BITS
            )
            Port map (
                clk => clk, 
                reset => reset,
                enable => '1',
                init => matrix_buffers_control_bus(MATRIX_BUFFERS_BIAS_INIT),
                add_in => matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_BIAS_LSB+i),
                
                step_in =>  status_interconnect_ports_out(0,i)(PE_OUTPUT_VALID),
                send_in =>  bias_buffers_send_lines(i),
                counter_in => bias_buffers_size_send,
                data_in => bias_data_in,
                data_out => bias_data_ports(i),
                valid_out => open,
                ready_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_BIAS_READY_LSB+i)
            );
           
        output_PE: output_processor 
            Port map (
                clk => clk, 
                reset => reset, 
                enable => '1',
                bias_in =>  bias_data_ports(i),
                data_in => accumulation_output_data_ports(i),
                shift_in => matrix_current_requantization_shift,
                bias_valid_in => output_processor_bias_enable_lines(i),
                data_valid_in => accumulation_output_valid_ports(i),
                            
                data_out => output_processors_data_ports(i),
                valid_out => output_processors_valid_ports(i)
            );
        
        output_buffer: buffer_unit 
            Generic map (
                DATA_SIZE => DATA_SIZE,
                BUFFER_SIZE_BITS => BUFFER_SIZE_BITS
            )
            Port map (
                clk => clk, 
                reset => reset,
                enable => matrix_buffers_control_bus(MATRIX_BUFFERS_GET_OUTPUTS_LSB+i),
                init => matrix_buffers_control_bus(MATRIX_BUFFERS_OUTPUTS_INIT),
                add_in => output_processors_valid_ports(i),
                
                step_in => matrix_buffers_control_bus(MATRIX_BUFFERS_GET_OUTPUTS_LSB+i),
                send_in =>  output_buffers_send_lines(i),
                counter_in =>  output_buffers_size_send,
                data_in => output_processors_data_ports(i),
                data_out => outputs_data_out,
                valid_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_OUTPUT_VALID_LSB+i),
                ready_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_OUTPUT_READY_LSB+i)
            );
        
        status_interconnect_ports_in(DEPTH-1,i)(PE_ACTIVE) <= '0';
    end generate; 
   
    
    weight_interface_routing: for i in 0 to (WEIGHT_LINES-1) generate 
    
        -- A weight buffer is connected in broadcast to an entire row for the PE matrix
        weight_buffer: buffer_unit 
            Generic map (
                DATA_SIZE => DATA_SIZE,
                BUFFER_SIZE_BITS => BUFFER_SIZE_BITS
            )
            Port map (
                clk => clk, 
                reset => reset,
                enable => '1',
                init => matrix_buffers_control_bus(MATRIX_BUFFERS_WEIGHTS_INIT),
                add_in => matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_WEIGHTS_LSB+i),
                step_in =>  '1',
                send_in =>  weight_buffers_send_lines(i),
                counter_in =>  weight_buffers_size_send,
                data_in => weights_data_in,
                data_out => weight_data_ports(i),
                valid_out => weight_valid_ports(i),
                ready_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_WEIGHTS_READY_LSB+i)
            );
          
    end generate; 
    
    
    activation_interface_routing: for i in 0 to (ACTIVATION_LINES-1) generate  
        
        -- An activation buffer is connected in broadcast to an entire diagonal of the PE matrix
        activation_buffer: buffer_unit 
            Generic map (
                DATA_SIZE => DATA_SIZE,
                BUFFER_SIZE_BITS => BUFFER_SIZE_BITS
            )
            Port map (
                clk => clk, 
                reset => reset,
                enable => '1',
                init => matrix_buffers_control_bus(MATRIX_BUFFERS_ACTIVATIONS_INIT),
                add_in =>  matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_ACTIVATIONS_LSB+i),
                step_in =>  '1',
                send_in =>  activation_buffers_send_lines(i),
                counter_in => activation_buffers_size_send,
                data_in => activations_data_in,
                data_out => activation_data_ports(i),
                valid_out => activation_valid_ports(i),
                ready_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_ACTIVATIONS_READY_LSB+i)
            );

    end generate; 
    
    
    -- combinatory signal decoders for the dimension decoding 
    column_enable_lines_routing: for i in 0 to (DEPTH-1) generate 
    begin
        column_enable_lines(i) <= '1'   when (i<to_integer(UNSIGNED(matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_Y_MSB downto MATRIX_CONTROL_CONV_SHIFTS_Y_LSB)))) else
                                  '0';
    end generate;  
    
    weight_enable_lines_routing: for i in 0 to (WEIGHT_LINES-1) generate 
    begin
        weight_enable_lines(i) <= '1'   when (i<to_integer(UNSIGNED(matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_Y_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_Y_LSB)))) else
                                  '0';
    end generate;  
    
    activation_forward_enable_lines_routing: for i in 0 to (ACTIVATION_LINES-1) generate 
    begin
        activation_enable_lines(i) <=   '1'   when (i<to_integer(UNSIGNED(matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_Y_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_Y_LSB)))) else
                                                '0';
    end generate;    
    
    -- combinatory signal decoders for each accumulation line status 
    ready_lines_routing:    for i in 0 to (ACCUMULATION_LINES-1) generate 
        and_line:   and_reductor 
            Generic map (
                DATA_SIZE => DEPTH
            )
            Port map (
                data_in => ready_bits(i),
                result => ready_lines(i)
            );
    end generate; 
    
    waiting_lines_routing:    for i in 0 to (ACCUMULATION_LINES-1) generate 
        or_line:   or_reductor 
            Generic map (
                DATA_SIZE => DEPTH
            )
            Port map (
                data_in => waiting_bits(i),
                result => waiting_lines(i)
            );
    end generate; 
    
    
    -- Command decode process 
    -- Each command received in the matrix command bus is decoded by the following process 
    matrix_process: process(clk)
    begin
        if (rising_edge(clk)) then 
            if (reset = '1') then    
                -- initialization of all the internal signals 
                matrix_current_requantization_shift <= (others => '0'); 

                matrix_status_bus(MATRIX_STATUS_LINES_READY_MSB downto MATRIX_STATUS_LINES_READY_LSB) <= (others => '0');
                matrix_status_bus(MATRIX_STATUS_LINES_WAITING_MSB downto MATRIX_STATUS_LINES_WAITING_LSB) <= (others => '0');
                output_buffers_size_send <= (others => '0');
                weight_buffers_size_send <= (others => '0');
                activation_buffers_size_send <= (others => '0');
                bias_buffers_size_send <= (others => '0');
                output_buffers_send_lines <= (others => '0');
                activation_buffers_send_lines <= (others => '0');
                weight_buffers_send_lines <= (others => '0');
                bias_buffers_send_lines <= (others => '0');
                output_processor_bias_enable_lines <= (others => '0');
                
                
                -- by default the PE matrix is completely turned off
                for r in 0 to DEPTH-1 loop 
                    for c in 0 to DEPTH-1 loop 
                            enables_matrix(r,c) <= '0';
                    end loop; 
                end loop;
               
            else
                if (matrix_control_bus(MATRIX_CONTROL_COMMAND_VALID) = '1') then 
                
                    -- command routing from the matrix control bus to the PE control lines 
                    if (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_LOAD) then 
                        for i in 0 to(ACCUMULATION_LINES)-1 loop 
                            control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= (others => '0');
                            control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= (others => '0');
                            control_ports(i)(PE_ACTIVATIONS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG);
                            control_ports(i)(PE_WEIGHTS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG);
                            control_ports(i)(PE_INIT) <= '0';
                            control_ports(i)(PE_PROCESS_START) <= '0';
                            control_ports(i)(PE_PROCESS_TYPE) <= '0';
                        end loop;
                        
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_COMPUTE) then 
                        for i in 0 to(ACCUMULATION_LINES)-1 loop 
                            control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= matrix_control_bus(MATRIX_CONTROL_CONV_STRIDE_X_MSB downto MATRIX_CONTROL_CONV_STRIDE_X_LSB);
                            control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                            control_ports(i)(PE_ACTIVATIONS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG);
                            control_ports(i)(PE_WEIGHTS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG);
                            control_ports(i)(PE_INIT) <= '0';
                            control_ports(i)(PE_PROCESS_START) <= '1';
                            control_ports(i)(PE_PROCESS_TYPE) <= '0';
                        end loop;
                                           
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_UNLOAD) then 
                        for i in 0 to(ACCUMULATION_LINES)-1 loop 
                            control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= (others => '0');
                            control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                            control_ports(i)(PE_ACTIVATIONS_CLEAR) <= '0';
                            control_ports(i)(PE_WEIGHTS_CLEAR) <= '0';
                            control_ports(i)(PE_INIT) <= '0';
                            control_ports(i)(PE_PROCESS_START) <= '1';
                            control_ports(i)(PE_PROCESS_TYPE) <= '1';
                        end loop;
                    
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_INIT) then 
                        for i in 0 to(ACCUMULATION_LINES)-1 loop 
                            control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= (others => '0');
                            control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= (others => '0');
                            control_ports(i)(PE_ACTIVATIONS_CLEAR) <= '0';
                            control_ports(i)(PE_WEIGHTS_CLEAR) <= '0';
                            control_ports(i)(PE_INIT) <= '1';
                            control_ports(i)(PE_PROCESS_START) <= '0';
                            control_ports(i)(PE_PROCESS_TYPE) <= '0';
                        end loop;       
                    else                        
                        for i in 0 to(ACCUMULATION_LINES)-1 loop 
                            control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= (others => '0');
                            control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= (others => '0');
                            control_ports(i)(PE_ACTIVATIONS_CLEAR) <= '0';
                            control_ports(i)(PE_WEIGHTS_CLEAR) <= '0';
                            control_ports(i)(PE_INIT) <= '0';
                            control_ports(i)(PE_PROCESS_START) <= '0';
                            control_ports(i)(PE_PROCESS_TYPE) <= '0';
                        end loop;
                    end if; 
                    
                    -- when a LOAD command is received, the weight/activation buffers are programmed to send a certain amount of  data to the PE matrix
                    if (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_LOAD) then 
                        -- if the load activations flag is set, the process request a transfer of activation_matrix_size_x elements 
                        -- only the buffers between 0 an activation_matrix_size_y receive the send command 
                        if (matrix_control_bus(MATRIX_CONTROL_LOAD_ACTIVATIONS_FLAG) = '1') then 
                            activation_buffers_send_lines <= activation_enable_lines; 
                            if (ACTIVATION_MATRIX_SIZE_BITS < BUFFER_SIZE_BITS) then  
                                activation_buffers_size_send(BUFFER_SIZE_BITS-1 downto ACTIVATION_MATRIX_SIZE_BITS) <= (others => '0');
                            end if;
                            activation_buffers_size_send(ACTIVATION_MATRIX_SIZE_BITS-1 downto 0) <= matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_X_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_X_LSB);
                        end if; 
                        
                        -- if the load weights flag is set, the process request a transfer of weight_matrix_size_x elements 
                        -- only the buffers between 0 an weight_matrix_size_y receive the send command 
                        if (matrix_control_bus(MATRIX_CONTROL_LOAD_WEIGHTS_FLAG) = '1') then 
                            weight_buffers_send_lines <= weight_enable_lines;
                            
                            if (WEIGHT_MATRIX_SIZE_BITS < BUFFER_SIZE_BITS) then  
                                weight_buffers_size_send(BUFFER_SIZE_BITS-1 downto WEIGHT_MATRIX_SIZE_BITS) <= (others => '0');
                            end if;
                            weight_buffers_size_send(WEIGHT_MATRIX_SIZE_BITS-1 downto 0) <= matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_X_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_X_LSB);
                        end if; 

                    -- if a COMPUTE command is received, the PE enable signals are updated to enable only the necessary PE for the computation, 
                    
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_COMPUTE) then 
                        for r in 0 to DEPTH-1 loop 
                            for c in 0 to DEPTH-1 loop 
                                    enables_matrix(r,c) <= weight_enable_lines(r) and column_enable_lines(c);
                            end loop; 
                        end loop;
                        
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_UNLOAD) then 
                        if (matrix_control_bus(MATRIX_CONTROL_LOAD_BIAS_FLAG) = '1') then 
                            output_processor_bias_enable_lines <= column_enable_lines;
                            bias_buffers_send_lines <= column_enable_lines; 
                            if (CONV_SHIFTS_BITS < BUFFER_SIZE_BITS) then  
                                bias_buffers_size_send(BUFFER_SIZE_BITS-1 downto CONV_SHIFTS_BITS) <= (others => '0');
                            end if;
                            bias_buffers_size_send(CONV_SHIFTS_BITS-1 downto 0) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                        end if; 
                        
                        output_buffers_send_lines <= column_enable_lines;                        
                        if (CONV_SHIFTS_BITS < BUFFER_SIZE_BITS) then  
                            output_buffers_size_send(BUFFER_SIZE_BITS-1 downto CONV_SHIFTS_BITS) <= (others => '0');
                        end if;
                        output_buffers_size_send(CONV_SHIFTS_BITS-1 downto 0) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                        matrix_current_requantization_shift <=  matrix_control_bus(MATRIX_CONTROL_REQUANTIZATION_SHIFT_MSB downto MATRIX_CONTROL_REQUANTIZATION_SHIFT_LSB);

                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_INIT) then 
                        for r in 0 to DEPTH-1 loop 
                            for c in 0 to DEPTH-1 loop 
                                    enables_matrix(r,c) <= '0';
                            end loop; 
                        end loop;
                        output_buffers_send_lines <= (others => '0');
                        activation_buffers_send_lines <= (others => '0');
                        weight_buffers_send_lines <= (others => '0');
                        bias_buffers_send_lines <= (others => '0');
                    end if; 
                else 
                    for i in 0 to(ACCUMULATION_LINES)-1 loop 
                        control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= (others => '0');
                        control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= (others => '0');
                        control_ports(i)(PE_ACTIVATIONS_CLEAR) <= '0';
                        control_ports(i)(PE_WEIGHTS_CLEAR) <= '0';
                        control_ports(i)(PE_INIT) <= '0';
                        control_ports(i)(PE_PROCESS_START) <= '0';
                        control_ports(i)(PE_PROCESS_TYPE) <= '0';
                    end loop;
                    
                    output_buffers_send_lines <= (others => '0');
                    activation_buffers_send_lines <= (others => '0');
                    weight_buffers_send_lines <= (others => '0');
                    bias_buffers_send_lines <= (others => '0');
                end if; 

                matrix_status_bus(MATRIX_STATUS_LINES_READY_MSB downto MATRIX_STATUS_LINES_READY_LSB) <= ready_lines;
                matrix_status_bus(MATRIX_STATUS_LINES_WAITING_MSB downto MATRIX_STATUS_LINES_WAITING_LSB) <= waiting_lines;
           end if;
        end if;
    end process;
        
end architecture;
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
    -- The columns_enable_lines signal is used to decode wich column of the matrix and bias/output buffers should be used for the comutation/unloading phase 
    -- The weight_enable_lines signal is used to decode which weight buffers and rows of the matrix should be used for the loading/computation 
    -- The activation_enable_lines signal is used to decode which activation buffers should be enabled for the loading phase 
   
    column_enable_lines_routing: for i in 0 to (DEPTH-1) generate 
        signal matrix_shifts_y:   INTEGER;
        signal stride_mode:       INTEGER;
        signal stride_enable:     STD_LOGIC;
        
    begin
        -- the number of columns in the PE matrix involved in the computation is given by the number of vertical shifts of the weight matrix (CONV_SHIFTS_Y)
        matrix_shifts_y <= to_integer(UNSIGNED(matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_Y_MSB downto MATRIX_CONTROL_CONV_SHIFTS_Y_LSB)));
        
        -- The stride mode indicates which columns should be masked or not because the stride of the convolution 
        stride_mode <= 2 when (matrix_control_bus(MATRIX_CONTROL_CONV_STRIDE_Y_MSB downto MATRIX_CONTROL_CONV_STRIDE_Y_LSB) = CONV_STRIDE_2) else 
                                                4 when (matrix_control_bus(MATRIX_CONTROL_CONV_STRIDE_Y_MSB downto MATRIX_CONTROL_CONV_STRIDE_Y_LSB) = CONV_STRIDE_4) else 
                                                8 when (matrix_control_bus(MATRIX_CONTROL_CONV_STRIDE_Y_MSB downto MATRIX_CONTROL_CONV_STRIDE_Y_LSB) = CONV_STRIDE_8) else 
                                                1;
        
        
        -- If the stride number > 1 (2, 4 or 8), the STRIDE_ENABLE value masks the unused columns. 
        
        --stride_enable <= '1' when ( i mod STRIDE_MODE = 0) else
        --                 '0';
        
        
        -- if STRIDE = 1 and i < CONV_SHIFTS_Y, the column is considered active (all the columns with an ID lower than CONV_SHIFTS_Y)
        -- if STRIDE > 1 and i < CONV_SHIFTS_Y, the column is enabled only when the column is not skipped because the striding)
        
        --column_enable_lines(i) <= '1'   when (i<matrix_shifts_y and stride_enable = '1') else
        column_enable_lines(i) <= '1'   when (i<(matrix_shifts_y*stride_mode) and (i mod stride_mode = 0)) else
                                                    '0';
    end generate;  
   
    
    weight_enable_lines_routing: for i in 0 to (WEIGHT_LINES-1) generate 
        signal matrix_weight_y:   INTEGER;
    begin
        matrix_weight_y <= to_integer(UNSIGNED(matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_Y_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_Y_LSB)));
    
        -- only the rows of the PE matrix that contain a valid weight matrix should be involved in the computation. 
        weight_enable_lines(i) <= '1'   when (i<matrix_weight_y) else
                                  '0';
    end generate;  
    
    activation_forward_enable_lines_routing: for i in 0 to (ACTIVATION_LINES-1) generate 
        signal MATRIX_ACTIVATION_Y: INTEGER;
    begin
        matrix_activation_y <= to_integer(UNSIGNED(matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_Y_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_Y_LSB)));
        
        -- only the diagonals of the PE matrix that contain a valid activation row ahould be able to receive a valid activation. 
        activation_enable_lines(i) <=   '1'   when (i< matrix_activation_y ) else
                                                '0';
    end generate;    
    
    -- combinatory signal decoders for each accumulation line status 
    -- ready_lines is a vector that signals which accumulation lines (columns) of the matrix are ready to receive a command 
    -- waiting_lines is a vector that signals which accumulation lines (columns) of the matrix are waiting for data to continue the computation/unloading process
    
    ready_lines_routing:    for i in 0 to (ACCUMULATION_LINES-1) generate 
        -- a bit of the ready lines is obtained by using an AND tree between all the ready bits of the PEs contained in a column. 
    
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
        -- a bit of the waiting lines is obtained by using an OR tree between all the waiting bits of the PEs contained in a column. 
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
                        
                        -- The command lines are modified in order to match witht the LOAD command 
                        for i in 0 to(ACCUMULATION_LINES)-1 loop 
                            control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= (others => '0');
                            control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= (others => '0');
                            control_ports(i)(PE_ACTIVATIONS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG);
                            control_ports(i)(PE_WEIGHTS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG);
                            control_ports(i)(PE_INIT) <= '0';
                            control_ports(i)(PE_PROCESS_START) <= '0';
                            control_ports(i)(PE_PROCESS_TYPE) <= '0';
                        end loop;
                    
                    -- if a COMPUTE command is received, the PE enable signals are updated to enable only the necessary PE for the computation, 
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_COMPUTE) then 
                        
                        -- Only the necessary PEs are enabled 
                        for r in 0 to DEPTH-1 loop 
                            for c in 0 to DEPTH-1 loop 
                                    -- A PE should be activated when it contains a valid weight row and the coulmn of the matrix is active. 
                                    enables_matrix(r,c) <= weight_enable_lines(r) and column_enable_lines(c);
                            end loop; 
                        end loop;
                        
                        -- The command lines are modified in order to match with the COMPUTE command 
                        for i in 0 to(ACCUMULATION_LINES)-1 loop 
                            control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= matrix_control_bus(MATRIX_CONTROL_CONV_STRIDE_X_MSB downto MATRIX_CONTROL_CONV_STRIDE_X_LSB);
                            control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                            control_ports(i)(PE_ACTIVATIONS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG);
                            control_ports(i)(PE_WEIGHTS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG);
                            control_ports(i)(PE_INIT) <= '0';
                            control_ports(i)(PE_PROCESS_START) <= '1';
                            control_ports(i)(PE_PROCESS_TYPE) <= '0';
                        end loop;
                    
                    -- if an UNLOAD command is received, the bias buffers, output processors and output buffers lines are prepared for processing the outputs from the Pe matrix          
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_UNLOAD) then 
                        
                        -- If the bias buffers sould be used for the output computation (LOAD_BIAS_FLAG = '1'), the necessary bias buffers are enabled 
                        if (matrix_control_bus(MATRIX_CONTROL_LOAD_BIAS_FLAG) = '1') then 
                            output_processor_bias_enable_lines <= column_enable_lines;
                            bias_buffers_send_lines <= column_enable_lines; 
                            if (CONV_SHIFTS_BITS < BUFFER_SIZE_BITS) then  
                                bias_buffers_size_send(BUFFER_SIZE_BITS-1 downto CONV_SHIFTS_BITS) <= (others => '0');
                            end if;
                            bias_buffers_size_send(CONV_SHIFTS_BITS-1 downto 0) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                        end if; 
                        -- only the required buffers receives a send command 
                        output_buffers_send_lines <= column_enable_lines;    
                        
                        -- A send command is issued only for the used output buffers.                    
                        if (CONV_SHIFTS_BITS < BUFFER_SIZE_BITS) then  
                            output_buffers_size_send(BUFFER_SIZE_BITS-1 downto CONV_SHIFTS_BITS) <= (others => '0');
                        end if;
                        output_buffers_size_send(CONV_SHIFTS_BITS-1 downto 0) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                        
                        -- The requantization shift is propagated to the output_processors. 
                        matrix_current_requantization_shift <=  matrix_control_bus(MATRIX_CONTROL_REQUANTIZATION_SHIFT_MSB downto MATRIX_CONTROL_REQUANTIZATION_SHIFT_LSB);
                        
                        
                        -- The control lines are modified in order to match the UNLOAD command
                        for i in 0 to(ACCUMULATION_LINES)-1 loop 
                            control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= (others => '0');
                            control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                            control_ports(i)(PE_ACTIVATIONS_CLEAR) <= '0';
                            control_ports(i)(PE_WEIGHTS_CLEAR) <= '0';
                            control_ports(i)(PE_INIT) <= '0';
                            control_ports(i)(PE_PROCESS_START) <= '1';
                            control_ports(i)(PE_PROCESS_TYPE) <= '1';
                        end loop;
                   
                    -- when a INIT command is received (or the command is not valid), the PE matrix is cleared and all PEs are disabled 
                    else
                        -- All the PEs are disabled 
                        for r in 0 to DEPTH-1 loop 
                            for c in 0 to DEPTH-1 loop 
                                    enables_matrix(r,c) <= '0';
                            end loop; 
                        end loop;
                        
                        -- The send signals are cleared
                        output_buffers_send_lines <= (others => '0');
                        activation_buffers_send_lines <= (others => '0');
                        weight_buffers_send_lines <= (others => '0');
                        bias_buffers_send_lines <= (others => '0');
                        
                        -- The command lines are modified to initialize the PE matrix
                        for i in 0 to(ACCUMULATION_LINES)-1 loop 
                            control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= (others => '0');
                            control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= (others => '0');
                            control_ports(i)(PE_ACTIVATIONS_CLEAR) <= '0';
                            control_ports(i)(PE_WEIGHTS_CLEAR) <= '0';
                            control_ports(i)(PE_INIT) <= '1';
                            control_ports(i)(PE_PROCESS_START) <= '0';
                            control_ports(i)(PE_PROCESS_TYPE) <= '0';
                        end loop;       
                    end if; 
                else 
                    -- the buffers send signals and the control signals are cleared when a command is not issued. 
                    
                    for i in 0 to(ACCUMULATION_LINES)-1 loop 
                        control_ports(i)(PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= (others => '0');
                        control_ports(i)(PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= (others => '0');
                        control_ports(i)(PE_ACTIVATIONS_CLEAR) <= '0';
                        control_ports(i)(PE_WEIGHTS_CLEAR) <= '0';
                        control_ports(i)(PE_INIT) <= '0';
                        control_ports(i)(PE_PROCESS_START) <= '0';
                        control_ports(i)(PE_PROCESS_TYPE) <= '0';
                    end loop;
                    
                    -- The send signals are cleared. 
                    output_buffers_send_lines <= (others => '0');
                    activation_buffers_send_lines <= (others => '0');
                    weight_buffers_send_lines <= (others => '0');
                    bias_buffers_send_lines <= (others => '0');
                end if; 
                
                -- Propagation of the matrix ready and waiting status lines
                matrix_status_bus(MATRIX_STATUS_LINES_READY_MSB downto MATRIX_STATUS_LINES_READY_LSB) <= ready_lines;
                matrix_status_bus(MATRIX_STATUS_LINES_WAITING_MSB downto MATRIX_STATUS_LINES_WAITING_LSB) <= waiting_lines;
           end if;
        end if;
    end process;
        
end architecture;
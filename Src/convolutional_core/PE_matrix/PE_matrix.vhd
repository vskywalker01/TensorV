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
    
    
    -- matrix PE interconnect matrices 
    type MATRIX_INTERCONNECT_DATA           is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_ACCUMULATOR    is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_CONTROL        is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of PE_CONTROL_INTERFACE;
    type MATRIX_INTERCONNECT_STATUS         is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of PE_STATUS_INTERFACE;
    type MATRIX_INTERCONNECT_BIAS_VALID     is array (DEPTH-1 downto 0) of STD_LOGIC; 
    type MATRIX_INTERCONNECT_BIAS           is array (DEPTH-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_OUTPUTS_VALID  is array (DEPTH-1 downto 0) of STD_LOGIC; 
    type MATRIX_INTERCONNECT_OUTPUTS        is array (DEPTH-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
    signal weight_interconnect_ports_in,weight_interconnect_ports_out:              MATRIX_INTERCONNECT_DATA; 
    signal activation_interconnect_ports_in,activation_interconnect_ports_out:      MATRIX_INTERCONNECT_DATA; 
    signal accumulator_interconnect_ports_in,accumulator_interconnect_ports_out:    MATRIX_INTERCONNECT_ACCUMULATOR;
    signal control_interconnect_ports_in,control_interconnect_ports_out:            MATRIX_INTERCONNECT_CONTROL; 
    signal status_interconnect_ports_in, status_interconnect_ports_out:             MATRIX_INTERCONNECT_STATUS;
    signal bias_interconnect_ports:                                                 MATRIX_INTERCONNECT_BIAS;
    signal bias_interconnect_valid:                                                 MATRIX_INTERCONNECT_BIAS_valid;
    signal outputs_interconnect_ports:                                              MATRIX_INTERCONNECT_OUTPUTS;
    signal outputs_interconnect_valid:                                              MATRIX_INTERCONNECT_OUTPUTS_VALID; 
        
    signal output_queues_size_send:                                                 STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
    signal weight_queues_size_send:                                                 STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
    signal activation_queues_size_send:                                             STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
    signal bias_queues_size_send:                                                   STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
    
    -- enable matrices
    type PE_ENABLES_MATRIX                      is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC;
    signal enables_matrix:                      PE_ENABLES_MATRIX;
    signal forward_enables_matrix:              PE_ENABLES_MATRIX;
    
    signal activation_forward_enable_lines:     STD_LOGIC_VECTOR(ACTIVATION_LINES-1 downto 0);
    signal weight_enable_lines:                 STD_LOGIC_VECTOR(WEIGHT_LINES-1 downto 0); 
    signal column_enable_lines:                 STD_LOGIC_VECTOR(DEPTH-1 downto 0);
    
    signal activation_buffers_send_lines:       STD_LOGIC_VECTOR(ACTIVATION_LINES-1 downto 0);
    signal weight_buffers_send_lines:           STD_LOGIC_VECTOR(WEIGHT_LINES-1 downto 0);
    signal bias_buffers_send_lines:             STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal output_buffers_send_lines:           STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal output_processor_bias_enable_lines:  STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    
    -- matrix status lines
    
    type MATRIX_STATUS_BITS     is array (DEPTH-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);

    signal ready_bits:          MATRIX_STATUS_BITS;
    signal waiting_bits:        MATRIX_STATUS_BITS;
    signal active_bits:         MATRIX_STATUS_BITS;
    
    signal ready_lines:         STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal waiting_lines:       STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal active_lines:        STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    
    component PE is 
        Port ( 
            clk:                    in STD_LOGIC;  
            reset:                  in STD_LOGIC;                 
            enable:                 in STD_LOGIC; 
            forward_enable:         in STD_LOGIC; 
            
            control_in:             in PE_CONTROL_INTERFACE; 
            status_in:              in PE_STATUS_INTERFACE;
            weight_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_in:          in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_in:         in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            
            control_out:            out PE_CONTROL_INTERFACE;
            status_out:             out PE_STATUS_INTERFACE;
            weight_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
            activation_out:         out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
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
            pe_entity: PE 
                Port map (
                    clk => clk, 
                    reset => reset,       
                    enable => enables_matrix(r,c),
                    forward_enable => forward_enables_matrix(r,c),
                    control_in => control_interconnect_ports_in(r,c),
                    control_out => control_interconnect_ports_out(r,c),
                    status_in => status_interconnect_ports_in(r,c),
                    status_out => status_interconnect_ports_out(r,c),
                    
                    weight_in => weight_interconnect_ports_in(r,c), 
                    weight_out => weight_interconnect_ports_out(r,c), 
                    
                    activation_in => activation_interconnect_ports_in(r,c),
                    activation_out => activation_interconnect_ports_out(r,c),
                    
                    accumulator_in => accumulator_interconnect_ports_in(r,c),
                    accumulator_out => accumulator_interconnect_ports_out(r,c)
                );
                        
            ready_bits(c)(r) <= status_interconnect_ports_out(r,c)(PE_READY);
            waiting_bits(c)(r) <= status_interconnect_ports_out(r,c)(PE_STATUS_WAITING);
            active_bits(c)(r) <= status_interconnect_ports_out(r,c)(PE_ACTIVE);
            
            weight_routing: if (c+1<DEPTH) generate 
                weight_interconnect_ports_in(r,c+1) <= weight_interconnect_ports_out(r,c);
            end generate; 
            
            accumulators_routing: if (r>0) generate 
                accumulator_interconnect_ports_in(r-1,c) <= accumulator_interconnect_ports_out(r,c);
                status_interconnect_ports_in(r-1,c)(PE_OUTPUT_VALID)<= status_interconnect_ports_out(r,c)(PE_OUTPUT_VALID);
                status_interconnect_ports_in(r-1,c)(PE_ACTIVE)<= status_interconnect_ports_out(r,c)(PE_ACTIVE);
            end generate; 
            
            activation_routing: if (r>0 and (c+1<DEPTH)) generate 
                activation_interconnect_ports_in(r-1,c+1) <= activation_interconnect_ports_out(r,c);
            end generate; 
            
            control_routing: if (c+1<DEPTH) generate 
                control_interconnect_ports_in(r,c+1) <= control_interconnect_ports_out(r,c);
            end generate; 
                  
        end generate;
    end generate;
    
    output_interfaces_routing: for i in 0 to (ACCUMULATION_LINES-1) generate 
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
                counter_in => bias_queues_size_send,
                data_in => bias_data_in,
                data_out => bias_interconnect_ports(i),
                valid_out => open,--bias_interconnect_valid(i),
                ready_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_BIAS_READY_LSB+i)
            );
           
        output_PE: output_processor 
            Port map (
                clk => clk, 
                reset => reset, 
                enable => '1',
                bias_in =>  bias_interconnect_ports(i),
                data_in => accumulator_interconnect_ports_out(0,i),
                shift_in => matrix_current_requantization_shift,
                bias_valid_in =>  output_processor_bias_enable_lines(i),
                data_valid_in => status_interconnect_ports_out(0,i)(PE_OUTPUT_VALID),
                            
                data_out => outputs_interconnect_ports(i),
                valid_out => outputs_interconnect_valid(i)
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
                add_in => outputs_interconnect_valid(i),
                
                step_in => matrix_buffers_control_bus(MATRIX_BUFFERS_GET_OUTPUTS_LSB+i),
                send_in =>  output_buffers_send_lines(i),
                counter_in =>  output_queues_size_send,
                data_in => outputs_interconnect_ports(i),
                data_out => outputs_data_out,
                valid_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_OUTPUT_VALID_LSB+i),
                ready_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_OUTPUT_READY_LSB+i)
            );
        
        accumulator_interconnect_ports_in(DEPTH-1,i) <= (others => '0');
        status_interconnect_ports_in(DEPTH-1,i)(PE_OUTPUT_VALID) <= '0';
        status_interconnect_ports_in(DEPTH-1,i)(PE_ACTIVE) <= '0';
    end generate; 
    
    weight_interface_routing: for i in 0 to (WEIGHT_LINES-1) generate 
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
                counter_in =>  weight_queues_size_send,
                data_in => weights_data_in,
                data_out => weight_interconnect_ports_in(i,0),
                valid_out => control_interconnect_ports_in(i,0)(PE_WEIGHT_VALID),
                ready_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_WEIGHTS_READY_LSB+i)
            );
    end generate; 
    
    activation_interface_routing: for i in 0 to (ACTIVATION_LINES-1) generate 
        constant ROW: INTEGER := i when (i<DEPTH) else (DEPTH-1); 
        constant COL: INTEGER := 0 when (i<DEPTH) else (i-DEPTH+1);
    begin 
        first_rows: if (i<DEPTH) generate
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
                    counter_in => activation_queues_size_send,
                    data_in => activations_data_in,
                    data_out => activation_interconnect_ports_in(ROW,COL),
                    valid_out => control_interconnect_ports_in(i,0)(PE_ACTIVATION_VALID),
                    ready_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_ACTIVATIONS_READY_LSB+i)
                );
        end generate; 
        last_rows: if (i>=DEPTH) generate
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
                    step_in =>  control_interconnect_ports_in(ROW,COL)(PE_ACTIVATION_VALID),
                    send_in =>  activation_buffers_send_lines(i),
                    counter_in => activation_queues_size_send,
                    data_in => activations_data_in,
                    data_out => activation_interconnect_ports_in(ROW,COL),
                    valid_out => open,
                    ready_out => matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_ACTIVATIONS_READY_LSB+i)
                );
        end generate; 

    end generate; 
    
    control_interface_routing: for i in 1 to (CONTROL_LINES-1) generate 
        control_interconnect_ports_in(i,0)(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB) <= control_interconnect_ports_in(i-1,0)(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB);
        control_interconnect_ports_in(i,0)(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB) <= control_interconnect_ports_in(i-1,0)(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB);
        control_interconnect_ports_in(i,0)(PE_ACTIVATIONS_CLEAR) <= control_interconnect_ports_in(i-1,0)(PE_ACTIVATIONS_CLEAR);
        control_interconnect_ports_in(i,0)(PE_WEIGHTS_CLEAR) <= control_interconnect_ports_in(i-1,0)(PE_WEIGHTS_CLEAR);
        control_interconnect_ports_in(i,0)(PE_INIT) <= control_interconnect_ports_in(i-1,0)(PE_INIT);
        control_interconnect_ports_in(i,0)(PE_PROCESS_START) <= control_interconnect_ports_in(i-1,0)(PE_PROCESS_START);
        control_interconnect_ports_in(i,0)(PE_PROCESS_TYPE) <= control_interconnect_ports_in(i-1,0)(PE_PROCESS_TYPE);
    end generate; 
    
   
    column_enable_lines_routing: for i in 0 to (DEPTH-1) generate 
    begin
        column_enable_lines(i) <= '1'   when (i<UNSIGNED(matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_Y_MSB downto MATRIX_CONTROL_CONV_SHIFTS_Y_LSB))) else
                                  '0';
    end generate;  
    
    weight_enable_lines_routing: for i in 0 to (WEIGHT_LINES-1) generate 
    begin
        weight_enable_lines(i) <= '1'   when (i<UNSIGNED(matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_Y_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_Y_LSB))) else
                                  '0';
    end generate;  
    
    activation_forward_enable_lines_routing: for i in 0 to (ACTIVATION_LINES-1) generate 
    begin
        activation_forward_enable_lines(i) <=   '1'   when (i<UNSIGNED(matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_Y_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_Y_LSB))) else
                                                '0';
    end generate;    
    
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
    
    matrix_process: process(clk)
    begin
        if (rising_edge(clk)) then 
            if (reset = '1') then    
                
                matrix_current_requantization_shift <= (others => '0'); 

                matrix_status_bus(MATRIX_STATUS_LINES_READY_MSB downto MATRIX_STATUS_LINES_READY_LSB) <= (others => '0');
                matrix_status_bus(MATRIX_STATUS_LINES_WAITING_MSB downto MATRIX_STATUS_LINES_WAITING_LSB) <= (others => '0');
                output_queues_size_send <= (others => '0');
                weight_queues_size_send <= (others => '0');
                activation_queues_size_send <= (others => '0');
                bias_queues_size_send <= (others => '0');
                output_buffers_send_lines <= (others => '0');
                activation_buffers_send_lines <= (others => '0');
                weight_buffers_send_lines <= (others => '0');
                bias_buffers_send_lines <= (others => '0');
                output_processor_bias_enable_lines <= (others => '0');
                 
                for r in 0 to DEPTH-1 loop 
                    for c in 0 to DEPTH-1 loop 
                            enables_matrix(r,c) <= '0';
                            forward_enables_matrix(r,c) <= '0';
                    end loop; 
                end loop;
                
            else
                if (matrix_control_bus(MATRIX_CONTROL_COMMAND_VALID) = '1') then 
                    if (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_LOAD) then 
                        control_interconnect_ports_in(0,0)(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB) <= (others => '0');
                        control_interconnect_ports_in(0,0)(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB) <= (others => '0');
                        control_interconnect_ports_in(0,0)(PE_ACTIVATIONS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG);
                        control_interconnect_ports_in(0,0)(PE_WEIGHTS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG);
                        control_interconnect_ports_in(0,0)(PE_INIT) <= '0';
                        control_interconnect_ports_in(0,0)(PE_PROCESS_START) <= '0';
                        control_interconnect_ports_in(0,0)(PE_PROCESS_TYPE) <= '0';
                        
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_COMPUTE) then 
                        control_interconnect_ports_in(0,0)(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB) <= matrix_control_bus(MATRIX_CONTROL_CONV_SKIP_X_MSB downto MATRIX_CONTROL_CONV_SKIP_X_LSB);
                        control_interconnect_ports_in(0,0)(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                        control_interconnect_ports_in(0,0)(PE_ACTIVATIONS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG);
                        control_interconnect_ports_in(0,0)(PE_WEIGHTS_CLEAR) <= matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG);
                        control_interconnect_ports_in(0,0)(PE_INIT) <= '0';
                        control_interconnect_ports_in(0,0)(PE_PROCESS_START) <= '1';
                        control_interconnect_ports_in(0,0)(PE_PROCESS_TYPE) <= '0';
                        
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_UNLOAD) then 
                        control_interconnect_ports_in(0,0)(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB) <= (others => '0');
                        control_interconnect_ports_in(0,0)(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                        control_interconnect_ports_in(0,0)(PE_ACTIVATIONS_CLEAR) <= '0';
                        control_interconnect_ports_in(0,0)(PE_WEIGHTS_CLEAR) <= '0';
                        control_interconnect_ports_in(0,0)(PE_INIT) <= '0';
                        control_interconnect_ports_in(0,0)(PE_PROCESS_START) <= '1';
                        control_interconnect_ports_in(0,0)(PE_PROCESS_TYPE) <= '1';  
                    
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_INIT) then 
                        control_interconnect_ports_in(0,0)(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB) <= (others => '0');
                        control_interconnect_ports_in(0,0)(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB) <= (others => '0');
                        control_interconnect_ports_in(0,0)(PE_ACTIVATIONS_CLEAR) <= '0';
                        control_interconnect_ports_in(0,0)(PE_WEIGHTS_CLEAR) <= '0';
                        control_interconnect_ports_in(0,0)(PE_INIT) <= '1';
                        control_interconnect_ports_in(0,0)(PE_PROCESS_START) <= '0';
                        control_interconnect_ports_in(0,0)(PE_PROCESS_TYPE) <= '0';            
                    else                        
                        control_interconnect_ports_in(0,0)(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB) <= (others => '0');
                        control_interconnect_ports_in(0,0)(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB) <= (others => '0');
                        control_interconnect_ports_in(0,0)(PE_ACTIVATIONS_CLEAR) <= '0';
                        control_interconnect_ports_in(0,0)(PE_WEIGHTS_CLEAR) <= '0';
                        control_interconnect_ports_in(0,0)(PE_INIT) <= '0';
                        control_interconnect_ports_in(0,0)(PE_PROCESS_START) <= '0';
                        control_interconnect_ports_in(0,0)(PE_PROCESS_TYPE) <= '0';
                    end if; 
                    

                    if (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_LOAD) then 
                        if (matrix_control_bus(MATRIX_CONTROL_LOAD_ACTIVATIONS_FLAG) = '1') then 
                            activation_buffers_send_lines <= activation_forward_enable_lines; 
                            if (ACTIVATION_MATRIX_SIZE_BITS < BUFFER_SIZE_BITS) then  
                            
                                activation_queues_size_send(BUFFER_SIZE_BITS-1 downto ACTIVATION_MATRIX_SIZE_BITS) <= (others => '0');
                            end if;
                            activation_queues_size_send(ACTIVATION_MATRIX_SIZE_BITS-1 downto 0) <= matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_X_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_X_LSB);
                        end if; 
                        if (matrix_control_bus(MATRIX_CONTROL_LOAD_WEIGHTS_FLAG) = '1') then 
                            weight_buffers_send_lines <= weight_enable_lines;
                            
                            if (WEIGHT_MATRIX_SIZE_BITS < BUFFER_SIZE_BITS) then  
                                weight_queues_size_send(BUFFER_SIZE_BITS-1 downto WEIGHT_MATRIX_SIZE_BITS) <= (others => '0');
                            end if;
                            weight_queues_size_send(WEIGHT_MATRIX_SIZE_BITS-1 downto 0) <= matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_X_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_X_LSB);
                        end if; 

                        for r in 0 to DEPTH-1 loop 
                            for c in 0 to DEPTH-1 loop 
                                    forward_enables_matrix(r,c) <= activation_forward_enable_lines(r+c) and column_enable_lines(c);
                            end loop; 
                        end loop;
                        
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_COMPUTE or
                            matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_UNLOAD) then 
                                                
                        if (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_UNLOAD) then
                            if (matrix_control_bus(MATRIX_CONTROL_LOAD_BIAS_FLAG) = '1') then 
                                bias_buffers_send_lines <= column_enable_lines; 
                                if (CONV_SHIFTS_BITS < BUFFER_SIZE_BITS) then  
                                    bias_queues_size_send(BUFFER_SIZE_BITS-1 downto CONV_SHIFTS_BITS) <= (others => '0');
                                end if;
                                bias_queues_size_send(CONV_SHIFTS_BITS-1 downto 0) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                            end if; 
                            
                            output_buffers_send_lines <= column_enable_lines;                        
                            output_processor_bias_enable_lines <= column_enable_lines;
                             
                            if (CONV_SHIFTS_BITS < BUFFER_SIZE_BITS) then  
                                output_queues_size_send(BUFFER_SIZE_BITS-1 downto CONV_SHIFTS_BITS) <= (others => '0');
                            end if;
                            output_queues_size_send(CONV_SHIFTS_BITS-1 downto 0) <= matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB);
                        
                            matrix_current_requantization_shift <=  matrix_control_bus(MATRIX_CONTROL_REQUANTIZATION_SHIFT_MSB downto MATRIX_CONTROL_REQUANTIZATION_SHIFT_LSB);
                        end if;
                        
                        for r in 0 to DEPTH-1 loop 
                            for c in 0 to DEPTH-1 loop 
                                    enables_matrix(r,c) <= weight_enable_lines(r) and column_enable_lines(c);
                            end loop; 
                        end loop;
                    
                    elsif (matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) = MATRIX_COMMAND_INIT) then 
                        for r in 0 to DEPTH-1 loop 
                            for c in 0 to DEPTH-1 loop 
                                    enables_matrix(r,c) <= '0';
                                    forward_enables_matrix(r,c) <= '0';
                            end loop; 
                        end loop;
                        output_buffers_send_lines <= (others => '0');
                        activation_buffers_send_lines <= (others => '0');
                        weight_buffers_send_lines <= (others => '0');
                        bias_buffers_send_lines <= (others => '0');
                    end if; 
                else 
                    control_interconnect_ports_in(0,0)(PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB) <= (others => '0');
                    control_interconnect_ports_in(0,0)(PE_CONV_SHIFTS_MSB downto PE_CONV_SHIFTS_LSB) <= (others => '0');
                    control_interconnect_ports_in(0,0)(PE_ACTIVATIONS_CLEAR) <= '0';
                    control_interconnect_ports_in(0,0)(PE_WEIGHTS_CLEAR) <= '0';
                    control_interconnect_ports_in(0,0)(PE_INIT) <= '0';
                    control_interconnect_ports_in(0,0)(PE_PROCESS_START) <= '0';
                    control_interconnect_ports_in(0,0)(PE_PROCESS_TYPE) <= '0';
                    
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
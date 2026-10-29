library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.PE_MATRIX_PARAMETERS.ALL;


entity PE_matrix is 
    Port ( 
        clk:                    in STD_LOGIC;  
        reset:                  in STD_LOGIC;                 
        
        matrix_control_bus:              in MATRIX_CONTROL_INTERFACE;
        matrix_status_bus:               out MATRIX_STATUS_INTERFACE;
        
        weights_data_in:                 in MATRIX_WEIGHTS_DATA_INTERFACE; 
        weights_control_buffer:          in MATRIX_WEIGHTS_CONTROL_INTERFACE; 
        
        activations_data_in:             in MATRIX_ACTIVATIONS_DATA_INTERFACE; 
        activations_control_buffer:      in MATRIX_ACTIVATIONS_CONTROL_INTERFACE;
        
        outputs_data_in:                 in MATRIX_OUTPUTS_DATA_INTERFACE; 
        outputs_data_out:                out MATRIX_OUTPUTS_DATA_INTERFACE;
        outputs_control_buffer:          in MATRIX_OUTPUTS_CONTROL_INTERFACE
        
        
        
    );
end PE_matrix;

architecture Behavioral of PE_matrix is 
    signal weight_interconnect_ports_in,weight_interconnect_ports_out: MATRIX_INTERCONNECT_DATA; 
    signal activation_interconnect_ports_in,activation_interconnect_ports_out: MATRIX_INTERCONNECT_DATA; 
    signal accumulator_interconnect_ports_in,accumulator_interconnect_ports_out: MATRIX_INTERCONNECT_ACCUMULATOR;
    signal control_interconnect_ports_in,control_interconnect_ports_out: MATRIX_INTERCONNECT_CONTROL; 
    signal status_interconnect_ports_in, status_interconnect_ports_out: MATRIX_INTERCONNECT_STATUS;
    
    type PE_ENABLES_MATRIX is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC;
    signal enables_matrix:           PE_ENABLES_MATRIX;
    signal activation_lines_enables: STD_LOGIC_VECTOR(ACTIVATION_LINES-1 downto 0);
    signal column_lines_enables:     STD_LOGIC_VECTOR(DEPTH-1 downto 0);
    
    type ACCUMULATION_MULTIPLEXERS is array (ACCUMULATION_LINES-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal accumulation_buffer_valid_in: STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal accumulation_mux: ACCUMULATION_MULTIPLEXERS;
    
    type MATRIX_DONE_LINES is array (DEPTH-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal done_bits:  MATRIX_DONE_LINES;
    
    signal done_lines: STD_LOGIC_VECTOR(DEPTH-1 downto 0);
    
    component buffer_unit is
        Generic (
            DATA_SIZE: INTEGER := 8;
            COUNTER_SIZE: INTEGER := 3
        );
        Port (         
            clk:        in STD_LOGIC;
            reset:      in STD_LOGIC;
        
            init:       in STD_LOGIC;
            add_in:     in STD_LOGIC;
            
            step_in:    in STD_LOGIC;
            send_in:    in STD_LOGIC;
            counter_in: in STD_LOGIC_VECTOR(COUNTER_SIZE-1 downto 0);
            data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
             
            data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            valid_out:  out STD_LOGIC;
            ready_out:  out STD_LOGIC
    
        );
    end component;
    component PE is 
        Port ( 
            clk:                    in STD_LOGIC;  
            reset:                  in STD_LOGIC;   
            enable:                 in STD_LOGIC;              
            
            control_in:             in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
            status_in:              in STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
            weight_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_in:          in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_in:         in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            
            control_out:            out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
            status_out:             out STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
            weight_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
            activation_out:         out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_out:        out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0)
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
            
            enables_matrix(r,c) <= activation_lines_enables(r+c) and column_lines_enables(c);
            done_bits(c)(r) <= status_interconnect_ports_out(r,c)(DONE_BIT);
            
            weight_routing: if (c+1<DEPTH) generate 
                weight_interconnect_ports_in(r,c+1) <= weight_interconnect_ports_out(r,c);
            end generate; 
            
            accumulators_routing: if (r>0) generate 
                accumulator_interconnect_ports_in(r-1,c) <= accumulator_interconnect_ports_out(r,c);
                status_interconnect_ports_in(r-1,c)(ACCUMULATOR_VALID_BIT)<= status_interconnect_ports_out(r,c)(ACCUMULATOR_VALID_BIT);
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
        output_buffer: buffer_unit 
            Generic map (
                DATA_SIZE => ACCUMULATOR_SIZE,
                COUNTER_SIZE => BUFFER_COUNTERS_SIZE
            )
            Port map (
                clk => clk, 
                reset => reset,
                init => matrix_control_bus(MATRIX_CONTROL_ACTIVATION_BUFFERS_INIT_BIT),
                add_in => accumulation_buffer_valid_in(i),
                
                step_in =>  matrix_control_bus(MATRIX_CONTROL_SEND_OUTPUT_BUFFERS_BIT),
                send_in =>  matrix_control_bus(MATRIX_CONTROL_ACTIVATION_BUFFERS_INIT_BIT),
                counter_in(BUFFER_COUNTERS_SIZE-1 downto QUEUE_COUNTERS_SIZE) => (others => '0'),
                counter_in(QUEUE_COUNTERS_SIZE-1 downto 0) => matrix_control_bus(MATRIX_CONTROL_SEND_OUTPUT_SIZE_MSB downto MATRIX_CONTROL_SEND_OUTPUT_SIZE_LSB),
                data_in => accumulator_interconnect_ports_out(0,i),
                data_out => outputs_data_out(i),
                valid_out => open,
                ready_out => matrix_status_bus(MATRIX_STATUS_OUTPUTS_READY_LSB+i)
            );
        
        accumulator_interconnect_ports_in(DEPTH-1,i) <= (others => '0');
        status_interconnect_ports_in(DEPTH-1,i)(ACCUMULATOR_VALID_BIT) <= '1';

    end generate; 
    
    weight_interface_routing: for i in 0 to (WEIGHT_LINES-1) generate 
        weight_buffer: buffer_unit 
            Generic map (
                DATA_SIZE => DATA_SIZE,
                COUNTER_SIZE => BUFFER_COUNTERS_SIZE
            )
            Port map (
                clk => clk, 
                reset => reset,
                init => matrix_control_bus(MATRIX_CONTROL_WEIGHT_BUFFERS_INIT_BIT),
                add_in =>  weights_control_buffer(i)(BUFFER_INTERFACE_ADD_BIT),
                step_in =>  control_interconnect_ports_in(i,0)(WEIGHT_VALID_BIT),
                send_in =>  matrix_control_bus(MATRIX_CONTROL_SEND_WEIGHT_BUFFERS_BIT),
                counter_in(BUFFER_COUNTERS_SIZE-1 downto QUEUE_COUNTERS_SIZE) => (others => '0'),
                counter_in(QUEUE_COUNTERS_SIZE-1 downto 0) => matrix_control_bus(MATRIX_CONTROL_SEND_WEIGHT_SIZE_MSB downto MATRIX_CONTROL_SEND_WEIGHT_SIZE_LSB),
                data_in => weights_data_in(i),
                data_out => weight_interconnect_ports_in(i,0),
                valid_out => control_interconnect_ports_in(i,0)(WEIGHT_VALID_BIT),
                ready_out => matrix_status_bus(MATRIX_STATUS_WEIGHTS_READY_LSB+i)
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
                    COUNTER_SIZE => BUFFER_COUNTERS_SIZE
                )
                Port map (
                    clk => clk, 
                    reset => reset,
                    init => matrix_control_bus(MATRIX_CONTROL_ACTIVATION_BUFFERS_INIT_BIT),
                    add_in =>  activations_control_buffer(i)(BUFFER_INTERFACE_ADD_BIT),
                    step_in =>  control_interconnect_ports_in(ROW,COL)(ACTIVATION_VALID_BIT),
                    send_in =>  matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_BUFFERS_BIT),
                    counter_in(BUFFER_COUNTERS_SIZE-1 downto QUEUE_COUNTERS_SIZE) => (others => '0'),
                    counter_in(QUEUE_COUNTERS_SIZE-1 downto 0) => matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_SIZE_MSB downto MATRIX_CONTROL_SEND_ACTIVATION_SIZE_LSB),
                    data_in => activations_data_in(i),
                    data_out => activation_interconnect_ports_in(ROW,COL),
                    valid_out => control_interconnect_ports_in(i,0)(ACTIVATION_VALID_BIT),
                    ready_out => matrix_status_bus(MATRIX_STATUS_ACTIVATIONS_READY_LSB+i)
                );
        end generate; 
        last_rows: if (i>=DEPTH) generate
            activation_buffer: buffer_unit 
                Generic map (
                    DATA_SIZE => DATA_SIZE,
                    COUNTER_SIZE => BUFFER_COUNTERS_SIZE
                )
                Port map (
                    clk => clk, 
                    reset => reset,
                    init => matrix_control_bus(MATRIX_CONTROL_ACTIVATION_BUFFERS_INIT_BIT),
                    add_in =>  activations_control_buffer(i)(BUFFER_INTERFACE_ADD_BIT),
                    step_in =>  control_interconnect_ports_in(ROW,COL)(ACTIVATION_VALID_BIT),
                    send_in =>  matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_BUFFERS_BIT),
                    counter_in(BUFFER_COUNTERS_SIZE-1 downto QUEUE_COUNTERS_SIZE) => (others => '0'),
                    counter_in(QUEUE_COUNTERS_SIZE-1 downto 0) => matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_SIZE_MSB downto MATRIX_CONTROL_SEND_ACTIVATION_SIZE_LSB),
                    data_in => activations_data_in(i),
                    data_out => activation_interconnect_ports_in(ROW,COL),
                    valid_out => open,
                    ready_out => matrix_status_bus(MATRIX_STATUS_ACTIVATIONS_READY_LSB+i)
                );
        end generate; 

    end generate; 
    
    control_interface_routing: for i in 0 to (CONTROL_LINES-1) generate 
        control_interconnect_ports_in(i,0)(ACTIVATION_SKIP_MS_BIT downto ACTIVATION_SKIP_LS_BIT) <= matrix_control_bus(MATRIX_CONTROL_ROW_SKIP_MSB downto MATRIX_CONTROL_ROW_SKIP_LSB);      
        control_interconnect_ports_in(i,0)(ACCUMULATIONS_NUMBER_MS_BIT downto ACCUMULATIONS_NUMBER_LS_BIT) <= matrix_control_bus(MATRIX_CONTROL_ROW_RESULTS_MSB downto MATRIX_CONTROL_ROW_RESULTS_LSB); 
        control_interconnect_ports_in(i,0)(ACTIVATION_INIT_BIT) <= matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_BUFFERS_BIT);
        control_interconnect_ports_in(i,0)(WEIGHT_INIT_BIT) <= matrix_control_bus(MATRIX_CONTROL_SEND_WEIGHT_BUFFERS_BIT);
        control_interconnect_ports_in(i,0)(ACCUMULATOR_INIT_BIT) <= matrix_control_bus(MATRIX_CONTROL_SEND_OUTPUT_BUFFERS_BIT);
        control_interconnect_ports_in(i,0)(PROCESS_ENABLE_BIT) <= matrix_control_bus(MATRIX_CONTROL_PROCESS_ENABLE_BIT);
        control_interconnect_ports_in(i,0)(PROCESS_TYPE_BIT) <= matrix_control_bus(MATRIX_CONTROL_PROCESS_TYPE_BIT);
    end generate; 
    
    enable_process: process(clk)
    begin
        if (rising_edge(clk)) then 
            if (reset = '1') then
                activation_lines_enables <= (others => '0'); 
                column_lines_enables <= (others => '0');
    
            else 
                for r in 0 to DEPTH-1 loop 
                    if (r<UNSIGNED(matrix_control_bus(MATRIX_CONTROL_ROWS_ENABLE_MSB downto MATRIX_CONTROL_ROWS_ENABLE_LSB))) then 
                        activation_lines_enables(r) <= '1'; 
                    else 
                        activation_lines_enables(r) <= '0'; 
                    end if; 
                end loop;
                    
                for c in 0 to DEPTH-1 loop
                    if (c<UNSIGNED(matrix_control_bus(MATRIX_CONTROL_COLS_ENABLE_MSB downto MATRIX_CONTROL_COLS_ENABLE_LSB))) then 
                        column_lines_enables(c) <= '1'; 
                    else 
                        column_lines_enables(c) <= '0'; 
                    end if; 
                end loop;
                
                
            end if;  
        end if;
    end process;
    
    matrix_status_bus(MATRIX_STATUS_DONE_MSB downto MATRIX_STATUS_DONE_LSB) <= done_lines;
    
    ready_process: process(clk)
        variable done: STD_LOGIC;
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1') then
                done_lines <= (others => '0');
            else 
                for l in 0 to DEPTH-1 loop 
                    done := '1';
                    for i in 0 to DEPTH-1 loop
                        done := done and done_bits(l)(i);
                    end loop;
                    
                    if (done = '1') then 
                        done_lines(l) <= '1';
                    else 
                        done_lines(l) <= '0';
                    end if;
                end loop;

            end if;  
        end if;
    end process;
    
    
end architecture;
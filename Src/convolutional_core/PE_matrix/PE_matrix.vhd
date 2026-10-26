library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_MATRIX_PARAMETERS.ALL;


entity PE_matrix is 
    Port ( 
        clk:                    in STD_LOGIC;  
        reset:                  in STD_LOGIC;                 
        
        matrix_control_in:               in MATRIX_CONTROL_INTERFACE;
        
        weights_data_in:                 in MATRIX_WEIGHTS_DATA_INTERFACE; 
        weights_control_bus:             in MATRIX_WEIGHTS_CONTROL_INTERFACE; 
        weights_status_bus:              out MATRIX_WEIGHTS_STATUS_INTERFACE;
        
        activations_data_in:             in MATRIX_ACTIVATIONS_DATA_INTERFACE; 
        activations_control_bus:         in MATRIX_ACTIVATIONS_CONTROL_INTERFACE;
        activations_status_bus:          out MATRIX_ACTIVATIONS_STATUS_INTERFACE;
        
        outputs_data_in:                 in MATRIX_OUTPUTS_DATA_INTERFACE; 
        outputs_data_out:                out MATRIX_OUTPUTS_DATA_INTERFACE;
        outputs_control_bus:             in MATRIX_OUTPUTS_CONTROL_INTERFACE;
        outputs_status_bus:              out MATRIX_OUTPUTS_STATUS_INTERFACE
        
        
    );
end PE_matrix;

architecture Behavioral of PE_matrix is 
    signal weight_interconnect_ports_in,weight_interconnect_ports_out: MATRIX_INTERCONNECT_DATA; 
    signal activation_interconnect_ports_in,activation_interconnect_ports_out: MATRIX_INTERCONNECT_DATA; 
    signal accumulator_interconnect_ports_in,accumulator_interconnect_ports_out: MATRIX_INTERCONNECT_ACCUMULATOR;
    signal control_interconnect_ports_in,control_interconnect_ports_out: MATRIX_INTERCONNECT_CONTROL; 
    signal status_interconnect_ports_in, status_interconnect_ports_out: MATRIX_INTERCONNECT_STATUS;
    
    
    
    type ACCUMULATION_MULTIPLEXERS is array (ACCUMULATION_LINES-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal accumulation_buffer_valid_in: STD_LOGIC_VECTOR(ACCUMULATION_LINES-1 downto 0);
    signal accumulation_mux: ACCUMULATION_MULTIPLEXERS;
    
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
           
            
            weight_routing: if (c+1<DEPTH) generate 
                weight_interconnect_ports_in(r,c+1) <= weight_interconnect_ports_out(r,c);
            end generate; 
            
            accumulators_routing: if (r+1<DEPTH) generate 
                accumulator_interconnect_ports_in(r+1,c) <= accumulator_interconnect_ports_out(r,c);
                status_interconnect_ports_in(r+1,c)<= status_interconnect_ports_out(r,c);
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
                init => outputs_control_bus(i)(BUFFER_INTERFACE_INIT_BIT),
                add_in => accumulation_buffer_valid_in(i),
                
                
                step_in =>  status_interconnect_ports_in(1,i)(ACCUMULATOR_VALID_BIT),
                send_in =>  outputs_control_bus(i)(BUFFER_INTERFACE_SEND_BIT),
                counter_in(BUFFER_COUNTERS_SIZE-1 downto QUEUE_COUNTERS_SIZE) => (others => '0'),
                counter_in(QUEUE_COUNTERS_SIZE-1 downto 0) => outputs_control_bus(i)(BUFFER_INTERFACE_SEND_SIZE_MSB downto BUFFER_INTERFACE_SEND_SIZE_LSB),
                data_in => accumulation_mux(i),
                data_out => accumulator_interconnect_ports_in(0,i),
                valid_out => open,
                ready_out => outputs_status_bus(i)(BUFFER_STATUS_READY_BIT)
            );
        
        accumulation_buffer_valid_in(i) <= outputs_control_bus(i)(BUFFER_INTERFACE_ADD_BIT) or status_interconnect_ports_out(DEPTH-1, i)(ACCUMULATOR_VALID_BIT);
        accumulation_mux(i) <= outputs_data_in(i) when (outputs_control_bus(i)(BUFFER_INTERFACE_ADD_BIT) = '1') else accumulator_interconnect_ports_out(DEPTH-1,i);
        
        outputs_data_out(i) <= accumulator_interconnect_ports_out(DEPTH-1,i);
        
        status_interconnect_ports_in(0,i) <= "1";
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
                init => weights_control_bus(i)(BUFFER_INTERFACE_INIT_BIT),
                add_in =>  weights_control_bus(i)(BUFFER_INTERFACE_ADD_BIT),
                step_in =>  control_interconnect_ports_in(i,0)(WEIGHT_VALID_BIT),
                send_in =>   weights_control_bus(i)(BUFFER_INTERFACE_SEND_BIT),
                counter_in(BUFFER_COUNTERS_SIZE-1 downto QUEUE_COUNTERS_SIZE) => (others => '0'),
                counter_in(QUEUE_COUNTERS_SIZE-1 downto 0) => weights_control_bus(i)(BUFFER_INTERFACE_SEND_SIZE_MSB downto BUFFER_INTERFACE_SEND_SIZE_LSB),
                data_in => weights_data_in(i),
                data_out => weight_interconnect_ports_in(i,0),
                valid_out => open,
                ready_out => weights_status_bus(i)(BUFFER_STATUS_READY_BIT)
            );
    end generate; 
    
    activation_interface_routing: for i in 0 to (ACTIVATION_LINES-1) generate 
        constant ROW: INTEGER := i when (i<DEPTH) else (DEPTH-1); 
        constant COL: INTEGER := 0 when (i<DEPTH) else (i-DEPTH+1);
    begin 
        activation_buffer: buffer_unit 
            Generic map (
                DATA_SIZE => DATA_SIZE,
                COUNTER_SIZE => BUFFER_COUNTERS_SIZE
            )
            Port map (
                clk => clk, 
                reset => reset,
                init => activations_control_bus(i)(BUFFER_INTERFACE_INIT_BIT),
                add_in =>  activations_control_bus(i)(BUFFER_INTERFACE_ADD_BIT),
                step_in =>  control_interconnect_ports_in(ROW,COL)(ACTIVATION_VALID_BIT),
                send_in =>   activations_control_bus(i)(BUFFER_INTERFACE_SEND_BIT),
                counter_in(BUFFER_COUNTERS_SIZE-1 downto QUEUE_COUNTERS_SIZE) => (others => '0'),
                counter_in(QUEUE_COUNTERS_SIZE-1 downto 0) => activations_control_bus(i)(BUFFER_INTERFACE_SEND_SIZE_MSB downto BUFFER_INTERFACE_SEND_SIZE_LSB),
                data_in => activations_data_in(i),
                data_out => activation_interconnect_ports_in(ROW,COL),
                valid_out => open,
                ready_out => activations_status_bus(i)(BUFFER_STATUS_READY_BIT)
            );

    end generate; 
    
    control_interface_routing: for i in 0 to (CONTROL_LINES-1) generate 
        control_interconnect_ports_in(i,0) <= matrix_control_in(i);             
    end generate; 
    
end architecture;
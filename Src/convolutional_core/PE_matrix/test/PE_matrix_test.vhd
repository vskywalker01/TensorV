library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_MATRIX_PARAMETERS.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PE_matrix_test is
--  Port ( );
end PE_matrix_test;

architecture Behavioral of PE_matrix_test is
    component PE_matrix is 
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
    end component;
    
    procedure send_matrix_command(
        constant activation_y_size:      in INTEGER := 0;
        constant activation_x_size:      in INTEGER := 0;
        constant weight_y_size:          in INTEGER := 0;
        constant weight_x_size:          in INTEGER := 0;
        constant conv_shifts_x:          in INTEGER := 0;
        constant conv_shifts_y:          in INTEGER := 0;  
        constant conv_skips:             in INTEGER := 0; 
        constant requantization_shift:   in INTEGER := 0;
        constant load_activations:       in STD_LOGIC := '0';
        constant load_weights:           in STD_LOGIC := '0'; 
        constant load_bias:              in STD_LOGIC := '0'; 
        constant clear_activations:      in STD_LOGIC := '0';
        constant clear_weights:          in STD_LOGIC := '0';
        constant command_type:           in STD_LOGIC_VECTOR(MATRIX_COMMAND_SIZE-1 downto 0):= MATRIX_COMMAND_INIT;
        
        signal clk:                     in STD_LOGIC;
        signal matrix_control_bus:      out MATRIX_CONTROL_INTERFACE
    ) is 
    begin 
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_X_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(activation_x_size,ACTIVATION_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_Y_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(activation_y_size,ACTIVATION_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_X_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(weight_x_size,WEIGHT_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_Y_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(weight_y_size,WEIGHT_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(conv_shifts_x,CONV_SHIFTS_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_Y_MSB downto MATRIX_CONTROL_CONV_SHIFTS_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(conv_shifts_y,CONV_SHIFTS_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SKIP_X_MSB downto MATRIX_CONTROL_CONV_SKIP_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(conv_skips,CONV_SKIP_BITS));
        matrix_control_bus(MATRIX_CONTROL_REQUANTIZATION_SHIFT_MSB downto MATRIX_CONTROL_REQUANTIZATION_SHIFT_LSB) <= STD_LOGIC_VECTOR(to_unsigned(requantization_shift,REQUANTIZATION_SHIFT_BITS));
        matrix_control_bus(MATRIX_CONTROL_LOAD_ACTIVATIONS_FLAG) <= load_activations;
        matrix_control_bus(MATRIX_CONTROL_LOAD_WEIGHTS_FLAG) <= load_weights;
        matrix_control_bus(MATRIX_CONTROL_LOAD_BIAS_FLAG) <= load_bias;
        matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG) <= clear_activations;
        matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG) <= clear_weights;
        matrix_control_bus(MATRIX_CONTROL_COMMAND_VALID) <= '1';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) <= command_type;
        
        wait until falling_edge(clk);
        
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_X_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_X_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_Y_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_Y_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_X_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_X_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_Y_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_Y_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_Y_MSB downto MATRIX_CONTROL_CONV_SHIFTS_Y_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_CONV_SKIP_X_MSB downto MATRIX_CONTROL_CONV_SKIP_X_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_REQUANTIZATION_SHIFT_MSB downto MATRIX_CONTROL_REQUANTIZATION_SHIFT_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_LOAD_ACTIVATIONS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_LOAD_WEIGHTS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_LOAD_BIAS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_VALID) <= '0';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) <= (others => '0');
    end procedure;
    
    procedure send_buffers_command(
        constant init_activations:               in STD_LOGIC := '0'; 
        constant init_weights:                   in STD_LOGIC := '0'; 
        constant init_outputs:                   in STD_LOGIC := '0'; 
        constant init_bias:                      in STD_LOGIC := '0'; 
        constant add_weight:                     in STD_LOGIC := '0'; 
        constant add_activation:                 in STD_LOGIC := '0'; 
        constant add_bias:                       in STD_LOGIC := '0'; 
        constant add_weight_address:             in INTEGER := 0; 
        constant add_activation_address:         in INTEGER := 0;
        constant add_bias_address:               in INTEGER := 0;  
        constant get_output:                     in STD_LOGIC := '0'; 
        constant get_output_address:             in INTEGER := 0;
        signal matrix_buffers_control_bus:     out MATRIX_BUFFERS_CONTROL_INTERFACE
    ) is 
    begin
        matrix_buffers_control_bus(MATRIX_BUFFERS_ACTIVATIONS_INIT) <= init_activations;
        matrix_buffers_control_bus(MATRIX_BUFFERS_WEIGHTS_INIT) <= init_weights;
        matrix_buffers_control_bus(MATRIX_BUFFERS_OUTPUTS_INIT) <= init_outputs;
        matrix_buffers_control_bus(MATRIX_BUFFERS_BIAS_INIT) <= init_bias;             
        if (add_weight = '1') then 
            for i in 0 to (WEIGHT_LINES)-1 loop 
                if (i = add_weight_address) then 
                    matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_WEIGHTS_LSB+i) <= '1';
                else 
                    matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_WEIGHTS_LSB+i) <= '0';
                end if;
            end loop; 
        else
            matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_WEIGHTS_MSB downto MATRIX_BUFFERS_ADD_WEIGHTS_LSB) <= (others => '0');
        end if; 
        
        if (add_activation = '1') then 
            for i in 0 to (ACTIVATION_LINES)-1 loop 
                if (i = add_activation_address) then 
                    matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_ACTIVATIONS_LSB+i) <= '1';
                else 
                    matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_ACTIVATIONS_LSB+i) <= '0';
                end if;
            end loop; 
        else
            matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_ACTIVATIONS_MSB downto MATRIX_BUFFERS_ADD_ACTIVATIONS_LSB) <= (others => '0');
        end if; 
        
        if (add_bias = '1') then 
            for i in 0 to (ACCUMULATION_LINES)-1 loop 
                if (i = add_bias_address) then 
                    matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_BIAS_LSB+i) <= '1';
                else 
                    matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_BIAS_LSB+i) <= '0';
                end if;
            end loop; 
        else
            matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_BIAS_MSB downto MATRIX_BUFFERS_ADD_BIAS_LSB) <= (others => '0');
        end if; 
        
        if (get_output = '1') then 
            for i in 0 to (ACCUMULATION_LINES)-1 loop 
                if (i = get_output_address) then 
                    matrix_buffers_control_bus(MATRIX_BUFFERS_GET_OUTPUTS_LSB+i) <= '1';
                else 
                    matrix_buffers_control_bus(MATRIX_BUFFERS_GET_OUTPUTS_LSB+i) <= '0';
                end if;
            end loop; 
        else
            matrix_buffers_control_bus(MATRIX_BUFFERS_GET_OUTPUTS_MSB downto MATRIX_BUFFERS_GET_OUTPUTS_LSB) <= (others => '0');
        end if;      
    end procedure; 
    
    signal clk, reset: STD_LOGIC;
    signal weights_data_in:                     MATRIX_WEIGHTS_DATA_INTERFACE;
    signal activations_data_in:                 MATRIX_ACTIVATIONS_DATA_INTERFACE;
    signal bias_data_in:                        MATRIX_BIAS_DATA_INTERFACE;
    signal outputs_data_out:                    MATRIX_OUTPUTS_DATA_INTERFACE;
    
    signal matrix_control_bus:                  MATRIX_CONTROL_INTERFACE;
    signal matrix_status_bus:                   MATRIX_STATUS_INTERFACE;
    
    signal matrix_buffers_control_bus:          MATRIX_BUFFERS_CONTROL_INTERFACE; 
    signal matrix_buffers_status_bus:           MATRIX_BUFFERS_STATUS_INTERFACE;

    signal data_load_signal:                    STD_LOGIC; 
    signal data_load_done:                      STD_LOGIC; 
    signal data_unload_signal:                  STD_LOGIC; 
    signal data_unload_done:                    STD_LOGIC; 
    
    type SAMPLE_MATRIX is array (natural range <>,natural range <>) of INTEGER; 
    constant TEST_MATRIX_SIZE: INTEGER := 5;
    constant TEST_WEIGHT_SIZE: INTEGER := 3;
    constant TEST_RESULT_SIZE: INTEGER := 3;
    constant TEST_MATRIX: SAMPLE_MATRIX(0 to TEST_MATRIX_SIZE-1, 0 to TEST_MATRIX_SIZE-1) := (
       (1,  2,  0,  -1, 3),
       (4,  0,  2,  -3, 1),
       (-2, 1,  3,  0,  4),
       (0,  -3, 1,  2, -1),
       (3,  1,  -2, 0,  2)
    );
    
    constant TEST_BIAS: SAMPLE_MATRIX(0 to TEST_RESULT_SIZE-1, 0 to TEST_RESULT_SIZE-1) := (
       (-1, 2,  -3),
       (-1, 2,  -3),
       (-1, 2,  -3)
    );
    
    constant TEST_WEIGHT: SAMPLE_MATRIX(0 to TEST_WEIGHT_SIZE-1, 0 to TEST_WEIGHT_SIZE-1) := (
        ( 1,    0,   -1),
        ( 2,    1,    0),
        ( -1,   2,    1)
    );
    
    constant SAMPLE_RESULTS: SAMPLE_MATRIX(0 to TEST_RESULT_SIZE-1, 0 to TEST_RESULT_SIZE-1) := (
        ( 15, 12, -1),
        ( -7, 17,  6),
        ( -12,  -7,  4)
    );
begin
    
    matrix: PE_matrix 
        port map (
            clk => clk,  
            reset => reset,               
            
            weights_data_in => weights_data_in,
            activations_data_in => activations_data_in, 
            bias_data_in => bias_data_in, 
            outputs_data_out => outputs_data_out, 
            matrix_control_bus => matrix_control_bus,
            matrix_status_bus => matrix_status_bus,
            matrix_buffers_status_bus => matrix_buffers_status_bus, 
            matrix_buffers_control_bus => matrix_buffers_control_bus
            
        );

    clock: process 
    begin 
        loop 
            clk <= '1';
            wait for 5ns; 
            clk <= '0'; 
            wait for 5ns;
        end loop; 
    end process; 
    
    data_test_process: process         
    begin 
        data_load_done <= '0';
        data_unload_done <= '0';
                
        send_buffers_command(
            matrix_buffers_control_bus => matrix_buffers_control_bus
        );

        wait until rising_edge(data_load_signal); 
        send_buffers_command(
              init_activations => '1',
              init_weights => '1',
              init_bias => '1', 
              init_outputs => '1',
              matrix_buffers_control_bus => matrix_buffers_control_bus
        );
        
        wait until falling_edge(clk);
    
        for r in 0 to (TEST_MATRIX_SIZE)-1 loop 
            for c in 0 to (TEST_MATRIX_SIZE)-1 loop        
                if (c < TEST_WEIGHT_SIZE and r < TEST_WEIGHT_SIZE and c < TEST_RESULT_SIZE and r < TEST_RESULT_SIZE) then 
                    weights_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(r,c),DATA_SIZE));
                    activations_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(r,c),DATA_SIZE)); 
                    bias_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_BIAS(r,c),DATA_SIZE)); 
                    send_buffers_command(
                          add_activation => '1',
                          add_weight => '1',
                          add_bias => '1',
                          add_activation_address => r, 
                          add_weight_address => r, 
                          add_bias_address => r, 
                          matrix_buffers_control_bus => matrix_buffers_control_bus
                    );
                elsif (c < TEST_WEIGHT_SIZE and r < TEST_WEIGHT_SIZE) then 
                    weights_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(r,c),DATA_SIZE));
                    activations_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(r,c),DATA_SIZE)); 
                    send_buffers_command(
                          add_activation => '1',
                          add_weight => '1',
                          add_activation_address => r, 
                          add_weight_address => r, 
                          matrix_buffers_control_bus => matrix_buffers_control_bus
                    );
                elsif (c < TEST_RESULT_SIZE and r < TEST_RESULT_SIZE) then 
                    bias_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_BIAS(r,c),DATA_SIZE)); 
                    activations_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(r,c),DATA_SIZE)); 
                    send_buffers_command(
                          add_activation => '1',
                          add_bias => '1',
                          add_activation_address => r,  
                          add_bias_address => r, 
                          matrix_buffers_control_bus => matrix_buffers_control_bus
                    );
                    
                else 
                    activations_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(r,c),DATA_SIZE)); 
                    send_buffers_command(
                          add_activation => '1',
                          add_activation_address => r, 
                          matrix_buffers_control_bus => matrix_buffers_control_bus
                    );
                end if; 
                wait until falling_edge(clk);
            end loop; 
        end loop; 
        send_buffers_command(
              matrix_buffers_control_bus => matrix_buffers_control_bus
        );
        data_load_done <= '1';
        
        wait until rising_edge(data_unload_signal);
        wait until falling_edge(clk);
        
        for l in 0 to (TEST_MATRIX_SIZE)-1 loop 
            while (matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_OUTPUT_READY_LSB+l) = '0') loop 
                send_buffers_command(
                    get_output => '1',
                    get_output_address => l,
                    matrix_buffers_control_bus => matrix_buffers_control_bus
                );           
                
                wait until falling_edge(clk);
            end loop;
        end loop;
        
        send_buffers_command(
              matrix_buffers_control_bus => matrix_buffers_control_bus
        );
        wait;
    end process; 
    
    control_test_process: process 
    begin  
        reset <= '1'; 
        data_load_signal <= '0'; 
        data_unload_signal <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        reset <= '0'; 
        
        send_matrix_command(
            command_type => MATRIX_COMMAND_INIT,
            matrix_control_bus => matrix_control_bus,
            clk => clk
        );
        
        wait until falling_Edge(clk);
        
        data_load_signal <= '1'; 
        
        wait until rising_edge(data_load_done);
        wait until falling_edge(clk); 

        send_matrix_command(
            activation_y_size => TEST_MATRIX_SIZE,
            activation_x_size => TEST_MATRIX_SIZE, 
            weight_x_size => TEST_WEIGHT_SIZE,
            weight_y_size => TEST_WEIGHT_SIZE, 
            conv_shifts_x => TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,
            conv_shifts_y => TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,
            conv_skips => 1, 
            requantization_shift => 0,
            load_activations => '1',
            load_weights => '1', 
            load_bias => '0', 
            clear_activations => '1', 
            clear_weights => '1', 
            command_type => MATRIX_COMMAND_LOAD,
            matrix_control_bus => matrix_control_bus,
            clk => clk
        );
                
        wait until falling_edge(clk); 

        wait until (matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_ACTIVATIONS_READY_LSB)='1');        
        wait until falling_edge(clk); 
        
        send_matrix_command(
            activation_y_size => TEST_MATRIX_SIZE,
            activation_x_size => TEST_MATRIX_SIZE, 
            weight_x_size => TEST_WEIGHT_SIZE,
            weight_y_size => TEST_WEIGHT_SIZE, 
            conv_shifts_x => TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,
            conv_shifts_y => TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,
            conv_skips => 1, 
            requantization_shift => 0,
            load_activations => '0',
            load_weights => '0', 
            load_bias => '0', 
            clear_activations => '0', 
            clear_weights => '0', 
            command_type => MATRIX_COMMAND_COMPUTE,
            matrix_control_bus => matrix_control_bus,
            clk => clk
        );

        wait until (matrix_status_bus(MATRIX_STATUS_LINES_READY_LSB)='1');
        wait until falling_edge(clk);
  
        send_matrix_command(
            activation_y_size => TEST_MATRIX_SIZE,
            activation_x_size => TEST_MATRIX_SIZE, 
            weight_x_size => TEST_WEIGHT_SIZE,
            weight_y_size => TEST_WEIGHT_SIZE, 
            conv_shifts_x => TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,
            conv_shifts_y => TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,
            conv_skips => 1, 
            requantization_shift => 0,
            load_activations => '0',
            load_weights => '0', 
            load_bias => '1', 
            clear_activations => '0', 
            clear_weights => '0', 
            command_type => MATRIX_COMMAND_UNLOAD,
            matrix_control_bus => matrix_control_bus,
            clk => clk
        );               
                
        wait until falling_edge(clk);
        data_unload_signal <= '1'; 

        wait;
           
    end process; 
end Behavioral;

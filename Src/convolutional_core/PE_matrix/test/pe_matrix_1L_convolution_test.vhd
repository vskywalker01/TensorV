---- PE convolutional core testbench -----
-- This testbench performs the execution of a scheduling of one convolution by sending commands to the convolutional matrix core 

-- By considering the architecture of the convolutional core, the process of computing a convolution is divided in the following steps: 
--  *   input buffers loading phase -> the activation and weight matrices are loaded in the matrix buffers (not the convolutional cores)
--  *   bias buffers loading phase .> the biases, if needed, are loaded in the bias buffers
--  *   matrix loading phase -> the data tontained in the activation/weight buffers are loaded into the PE of the matrix 
--  *   matrix computing phase -> the PEs in the matrix proeed to compute the convolution
--  *   matrix unloading phase -> the results computed by the PEs are transferred into the output buffers 
--  *   output buffers unloading phase -> the results saved in the output buffers are transferred in the output lines.   

-- The matrix unloading phase and the matrix loading phase can be performed at the same time.
-- If we consider the bias and activation input lines as a single bus, we can rewrite the scheduling of the operations in the following order: 

--  buffer units        matrix 
--  Input loading        
--  Bias loading        matrix loading 
--                      matrix computing 
--                      matrix unloading 
--  output unloading    

-- If we schedule the computation of two matrices M1 and M2, we obtain

-- buffer units         matrix 
-- M1 input loading     
-- M1 bias loading      M! matrix loading 
-- M2 input loading     M! matrix computing            
-- M2 bias loading      M1 matrix unloading + M2 matrix loading
-- M1 output unloading  M2 matrix computing
--                      M2 matrix unloading
-- M2 output unloading

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_MATRIX_PARAMETERS.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pe_matrix_1L_convolution_test is
--  Port ( );
end pe_matrix_1L_convolution_test;

architecture Behavioral of pe_matrix_1L_convolution_test is
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
    
    -- The procedure send matrix_command sends a command to the convolutional matrix using its specific format 
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
        
        wait until rising_edge(clk);
        
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
    
    -- the send_buffer_command procedure sends a command to the buffer units using its specific format 
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
    
    -- signal used for interfacing the matrix 
    signal clk, reset: STD_LOGIC;
    signal weights_data_in:                     MATRIX_WEIGHTS_DATA_INTERFACE;
    signal activations_data_in:                 MATRIX_ACTIVATIONS_DATA_INTERFACE;
    signal bias_data_in:                        MATRIX_BIAS_DATA_INTERFACE;
    signal outputs_data_out:                    MATRIX_OUTPUTS_DATA_INTERFACE;
    
    signal matrix_control_bus:                  MATRIX_CONTROL_INTERFACE;
    signal matrix_status_bus:                   MATRIX_STATUS_INTERFACE;
    
    signal matrix_buffers_control_bus:          MATRIX_BUFFERS_CONTROL_INTERFACE; 
    signal matrix_buffers_status_bus:           MATRIX_BUFFERS_STATUS_INTERFACE;
    
    --signal used to synchronize the buffer unit process and the matrix scheduler process 
    signal inputs_load_signal:                      STD_LOGIC; 
    signal inputs_load_done:                        STD_LOGIC;
    signal bias_load_signal:                        STD_LOGIC;
    signal bias_load_done:                          STD_LOGIC;  
    signal results_unload_signal:                      STD_LOGIC; 
    signal results_unload_done:                        STD_LOGIC; 
    
    -- test matrices used for the testbenches 
    type SAMPLE_MATRIX is array (natural range <>,natural range <>) of INTEGER; 
    constant TEST_MATRIX_SIZE: INTEGER := 10;
    constant TEST_WEIGHT_SIZE: INTEGER := 3;
    constant TEST_RESULT_SIZE: INTEGER := 8;
    constant TEST_MATRIX: SAMPLE_MATRIX(0 to TEST_MATRIX_SIZE-1, 0 to TEST_MATRIX_SIZE-1) := (
        (3, 7, -4, 12, -1, 9, 3, 6, -8, 15),
        (11, -2, 6, 14, 0, 7, -5, 3, 10, -1),
        (-7, 5, 13, -2, 8, 1, 6, 11, -3, 4),
        (2, 8, -6, 10, 4, -3, 7, 1, 6, 12),
        (15, -1, 7, -8, 2, 11, 4, 9, -5, 3),
        (-3, 6, 12, 1, 9, 4, -7, 2, 8, 14),
        (8, -5, 1, 7, 13, 3, 6, -2, 4, 11),
        (-9, 3, 8, 10, -4, 6, 1, 12, 5, 2),
        (5, 11, -2, 7, 3, 9, 4, -6, 8, 1),
        (12, 0, 6, -8, 5, 2, 8, 3, -1, 7)
    );
  
    constant TEST_WEIGHT: SAMPLE_MATRIX(0 to TEST_WEIGHT_SIZE-1, 0 to TEST_WEIGHT_SIZE-1) := (
        (-1, 0, 1),
        (-2, 0, 2),
        (-3, 0, 3)
    );
    
    constant TEST_RESULTS: SAMPLE_MATRIX(0 to TEST_RESULT_SIZE-1, 0 to TEST_RESULT_SIZE-1) := (
        (43, 16,  0,  0,  0, 19,  0,  0),
        (11,  8, 14,  0,  0, 28,  0, 15),
        ( 0,  0,  0, 34, 10, 12,  0,  0),
        (21,  0,  0, 34,  0,  0, 26, 35),
        ( 1, 19, 25, 13,  0,  0, 15, 57),
        (52, 40,  0,  0,  0,  6, 23,  8),
        ( 6, 14,  3,  0,  6,  0, 18, 14),
        ( 0,  0,  0, 30, 16,  0,  0, 16)
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

    -- clock process 
    clock: process 
    begin 
        loop 
            clk <= '1';
            wait for 5ns; 
            clk <= '0'; 
            wait for 5ns;
        end loop; 
    end process; 
    
    -- This process simulates the buffer control unit. It uses the inputs/bias/outputs load/unload signals to be synchronized with the scheduler process.
    data_test_process: process         
        variable error_counter: INTEGER := 0;
    begin 
        -- after the reset, the done flags are cleared
        inputs_load_done <= '0';
        bias_load_done <= '0';
        results_unload_done <= '0';
                
        send_buffers_command(
            matrix_buffers_control_bus => matrix_buffers_control_bus
        );
        
        wait until rising_edge(inputs_load_signal); 
        
        -- when the inputs_load_signal command is received, the process sends a load command for the weights and activations 
        
        -- The buffers are cleared from eventual past results
        send_buffers_command(
              init_activations => '1',
              init_weights => '1',
              init_bias => '1', 
              init_outputs => '1',
              matrix_buffers_control_bus => matrix_buffers_control_bus
        );
        
        wait until rising_edge(clk);
 
        -- We send the weights and activations at the same time without stalls from the caches  
        for r in 0 to (TEST_MATRIX_SIZE)-1 loop 
            for c in 0 to (TEST_MATRIX_SIZE)-1 loop        
                if (c < TEST_WEIGHT_SIZE and r < TEST_WEIGHT_SIZE) then 
                    weights_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(r,c),DATA_SIZE));
                    activations_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(r,c),DATA_SIZE));  
                    send_buffers_command(
                          add_activation => '1',
                          add_weight => '1',
                          add_activation_address => r, 
                          add_weight_address => r, 
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
                wait until rising_edge(clk);
            end loop; 
        end loop; 
        send_buffers_command(
              matrix_buffers_control_bus => matrix_buffers_control_bus
        );
        
        inputs_load_done <= '1';

        wait until rising_edge(results_unload_signal);
        wait until rising_edge(clk); 
        
        -- if the unload signal is received, the process unloads the values from the output buffers and checks for eventual errors. 
        send_buffers_command(
              matrix_buffers_control_bus => matrix_buffers_control_bus
        );

        wait until rising_edge(clk);
        
        bias_load_done <= '0';
        
        for r in 0 to (TEST_RESULT_SIZE)-1 loop
            send_buffers_command(
                get_output => '1',
                get_output_address => r,
                matrix_buffers_control_bus => matrix_buffers_control_bus
            );
            wait until rising_edge(clk);
            
            for c in 0 to (TEST_RESULT_SIZE)-1 loop 
                wait until rising_edge(clk);
                if not(outputs_data_out = STD_LOGIC_VECTOR(TO_SIGNED(TEST_RESULTS(r,c),DATA_SIZE))) then 
                    report "Error during result verification of element ("
                        & integer'image(r)
                        & ","
                        & integer'image(c)
                        & ") \n Expected " 
                        & integer'image(TEST_RESULTS(r,c)) 
                        & ", got "
                        & integer'image(to_integer(SIGNED(outputs_data_out))) 
                    severity error; 
                    error_counter := error_counter +1;
                end if; 
 
                
            end loop; 
        end loop;
        
        results_unload_done <= '1';
        send_buffers_command(
              matrix_buffers_control_bus => matrix_buffers_control_bus
        );
        
        -- Test reports 
        if (error_counter = 0) then 
            report "test completed successfully :)";
        else 
            report "Test failed. Got "
                & integer'image(error_counter) 
                & " errors :("
            severity error;
        end if;

        wait;
        
        
        
    end process; 
    
    -- the control test process sends commands to the matrix and controls the buffer process 
    control_test_process: process 
    begin  
    
        reset <= '1'; 
        inputs_load_signal <= '0'; 
        bias_load_signal <= '0';
        results_unload_signal <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        reset <= '0'; 
        
        -- The process sends an INIT command to initialize the PEs 
        send_matrix_command(
            command_type => MATRIX_COMMAND_INIT,
            matrix_control_bus => matrix_control_bus,
            clk => clk
        );
        
        wait until rising_edge(clk);
        
        -- The process signals to the buffer process to load the inputs in the buffers and waits
        inputs_load_signal <= '1'; 
        
        wait until rising_edge(inputs_load_done);
        wait until rising_edge(clk); 
        
        -- When the buffer loading phase is completed, the process sends a LOAD command to move the input data into the PEs and waits
        inputs_load_signal <= '0';

        send_matrix_command(
            activation_y_size => TEST_MATRIX_SIZE,
            activation_x_size => TEST_MATRIX_SIZE, 
            weight_x_size => TEST_WEIGHT_SIZE,
            weight_y_size => TEST_WEIGHT_SIZE, 
            conv_shifts_x => TEST_RESULT_SIZE,
            conv_shifts_y => TEST_RESULT_SIZE,
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
                
        wait until rising_edge(clk); 
        
        wait until (matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_ACTIVATIONS_READY_LSB)='1');        
        
        -- when the ready signal is received from the input buffers, the process sends a bias load command to the buffer process and sends a 
        -- COMPUTE command to the matrix 
        wait until rising_edge(clk); 
 
        send_matrix_command(
            activation_y_size => TEST_MATRIX_SIZE,
            activation_x_size => TEST_MATRIX_SIZE, 
            weight_x_size => TEST_WEIGHT_SIZE,
            weight_y_size => TEST_WEIGHT_SIZE, 
            conv_shifts_x => TEST_RESULT_SIZE,
            conv_shifts_y => TEST_RESULT_SIZE,
            conv_skips => 1, 
            requantization_shift => 0,
            load_activations => '0',
            load_weights => '0', 
            load_bias => '0', 
            clear_activations => '0', 
            clear_weights => '0', 
            command_type => MATRIX_COMMAND_UNLOAD,
            matrix_control_bus => matrix_control_bus,
            clk => clk
        );               
        
        -- when the PEs are ready, the process sends a buffer unload command to the buffer process 
        wait until (matrix_status_bus(MATRIX_STATUS_LINES_READY_LSB)='1');
        wait until rising_edge(clk);
        results_unload_signal <= '1'; 

        wait;
           
    end process; 
end Behavioral;

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
    
    signal clk, reset: STD_LOGIC;
    signal weights_data_in:                     MATRIX_WEIGHTS_DATA_INTERFACE;
    signal activations_data_in:                 MATRIX_ACTIVATIONS_DATA_INTERFACE;
    signal bias_data_in:                        MATRIX_BIAS_DATA_INTERFACE;
    signal outputs_data_out:                    MATRIX_OUTPUTS_DATA_INTERFACE;
    
    signal matrix_control_bus:                  MATRIX_CONTROL_INTERFACE;
    signal matrix_status_bus:                   MATRIX_STATUS_INTERFACE;
    
    signal matrix_buffers_control_bus:          MATRIX_BUFFERS_CONTROL_INTERFACE; 
    signal matrix_buffers_status_bus:           MATRIX_BUFFERS_STATUS_INTERFACE;

    
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
    
    test: process 
        type SAMPLE_MATRIX is array (natural range <>,natural range <>) of INTEGER; 
        constant TEST_MATRIX: SAMPLE_MATRIX(0 to 4, 0 to 4) := (
            ( 20, -10,   5,  12,  -7),
            (  3,   8, -15,   6,  11),
            ( -4,   9,  13,  -2,  10),
            (  7,  -6,   4,  14, -12),
            (  5,   3,  -8,   6,   9)
        );
        
        constant TEST_MATRIX2: SAMPLE_MATRIX(0 to 4, 0 to 4) := (
            (  1,  2,  3,  4,  5),
            ( -8,  9, 10, 11, 12),
            ( 13, 14, 15, 16, -7),
            ( -6,  8,  1,  2,  3),
            ( -4,  5,  6,  7,  8)
        );
        
        constant TEST_WEIGHT: SAMPLE_MATRIX(0 to 2, 0 to 2) := (
            ( 12,  -5,   7),
            ( -3,   9, -11),
            (  4,   6,  -8)
        );
        constant SAMPLE_RESULTS: SAMPLE_MATRIX(0 to 2, 0 to 2) := (
            ( 487, -156,  -111),
            ( -199, 213,  -104),
            ( -19,  -155,   414)
        );
        constant TEST_MATRIX_SIZE: INTEGER := 5;
        constant TEST_WEIGHT_SIZE: INTEGER := 3;
        constant accumulators: INTEGER := 0;
        constant skip: INTEGER := 1;

    begin 
    
        reset <= '1'; 
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        reset <= '0'; 
        
        wait until falling_edge(clk);
        matrix_buffers_control_bus(MATRIX_BUFFERS_ACTIVATIONS_INIT) <= '0';
        matrix_buffers_control_bus(MATRIX_BUFFERS_WEIGHTS_INIT) <= '0';
        matrix_buffers_control_bus(MATRIX_BUFFERS_OUTPUTS_INIT) <= '0';
        matrix_buffers_control_bus(MATRIX_BUFFERS_BIAS_INIT) <= '0';             
        matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_WEIGHTS_MSB downto MATRIX_BUFFERS_ADD_WEIGHTS_LSB) <= (others => '0');
        matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_ACTIVATIONS_MSB downto MATRIX_BUFFERS_ADD_ACTIVATIONS_LSB) <= (others => '0');
        matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_BIAS_MSB downto MATRIX_BUFFERS_ADD_BIAS_LSB) <= (others => '0');
        matrix_buffers_control_bus(MATRIX_BUFFERS_STEP_OUTPUTS_MSB downto MATRIX_BUFFERS_STEP_OUTPUTS_LSB) <= (others => '0');
        
        
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
        
        wait until falling_Edge(clk);
        
        
        
        -- reset phase 
        
        -- resetting buffers
        matrix_buffers_control_bus(MATRIX_BUFFERS_ACTIVATIONS_INIT) <= '1';
        matrix_buffers_control_bus(MATRIX_BUFFERS_WEIGHTS_INIT) <= '1';
        matrix_buffers_control_bus(MATRIX_BUFFERS_OUTPUTS_INIT) <= '1';
        matrix_buffers_control_bus(MATRIX_BUFFERS_BIAS_INIT) <= '1';             
        matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_WEIGHTS_MSB downto MATRIX_BUFFERS_ADD_WEIGHTS_LSB) <= (others => '0');
        matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_ACTIVATIONS_MSB downto MATRIX_BUFFERS_ADD_ACTIVATIONS_LSB) <= (others => '0');
        matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_BIAS_MSB downto MATRIX_BUFFERS_ADD_BIAS_LSB) <= (others => '0');
        matrix_buffers_control_bus(MATRIX_BUFFERS_STEP_OUTPUTS_MSB downto MATRIX_BUFFERS_STEP_OUTPUTS_LSB) <= (others => '0');
        
        
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
        matrix_control_bus(MATRIX_CONTROL_COMMAND_VALID) <= '1';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) <= MATRIX_COMMAND_INIT;
        
        wait until falling_edge(clk); 
        
        matrix_buffers_control_bus(MATRIX_BUFFERS_ACTIVATIONS_INIT) <= '0';
        matrix_buffers_control_bus(MATRIX_BUFFERS_WEIGHTS_INIT) <= '0';
        matrix_buffers_control_bus(MATRIX_BUFFERS_OUTPUTS_INIT) <= '0';
        matrix_buffers_control_bus(MATRIX_BUFFERS_BIAS_INIT) <= '0';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_VALID) <= '0';
 
        wait until falling_edge(clk); 
             
        -- loading phase
        for r in 0 to (TEST_MATRIX_SIZE)-1 loop 
            for c in 0 to (TEST_MATRIX_SIZE)-1 loop 
                if (c < TEST_WEIGHT_SIZE and r < TEST_WEIGHT_SIZE) then 
                    weights_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(r,c),DATA_SIZE));
                    matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_WEIGHTS_MSB downto MATRIX_BUFFERS_ADD_WEIGHTS_LSB) <= (MATRIX_BUFFERS_ADD_WEIGHTS_LSB+r => '1', others => '0');
                else 
                    matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_WEIGHTS_MSB downto MATRIX_BUFFERS_ADD_WEIGHTS_LSB) <= (others => '0');
                end if; 
                
                activations_data_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(r,c),DATA_SIZE)); 
                matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_ACTIVATIONS_MSB downto MATRIX_BUFFERS_ADD_ACTIVATIONS_LSB) <= (MATRIX_BUFFERS_ADD_ACTIVATIONS_LSB+r => '1', others => '0');
                
                wait until falling_edge(clk);
            end loop; 
        end loop; 
        
        matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_WEIGHTS_MSB downto MATRIX_BUFFERS_ADD_WEIGHTS_LSB) <= (others => '0');
        matrix_buffers_control_bus(MATRIX_BUFFERS_ADD_ACTIVATIONS_MSB downto MATRIX_BUFFERS_ADD_ACTIVATIONS_LSB) <= (others => '0');
        
        wait until falling_edge(clk); 

        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_X_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE,ACTIVATION_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_Y_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE,ACTIVATION_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_X_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_WEIGHT_SIZE,WEIGHT_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_Y_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_WEIGHT_SIZE,WEIGHT_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,CONV_SHIFTS_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_Y_MSB downto MATRIX_CONTROL_CONV_SHIFTS_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,CONV_SHIFTS_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SKIP_X_MSB downto MATRIX_CONTROL_CONV_SKIP_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(1,CONV_SKIP_BITS));
        matrix_control_bus(MATRIX_CONTROL_REQUANTIZATION_SHIFT_MSB downto MATRIX_CONTROL_REQUANTIZATION_SHIFT_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_LOAD_ACTIVATIONS_FLAG) <= '1';
        matrix_control_bus(MATRIX_CONTROL_LOAD_WEIGHTS_FLAG) <= '1';
        matrix_control_bus(MATRIX_CONTROL_LOAD_BIAS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG) <= '1';
        matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG) <= '1';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_VALID) <= '1';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) <= MATRIX_COMMAND_LOAD;
        
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
        
        wait until falling_edge(clk); 

        wait until (matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_ACTIVATIONS_READY_LSB)='1');        
        wait until falling_edge(clk); 
        
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_X_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE,ACTIVATION_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_Y_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE,ACTIVATION_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_X_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_WEIGHT_SIZE,WEIGHT_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_Y_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_WEIGHT_SIZE,WEIGHT_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,CONV_SHIFTS_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_Y_MSB downto MATRIX_CONTROL_CONV_SHIFTS_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,CONV_SHIFTS_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SKIP_X_MSB downto MATRIX_CONTROL_CONV_SKIP_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(1,CONV_SKIP_BITS));
        matrix_control_bus(MATRIX_CONTROL_REQUANTIZATION_SHIFT_MSB downto MATRIX_CONTROL_REQUANTIZATION_SHIFT_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_LOAD_ACTIVATIONS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_LOAD_WEIGHTS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_LOAD_BIAS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_VALID) <= '1';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) <= MATRIX_COMMAND_COMPUTE;
        
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
        
        wait until (matrix_status_bus(MATRIX_STATUS_LINES_READY_LSB)='1');
        wait until falling_edge(clk);
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_X_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE,ACTIVATION_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_SIZE_Y_MSB downto MATRIX_CONTROL_ACTIVATION_SIZE_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE,ACTIVATION_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_X_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_WEIGHT_SIZE,WEIGHT_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_SIZE_Y_MSB downto MATRIX_CONTROL_WEIGHT_SIZE_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_WEIGHT_SIZE,WEIGHT_MATRIX_SIZE_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_X_MSB downto MATRIX_CONTROL_CONV_SHIFTS_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,CONV_SHIFTS_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SHIFTS_Y_MSB downto MATRIX_CONTROL_CONV_SHIFTS_Y_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,CONV_SHIFTS_BITS));
        matrix_control_bus(MATRIX_CONTROL_CONV_SKIP_X_MSB downto MATRIX_CONTROL_CONV_SKIP_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(1,CONV_SKIP_BITS));
        matrix_control_bus(MATRIX_CONTROL_REQUANTIZATION_SHIFT_MSB downto MATRIX_CONTROL_REQUANTIZATION_SHIFT_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_LOAD_ACTIVATIONS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_LOAD_WEIGHTS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_LOAD_BIAS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_CLEAR_ACTIVATIONS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_CLEAR_WEIGHTS_FLAG) <= '0';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_VALID) <= '1';
        matrix_control_bus(MATRIX_CONTROL_COMMAND_TYPE_MSB downto MATRIX_CONTROL_COMMAND_TYPE_LSB) <= MATRIX_COMMAND_UNLOAD;
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
                
                
        wait until falling_edge(clk);
        
        for l in 0 to (TEST_MATRIX_SIZE)-1 loop 
            while (matrix_buffers_status_bus(MATRIX_BUFFERS_STATUS_OUTPUT_READY_LSB+l) = '0') loop 
                matrix_buffers_control_bus(MATRIX_BUFFERS_STEP_OUTPUTS_LSB+l) <= '1';
                wait until falling_edge(clk);
            end loop;
            matrix_buffers_control_bus(MATRIX_BUFFERS_STEP_OUTPUTS_LSB+l) <= '0';
        end loop;

        wait;
           
    end process; 
end Behavioral;

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
            
            weights_data_in:                 in MATRIX_WEIGHTS_DATA_INTERFACE; 
            weights_control_buffer:          in MATRIX_WEIGHTS_CONTROL_INTERFACE; 
            
            activations_data_in:             in MATRIX_ACTIVATIONS_DATA_INTERFACE; 
            activations_control_buffer:      in MATRIX_ACTIVATIONS_CONTROL_INTERFACE;
            
            outputs_data_in:                 in MATRIX_OUTPUTS_DATA_INTERFACE; 
            outputs_data_out:                out MATRIX_OUTPUTS_DATA_INTERFACE;
            outputs_control_buffer:          in MATRIX_OUTPUTS_CONTROL_INTERFACE
        );
    end component;
    
    signal clk, reset: STD_LOGIC;
    signal weights_data_in:                     MATRIX_WEIGHTS_DATA_INTERFACE;
    signal activations_data_in:                 MATRIX_ACTIVATIONS_DATA_INTERFACE;
    signal outputs_data_in,outputs_data_out:    MATRIX_OUTPUTS_DATA_INTERFACE;
    signal matrix_control_bus:                  MATRIX_CONTROL_INTERFACE;
    signal matrix_status_bus:                   MATRIX_STATUS_INTERFACE;
    
    signal weights_control_buffer:              MATRIX_WEIGHTS_CONTROL_INTERFACE; 
    signal activations_control_buffer:          MATRIX_ACTIVATIONS_CONTROL_INTERFACE;
    signal outputs_control_buffer:              MATRIX_OUTPUTS_CONTROL_INTERFACE;
    
begin
    
    matrix: PE_matrix 
        port map (
            clk => clk,  
            reset => reset,               
            
            weights_data_in => weights_data_in,
            activations_data_in => activations_data_in, 
            outputs_data_in => outputs_data_in, 
            outputs_data_out => outputs_data_out, 
            matrix_control_bus => matrix_control_bus,
            matrix_status_bus => matrix_status_bus,
            
            outputs_control_buffer => outputs_control_buffer, 
            weights_control_buffer => weights_control_buffer, 
            activations_control_buffer => activations_control_buffer
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
        
        -- reset phase 
        
        
        -- resetting buffers
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_BUFFERS_INIT_BIT) <= '1';
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_BUFFERS_INIT_BIT) <= '1';
        matrix_control_bus(MATRIX_CONTROL_OUTPUT_BUFFERS_INIT_BIT) <= '1';
        matrix_control_bus(MATRIX_CONTROL_ROWS_ENABLE_MSB downto MATRIX_CONTROL_ROWS_ENABLE_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_COLS_ENABLE_MSB downto MATRIX_CONTROL_COLS_ENABLE_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_SIZE_MSB downto MATRIX_CONTROL_SEND_ACTIVATION_SIZE_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_SEND_WEIGHT_SIZE_MSB downto MATRIX_CONTROL_SEND_WEIGHT_SIZE_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_SEND_OUTPUT_SIZE_MSB downto MATRIX_CONTROL_SEND_OUTPUT_SIZE_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_ROW_SKIP_MSB downto MATRIX_CONTROL_ROW_SKIP_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_ROW_RESULTS_MSB downto MATRIX_CONTROL_ROW_RESULTS_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_BUFFERS_BIT) <= '0';
        matrix_control_bus(MATRIX_CONTROL_SEND_WEIGHT_BUFFERS_BIT) <= '0';
        matrix_control_bus(MATRIX_CONTROL_SEND_OUTPUT_BUFFERS_BIT) <= '0';
        matrix_control_bus(MATRIX_CONTROL_PROCESS_ENABLE_BIT) <= '0';
        matrix_control_bus(MATRIX_CONTROL_PROCESS_TYPE_BIT) <= '0';
        
        for l in 0 to (WEIGHT_LINES -1) loop 
            weights_control_buffer(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
        end loop; 
        
        for l in 0 to (ACTIVATION_LINES-1) loop 
            activations_control_buffer(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
        end loop; 
        
        for l in 0 to (ACCUMULATION_LINES-1) loop 
            outputs_control_buffer(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
        end loop; 
        
        
        wait until falling_edge(clk); 
        
        matrix_control_bus(MATRIX_CONTROL_ACTIVATION_BUFFERS_INIT_BIT) <= '0';
        matrix_control_bus(MATRIX_CONTROL_WEIGHT_BUFFERS_INIT_BIT) <= '0';
        matrix_control_bus(MATRIX_CONTROL_OUTPUT_BUFFERS_INIT_BIT) <= '0';
 
        wait until falling_edge(clk); 
        
        
        
        -- loading phase (two matrices in the activation buffers)
        
        for e in 0 to ((TEST_MATRIX_SIZE*2)-1) loop
            for l in 0 to (WEIGHT_LINES - 1) loop 
                if (l < TEST_WEIGHT_SIZE and e < TEST_WEIGHT_SIZE) then
                    weights_control_buffer(l)(BUFFER_INTERFACE_ADD_BIT) <= '1';
                    weights_data_in(l) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(l,e),DATA_SIZE));
                else 
                    weights_control_buffer(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
                end if;
            end loop; 
            
            for l in 0 to (ACTIVATION_LINES - 1) loop         
                if (l < TEST_MATRIX_SIZE) then
                    if (e < TEST_MATRIX_SIZE) then 
                        activations_control_buffer(l)(BUFFER_INTERFACE_ADD_BIT) <= '1';
                        activations_data_in(l) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(l,e),DATA_SIZE)); 
                    else
                        activations_control_buffer(l)(BUFFER_INTERFACE_ADD_BIT) <= '1';
                        activations_data_in(l) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX2(l,e-TEST_MATRIX_SIZE),DATA_SIZE));
                    end if;
                else 
                    activations_control_buffer(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
                end if;
                
            end loop; 
                        
            wait until falling_edge(clk);
        end loop;
                
        for l in 0 to (WEIGHT_LINES -1) loop 
            weights_control_buffer(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
        end loop; 
        
        for l in 0 to (ACTIVATION_LINES-1) loop 
            activations_control_buffer(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
        end loop; 
        
        wait until falling_edge(clk);
        
        matrix_control_bus(MATRIX_CONTROL_ROWS_ENABLE_MSB downto MATRIX_CONTROL_ROWS_ENABLE_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE,ROWS_ENABLE_BITS));
        matrix_control_bus(MATRIX_CONTROL_COLS_ENABLE_MSB downto MATRIX_CONTROL_COLS_ENABLE_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_WEIGHT_SIZE,COLS_ENABLE_BITS));
        matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_SIZE_MSB downto MATRIX_CONTROL_SEND_ACTIVATION_SIZE_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE,QUEUE_COUNTERS_SIZE));
        matrix_control_bus(MATRIX_CONTROL_SEND_WEIGHT_SIZE_MSB downto MATRIX_CONTROL_SEND_WEIGHT_SIZE_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_WEIGHT_SIZE,QUEUE_COUNTERS_SIZE));
        matrix_control_bus(MATRIX_CONTROL_SEND_OUTPUT_SIZE_MSB downto MATRIX_CONTROL_SEND_OUTPUT_SIZE_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,QUEUE_COUNTERS_SIZE));
        matrix_control_bus(MATRIX_CONTROL_ROW_SKIP_MSB downto MATRIX_CONTROL_ROW_SKIP_LSB) <= STD_LOGIC_VECTOR(to_unsigned(1,QUEUE_COUNTERS_SIZE));
        matrix_control_bus(MATRIX_CONTROL_ROW_RESULTS_MSB downto MATRIX_CONTROL_ROW_RESULTS_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,QUEUE_COUNTERS_SIZE));
        
        wait until falling_edge(clk);
        matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_BUFFERS_BIT) <= '1';
        matrix_control_bus(MATRIX_CONTROL_SEND_WEIGHT_BUFFERS_BIT) <= '1';
        matrix_control_bus(MATRIX_CONTROL_SEND_OUTPUT_BUFFERS_BIT) <= '0';
        matrix_control_bus(MATRIX_CONTROL_PROCESS_ENABLE_BIT) <= '0';
        matrix_control_bus(MATRIX_CONTROL_PROCESS_TYPE_BIT) <= '0';
        
        wait until falling_edge(clk);
        
        matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_SIZE_MSB downto MATRIX_CONTROL_SEND_ACTIVATION_SIZE_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_SEND_WEIGHT_SIZE_MSB downto MATRIX_CONTROL_SEND_WEIGHT_SIZE_LSB) <= (others => '0');
        matrix_control_bus(MATRIX_CONTROL_SEND_OUTPUT_SIZE_MSB downto MATRIX_CONTROL_SEND_OUTPUT_SIZE_LSB) <= (others => '0');

        matrix_control_bus(MATRIX_CONTROL_SEND_ACTIVATION_BUFFERS_BIT) <= '0';
        matrix_control_bus(MATRIX_CONTROL_SEND_WEIGHT_BUFFERS_BIT) <= '0';
        
        wait until (matrix_status_bus(MATRIX_STATUS_ACTIVATIONS_READY_LSB)='1');
        wait until falling_edge(clk); 
        
        matrix_control_bus(MATRIX_CONTROL_SEND_OUTPUT_BUFFERS_BIT) <= '1';
        wait until falling_edge(clk); 
        
        matrix_control_bus(MATRIX_CONTROL_SEND_OUTPUT_BUFFERS_BIT) <= '0';
        
        matrix_control_bus(MATRIX_CONTROL_PROCESS_ENABLE_BIT) <= '1';
        matrix_control_bus(MATRIX_CONTROL_PROCESS_TYPE_BIT) <= '0';
        
        wait until (matrix_status_bus(MATRIX_STATUS_DONE_LSB) = '1');
        
        matrix_control_bus(MATRIX_CONTROL_PROCESS_ENABLE_BIT) <= '1';
        matrix_control_bus(MATRIX_CONTROL_PROCESS_TYPE_BIT) <= '1';
        
--        -- loading phase (first matrix and weights)
        
--        for l in 0 to (WEIGHT_LINES -1) loop 
--            weights_control_bus(l)(BUFFER_INTERFACE_INIT_BIT) <= '0';
--            weights_control_bus(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
--            weights_control_bus(l)(BUFFER_INTERFACE_SEND_BIT) <= '1';
--            weights_control_bus(l)(BUFFER_INTERFACE_SEND_SIZE_MSB downto BUFFER_INTERFACE_SEND_SIZE_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_WEIGHT_SIZE,QUEUE_COUNTERS_SIZE));
--        end loop; 
        
--        for l in 0 to (ACTIVATION_LINES-1) loop 
--            activations_control_bus(l)(BUFFER_INTERFACE_INIT_BIT) <= '0';
--            activations_control_bus(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
--            activations_control_bus(l)(BUFFER_INTERFACE_SEND_BIT) <= '1';
--            activations_control_bus(l)(BUFFER_INTERFACE_SEND_SIZE_MSB downto BUFFER_INTERFACE_SEND_SIZE_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE,QUEUE_COUNTERS_SIZE));
--        end loop; 
        
----        for l in 0 to (ACCUMULATION_LINES-1) loop 
----            outputs_control_bus(l)(BUFFER_INTERFACE_INIT_BIT) <= '0';
----            outputs_control_bus(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
----            outputs_control_bus(l)(BUFFER_INTERFACE_SEND_BIT) <= '1';
----            outputs_control_bus(l)(BUFFER_INTERFACE_SEND_SIZE_MSB downto BUFFER_INTERFACE_SEND_SIZE_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,QUEUE_COUNTERS_SIZE));
----        end loop; 

--        for l in 0 to (CONTROL_LINES-1) loop
--            matrix_control_in(l)(ACTIVATION_INIT_BIT) <= '1';
--            matrix_control_in(l)(WEIGHT_INIT_BIT) <= '1';
--            matrix_control_in(l)(ACCUMULATOR_INIT_BIT) <= '1';
--            matrix_control_in(l)(WEIGHT_VALID_BIT) <= '0';
--            matrix_control_in(l)(ACTIVATION_VALID_BIT) <= '0';
--            matrix_control_in(l)(ENABLE_BIT) <= '0';
--            matrix_control_in(l)(PROCESS_TYPE_BIT) <= '0';
--        end loop; 

--        wait until falling_edge(clk); 
        
--        for l in 0 to (WEIGHT_LINES - 1 ) loop 
--            weights_control_bus(l)(BUFFER_INTERFACE_INIT_BIT) <= '0';
--            weights_control_bus(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
--            weights_control_bus(l)(BUFFER_INTERFACE_SEND_BIT) <= '0';
            
--        end loop; 
        
--        for l in 0 to (ACTIVATION_LINES-1) loop 
--            activations_control_bus(l)(BUFFER_INTERFACE_INIT_BIT) <= '0';
--            activations_control_bus(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
--            activations_control_bus(l)(BUFFER_INTERFACE_SEND_BIT) <= '0';
            
--        end loop; 
        
--        for l in 0 to (ACCUMULATION_LINES-1) loop 
--            outputs_control_bus(l)(BUFFER_INTERFACE_INIT_BIT) <= '0';
--            outputs_control_bus(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
--            outputs_control_bus(l)(BUFFER_INTERFACE_SEND_BIT) <= '0';
            
--        end loop; 

--        for l in 0 to (CONTROL_LINES-1) loop
--            matrix_control_in(l)(ACTIVATION_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_INIT_BIT) <= '0';
--            matrix_control_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_VALID_BIT) <= '1';
--            matrix_control_in(l)(ACTIVATION_VALID_BIT) <= '1';
--            matrix_control_in(l)(ENABLE_BIT) <= '0';
--            matrix_control_in(l)(PROCESS_TYPE_BIT) <= '0';
--        end loop; 
        
--        for i in 0 to TEST_WEIGHT_SIZE-1 loop
--            wait until falling_edge(clk); 
--        end loop;

--        for l in 0 to (CONTROL_LINES-1) loop
--            matrix_control_in(l)(ACTIVATION_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_INIT_BIT) <= '0';
--            matrix_control_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_VALID_BIT) <= '0';
--            matrix_control_in(l)(ACTIVATION_VALID_BIT) <= '1';
--            matrix_control_in(l)(ENABLE_BIT) <= '0';
--            matrix_control_in(l)(PROCESS_TYPE_BIT) <= '0';
--        end loop; 
        
--        for i in 0 to TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE-1 loop 
--            wait until falling_edge(clk); 
--        end loop;
        
--        -- processing phase
        
--        for l in 0 to (CONTROL_LINES-1) loop
--            matrix_control_in(l)(ACTIVATION_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_INIT_BIT) <= '0';
--            matrix_control_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_VALID_BIT) <= '0';
--            matrix_control_in(l)(ACTIVATION_VALID_BIT) <= '0';
--            matrix_control_in(l)(PROCESS_TYPE_BIT) <= '0';
            
--            if (l < TEST_WEIGHT_SIZE) then 
--                matrix_control_in(l)(ENABLE_BIT) <= '1';
--            else 
--                matrix_control_in(l)(ENABLE_BIT) <= '0';
--            end if;
            
--        end loop; 
        
        
--        for i in 0 to ((TEST_WEIGHT_SIZE+1)*(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1))-1 loop 
--            wait until falling_edge(clk);  
--        end loop;
        
--        -- loading phase (second matrix) (unloading first results)
        
--        for l in 0 to (ACTIVATION_LINES-1) loop 
--            activations_control_bus(l)(BUFFER_INTERFACE_INIT_BIT) <= '0';
--            activations_control_bus(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
--            activations_control_bus(l)(BUFFER_INTERFACE_SEND_BIT) <= '1';
--            activations_control_bus(l)(BUFFER_INTERFACE_SEND_SIZE_MSB downto BUFFER_INTERFACE_SEND_SIZE_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE,QUEUE_COUNTERS_SIZE));
--        end loop; 
        
--        for l in 0 to (CONTROL_LINES-1) loop
--            matrix_control_in(l)(ACTIVATION_INIT_BIT) <= '1';
--            matrix_control_in(l)(WEIGHT_INIT_BIT) <= '0';
--            matrix_control_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_VALID_BIT) <= '0';
--            matrix_control_in(l)(ACTIVATION_VALID_BIT) <= '0';
--            matrix_control_in(l)(PROCESS_TYPE_BIT) <= '1';
--            if (l < TEST_WEIGHT_SIZE) then 
--                matrix_control_in(l)(ENABLE_BIT) <= '1';
--            else 
--                matrix_control_in(l)(ENABLE_BIT) <= '0';
--            end if;
--        end loop; 

--        wait until falling_edge(clk); 
        
--        for l in 0 to (ACTIVATION_LINES-1) loop 
--            activations_control_bus(l)(BUFFER_INTERFACE_INIT_BIT) <= '0';
--            activations_control_bus(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
--            activations_control_bus(l)(BUFFER_INTERFACE_SEND_BIT) <= '0';
--        end loop; 
        
--        for l in 0 to (CONTROL_LINES-1) loop
--            matrix_control_in(l)(ACTIVATION_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_INIT_BIT) <= '0';
--            matrix_control_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_VALID_BIT) <= '0';
--            matrix_control_in(l)(ACTIVATION_VALID_BIT) <= '1';
--            matrix_control_in(l)(PROCESS_TYPE_BIT) <= '1';

--        end loop; 
        
--        for i in 0 to TEST_MATRIX_SIZE-1 loop
--            wait until falling_edge(clk); 
--        end loop;
        

--        for l in 0 to (CONTROL_LINES-1) loop
--            matrix_control_in(l)(ACTIVATION_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_INIT_BIT) <= '0';
--            matrix_control_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_VALID_BIT) <= '0';
--            matrix_control_in(l)(ACTIVATION_VALID_BIT) <= '0';

--            matrix_control_in(l)(PROCESS_TYPE_BIT) <= '1';
--        end loop; 
        
--        wait until rising_edge(outputs_status_bus(0)(ACCUMULATOR_VALID_BIT));
        
--        for i in 0 to (DEPTH*4)-1 loop 
--            wait until falling_edge(clk);
--        end loop;
        
--        for l in 0 to (ACCUMULATION_LINES-1) loop 
--            outputs_control_bus(l)(BUFFER_INTERFACE_INIT_BIT) <= '0';
--            outputs_control_bus(l)(BUFFER_INTERFACE_ADD_BIT) <= '0';
--            outputs_control_bus(l)(BUFFER_INTERFACE_SEND_BIT) <= '1';
--            outputs_control_bus(l)(BUFFER_INTERFACE_SEND_SIZE_MSB downto BUFFER_INTERFACE_SEND_SIZE_LSB) <= STD_LOGIC_VECTOR(to_unsigned(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE+1,QUEUE_COUNTERS_SIZE));
--        end loop; 
        
--        wait until falling_edge(clk); 
        
--        for l in 0 to (ACCUMULATION_LINES-1) loop 
--            outputs_control_bus(l)(BUFFER_INTERFACE_SEND_BIT) <= '0';
--        end loop; 

--        wait until falling_edge(clk);

--        -- processing phase
        
--        for l in 0 to (CONTROL_LINES-1) loop
--            matrix_control_in(l)(ACTIVATION_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_INIT_BIT) <= '0';
--            matrix_control_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_VALID_BIT) <= '0';
--            matrix_control_in(l)(ACTIVATION_VALID_BIT) <= '0';
--            matrix_control_in(l)(PROCESS_TYPE_BIT) <= '0';
            
--            if (l < TEST_WEIGHT_SIZE) then 
--                matrix_control_in(l)(ENABLE_BIT) <= '1';
--            else 
--                matrix_control_in(l)(ENABLE_BIT) <= '0';
--            end if;
            
--        end loop; 
        
--        for i in 0 to (TEST_WEIGHT_SIZE*8) loop 
--            wait until falling_edge(clk);  
--        end loop;
            
--        -- unloading phase 
        
--        for l in 0 to (CONTROL_LINES-1) loop
--            matrix_control_in(l)(ACTIVATION_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_INIT_BIT) <= '0';
--            matrix_control_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_VALID_BIT) <= '0';
--            matrix_control_in(l)(ACTIVATION_VALID_BIT) <= '0';
--            matrix_control_in(l)(PROCESS_TYPE_BIT) <= '1';
            
--            if (l < TEST_WEIGHT_SIZE) then 
--                matrix_control_in(l)(ENABLE_BIT) <= '1';
--            else 
--                matrix_control_in(l)(ENABLE_BIT) <= '0';
--            end if;
            
--        end loop; 
        
  
--        wait;
        
        
        
--        -- unloading phase 
        
--        for l in 0 to (ACCUMULATION_LINES-1) loop 
--            outputs_control_bus(l)(BUFFER_INTERFACE_INIT_BIT) <= '1';  
--        end loop; 
        
--        for l in 0 to (CONTROL_LINES-1) loop
--            matrix_control_in(l)(ACTIVATION_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_INIT_BIT) <= '0';
--            matrix_control_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
--            matrix_control_in(l)(WEIGHT_VALID_BIT) <= '0';
--            matrix_control_in(l)(ACTIVATION_VALID_BIT) <= '0';
--            matrix_control_in(l)(PROCESS_TYPE_BIT) <= '1';
            
--            if (l < TEST_WEIGHT_SIZE) then 
--                matrix_control_in(l)(ENABLE_BIT) <= '1';
--            else 
--                matrix_control_in(l)(ENABLE_BIT) <= '0';
--            end if;
            
--        end loop; 
        
  
        wait;
           
    end process; 
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_MATRIX_PARAMETERS.ALL; 
use IEEE.NUMERIC_STD.ALL;

entity pe_test is 

end pe_test;

architecture behavioral of pe_test is
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
    
    signal clk, reset, enable: STD_LOGIC; 
    signal weight_in, activation_in:        STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal accumulator_in, accumulator_out: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal control_in:                      PE_CONTROL_INTERFACE;
    signal status_in, status_out:           PE_STATUS_INTERFACE;
    
    
begin 
    
    processing_element: pe 
        port map(
            clk => clk,
            reset => reset,
            enable => enable,
            
            weight_in => weight_in,
            activation_in => activation_in,
            accumulator_in => accumulator_in,
       
            accumulator_out => accumulator_out, 
            
            control_in => control_in, 
            status_in => status_in,
            status_out => status_out
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
        type SAMPLE_ARRAY is array (natural range <>) of INTEGER; 
        constant TEST_VECTOR: SAMPLE_ARRAY := (-50,20,-30,90,-40,60,-10,80);
        constant TEST_WEIGHT: SAMPLE_ARRAY := (2,-5,3);
        constant TEST_RESULTS: SAMPLE_ARRAY := (-290,460,-630,560,-410,410);
        
        constant TEST_VECTOR_SIZE: INTEGER := 8;
        constant TEST_WINDOW_SIZE: INTEGER := 5;
        constant TEST_WEIGHT_SIZE: INTEGER := 3;
        
        constant ACCUMULATOR: INTEGER := 0;

    begin 
    
        -- resetting the PE
        reset <= '1'; 

        wait until falling_edge(clk);        
        wait until falling_edge(clk);
        
        reset <= '0'; 
        control_in(PE_INIT) <= '1';
        control_in(PE_ACTIVATIONS_CLEAR) <= '1';
        control_in(PE_WEIGHTS_CLEAR) <= '1'; 
        control_in(PE_WEIGHT_VALID) <= '0';
        control_in(PE_ACTIVATION_VALID) <= '0';
        control_in( PE_CONV_STRIDE_X_MSB downto  PE_CONV_STRIDE_X_LSB) <= (others => '0');
        control_in( PE_CONV_SHIFTS_X_MSB downto  PE_CONV_SHIFTS_X_LSB) <= (others => '0');
        control_in(PE_PROCESS_START) <= '0';
        control_in(PE_PROCESS_TYPE) <= '0';
        
        status_in(PE_ACTIVE) <= '0';
        status_in(PE_OUTPUT_VALID) <= '0';
        enable <= '0';
        
        wait until rising_edge(clk); 

        
        -- Loading phase
        
        
        control_in(PE_INIT) <= '0';
        control_in(PE_ACTIVATIONS_CLEAR) <= '0';
        control_in(PE_WEIGHTS_CLEAR) <= '0'; 
        
       
        for i in 0 to TEST_WINDOW_SIZE-1 loop
        
                -- All the weights are loaded in the weight queue
                if (i<TEST_WEIGHT_SIZE) then 
                    weight_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(i),DATA_SIZE));
                    control_in(PE_WEIGHT_VALID) <= '1';
                else 
                    control_in(PE_WEIGHT_VALID) <= '0';
                end if; 
                
                -- Only one half of the activation vector is loaded in the activation queue
                activation_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_VECTOR(i),DATA_SIZE));
                control_in(PE_ACTIVATION_VALID) <= '1';
                
                wait until rising_edge(clk);   
        end loop; 

        control_in(PE_WEIGHT_VALID) <= '0';
        control_in(PE_ACTIVATION_VALID) <= '0';
                
        -- Execution phase
        
        enable <= '1';
        weight_in <= (others => '0');
        activation_in <= (others => '0');
        
        -- We send a process start command to start the convolution of three elements
        control_in( PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(3,CONV_SHIFTS_BITS));
        control_in( PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= CONV_STRIDE_1;
        control_in(PE_PROCESS_START) <= '1';
        control_in(PE_PROCESS_TYPE) <= '0';
        wait until rising_edge(clk); 
        
        -- the start command should last only one clock cycle
        control_in( PE_CONV_SHIFTS_X_MSB downto  PE_CONV_SHIFTS_X_LSB) <= (others => '0');
        control_in( PE_CONV_STRIDE_X_MSB downto  PE_CONV_STRIDE_X_LSB) <= (others => '0');

        control_in(PE_PROCESS_START) <= '0';
        control_in(PE_PROCESS_TYPE) <= '0';

        -- waiting fot the PE to be ready (we consider a latency of 3 clock cycles)
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        
        wait until rising_edge(status_out(PE_READY));
        wait until rising_edge(clk);
        
        -- simulating a buffer stall 
        for i in 0 to 10 loop 
            wait until rising_edge(clk); 
        end loop;
        
        -- Second loading phase

        control_in(PE_ACTIVATION_VALID) <= '1';
        for i in 0 to TEST_VECTOR_SIZE-TEST_WINDOW_SIZE-1 loop
                -- The second hald of the activation vector is loaded in the activation queue
                activation_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_VECTOR(TEST_WINDOW_SIZE+i),DATA_SIZE));
                wait until rising_edge(clk);   
        end loop; 
        control_in(PE_ACTIVATION_VALID) <= '0';
        
        -- We send a process start command to start the convolution of three elements
        
        control_in( PE_CONV_SHIFTS_X_MSB downto PE_CONV_SHIFTS_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(3,CONV_SHIFTS_BITS));
        control_in( PE_CONV_STRIDE_X_MSB downto PE_CONV_STRIDE_X_LSB) <= CONV_STRIDE_1;
        control_in(PE_PROCESS_START) <= '1';
        control_in(PE_PROCESS_TYPE) <= '0';
        wait until rising_edge(clk); 
        
        -- the start command should last only one clock cycle
        
        control_in( PE_CONV_SHIFTS_X_MSB downto  PE_CONV_SHIFTS_X_LSB) <= (others => '0');
        control_in( PE_CONV_STRIDE_X_MSB downto  PE_CONV_STRIDE_X_LSB) <= (others => '0');
        control_in(PE_PROCESS_START) <= '0';
        control_in(PE_PROCESS_TYPE) <= '0';
        
        -- waiting fot the PE to be ready (we consider a latency of 3 clock cycles)
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(status_out(PE_READY));
        wait until rising_edge(clk);
        
        
        -- Unloading phase
        
        -- sending the unload command 
        -- We unload all the 6 results collected in the accumulation_queue
        control_in(PE_CONV_SHIFTS_X_MSB downto  PE_CONV_SHIFTS_X_LSB) <= STD_LOGIC_VECTOR(to_unsigned(6,CONV_SHIFTS_BITS));
        control_in(PE_PROCESS_START) <= '1';
        control_in(PE_PROCESS_TYPE) <= '1';
        wait until rising_edge(clk); 
        
        control_in(PE_CONV_SHIFTS_X_MSB downto  PE_CONV_SHIFTS_X_LSB) <= (others => '0');
        control_in(PE_PROCESS_START) <= '0';
        control_in(PE_PROCESS_TYPE) <= '0';
        
        -- simulating a delay before sending a valid result 
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        
        status_in(PE_OUTPUT_VALID) <= '1';
        
        -- waiting until all the results are unloaded
        
        wait until rising_edge(status_out(PE_READY));
        
        wait;
           
    end process; 

end architecture; 
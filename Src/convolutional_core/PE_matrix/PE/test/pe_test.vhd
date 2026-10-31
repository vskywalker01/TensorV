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
    
    signal clk, reset, enable, forward_enable: STD_LOGIC; 
    signal weight_in, weight_out, activation_in,activation_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal accumulator_in, accumulator_out: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal control_in, control_out: PE_CONTROL_INTERFACE;
    signal status_in, status_out: PE_STATUS_INTERFACE;
    
    
begin 
    
    processing_element: pe 
        port map(
            clk => clk,
            reset => reset,
            enable => enable,
            forward_enable => forward_enable,
            
            weight_in => weight_in,
            activation_in => activation_in,
            accumulator_in => accumulator_in,
            
            weight_out => weight_out,
            activation_out => activation_out,
            accumulator_out => accumulator_out, 
            
            control_in => control_in, 
            status_in => status_in,
            control_out => control_out,
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
        constant TEST_VECTOR: SAMPLE_ARRAY := (-50,20,-30,90,-40,60,-10,80,-70, 12);
        constant TEST_WEIGHT: SAMPLE_ARRAY := (2,-5,3);
        constant TEST_RESULTS: SAMPLE_ARRAY := (-290,460,-630,560,-410,410,-630,546);
        
        constant TEST_WINDOW_SIZE: INTEGER := 5;
        constant TEST_WEIGHT_SIZE: INTEGER := 3;
        
        constant ACCUMULATOR: INTEGER := 0;

    begin 
    
        -- resetting the PE
        reset <= '1'; 
        enable <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        
        reset <= '0'; 
        wait until falling_edge(clk); 
        
        -- Forward data test (enable = '0' and forward_enable = '1')
        enable <= '0';
        forward_enable <= '0'; 
        wait until falling_edge(clk);
        forward_enable <= '1'; 
        
        -- sending some values to test their propagation
        for i in 0 to TEST_WINDOW_SIZE-1 loop
            if (i<TEST_WEIGHT_SIZE) then 
                weight_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(i),DATA_SIZE));
                activation_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_VECTOR(i),DATA_SIZE));
            else 
                forward_enable <= '0';
            end if; 
            wait until falling_edge(clk);   
        end loop; 

        
        -- Process data test (enable = '1' and forward_enable = '0')
        
        -- initialization phase
        
        wait until falling_edge(clk);
        enable <= '1';
        forward_enable <= '0';
        weight_in <= (others => '0');
        activation_in <= (others => '0');
        accumulator_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(accumulator,ACCUMULATOR_SIZE));
        
        -- We set the PE to process a convolution between a 
        control_in( PE_CONV_SKIP_MSB downto PE_CONV_SKIP_LSB) <= STD_LOGIC_VECTOR(to_unsigned(1,CONV_SKIP_BITS));
        control_in( PE_CONV_SHIFTS_MSB downto  PE_CONV_SHIFTS_LSB) <= (others => '0');
        
        -- we initialize all the internal queues 
        control_in(PE_ACTIVATION_INIT) <= '1';
        control_in(PE_WEIGHT_INIT) <= '1';
        control_in(PE_ACCUMULATOR_INIT) <= '1';
        control_in(PE_WEIGHT_VALID) <= '0';
        control_in(PE_ACTIVATION_VALID) <= '0';
        control_in(PE_PROCESS_START) <= '0';
        control_in(PE_PROCESS_TYPE) <= '0';
        status_in(PE_OUTPUT_VALID) <= '0';
        
        wait until falling_edge(clk); 
        
        -- Loading phase
        -- We signal the PE to receive data in the weight and activation queues
        control_in(PE_ACTIVATION_INIT) <= '0';
        control_in(PE_WEIGHT_INIT) <= '0';
        control_in(PE_ACCUMULATOR_INIT) <= '0';
        control_in(PE_WEIGHT_VALID) <= '1';
        control_in(PE_ACTIVATION_VALID) <= '1';
        
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
                
                wait until falling_edge(clk);   
        end loop; 
        
        control_in(PE_WEIGHT_VALID) <= '0';
        control_in(PE_ACTIVATION_VALID) <= '0';
        
        -- Execution phase
        
        -- We send a process start command to start the convolution of three elements
        control_in( PE_CONV_SHIFTS_MSB downto  PE_CONV_SHIFTS_LSB) <= STD_LOGIC_VECTOR(to_unsigned(3,CONV_SHIFTS_BITS));
        control_in(PE_PROCESS_START) <= '1';
        control_in(PE_PROCESS_TYPE) <= '0';
        wait until falling_edge(clk); 
        
        -- the start command should last only one clock cycle
        
        control_in( PE_CONV_SHIFTS_MSB downto  PE_CONV_SHIFTS_LSB) <= (others => '0');
        control_in(PE_PROCESS_START) <= '0';
        control_in(PE_PROCESS_TYPE) <= '0';

        -- waiting fot the PE to be ready (we consider a latency of 3 clock cycles)
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until rising_edge(status_out(PE_READY));
        wait until falling_edge(clk);
        
        -- simulating a buffer loading phase 
        for i in 0 to 10 loop 
            wait until falling_edge(clk); 
        end loop;
        
        -- Second loading phase

        control_in(PE_ACTIVATION_VALID) <= '1';
        for i in 0 to TEST_WINDOW_SIZE-1 loop
                -- The second hald of the activation vector is loaded in the activation queue
                activation_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_VECTOR(TEST_WINDOW_SIZE+i),DATA_SIZE));
                wait until falling_edge(clk);   
        end loop; 
        control_in(PE_ACTIVATION_VALID) <= '0';
        
        -- sending the second start command 
        control_in( PE_CONV_SHIFTS_MSB downto  PE_CONV_SHIFTS_LSB) <= STD_LOGIC_VECTOR(to_unsigned(3,CONV_SHIFTS_BITS));
        control_in(PE_PROCESS_START) <= '1';
        control_in(PE_PROCESS_TYPE) <= '0';
        wait until falling_edge(clk); 
        
        -- the start command should last only one clock cycle
        
        control_in(PE_CONV_SHIFTS_MSB downto  PE_CONV_SHIFTS_LSB) <= (others => '0');
        control_in(PE_PROCESS_START) <= '0';
        control_in(PE_PROCESS_TYPE) <= '0';
        
        -- waiting fot the PE to be ready (we consider a latency of 3 clock cycles)
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until rising_edge(status_out(PE_READY));
        wait until falling_edge(clk);
        
        
        -- Unloading phase
        
        -- sending the unload command 
        -- We unload all the 6 results collected in the accumulation_queue
        control_in(PE_CONV_SHIFTS_MSB downto  PE_CONV_SHIFTS_LSB) <= STD_LOGIC_VECTOR(to_unsigned(6,CONV_SHIFTS_BITS));
        control_in(PE_PROCESS_START) <= '1';
        control_in(PE_PROCESS_TYPE) <= '1';
        wait until falling_edge(clk); 
        
        control_in(PE_CONV_SHIFTS_MSB downto  PE_CONV_SHIFTS_LSB) <= (others => '0');
        control_in(PE_PROCESS_START) <= '0';
        control_in(PE_PROCESS_TYPE) <= '0';
        
        -- simulating a delay before sending a valid result 
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        
        status_in(PE_OUTPUT_VALID) <= '1';
        
        -- waiting until all the results are unloaded
        
        wait until rising_edge(status_out(PE_READY));
        
        enable <= '0';
        
        wait;
           
    end process; 

end architecture; 
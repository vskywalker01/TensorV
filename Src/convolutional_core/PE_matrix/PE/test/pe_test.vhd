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
    
    signal clk, reset, enable: STD_LOGIC; 
    signal weight_in, weight_out, activation_in,activation_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal accumulator_in, accumulator_out: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal control_in, control_out: STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
    signal status_in, status_out: STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
    
    
begin 
    
    processing_element: pe 
        port map(
            clk => clk,
            reset => reset,
            enable => enable,
            
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
        
        constant TEST_VECTOR_SIZE: INTEGER := 5;
        constant TEST_WEIGHT_SIZE: INTEGER := 3;
        
        constant ACCUMULATOR: INTEGER := 0;

    begin 
        reset <= '1'; 
        enable <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        
        reset <= '0'; 
        wait until falling_edge(clk); 
        
        enable <= '0';
        -- initialization phase
        
        wait until falling_edge(clk);
        enable <= '1';
        weight_in <= (others => '0');
        activation_in <= (others => '0');
        accumulator_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(accumulator,ACCUMULATOR_SIZE));
        
        -- we set the PE so that it will process rows with size TEST_WEIGHT_SIZE and with a stride number equal to 1 (standard convolution);
        control_in(ACTIVATION_SKIP_MS_BIT downto ACTIVATION_SKIP_LS_BIT) <= STD_LOGIC_VECTOR(to_unsigned(1,QUEUE_COUNTERS_SIZE));
        control_in(ACCUMULATIONS_NUMBER_MS_BIT downto ACCUMULATIONS_NUMBER_LS_BIT) <= (others => '0');
        
        -- queue initialization
        control_in(ACTIVATION_INIT_BIT) <= '1';
        control_in(WEIGHT_INIT_BIT) <= '1';
        control_in(ACCUMULATOR_INIT_BIT) <= '0';
        control_in(WEIGHT_VALID_BIT) <= '0';
        control_in(ACTIVATION_VALID_BIT) <= '0';
        control_in(PROCESS_ENABLE_BIT) <= '0';
        control_in(PROCESS_TYPE_BIT) <= '0';
        status_in(ACCUMULATOR_VALID_BIT) <= '0';
        
        wait until falling_edge(clk); 
        control_in(ACTIVATION_SKIP_MS_BIT downto ACTIVATION_SKIP_LS_BIT) <= (others => '0');
        
        -- Loading phase
        control_in(ACTIVATION_INIT_BIT) <= '0';
        control_in(WEIGHT_INIT_BIT) <= '0';
        control_in(ACCUMULATOR_INIT_BIT) <= '0';
        control_in(ACTIVATION_VALID_BIT) <= '1';
        control_in(PROCESS_ENABLE_BIT) <= '0';
        control_in(PROCESS_TYPE_BIT) <= '0';
        status_in(ACCUMULATOR_VALID_BIT) <= '0';
        
        for i in 0 to TEST_VECTOR_SIZE-1 loop
        
                -- The weights are loaded in the weight queue
                if (i<TEST_WEIGHT_SIZE) then 
                    weight_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(i),DATA_SIZE));
                    control_in(WEIGHT_VALID_BIT) <= '1';
                else 
                    control_in(WEIGHT_VALID_BIT) <= '0';
                end if; 
                
                -- The entire row is loaded in the activation queue
                activation_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_VECTOR(i),DATA_SIZE));
                
                wait until falling_edge(clk);   
        end loop; 
        
        -- Execution phase
        control_in(ACCUMULATIONS_NUMBER_MS_BIT downto ACCUMULATIONS_NUMBER_LS_BIT) <= STD_LOGIC_VECTOR(to_unsigned(3,QUEUE_COUNTERS_SIZE));
        control_in(ACTIVATION_INIT_BIT) <= '0';
        control_in(WEIGHT_INIT_BIT) <= '0';
        control_in(ACCUMULATOR_INIT_BIT) <= '1';
        control_in(ACTIVATION_VALID_BIT) <= '0';
        control_in(PROCESS_ENABLE_BIT) <= '0';
        control_in(PROCESS_TYPE_BIT) <= '0';
        status_in(ACCUMULATOR_VALID_BIT) <= '0';
        
        wait until falling_edge(clk);
        control_in(ACCUMULATOR_INIT_BIT) <= '0';
        control_in(ACCUMULATIONS_NUMBER_MS_BIT downto ACCUMULATIONS_NUMBER_LS_BIT) <= (others => '0');
        control_in(PROCESS_ENABLE_BIT) <= '1';
        
        wait until (status_out(DONE_BIT) = '1'); 
        wait until falling_edge(clk); 

        -- unloading phase + second loading phase
        control_in(ACTIVATION_INIT_BIT) <= '1';
        control_in(WEIGHT_INIT_BIT) <= '0';
        control_in(ACCUMULATOR_INIT_BIT) <= '0';
        control_in(ACTIVATION_VALID_BIT) <= '0';
        control_in(WEIGHT_VALID_BIT) <= '0';
        control_in(PROCESS_ENABLE_BIT) <= '1';
        control_in(PROCESS_TYPE_BIT) <= '1';
        status_in(ACCUMULATOR_VALID_BIT) <= '1';
        
        wait until falling_edge(clk);
        
        control_in(ACTIVATION_INIT_BIT) <= '0';
        control_in(WEIGHT_INIT_BIT) <= '0';
        control_in(ACCUMULATOR_INIT_BIT) <= '0';
        control_in(ACTIVATION_VALID_BIT) <= '1';
        control_in(WEIGHT_VALID_BIT) <= '0';
        control_in(PROCESS_ENABLE_BIT) <= '1';
        control_in(PROCESS_TYPE_BIT) <= '1';
        status_in(ACCUMULATOR_VALID_BIT) <= '1';
        
        for i in 0 to TEST_VECTOR_SIZE-1 loop
                
                -- The entire row is loaded in the activation queue
                activation_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_VECTOR(TEST_VECTOR_SIZE+i),DATA_SIZE));
                
                wait until falling_edge(clk);   
        end loop; 
        
        -- execution phase 
        
        control_in(ACCUMULATIONS_NUMBER_MS_BIT downto ACCUMULATIONS_NUMBER_LS_BIT) <= STD_LOGIC_VECTOR(to_unsigned(3,QUEUE_COUNTERS_SIZE));
        control_in(ACTIVATION_INIT_BIT) <= '0';
        control_in(WEIGHT_INIT_BIT) <= '0';
        control_in(ACCUMULATOR_INIT_BIT) <= '0';
        control_in(ACTIVATION_VALID_BIT) <= '0';
        control_in(PROCESS_ENABLE_BIT) <= '0';
        control_in(PROCESS_TYPE_BIT) <= '0';
        status_in(ACCUMULATOR_VALID_BIT) <= '0';
        
        wait until falling_edge(clk);
        control_in(ACCUMULATOR_INIT_BIT) <= '0';
        control_in(ACCUMULATIONS_NUMBER_MS_BIT downto ACCUMULATIONS_NUMBER_LS_BIT) <= (others => '0');
        control_in(PROCESS_ENABLE_BIT) <= '1';
        
        wait until (status_out(DONE_BIT) = '1'); 
        wait until falling_edge(clk); 
        
        -- unloading phase
        
        control_in(ACTIVATION_INIT_BIT) <= '0';
        control_in(WEIGHT_INIT_BIT) <= '0';
        control_in(ACCUMULATOR_INIT_BIT) <= '0';
        control_in(ACTIVATION_VALID_BIT) <= '0';
        control_in(PROCESS_ENABLE_BIT) <= '1';
        control_in(PROCESS_TYPE_BIT) <= '1';
        status_in(ACCUMULATOR_VALID_BIT) <= '1';
        
        for i in 0 to (TEST_WEIGHT_SIZE*6) loop 
            wait until falling_edge(clk);  
        end loop;
        
        control_in(PROCESS_ENABLE_BIT) <= '0';
        control_in(PROCESS_TYPE_BIT) <= '0';
        enable <= '0';
        
        wait;
           
    end process; 

end architecture; 
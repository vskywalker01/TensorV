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
            
            control_in:             in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
            weight_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_in:          in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_in:         in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            
            control_out:            out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
            weight_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
            activation_out:         out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_out:        out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0)
            
        );
    end component;
    
    signal clk, reset: STD_LOGIC; 
    signal weight_in, weight_out, activation_in,activation_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal accumulator_in, accumulator_out: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal control_in, control_out: STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
    
    
    
begin 
    
    processing_element: pe 
        port map(
            clk => clk,
            reset => reset,
        
            weight_in => weight_in,
            activation_in => activation_in,
            accumulator_in => accumulator_in,
            
            weight_out => weight_out,
            activation_out => activation_out,
            accumulator_out => accumulator_out, 
            
            control_in => control_in, 
            control_out => control_out
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
        constant TEST_VECTOR: SAMPLE_ARRAY := (-50,20,-30,90,-40,60,-10,80,-70);
        constant TEST_WEIGHT: SAMPLE_ARRAY := (2,-5,3);
        constant TEST_RESULTS: SAMPLE_ARRAY := (-290,460,-630,560,-410,410,630);
        constant TEST_VECTOR_SIZE: INTEGER := 9;
        constant TEST_WEIGHT_SIZE: INTEGER := 3;

        constant ACCUMULATOR: INTEGER := 0;
        constant error_counter: INTEGER := 0;
    begin 
        reset <= '1'; 
        wait until falling_edge(clk);
        
        reset <= '0'; 
        
        wait until falling_edge(clk);
        weight_in <= (others => '0');
        activation_in <= (others => '0');
        accumulator_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(accumulator,ACCUMULATOR_SIZE));
        
        control_in <= "1110000";
        
        wait until falling_edge(clk); 
        
        control_in <= "0001100";
        
        for i in 0 to TEST_WEIGHT_SIZE-1 loop
                weight_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(i),DATA_SIZE));
                activation_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_VECTOR(i),DATA_SIZE));
                
                wait until falling_edge(clk);   
        end loop; 
        
        
        for r in 0 to TEST_VECTOR_SIZE-TEST_WEIGHT_SIZE loop 
            if (r<TEST_VECTOR_SIZE-TEST_WEIGHT_SIZE) then 
                control_in <= "0001001";
                activation_in <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_VECTOR(TEST_WEIGHT_SIZE+r),DATA_SIZE));
            else 
                control_in <= "0000001";
            end if;
            
            wait until falling_edge(clk);
            
            control_in <= "0000001";
            
            for i in 0 to TEST_WEIGHT_SIZE-2 loop
                wait until falling_edge(clk);
            end loop;
            
            control_in <= "0010011";
            accumulator_in <= STD_LOGIC_VECTOR(TO_SIGNED(accumulator,ACCUMULATOR_SIZE));

            wait until falling_edge(clk);
            
        end loop;
        
        control_in <= "0000000";
        
        wait;
           
    end process; 

end architecture; 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.REGISTERS.ALL; 
use IEEE.NUMERIC_STD.ALL;

entity pe_test is 

end pe_test;

architecture behavioral of pe_test is 
    constant DATA_SIZE: INTEGER := 8;
    constant ACCUMULATOR_SIZE: INTEGER := 20;
    constant QUEUE_SIZE: INTEGER := 8;
    constant ACTIVATION_INIT_BIT: INTEGER := 6; 
    constant WEIGHT_INIT_BIT: INTEGER := 5;
    constant ACCUMULATOR_INIT_BIT: INTEGER := 4;
    constant ACTIVATION_VALID_BIT: INTEGER := 3; 
    constant WEIGHT_VALID_BIT:   INTEGER := 2; 
    constant PROCESS_ELEMENT_BIT: INTEGER := 1; 
    constant PROCESS_ACCUMULATOR_BIT: INTEGER := 0;


    component PE is 
        Generic (
            DATA_SIZE: INTEGER := 8; 
            ACCUMULATOR_SIZE: INTEGER := 20; 
            QUEUE_SIZE: INTEGER := 8;
            
            ACTIVATION_INIT_BIT: INTEGER := 6; 
            WEIGHT_INIT_BIT: INTEGER := 5;
            ACCUMULATOR_INIT_BIT: INTEGER := 4;
            ACTIVATION_VALID_BIT: INTEGER := 3; 
            WEIGHT_VALID_BIT:   INTEGER := 2; 
            PROCESS_ELEMENT_BIT: INTEGER := 1; 
            PROCESS_ACCUMULATOR_BIT: INTEGER := 0
            
        );
        Port ( 
            clk:                    in STD_LOGIC;  
            reset:                  in STD_LOGIC;                 
            
            control_in:             in STD_LOGIC_VECTOR(6 downto 0); 
            weight_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_in:          in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_in:         in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            
            control_out:            out STD_LOGIC_VECTOR(6 downto 0);
            weight_out:             out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_out:         out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_out:        out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0)
            
        );
    end component;
    
    signal clk, reset: STD_LOGIC; 
    signal weight_in, weight_out, activation_in,activation_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal accumulator_in, accumulator_out: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal control_in, control_out: STD_LOGIC_VECTOR(6 downto 0);
    
    
    
begin 
    
    processing_element: pe 
        generic map(
            DATA_SIZE => DATA_SIZE,
            ACCUMULATOR_SIZE => ACCUMULATOR_SIZE, 
            QUEUE_SIZE => QUEUE_SIZE,
            
            ACTIVATION_INIT_BIT => ACTIVATION_INIT_BIT,
            WEIGHT_INIT_BIT => WEIGHT_INIT_BIT, 
            ACCUMULATOR_INIT_BIT => ACCUMULATOR_INIT_BIT,
            ACTIVATION_VALID_BIT => ACTIVATION_VALID_BIT,
            WEIGHT_VALID_BIT =>  WEIGHT_VALID_BIT,
            PROCESS_ELEMENT_BIT => PROCESS_ELEMENT_BIT,
            PROCESS_ACCUMULATOR_BIT => PROCESS_ACCUMULATOR_BIT
        ) 
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
        clk <= '1';
        wait for 5ns; 
        clk <= '0'; 
        wait for 5ns; 
    end process; 
    
    test: process 
        type SAMPLE_ARRAY is array (natural range <>) of INTEGER; 
        constant TEST_VECTOR: SAMPLE_ARRAY := (-50,20,-30,90,-40,60,-10,80,-70);
        constant TEST_WEIGHT: SAMPLE_ARRAY := (2,-5,3);
        constant TEST_RESULTS: SAMPLE_ARRAY := (-290,460,-630,560,-410,410,630);
        constant TEST_VECTOR_SIZE: INTEGER := 9;
        constant TEST_WEIGHT_SIZE: INTEGER := 3;

        constant ACCUMULATOR: INTEGER := 000;
        constant error_counter: INTEGER := 0;
    begin 
        reset <= '1'; 
        wait until rising_edge(clk); 
        
        reset <= '0'; 
      
        weight_in <= (others => '0');
        activation_in <= (others => '0');
        accumulator_in <= (others => '0'); --STD_LOGIC_VECTOR(TO_UNSIGNED(accumulator,ACCUMULATOR_SIZE));
        
        control_in <= "1110000";
        
        wait until rising_edge(clk);
        
        control_in <= "0001100";
        
        for i in 0 to TEST_WEIGHT_SIZE-1 loop
                weight_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(TEST_WEIGHT(i),DATA_SIZE));
                activation_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(TEST_VECTOR(i),DATA_SIZE));
                wait until rising_edge(clk);      
        end loop; 
        
        
        for r in 0 to TEST_VECTOR_SIZE-TEST_WEIGHT_SIZE loop 
            if (r<TEST_VECTOR_SIZE-TEST_WEIGHT_SIZE) then 
                control_in <= "0001010";
                activation_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(TEST_VECTOR(TEST_WEIGHT_SIZE+r),DATA_SIZE));
            else 
                control_in <= "0000010";
            end if;
            
            wait until rising_edge(clk);
            
            control_in <= "0000010";
            
            for i in 0 to TEST_WEIGHT_SIZE-2 loop
                wait until rising_edge(clk);
            end loop;
            
            control_in <= "0010001";
            accumulator_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(accumulator,ACCUMULATOR_SIZE));

                wait until rising_edge(clk);
            
        end loop;
        
        control_in <= "0000000";
        
        wait;
           
    end process; 

end architecture; 
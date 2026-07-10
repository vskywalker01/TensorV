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
            QUEUE_SIZE => QUEUE_SIZE
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
        constant ELEMENTS: INTEGER := 4;
        variable weight: INTEGER := 0;
        variable activation: INTEGER := 0;
        
    begin 
        reset <= '1'; 
        wait for 20ns; 
        
        reset <= '0'; 
      
        weight_in <= (others => '0');
        activation_in <= (others => '0');
        accumulator_in <= (others => '0');
        
        control_in <= "1110000";
        
        wait for 10ns; 
        
        control_in <= "0001100";
        
        for i in 0 to ELEMENTS-1 loop
            weight_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(weight,DATA_SIZE));
            activation_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(activation,DATA_SIZE));
            weight := weight +1;
            activation := activation +1;
            wait for 10ns;
        end loop; 
        
        control_in <= "0000010";
        wait for (ELEMENTS*10ns); 
        
        control_in <= "0000001";

        wait for 10ns; 
        
        control_in <= "0000000";
        
        wait;
           
    end process; 

end architecture; 
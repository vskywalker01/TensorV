library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity requantizer_test is
--  Port ( );
end requantizer_test;

architecture Behavioral of requantizer_test is
    constant DATA_SIZE:          INTEGER := 20; 
    constant OUTPUT_SIZE:        INTEGER := 8;
    constant SHIFT_VALUE_BITS:   INTEGER := 5;
    component requantizer is
        Generic (
            DATA_SIZE:          INTEGER := 20; 
            OUTPUT_SIZE:        INTEGER := 8;
            SHIFT_VALUE_BITS:   INTEGER := 5
        );
        Port ( 
            clk:        in STD_LOGIC; 
            reset:      in STD_LOGIC; 
        
            data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            shift:      in STD_LOGIC_VECTOR(SHIFT_VALUE_BITS-1 downto 0);
            valid_in:   in STD_LOGIC;  
            
            data_out:   out STD_LOGIC_VECTOR(OUTPUT_SIZE-1 downto 0); 
            valid_out:  out STD_LOGIC
            
        );
    end component;
    signal clk, reset:  STD_LOGIC; 
    signal data_in:     STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal shift:       STD_LOGIC_VECTOR(SHIFT_VALUE_BITS-1 downto 0);
    signal valid_in:    STD_LOGIC;  
    signal data_out:    STD_LOGIC_VECTOR(OUTPUT_SIZE-1 downto 0); 
    signal valid_out:   STD_LOGIC;
 
begin
    requantizer_entity: requantizer 
        Generic map (
            DATA_SIZE => DATA_SIZE,
            OUTPUT_SIZE => OUTPUT_SIZE,
            SHIFT_VALUE_BITS => SHIFT_VALUE_BITS
        )
        Port map (
            clk => clk, 
            reset => reset, 
            data_in => data_in,
            shift => shift, 
            valid_in => valid_in,
            data_out => data_out,
            valid_out => valid_out
        );
    
    clock: process is 
    begin 
        clk <= '0'; 
        wait for 5ns; 
        clk <= '1';
        wait for 5ns;
    end process;
    
    test: process is 
        variable shift_value: INTEGER := 0;
    begin 
        reset <= '1'; 
        data_in <= (others => '0'); 
        shift <= (others => '0');
        valid_in <= '0';
        
        wait until rising_edge(clk); 
        wait until rising_edge(clk); 
        
        reset <= '0'; 
        
        wait until rising_edge(clk); 
        
        data_in <= (3 => '0', others => '1'); 
        shift <= STD_LOGIC_VECTOR(to_unsigned(2, SHIFT_VALUE_BITS));
        valid_in <= '1'; 
        
        wait until rising_edge(clk); 
        valid_in <= '0';
        
        wait until rising_edge(clk); 
        valid_in <= '1'; 
        data_in <= (DATA_SIZE-1 => '0', others => '1');
        
        for i in 0 to DATA_SIZE-1 loop 
            shift <= STD_LOGIC_VECTOR(to_unsigned(shift_value, SHIFT_VALUE_BITS));
            shift_value := shift_value +1; 
            wait until rising_edge(clk); 
        end loop; 
        
        valid_in <= '0';
        
        wait;
    end process;
    
end Behavioral;

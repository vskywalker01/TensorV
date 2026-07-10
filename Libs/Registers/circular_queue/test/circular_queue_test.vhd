library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity  circular_queue_test is 
    
end  circular_queue_test;

architecture behavioral of  circular_queue_test is 
    constant DATA_SIZE: INTEGER := 8;
    constant REGISTERS: INTEGER := 4; 

        

    component circular_queue is 
        Generic (
            DATA_SIZE:      INTEGER := 8;
            REGISTERS:      INTEGER := 16 
        );
        Port (
            -- Control lines 
            clk: in STD_LOGIC;                                          -- clock 
            reset: in STD_LOGIC;                                        -- reset (when '1') 
             
            
            init: in STD_LOGIC;
            add: in STD_LOGIC; 
            shift: in STD_LOGIC; 
    
            
            -- Data lines
            data_in:         in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- input port
            data_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0)           -- output port
    
        );
    end component;
    
    signal clk,reset, init,add,shift: STD_LOGIC;
    signal data_in,data_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);

begin 

    queue:  circular_queue 
        generic map (
            DATA_SIZE => DATA_SIZE,
            REGISTERS => REGISTERS
        )
        port map (
            clk => clk, 
            reset => reset, 
            init => init, 
            add => add, 
            shift => shift,
            data_in => data_in, 
            data_out => data_out
        );
    
    clock: process
    begin 
        clk <= '1';
        wait for 5ns; 
        clk <= '0';
        wait for 5ns; 
    end process;
    
    test: process 
        variable counter: INTEGER := 1;
    begin 
        reset <= '1'; 
        wait for 20ns;
        reset <= '0';
        init <='1'; 
        add <= '0'; 
        shift <= '0'; 
        
        wait for 20ns; 
        init <= '0';
        add <= '1'; 
        shift <= '0';
        counter := 0;  

        for i in 0 to 4 loop 
            counter := counter+1; 
            data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));      
            wait for 10ns;
        end loop;
        
        add <= '0'; 
        shift <= '0';
        wait for 20ns; 
        add <= '0';
        shift <= '1';  
        wait for 30ns;         
        shift <= '0';
        wait for 30ns;
        shift <= '1'; 
        add <= '1'; 
        for i in 0 to 3 loop 
            counter := counter+1; 
            data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));      
            wait for 10ns;
        end loop;
        shift <= '0'; 
        add <= '0'; 
        wait;
        
    end process;

end architecture; 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity  circular_queue_test is 
    
end  circular_queue_test;

architecture behavioral of  circular_queue_test is 
    constant DATA_SIZE: INTEGER := 8;
    constant REGISTERS: INTEGER := 5; 
    component circular_queue is 
--        Generic (
--            DATA_SIZE:      INTEGER := 8;
--            REGISTERS:      INTEGER := 8
--        );
        Port (
            -- Control lines 
            clk: in STD_LOGIC;                                          -- clock 
            reset: in STD_LOGIC;                                        -- reset (when '1') 
             
            
            init: in STD_LOGIC; 
            shift: in STD_LOGIC; 
            add: in STD_LOGIC;
    
            
            -- Data lines
            data_in:         in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- input port
            data_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- output port
            
            empty_out:       out STD_LOGIC
    
        );
    end component;
    
    signal clk,reset, init,add,empty,shift: STD_LOGIC;
    signal data_in,data_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);

begin 

    queue: circular_queue 
--        generic map (
--            DATA_SIZE => DATA_SIZE,
--            REGISTERS => REGISTERS
--        )
        port map (
            clk => clk, 
            reset => reset, 
            init => init, 
            add => add, 
            shift => shift,
            data_in => data_in, 
            data_out => data_out,
            empty_out => empty
        );
    
    clock: process
    begin 
        clk <= '1';
        wait for 5ns; 
        clk <= '0';
        wait for 5ns; 
    end process;
    
    test: process 
        variable counter: INTEGER := 0;
    begin 
        reset <= '1'; 

        wait until rising_edge(clk);
        
        reset <= '0';
        init <='1'; 
        add <= '0'; 
        shift <= '0'; 
        data_in <= (others => '0');
        
        for i in 0 to 2 loop 
            wait until rising_edge(clk);
        end loop;
        init <= '0';
        add <= '1'; 

             
        for i in 0 to REGISTERS-1 loop 
            data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));  
            counter := counter+1;     
            wait until rising_edge(clk);
        end loop;
        
        add <= '0'; 
        shift <= '1';

        for i in 0 to REGISTERS-1 loop 
            wait until rising_edge(clk);
        end loop;
                
        data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE)); 
        add <= '1';
        shift <= '1'; 
        for i in 0 to (REGISTERS*2)-1 loop     
            wait until rising_edge(clk);
            add <= '0';
        end loop;
        shift <= '0';
        add <= '0'; 
        wait;
        
    end process;

end architecture; 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity  queue_test is 
    
end  queue_test;

architecture behavioral of queue_test is 
    constant DATA_SIZE: INTEGER := 8;
    constant REGISTERS: INTEGER := 8; 
    component queue is 
--        Generic (
--            DATA_SIZE:      INTEGER := 8;
--            REGISTERS:      INTEGER := 8
--        );
        Port (
            -- Control lines 
            clk: in STD_LOGIC;                                          -- clock 
            reset: in STD_LOGIC;                                        -- reset (when '1') 
             
            
            init: in STD_LOGIC; 
            push: in STD_LOGIC; 
            pop: in STD_LOGIC;
    
            
            -- Data lines
            data_in:         in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- input port
            data_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- output port
            
            empty_out:       out STD_LOGIC
    
        );
    end component;
    
    signal clk,reset, init,push,empty,pop: STD_LOGIC;
    signal data_in,data_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);

begin 

    fifo: queue 
--        generic map (
--            DATA_SIZE => DATA_SIZE,
--            REGISTERS => REGISTERS
--        )
        port map (
            clk => clk, 
            reset => reset, 
            init => init, 
            push => push, 
            pop => pop,
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
        variable counter: INTEGER := 10;
    begin 
        reset <= '1';

        wait until rising_edge(clk);
        
        reset <= '0';
        init <='1'; 
        push <= '0'; 
        pop <= '0'; 
        data_in <= (others => '0');
        wait until rising_edge(clk);
        pop <= '1'; 
        wait until rising_edge(clk);
        pop <= '0';
        
        for i in 0 to 2 loop 
            wait until rising_edge(clk);
        end loop;
        init <= '0';
        push <= '1'; 

             
        for i in 0 to REGISTERS-1 loop 
            data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));  
            counter := counter+1;     
            wait until rising_edge(clk);
        end loop;
        
        push <= '0'; 
        pop <= '1';

        for i in 0 to REGISTERS-3 loop 
            wait until rising_edge(clk);
        end loop;
  
        data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE)); 
        push <= '1';
        pop <= '1'; 
        for i in 0 to (REGISTERS*2)-1 loop     
            wait until rising_edge(clk);
            push <= '0';
        end loop;
        
        --
        
        push <= '1'; 
        pop <= '0';
        for i in 0 to REGISTERS-1 loop 
            data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));  
            counter := counter+1;     
            wait until rising_edge(clk);
        end loop;
        
        push <= '0'; 
        pop <= '1';
  
        for i in 0 to (REGISTERS*2)-1 loop     
            wait until rising_edge(clk);
            push <= '0';
        end loop;
        
        pop <= '0';
        push <= '0'; 
        wait;
        
    end process;

end architecture; 
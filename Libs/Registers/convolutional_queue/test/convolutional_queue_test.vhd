library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity  convolutional_queue_test is 
    
end  convolutional_queue_test;

architecture behavioral of  convolutional_queue_test is 
    constant DATA_SIZE: INTEGER := 8;
    constant REGISTERS: INTEGER := 8; 
    constant COUNTER_SIZE: INTEGER := 3;
    component convolutional_queue is 
        Generic (
            DATA_SIZE:      INTEGER := 8;
            REGISTERS:      INTEGER := 8;
            COUNTER_SIZE:   INTEGER := 3
        );
        Port (
            -- Control lines 
            clk: in STD_LOGIC;                                          -- clock 
            reset: in STD_LOGIC;                                        -- reset (when '1') 
            
            init: in STD_LOGIC; 
            move: in STD_LOGIC; 
            add: in STD_LOGIC;
    
            
            -- Data lines
            data_in:         in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- input port
            data_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);          -- output port
            
            size_in:         in STD_LOGIC_VECTOR(COUNTER_SIZE-1 downto 0); 
            skip_in:         in STD_LOGIC_VECTOR(COUNTER_SIZE-1 downto 0);
            
            empty_out:           out STD_LOGIC;
            done_out:            out STD_LOGIC           
        );
    end component;
    
    signal clk,reset, init,add,move, empty, done: STD_LOGIC;
    signal data_in,data_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal skip_in, size_in: STD_LOGIC_VECTOR(COUNTER_SIZE-1 downto 0);
begin 

    queue: convolutional_queue 
--        generic map (
--            DATA_SIZE => DATA_SIZE,
--            REGISTERS => REGISTERS
--        )
        port map (
            clk => clk, 
            reset => reset, 
            init => init, 
            add => add, 
            move => move,
            data_in => data_in, 
            data_out => data_out,
            skip_in => skip_in,
            size_in => size_in,
            empty_out => empty,
            done_out => done
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
        variable size: INTEGER := 5;
    begin 
        reset <= '1'; 

        wait until rising_edge(clk);
        -- first test (skip =1, size>skip, the queue is not full)
        reset <= '0';
        init <='1'; 
        size_in <= STD_LOGIC_VECTOR(to_unsigned(size,COUNTER_SIZE)); 
        skip_in <= STD_LOGIC_VECTOR(to_unsigned(1,COUNTER_SIZE));
        
        add <= '0'; 
        move <= '0'; 
        data_in <= (others => '0');
        
        for i in 0 to 2 loop 
            wait until rising_edge(clk);
        end loop;
        init <= '0';
        add <= '1'; 

             
        for i in 0 to REGISTERS-2 loop 
            data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));  
            counter := counter+1;     
            wait until rising_edge(clk);
        end loop;
        
        add <= '0'; 
        move <= '1';

        for i in 0 to (size*3)+3 loop 
            wait until rising_edge(clk);
        end loop;

        
        -- second test (skip > size, the queue is not full)
                
        init <='1'; 
        size_in <= STD_LOGIC_VECTOR(to_unsigned(size,COUNTER_SIZE)); 
        skip_in <= STD_LOGIC_VECTOR(to_unsigned(size+1,COUNTER_SIZE));
        
        add <= '0'; 
        move <= '0'; 
        data_in <= (others => '0');
        
        for i in 0 to 2 loop 
            wait until rising_edge(clk);
        end loop;
        init <= '0';
        add <= '1'; 

             
        for i in 0 to REGISTERS-2 loop 
            data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));  
            counter := counter+1;     
            wait until rising_edge(clk);
        end loop;
        
        add <= '0'; 
        move <= '1';
        
        for i in 0 to (size*3)+3 loop 
            wait until rising_edge(clk);
        end loop;
        
        -- third test (the queue is full)
        
        init <='1'; 
        size_in <= STD_LOGIC_VECTOR(to_unsigned(size,COUNTER_SIZE)); 
        skip_in <= STD_LOGIC_VECTOR(to_unsigned(size-2,COUNTER_SIZE));
        
        add <= '0'; 
        move <= '0'; 
        data_in <= (others => '0');
        
        for i in 0 to 2 loop 
            wait until rising_edge(clk);
        end loop;
        init <= '0';
        add <= '1'; 

             
        for i in 0 to REGISTERS+2 loop 
            data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));  
            counter := counter+1;     
            wait until rising_edge(clk);
        end loop;
        
        add <= '0'; 
        move <= '1';
        
        for i in 0 to (size*2)+3 loop 
            wait until rising_edge(clk);
        end loop;
        
        move <= '0';
        wait;
        
    end process;

end architecture; 

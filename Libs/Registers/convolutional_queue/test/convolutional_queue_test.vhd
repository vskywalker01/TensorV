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
    
            add_weight: in STD_LOGIC;
            add_activation: in STD_LOGIC;
            
            move: in STD_LOGIC; 
                    
            -- Data lines
            activation_in:         in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- input port
            activation_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);          -- output port
            
            weight_in:             in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            weight_out:            out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            
            skip_in:         in STD_LOGIC_VECTOR(COUNTER_SIZE-1 downto 0);
            
            empty_out:           out STD_LOGIC;         
            done_out:            out STD_LOGIC 
        );  
    end component;
    
    signal clk,reset, init, add_weight, add_activation, move, empty, done: STD_LOGIC;
    signal activation_in,activation_out,weight_in,weight_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal skip_in: STD_LOGIC_VECTOR(COUNTER_SIZE-1 downto 0);
begin 

    queue: convolutional_queue 
        port map (
            clk => clk, 
            reset => reset, 
            init => init, 
            add_activation => add_activation,
            add_weight => add_weight, 
            move => move,
            weight_in => weight_in, 
            weight_out => weight_out,
            activation_in => activation_in,
            activation_out => activation_out,
            skip_in => skip_in,
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
        variable weight_counter: INTEGER := 10;
        variable weight_size: INTEGER := 3;
        variable activation_size: INTEGER := 7;
    begin 
        reset <= '1'; 

        wait until rising_edge(clk);
        -- first test (skip =1, size>skip, the queue is not full)
        reset <= '0';
        init <='1'; 
        skip_in <= STD_LOGIC_VECTOR(to_unsigned(1,COUNTER_SIZE));
        
        add_weight <= '0'; 
        add_activation <= '0';
        move <= '0'; 
        weight_in <= (others => '0');
        activation_in <= (others => '0');
        
        for i in 0 to 2 loop 
            wait until rising_edge(clk);
        end loop;
        
        init <= '0';
        add_activation <= '1'; 

             
        for i in 0 to ACTIVATION_SIZE-1 loop 
            activation_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));  
            if (i < WEIGHT_SIZE) then 
                add_weight <= '1';
                weight_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(weight_counter,DATA_SIZE));
                weight_counter := weight_counter +1;
            else 
                add_weight <= '0';
            end if; 
            counter := counter+1;     
            wait until rising_edge(clk);
        end loop;
        
        add_activation <= '0'; 
        move <= '1';

        for i in 0 to (ACTIVATION_SIZE*3)+3 loop 
            wait until rising_edge(clk);
        end loop;

         -- second test (skip = activation_size)

        init <='1'; 
        skip_in <= STD_LOGIC_VECTOR(to_unsigned(ACTIVATION_SIZE,COUNTER_SIZE));
        
        add_weight <= '0'; 
        add_activation <= '0';
        move <= '0'; 
        weight_in <= (others => '0');
        activation_in <= (others => '0');
        
        for i in 0 to 2 loop 
            wait until rising_edge(clk);
        end loop;
        
        init <= '0';
        add_activation <= '1'; 

             
        for i in 0 to ACTIVATION_SIZE-1 loop 
            activation_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));  
            if (i < WEIGHT_SIZE) then 
                add_weight <= '1';
                weight_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(weight_counter,DATA_SIZE));
                weight_counter := weight_counter +1;
            else 
                add_weight <= '0';
            end if; 
            counter := counter+1;     
            wait until rising_edge(clk);
        end loop;
        
        add_activation <= '0'; 
        move <= '1';

        for i in 0 to (ACTIVATION_SIZE*3)+3 loop 
            wait until rising_edge(clk);
        end loop;

         -- third test (activation queue overflow)

        init <='1'; 
        skip_in <= STD_LOGIC_VECTOR(to_unsigned(ACTIVATION_SIZE,COUNTER_SIZE));
        
        add_weight <= '0'; 
        add_activation <= '0';
        move <= '0'; 
        weight_in <= (others => '0');
        activation_in <= (others => '0');
        
        for i in 0 to 2 loop 
            wait until rising_edge(clk);
        end loop;
        
        init <= '0';
        add_activation <= '1'; 

             
        for i in 0 to ACTIVATION_SIZE+5 loop 
            activation_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));  
            if (i < WEIGHT_SIZE) then 
                add_weight <= '1';
                weight_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(weight_counter,DATA_SIZE));
                weight_counter := weight_counter +1;
            else 
                add_weight <= '0';
            end if; 
            counter := counter+1;     
            wait until rising_edge(clk);
        end loop;
        
        add_activation <= '0'; 
        move <= '1';

        for i in 0 to (ACTIVATION_SIZE*3)+3 loop 
            wait until rising_edge(clk);
        end loop;

         -- fourth test (activation and weight queue overflow)

        init <='1'; 
        skip_in <= STD_LOGIC_VECTOR(to_unsigned(ACTIVATION_SIZE,COUNTER_SIZE));
        
        add_weight <= '0'; 
        add_activation <= '0';
        move <= '0'; 
        weight_in <= (others => '0');
        activation_in <= (others => '0');
        
        for i in 0 to 2 loop 
            wait until rising_edge(clk);
        end loop;
        
        init <= '0';
        add_activation <= '1'; 
        add_weight <= '1';
             
        for i in 0 to ACTIVATION_SIZE+5 loop 
            activation_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter,DATA_SIZE));  
            weight_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(weight_counter,DATA_SIZE));
            weight_counter := weight_counter +1;
            counter := counter+1;     
            wait until rising_edge(clk);
        end loop;
        
        add_activation <= '0'; 
        add_weight <= '0';
        move <= '1';

        for i in 0 to (ACTIVATION_SIZE*3)+3 loop 
            wait until rising_edge(clk);
        end loop;

        move <= '0';
        
        wait;
        
    end process;

end architecture; 

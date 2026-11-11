library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity buffer_unit_test is
--  Port ( );
end buffer_unit_test;

architecture Behavioral of buffer_unit_test is
    constant DATA_SIZE: INTEGER := 8;
    constant QUEUE_SIZE: INTEGER := 8;
    constant BUFFER_SIZE_BITS: INTEGER := 3;

    component buffer_unit is
        Generic (
            DATA_SIZE: INTEGER := 8;
            BUFFER_SIZE_BITS: INTEGER := 3
        );
        Port (         
            clk:        in STD_LOGIC;
            reset:      in STD_LOGIC;
            enable:     in STD_LOGIC;
        
            init:       in STD_LOGIC;
            add_in:     in STD_LOGIC;
            
            step_in:   in STD_LOGIC;
            send_in:    in STD_LOGIC;
            counter_in: in STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
            data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
             
            valid_out:  out STD_LOGIC;
            data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            ready_out:  out STD_LOGIC
    
        );
    end component;
    
    signal clk, reset, init, step_in, add_in, send_in, valid_out, ready_out, enable: STD_LOGIC;
    signal counter_in: STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
    signal data_in,data_out: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
   
begin
    unit: buffer_unit 
        Generic map (
            DATA_SIZE => DATA_SIZE,
            BUFFER_SIZE_BITS => BUFFER_SIZE_BITS
        )
        Port map (
            clk => clk, 
            reset => reset, 
            enable => enable,
            init => init, 
            add_in => add_in, 
            step_in => step_in, 
            send_in => send_in, 
            counter_in => counter_in,
            data_in => data_in, 
            valid_out => valid_out, 
            data_out => data_out, 
            ready_out => ready_out
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
        counter_in <= STD_LOGIC_VECTOR(to_unsigned(7, BUFFER_SIZE_BITS));
        
        reset <= '0'; 
        enable <= '1';
        init <= '1'; 
        add_in <= '0';
        step_in <= '0';
        send_in <= '0';
        data_in <= (others => '0');
        
        wait until rising_edge(clk); 
        
        send_in <= '0';
        add_in <= '1';
        init <= '0';
        for i in 0 to 9 loop
            data_in <= STD_LOGIC_VECTOR(to_unsigned(counter, DATA_SIZE));
            counter := counter + 1;
            wait until rising_edge(clk);
        end loop;

        init <= '0'; 
        add_in <= '0';
        send_in <= '1';
        step_in <= '1';
        wait until rising_edge(clk);
        send_in <= '0';
      
        for i in 0 to 2 loop
            wait until rising_edge(clk);
        end loop;
        
        step_in <= '0';
        
        for i in 0 to 3 loop
            wait until rising_edge(clk);
        end loop;
        
        step_in <= '1';
        
        for i in 0 to 5 loop 
            wait until rising_edge(clk); 
        end loop; 
        init <= '1'; 
        
        wait until rising_edge(clk); 
        init <= '0';
        enable <= '0';
        
        counter_in <= (others => '0');
        send_in <= '1';
        step_in <= '1'; 
        
        wait until rising_edge(clk); 
        send_in <= '0';
        step_in <= '0'; 
        
        
        wait until rising_edge(clk);
        
        enable <= '1';
        send_in <= '1';
        counter_in <= STD_LOGIC_VECTOR(to_unsigned(5, BUFFER_SIZE_BITS));
        
        wait until rising_edge(clk);
        send_in <= '0';
        
        step_in <= '1';
        add_in <= '1';
        init <= '0';
        for i in 0 to 9 loop
            data_in <= STD_LOGIC_VECTOR(to_unsigned(counter, DATA_SIZE));
            counter := counter + 1;
            wait until rising_edge(clk);
        end loop;
        add_in <= '0';
                
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        step_in <= '1';
        
        
        
        wait;
        
    end process;
    
end Behavioral;

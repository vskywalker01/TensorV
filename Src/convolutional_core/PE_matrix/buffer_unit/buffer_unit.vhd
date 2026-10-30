library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.registers.ALL;

entity buffer_unit is
    Generic (
        DATA_SIZE: INTEGER := 8;
        COUNTER_SIZE: INTEGER := 3
    );
    Port (         
        clk:        in STD_LOGIC;
        reset:      in STD_LOGIC;
        enable:     in STD_LOGIC; 
    
        init:       in STD_LOGIC;
        add_in:     in STD_LOGIC;
        
        step_in:    in STD_LOGIC;
        send_in:    in STD_LOGIC;
        counter_in: in STD_LOGIC_VECTOR(COUNTER_SIZE-1 downto 0);
        data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
         
        data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        valid_out:  out STD_LOGIC;
        ready_out:  out STD_LOGIC

    );
end buffer_unit;

architecture Behavioral of buffer_unit is
    signal counter: UNSIGNED(COUNTER_SIZE-1 downto 0);
    signal buffer_pop, buffer_empty: STD_LOGIC;
begin
    buffer_queue: queue 
        generic map ( 
            DATA_SIZE => DATA_SIZE, 
            COUNTER_BITS => COUNTER_SIZE
        ) 
        port map (
            clk => clk, 
            reset => reset, 
            init => init,
            pop => buffer_pop,
            push => add_in,
            empty_out => buffer_empty,
            data_in => data_in, 
            data_out => data_out
        );

    buffer_pop <= '1' when (enable = '1' and ((counter > 1 and step_in = '1') or send_in = '1')) else '0'; 
    
    stage1: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1' or init = '1') then 
                counter <= (others => '0');
                ready_out <= '1';
                valid_out <= '0';
            elsif(enable = '1') then
                if (send_in = '1') then 
                    counter <= UNSIGNED(counter_in);
                    ready_out <= '0';
                elsif (counter > 1 and buffer_empty = '0' and step_in = '1') then 
                    counter <= counter - 1;
                    ready_out <= '0';
                else 
                    ready_out <= '1';
                end if;               
                
                valid_out <= buffer_pop;
            end if;
        end if;
    end process;
    
end Behavioral;

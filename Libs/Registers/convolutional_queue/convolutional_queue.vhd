-- Definition of dynamic queue. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.ALL;

entity convolutional_queue is 
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
end  convolutional_queue;

architecture Behavioral of convolutional_queue is

    type REGISTER_ARRAY         is array (REGISTERS-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
    -- The registers are defined as an array of vectors;
    signal register_file: REGISTER_ARRAY; 
    signal tail: UNSIGNED(COUNTER_SIZE downto 0);
    signal head, current_head: UNSIGNED(COUNTER_SIZE downto 0);
    signal skip, size, current_skip, current_size: UNSIGNED(COUNTER_SIZE-1 downto 0);

begin     

    empty_out <= '1' when (tail = head) or (tail = current_head) else '0';
    done_out <= '1' when (current_size = size) else '0';          
           
    queue: process (clk) 
        variable index: INTEGER; 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1' or init = '1') then 
            
                data_out <= (others => '0');
                head <= (others => '0');
                current_head <= (others => '0');
                tail <= (others => '0');
                skip <= UNSIGNED(skip_in);
                size <= UNSIGNED(size_in); 
                current_skip <= UNSIGNED(skip_in);
                current_size <= UNSIGNED(size_in);

            else               
                if (add = '1' and (not (tail = (head-1) mod REGISTERS))) then
                    register_file(to_integer(tail)) <= data_in;
                    tail <= tail + 1;  
                end if;
                
                if (move = '1') then 
                    if (current_skip > 0 and current_size > 0 and not(tail = head)) then 
                        current_skip <=  current_skip-1;
                        current_size <= current_size-1; 
                        head <= head + 1;
                        current_head <= head + 1;
                        data_out <= register_file(to_integer(head));

                    elsif (current_skip = 0 and current_size > 0 and not(tail = current_head)) then 
                        current_size <= current_size-1; 
                        current_head <= (current_head+1);
                        data_out <= register_file(to_integer(current_head));
                        
                    elsif (current_size = 0) then
                        current_size <= size; 
                        current_skip <= skip; 
                        current_head <= head;
                    end if;
                end if; 
            end if; 
        end if;
    end process;
end architecture;
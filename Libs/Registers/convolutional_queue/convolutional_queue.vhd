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
end  convolutional_queue;

architecture Behavioral of convolutional_queue is

    type REGISTER_ARRAY         is array (REGISTERS-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
    -- The registers are defined as an array of vectors;
    signal activation_register_file, weight_register_file: REGISTER_ARRAY; 
    
    signal activation_tail, weight_tail: UNSIGNED(COUNTER_SIZE downto 0);
    signal activation_head, activation_current_head, weight_head: UNSIGNED(COUNTER_SIZE downto 0);
    signal skip, size, current_skip, current_size: UNSIGNED(COUNTER_SIZE-1 downto 0);

begin     
    
    done_out <= '1' when (current_size = size) else '0';          

    queue: process (clk) 
        variable index: INTEGER; 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1' or init = '1') then 
                activation_out <= (others => '0');
                weight_out <= (others => '0');
                
                activation_current_head <= (others => '0');
                activation_head <= (others => '0');
                activation_tail <= (others => '0');
                
                weight_head <= (others => '0');
                weight_tail <= (others => '0');
                skip <= UNSIGNED(skip_in);
                size <= (others => '0');
                current_skip <= UNSIGNED(skip_in);
                current_size <= (others => '0');
                
                empty_out <= '1';
            else               
            
                if (add_weight = '1' and (weight_tail + 1) < REGISTERS) then
                    weight_register_file(to_integer(weight_tail)) <= weight_in;
                    weight_tail <= (weight_tail + 1) mod REGISTERS;
                    size <= size + 1;  
                end if;
                
                if (add_activation = '1' and (not (activation_tail = (activation_head-1) mod REGISTERS))) then
                    activation_register_file(to_integer(activation_tail)) <= activation_in;
                    activation_tail <= (activation_tail + 1) mod REGISTERS;  
                end if;
                
                if (move = '1') then 
                    if (current_skip > 0 and current_size > 0 and not(weight_head = weight_tail) and not(activation_tail = activation_head)) then 
                        current_skip <=  current_skip-1;
                        current_size <= current_size-1; 
                        activation_head <= (activation_head + 1) mod REGISTERS;
                        activation_current_head <= (activation_head + 1) mod REGISTERS;
                        weight_head <= (weight_head + 1) mod REGISTERS;
                        
                        activation_out <= activation_register_file(to_integer(activation_head));
                        weight_out <= weight_register_file(to_integer(weight_head));

                    elsif (current_skip = 0 and current_size > 0 and not(activation_tail = activation_current_head) and not (weight_tail = 0)) then 
                        current_size <= current_size-1; 
                        activation_current_head <= (activation_current_head+1) mod REGISTERS;
                        weight_head <= (weight_head + 1) mod REGISTERS;
                        activation_out <= activation_register_file(to_integer(activation_current_head));
                        weight_out <= weight_register_file(to_integer(weight_head));
                        
                    elsif (current_size = 0) then
                        current_size <= size; 
                        current_skip <= skip; 
                        activation_current_head <= activation_head;
                        weight_head <= (others => '0');
                    end if;
                    
                end if; 
                
                if (activation_tail = activation_head or (activation_tail = activation_current_head and current_size>0)) then 
                    empty_out <= '1';
                else 
                    empty_out <= '0';
                end if; 
                
            end if; 
        end if;
    end process;
end architecture;
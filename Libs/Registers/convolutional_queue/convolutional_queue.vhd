-- Definition of dynamic queue. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.ALL;

entity convolutional_queue is 
    Generic (
        DATA_SIZE:      INTEGER := 8;
        COUNTER_BITS:   INTEGER := 3
    );
    Port (
        -- Control lines 
        clk: in STD_LOGIC;                                          -- clock 
        reset: in STD_LOGIC;                                        -- reset (when '1') 
        
        init_activation: in STD_LOGIC;
        init_weight:    in STD_LOGIC;
    
        add_weight: in STD_LOGIC;
        add_activation: in STD_LOGIC;
        
        move: in STD_LOGIC; 
                
        -- Data lines
        activation_in:         in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- input port
        activation_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);          -- output port
        
        weight_in:             in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        weight_out:            out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        
        skip_in:         in STD_LOGIC_VECTOR(COUNTER_BITS-1 downto 0);
        
        empty_out:           out STD_LOGIC;         
        done_out:            out STD_LOGIC 
    );
end  convolutional_queue;

architecture Behavioral of convolutional_queue is
    constant REGISTERS: INTEGER := 2 ** COUNTER_BITS; 
    type REGISTER_ARRAY         is array (REGISTERS-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
    -- The registers are defined as an array of vectors;
    signal activation_register_file, weight_register_file: REGISTER_ARRAY; 
    
    signal activation_head, activation_current_head:            UNSIGNED(COUNTER_BITS downto 0);
    signal activation_tail:                                     UNSIGNED(COUNTER_BITS downto 0);
    signal weight_size, weight_current_head:                    UNSIGNED(COUNTER_BITS downto 0);
    signal skip, current_skip:                                  UNSIGNED(COUNTER_BITS-1 downto 0); 
    
    signal activation_full, activation_empty: STD_LOGIC; 
    signal activation_waiting: STD_LOGIC; 
    
begin     
    activation_full <= '1' when (activation_head(COUNTER_BITS-1 downto 0) = activation_tail(COUNTER_BITS-1 downto 0) and not(activation_head(COUNTER_BITS) = activation_tail(COUNTER_BITS))) else '0';
    activation_empty <= '1' when (activation_head(COUNTER_BITS-1 downto 0) = activation_tail(COUNTER_BITS-1 downto 0) and activation_head(COUNTER_BITS) = activation_tail(COUNTER_BITS)) else '0';
    activation_waiting <= '1' when (activation_current_head(COUNTER_BITS-1 downto 0) = activation_tail(COUNTER_BITS-1 downto 0) and activation_current_head(COUNTER_BITS) = activation_tail(COUNTER_BITS)) else '0';
    
    queue: process (clk) 
        variable index: INTEGER; 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1') then 
                activation_out <= (others => '0');
                weight_out <= (others => '0');
                
                weight_current_head <= (others => '0');
                activation_current_head <= (others => '0');
                activation_head <= (others => '0');
                activation_tail <= (others => '0');
                
                weight_size <= (others => '0');
             
                skip <= (others => '0');
                current_skip <= UNSIGNED(skip_in);
                
                done_out <= '0';
                empty_out <= '1';
           
            elsif (init_activation = '1' or init_weight = '1') then 
                if (init_weight = '1') then
                    skip <= UNSIGNED(skip_in);
                    current_skip <= UNSIGNED(skip_in); 
                    weight_size <= (others => '0');
                else 
                    current_skip <= skip;
                end if; 
                
                activation_current_head <= (others => '0');
                weight_current_head <= (others => '0');
                activation_head <= (others => '0');
                activation_tail <= (others => '0');
                
            else                         
                if (add_weight = '1' and weight_size < REGISTERS) then
                    weight_register_file(to_integer(weight_size(COUNTER_BITS-1 downto 0))) <= weight_in;
                    weight_size <= weight_size +1;
                end if;
                
                if (add_activation = '1' and activation_full = '0') then
                    activation_register_file(to_integer(activation_tail(COUNTER_BITS-1 downto 0))) <= activation_in;
                    activation_tail <= activation_tail + 1;
                end if;
                
                if (move = '1') then 
                    if (weight_current_head < weight_size and current_skip > 0 and activation_empty = '0') then 
                        current_skip <=  current_skip-1;
                        weight_current_head <= weight_current_head-1;       
                        activation_head <= activation_head + 1;
                        activation_current_head <= activation_head + 1;
                        weight_current_head <= weight_current_head + 1;
                        
                        activation_out <= activation_register_file(to_integer(activation_head(COUNTER_BITS-1 downto 0)));
                        weight_out <= weight_register_file(to_integer(weight_current_head(COUNTER_BITS-1 downto 0)));
                        done_out <= '0';

                    elsif (current_skip = 0 and weight_current_head < weight_size and activation_waiting = '0') then 
                        activation_current_head <= activation_current_head+1 ;
                        weight_current_head <= weight_current_head + 1;
                        activation_out <= activation_register_file(to_integer(activation_current_head(COUNTER_BITS-1 downto 0)));
                        weight_out <= weight_register_file(to_integer(weight_current_head(COUNTER_BITS-1 downto 0)));
                        done_out <= '0';
                        
                    elsif (weight_current_head = weight_size) then
                        current_skip <= skip; 
                        activation_current_head <= activation_head;
                        weight_current_head <= (others => '0');
                        done_out <= '1';
                    end if;
                end if;         
                
                if ((activation_empty = '1' or (weight_current_head < weight_size and activation_waiting = '1')) and add_activation = '0') then 
                    empty_out <= '1';
                else 
                    empty_out <= '0';
                end if;
                        
            end if; 
        end if;
    end process;
end architecture;
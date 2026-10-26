-- Definition of dynamic queue. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.ALL;

entity queue is 
    Generic (
        DATA_SIZE:      INTEGER := 8;
        COUNTER_BITS:   INTEGER := 3
    );
    Port (
        -- Control lines 
        clk: in STD_LOGIC;                                          -- clock 
        reset: in STD_LOGIC;                                        -- reset (when '1') 
         
        
        init: in STD_LOGIC; 
        pop: in STD_LOGIC; 
        push: in STD_LOGIC;

        
        -- Data lines
        data_in:         in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- input port
        data_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- output port
        
        empty_out:           out STD_LOGIC

    );
end queue;

architecture Behavioral of queue is
    constant REGISTERS: INTEGER := 2 ** COUNTER_BITS; 
    type REGISTER_ARRAY is array (REGISTERS-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
    
    -- The registers are defined as an array of vectors;
    signal register_file:   REGISTER_ARRAY; 
    signal tail:            UNSIGNED(COUNTER_BITS downto 0);
    signal head:            UNSIGNED(COUNTER_BITS downto 0);
    signal lsb_equal, msb_equal:   STD_LOGIC;
    
begin     
    lsb_equal <= '1' when (tail(COUNTER_BITS-1 downto 0) = head(COUNTER_BITS-1 downto 0)) else '0';
    msb_equal <= '1' when (tail(COUNTER_BITS) = head(COUNTER_BITS)) else '0';
   
    queue: process (clk) 
        variable index: INTEGER; 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1' or init = '1') then 
                data_out <= (others => '0');
                head <= (others => '0');
                tail <= (others => '0');
                empty_out <= '1';
            else           
                if (push = '1' and not(lsb_equal = '1' and msb_equal = '0')) then            
                    register_file(to_integer(tail(COUNTER_BITS-1 downto 0))) <= data_in;
                    tail <= (tail + 1); 
                end if; 
                if (pop = '1' and not(lsb_equal = '1' and msb_equal = '1'))  then 
                    data_out <= register_file(to_integer(head(COUNTER_BITS-1 downto 0)));
                    head <= (head + 1);
                end if;
                
                if ((lsb_equal = '1' and msb_equal = '1') and push = '0') then
                    empty_out <= '1';
                else 
                    empty_out <= '0';
                end if;
            end if; 
        end if;
    end process;
end architecture;
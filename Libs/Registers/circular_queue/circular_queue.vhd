-- Definition of dynamic queue. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.ALL;

entity circular_queue is 
    Generic (
        DATA_SIZE:      INTEGER := 8;
        REGISTERS:      INTEGER := 8
    );
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
        
        empty_out:           out STD_LOGIC

    );
end  circular_queue;

architecture Behavioral of  circular_queue is
    constant COUNTER_SIZE: INTEGER := INTEGER(ceil(log2(REAL(REGISTERS))));

    type REGISTER_ARRAY         is array (REGISTERS-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
    -- The registers are defined as an array of vectors;
    signal register_file: REGISTER_ARRAY; 

    signal tail: UNSIGNED(COUNTER_SIZE-1 downto 0);
    signal head: UNSIGNED(COUNTER_SIZE-1 downto 0);
    signal full, empty: STD_LOGIC;
    
begin     
    full <= '1' when (tail = (head-1) mod REGISTERS) else '0'; 
    empty <= '1' when (tail = (head) mod REGISTERS) else '0';
    empty_out <= empty;
    queue: process (clk) 
        variable index: INTEGER; 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1' or init = '1') then 
                data_out <= (others => '0');
                head <= (others => '0');
                tail <= (others => '0');
                --empty_out <= '1';
            else           
                if (add = '1' and shift = '0' and not(tail = (head-1) mod REGISTERS)) then 
                    register_file(to_integer(tail)) <= data_in;
                    tail <= (tail + 1); -- mod REGISTER;;  
                end if; 
                if (add = '1' and shift = '1' and not(tail = (head) mod REGISTERS)) then 
                    register_file(to_integer(tail)) <= data_in;
                    tail <= (tail + 1); -- mod REGISTERS; 
                    data_out <= register_file(to_integer(head));
                    head <= (head + 1); -- mod REGISTERS; 
                end if; 
                
                if (add = '0' and shift = '1' and not(tail = (head) mod REGISTERS)) then 
                    register_file(to_integer(tail)) <= register_file(to_integer(head));
                    tail <= (tail + 1); -- mod REGISTERS; 
                    data_out <= register_file(to_integer(head));
                    head <= (head + 1); -- mod REGISTERS; 
                end if; 
            end if; 
        end if;
    end process;
end architecture;
-- Definition of dynamic queue. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

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
        data_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0)           -- output port

    );
end  circular_queue;


architecture Behavioral of  circular_queue is
    type REGISTER_ARRAY         is array (REGISTERS-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type REGISTER_STATUS        is (NOP, READ_SHIFT, READ_LOOP, READ_DATA); 
    type REGISTER_STATUS_ARRAY  is array (REGISTERS downto 0) of REGISTER_STATUS;
    -- The registers are defined as an array of vectors;
    signal register_file: REGISTER_ARRAY; 
    signal register_file_control: REGISTER_STATUS_ARRAY;
begin 

    FIFO: process (clk) 
        variable index: INTEGER; 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1' or init = '1') then 
                for i in REGISTERS downto 2 loop
                    register_file_control(i) <= NOP;
                end loop;
                register_file_control(1) <= READ_DATA;
                register_file_control(0) <= READ_LOOP;
                data_out <= (others => '0');
            else
            
                if (add = '1' and not(register_file_control(REGISTERS)=READ_LOOP) and shift = '0') then 
                    for i in REGISTERS downto 1 loop 
                        register_file_control(i) <= register_file_control(i-1); 
                        if (register_file_control(i) = READ_DATA) then 
                            register_file(i-1) <= data_in; 
                        end if; 
                    end loop;  
                    register_file_control(0) <= READ_SHIFT; 
                end if; 
                if (shift = '1' and add = '0') then 
                    for i in 0 to (REGISTERS-1) loop
                        if(register_file_control(i+1)=READ_SHIFT and (i<(REGISTERS-1))) then  
                            register_file(i) <= register_file(i+1); 
                        end if; 
                        if(register_file_control(i+1)=READ_LOOP) then 
                            register_file(i) <= register_file(0);  
                        end if;
                    end loop; 
                end if; 
                if (shift = '1' and add = '1') then 
                    for i in 0 to (REGISTERS-1) loop
                        if(register_file_control(i+1)=READ_SHIFT and (i<(REGISTERS-1))) then  
                            register_file(i) <= register_file(i+1); 
                        end if; 
                        if(register_file_control(i+1)=READ_LOOP) then 
                            register_file(i) <= data_in;  
                        end if;
                    end loop; 
                end if; 
            end if;
            data_out <= register_file(0); 
        end if;
    end process;
end architecture;
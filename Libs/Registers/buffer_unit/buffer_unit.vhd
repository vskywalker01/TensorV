library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.registers.ALL;

entity buffer_unit is
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
        
        step_in:    in STD_LOGIC;
        send_in:    in STD_LOGIC;
        counter_in: in STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
        data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
         
        data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        valid_out:  out STD_LOGIC;
        ready_out:  out STD_LOGIC

    );
end buffer_unit;

architecture Behavioral of buffer_unit is
    constant BUFFER_REGISTERS: INTEGER := 2 ** BUFFER_SIZE_BITS; 
    type REGISTER_ARRAY is array (BUFFER_REGISTERS-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
    

    -- The registers are defined as an array of vectors;
    signal register_file:   REGISTER_ARRAY; 
    signal tail,head:            UNSIGNED(BUFFER_SIZE_BITS downto 0);
    signal buffer_empty, buffer_full:   STD_LOGIC;
    
    signal counter: UNSIGNED(BUFFER_SIZE_BITS-1 downto 0);
    
begin
    buffer_empty <= '1' when (tail = head)
                        else '0';
    buffer_full <= '1'  when (tail(BUFFER_SIZE_BITS-1 downto 0) = head(BUFFER_SIZE_BITS-1 downto 0) and not(tail(BUFFER_SIZE_BITS) = head(BUFFER_SIZE_BITS)))
                        else '0';
    
    stage1: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1' or init = '1') then 
                counter <= (others => '0');
                head <= (others => '0'); 
                tail <= (others => '0'); 
                
                ready_out <= '1';
                valid_out <= '0';
                
            else
                if (add_in = '1' and buffer_full = '0') then 
                    register_file(to_integer(tail(BUFFER_SIZE_BITS-1 downto 0))) <= data_in;
                    tail <= (tail + 1); 
                
                elsif (enable = '1') then
                    if (send_in = '1' ) then 
                        counter <= UNSIGNED(counter_in); 
                        ready_out <= '0'; 
                        if (buffer_empty = '0') then 
                            data_out <= register_file(to_integer(head(BUFFER_SIZE_BITS-1 downto 0)));
                            head <= (head + 1); 
                            valid_out <= '1';
                        else 
                            valid_out <= '0';
                        end if; 
                    elsif (counter > 0 and buffer_empty = '0' and step_in = '1') then 
                        data_out <= register_file(to_integer(head(BUFFER_SIZE_BITS-1 downto 0)));
                        head <= (head + 1); 
                        counter <= counter - 1; 
                        ready_out <= '0'; 
                        valid_out <= '1';
                    elsif (counter = 0) then 
                        ready_out <= '1';
                        valid_out <= '0';
                    else 
                        valid_out <= '0';
                    end if;
                end if; 
            end if;
        end if;
    end process;
    
end Behavioral;

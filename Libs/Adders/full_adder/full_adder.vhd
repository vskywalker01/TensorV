-- Full adder implementation for general purpose (used in tree reduction)


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity full_adder is
        Port (

            -- Inputs 
            a:      in STD_LOGIC;   -- bit a 
            b:      in STD_LOGIC;   -- bit b 
            c_in:   in STD_LOGIC;   -- carry in 
        
            -- Outputs 
            r:      out STD_LOGIC;  -- result bit 
            c_out:  out STD_LOGIC   -- carry out 
        );
end full_adder;

architecture Behavioral of full_adder is
begin
    r <= (a xor b) xor c_in;
    c_out <= (a and b) or (c_in and (a xor b)); 
end Behavioral;

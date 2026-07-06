-- Half adder definition for general purpose (used in tree reductors)


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity half_adder is
    Port (
        -- Inputs  
        a:      in STD_LOGIC;   -- bit a 
        b:      in STD_LOGIC;   -- bit b 
    
        -- outputs
        r:      out STD_LOGIC;  -- result bit 
        c:  out STD_LOGIC       -- carry bit 
    );
end half_adder;

architecture Behavioral of half_adder is
    
begin
    r <= a xor b;
    c <= a and b; 
    
end Behavioral;

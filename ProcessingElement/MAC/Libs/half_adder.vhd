library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity half_adder is
    Port (
        a: in STD_LOGIC;
        b: in STD_LOGIC;
        
        r: out STD_LOGIC;
        c: out STD_LOGIC
    );
end half_adder;

architecture Behavioral of half_adder is
    
    
begin
    r <= a xor b;
    c <= a and b; 
    
end Behavioral;

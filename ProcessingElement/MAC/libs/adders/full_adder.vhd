library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity full_adder is
    Port (
        a:      in STD_LOGIC;
        b:      in STD_LOGIC;
        c_in:   in STD_LOGIC;
        
        r:      out STD_LOGIC;
        c_out:  out STD_LOGIC
    );
end full_adder;

architecture Behavioral of full_adder is

begin
    r <= (a xor b) xor c_in;
    c_out <= (a and b) or (c_in and (a xor b)); 
end Behavioral;
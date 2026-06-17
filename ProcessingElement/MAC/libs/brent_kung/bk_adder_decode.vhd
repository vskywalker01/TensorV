
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bk_adder_decode is
    Generic (
        DIM: INTEGER := 32
    );
    Port ( 
        g_in: in STD_LOGIC_VECTOR(DIM-1 downto 0); 
        p_in: in STD_LOGIC_VECTOR(DIM-1 downto 0);
        
        r: out STD_LOGIC_VECTOR(DIM-1 downto 0)
        
    );
end bk_adder_decode;

architecture Behavioral of bk_adder_decode is
begin
    gp_extraction: for i in 0 to (DIM-1) generate
        r_out(i) <= g_in(i) xor p_in(i); 
    end generate; 
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bk_adder_encode is
    Generic (
        DIM: INTEGER := 32
    );
    Port ( 
        a: in STD_LOGIC_VECTOR(DIM-1 downto 0);
        b: in STD_LOGIC_VECTOR(DIM-1 downto 0);
      
        g_out: out STD_LOGIC_VECTOR(DIM-1 downto 0); 
        p_out: out STD_LOGIC_VECTOR(DIM-1 downto 0)
    );
end bk_adder_encode;

architecture Behavioral of bk_adder_encode is
begin
    gp_extraction: for i in 0 to (DIM-1) generate
        g_out(i) <= a(i) and b(i); 
        p_out(i) <= a(i) xor b(i);
    end generate; 
end Behavioral;
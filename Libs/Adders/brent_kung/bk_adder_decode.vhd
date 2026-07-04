library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bk_adder_decode is
        Generic (
            DIM: INTEGER := 8
        );
        Port ( 
            c_in: in STD_LOGIC;
            g_in: in STD_LOGIC_VECTOR(DIM-1 downto 0); 
            p_in: in STD_LOGIC_VECTOR(DIM-1 downto 0);
            
            r: out STD_LOGIC_VECTOR(DIM-1 downto 0);
            c_out: out STD_LOGIC
        );
end bk_adder_decode;


architecture Behavioral of bk_adder_decode is
begin
    gp_extraction: for i in 0 to (DIM-1) generate
        r(i) <= g_in(i-1) xor p_in(i) when (i>0) else p_in(0) xor c_in; 
    end generate; 
    c_out <= g_in(DIM-1);
end Behavioral;

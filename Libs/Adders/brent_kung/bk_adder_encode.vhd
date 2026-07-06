-- Definition of Encode layer for brent-kung adder 
-- This layer encodes the inputs a, b into generate and propagate signals used for the computation of the sum. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bk_adder_encode is
        Generic (
            DIM: INTEGER := 8
        );
        Port ( 
            -- Inputs 
            a: in STD_LOGIC_VECTOR(DIM-1 downto 0);         -- Vector A  
            b: in STD_LOGIC_VECTOR(DIM-1 downto 0);         -- Vector B 
          
            -- Outputs 
            g_out: out STD_LOGIC_VECTOR(DIM-1 downto 0);    -- Generate vector 
            p_out: out STD_LOGIC_VECTOR(DIM-1 downto 0)     -- Propagate vector 
        );
    end bk_adder_encode;

architecture Behavioral of bk_adder_encode is
begin
    gp_extraction: for i in 0 to (DIM-1) generate
        g_out(i) <= a(i) and b(i);                  -- The generate bits are obtained by an AND between the input bits 
        p_out(i) <= a(i) xor b(i);                  -- The propagate bits are obtained by an XOR between the input bits.
    end generate; 
end Behavioral;

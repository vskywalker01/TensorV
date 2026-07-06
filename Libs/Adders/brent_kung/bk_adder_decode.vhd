-- Definition of decode layer for brent-kung adders 
-- This layer computes the result using the propagate lines from the encode layer and the carrys saved in the last generate vector obtained from the last layer of the adder. 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bk_adder_decode is
        Generic (
            DIM: INTEGER := 8
        );
        Port ( 

            -- Inputs             
            c_in: in STD_LOGIC;                         -- Carry in  
            g_in: in STD_LOGIC_VECTOR(DIM-1 downto 0);  -- Generate vector (from last layer)
            p_in: in STD_LOGIC_VECTOR(DIM-1 downto 0);  -- Propagate vector (from encode layer)
            
            -- Outputs 
            r: out STD_LOGIC_VECTOR(DIM-1 downto 0);    -- result 
            c_out: out STD_LOGIC                        -- Carry out/overflow bit 
        );
end bk_adder_decode;


architecture Behavioral of bk_adder_decode is
begin

    -- The result of bit i is obtained by performing a XOR between the carry i (in the generate vector) and the propagate i-1 (the first propagate is c_in) 
    gp_extraction: for i in 0 to (DIM-1) generate
        r(i) <= g_in(i-1) xor p_in(i) when (i>0) else p_in(0) xor c_in; 
    end generate; 
    c_out <= g_in(DIM-1);
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all;

entity bk_adder_level is
    Generic (
        DIM: INTEGER := 32;
        LEVEL: INTEGER
    );
    Port ( 
        g_in: in STD_LOGIC_VECTOR(DIM-1 downto 0); 
        p_in: in STD_LOGIC_VECTOR(DIM-1 downto 0);
      
        g_out: out STD_LOGIC_VECTOR(DIM-1 downto 0); 
        p_out: out STD_LOGIC_VECTOR(DIM-1 downto 0)
    );
end bk_adder_level;

architecture Behavioral of bk_adder_level is
    constant M: INTEGER := INTEGER(ceil(log2(REAL(DIM))));
    constant LEVELS: INTEGER := 2*M-2;

begin
    up_sweep: if (LEVEL < LEVELS and LEVEL < M) generate 
        constant K: INTEGER := LEVEL; 
        constant D: INTEGER := 2 ** K;
        constant D_CELL: INTEGER := 2 ** (K+1);
    begin 
        black_cell: for c in 0 to (DIM-1) generate 
            forward: if not((c+1) mod(D_CELL) = 0) generate 
                g_out(c) <= g_in(c);
                p_out(c) <= p_in(c);
            end generate; 
            
            combine: if ((c+1) mod(D_CELL) = 0) generate 
                g_out(c) <= g_in(c) or (p_in(c) and g_in(c-D));
                p_out(c) <= p_in(c) and p_in(c-D);
            end generate;  
        end generate; 
    end generate; 
    
    down_sweep: if (LEVEL < LEVELS and LEVEL >= M) generate 
        constant K: INTEGER := LEVELS-LEVEL-1; 
        constant D: INTEGER := 2 ** K;
        constant D_CELL: INTEGER := 2 ** (K+1);

    begin 
        gray_cell: for c in 0 to (DIM-1) generate 
            forward: if not((c-D-1) mod(D_CELL) = 0 and c>=D) generate 
                g_out(c) <= g_in(c);
                p_out(c) <= p_in(c);
            end generate; 
            
            combine: if ((c-D-1) mod(D_CELL) = 0 and c>=D) generate 
                g_out(c) <= g_in(c) or (p_in(c) and g_in(c-D));
                p_out(c) <= p_in(c);
            end generate;  
        end generate; 
    end generate; 
    
end Behavioral;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all;

entity bk_adder_level is
        Generic (
            DIM: INTEGER := 8;
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
    constant LEVELS: INTEGER := (2*M)-1;

begin
    up_sweep: if (LEVEL < LEVELS and LEVEL < M) generate 
        constant K: INTEGER := LEVEL; 
        constant D: INTEGER := 2 ** K;
        constant D_CELL: INTEGER := 2 ** (K+1);
    begin 
        col: for c in 0 to (DIM-1) generate 
            constant BLACK_CELL_ENABLE: BOOLEAN := ((c+1) mod(D_CELL) = 0) and not(c+1=D_CELL);
            constant GRAY_CELL_ENABLE: BOOLEAN := ((c+1) mod(D_CELL) = 0) and (c+1=D_CELL);
        begin 
            forward: if not(BLACK_CELL_ENABLE) and not(GRAY_CELL_ENABLE) generate 
                g_out(c) <= g_in(c);
                p_out(c) <= p_in(c);
            end generate; 
            
            back_cell: if (BLACK_CELL_ENABLE) generate 
                g_out(c) <= g_in(c) or (p_in(c) and g_in(c-D));
                p_out(c) <= p_in(c) and p_in(c-D);
            end generate;  
            gray_cell: if (GRAY_CELL_ENABLE) generate 
                g_out(c) <= g_in(c) or (p_in(c) and g_in(c-D));
            end generate;  
        end generate; 
    end generate; 
    
    down_sweep: if (LEVEL < LEVELS and LEVEL >= (M)) generate 
        constant K: INTEGER := LEVELS-LEVEL-1; 
        constant D: INTEGER := 2 ** K;
        constant D_CELL: INTEGER := 2 ** (K+1);

    begin 
        col: for c in 0 to (DIM-1) generate 
            constant GRAY_CELL_ENABLE: BOOLEAN := ((c+D+1) mod(D_CELL) = 0 and c>=D_CELL);
        begin 
            forward: if not(GRAY_CELL_ENABLE) generate 
                g_out(c) <= g_in(c);
                p_out(c) <= p_in(c);
            end generate; 
            
            gray_cell: if (GRAY_CELL_ENABLE) generate 
                g_out(c) <= g_in(c) or (p_in(c) and g_in(c-D));
            end generate;  
        end generate; 
    end generate; 
    
end Behavioral;

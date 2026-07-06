-- Definition of intermediate layer used for the brent-kung adder. 
-- An intermediate layer computes the generate/propagate vectors using the criteria specified in a normal brent-kung adder. 
-- The same component is used bot for up-sweep and down-sweep (the component places automatically the white/gray/black cells). 

-- ** Example 4 bit ** 
-- g,p 3  g,p 2  g,p 1  g,p 0 
--   B      |      G      |     -- Layer 0 (up-sweep)
--   G      |      |      |     -- Layer 1 (up-sweep) 
--   |      G      |      |     -- Layer 2 (down-sweep)
--  C 4    C 3    C 2    C 1

-- The final propagate vector will assume U (not used) and the final generate vector will contain all the carrys generated from all the bits. 
-- Note that in an unpipelined implementation the not used bits in the vector are automatically discarded during the syntesis. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all;

entity bk_adder_level is
        Generic (
            DIM: INTEGER := 8;
            LEVEL: INTEGER      -- ID of the level (from 0 to 2*log(DIM-1)) 
        );
        Port ( 
            g_in: in STD_LOGIC_VECTOR(DIM-1 downto 0);           -- Input generate vector 
            p_in: in STD_LOGIC_VECTOR(DIM-1 downto 0);           -- Input propagate vector 
          
            g_out: out STD_LOGIC_VECTOR(DIM-1 downto 0);         -- Output generate vector 
            p_out: out STD_LOGIC_VECTOR(DIM-1 downto 0)          -- Output propagate vector 
        );
    end bk_adder_level;


architecture Behavioral of bk_adder_level is

    constant M: INTEGER := INTEGER(ceil(log2(REAL(DIM))));     -- Number of levels necessary for the complete up-sweep  
    constant LEVELS: INTEGER := (2*M)-1;                       -- Number of the total levels necessary for the complete elaboration of the carrys (up-sweep and downsweep)

begin
    up_sweep: if (LEVEL < LEVELS and LEVEL < M) generate 
        constant K: INTEGER := LEVEL;                          -- ID of the level (up-sweep)
        constant D: INTEGER := 2 ** K;                         -- Distance between the first and the second input of the gray/black cell 
        constant D_CELL: INTEGER := 2 ** (K+1);                -- Distance between two gray/black cells 
    begin 
        col: for c in 0 to (DIM-1) generate 

            -- If the bit C+1 is multiple of the value D_CELL -> place a gray cell 
            constant BLACK_CELL_ENABLE: BOOLEAN := ((c+1) mod(D_CELL) = 0) and not(c+1=D_CELL); 

            -- The first cell to be placed should be a gray cell instead a black one.
            constant GRAY_CELL_ENABLE: BOOLEAN := ((c+1) mod(D_CELL) = 0) and (c+1=D_CELL);
        begin 

            -- If c does not correspond to a black/gray cells -> forward the input bits (white cell)
            white_cell: if not(BLACK_CELL_ENABLE) and not(GRAY_CELL_ENABLE) generate 
                g_out(c) <= g_in(c);
                p_out(c) <= p_in(c);
            end generate; 
            
            -- c corresponds to a  black cell should be placed, -> elaborate new generate/propagate bits  
            black_cell: if (BLACK_CELL_ENABLE) generate 
                g_out(c) <= g_in(c) or (p_in(c) and g_in(c-D));
                p_out(c) <= p_in(c) and p_in(c-D);
            end generate;  

            -- If c corresponds to a gray cell should be placed -> elaborate only the generate bit 
            gray_cell: if (GRAY_CELL_ENABLE) generate 
                g_out(c) <= g_in(c) or (p_in(c) and g_in(c-D));
            end generate;  
        end generate; 
    end generate; 
    
    down_sweep: if (LEVEL < LEVELS and LEVEL >= (M)) generate 
        constant K: INTEGER := LEVELS-LEVEL-1;               -- ID of the level (up-sweep)
        constant D: INTEGER := 2 ** K;                       -- Distance between the first and the second input of the gray cell
        constant D_CELL: INTEGER := 2 ** (K+1);              -- Distance between two gray cells

    begin 
        col: for c in 0 to (DIM-1) generate 

            -- A gray cell is placed when C+1 (with an offset of D) is multiple of D_CELL (the first one is skipped) 
            constant GRAY_CELL_ENABLE: BOOLEAN := ((c+D+1) mod(D_CELL) = 0 and c>=D_CELL);
        begin

            -- If c is not a gray cell -> forward the signals (white cells)
            white_cell: if not(GRAY_CELL_ENABLE) generate 
                g_out(c) <= g_in(c);
                p_out(c) <= p_in(c);
            end generate; 
            
            -- If C is a gray cell, elaborate only the generate bit
            gray_cell: if (GRAY_CELL_ENABLE) generate 
                g_out(c) <= g_in(c) or (p_in(c) and g_in(c-D));
            end generate;  
        end generate; 
    end generate; 
    
end Behavioral;

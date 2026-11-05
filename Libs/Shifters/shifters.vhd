-- Definition of SHIFTERS package. It contains:
-- * Definition of right barrel shifter

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.ALL;

package SHIFTERS is
    component barrel_right_shifter is
        Generic (
            DATA_SIZE: INTEGER := 32;
            SHIFT_SIZE: INTEGER := 5
        );
        Port (
            data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            shift:      in STD_LOGIC_VECTOR(SHIFT_SIZE-1 downto 0); 
            logic:      in STD_LOGIC; 
            
            data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0)
        );
    end component;
end package;

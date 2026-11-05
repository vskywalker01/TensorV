-- Definition of BIT_REDUCTORS package. It contains:
-- * Definition of or bit reductor

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.ALL;

package BIT_REDUCTORS is
    component or_reductor is
        Generic(
            DATA_SIZE: INTEGER := 20
        );
        Port (
            data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            result:     out STD_LOGIC
        );
    end component;
end package;
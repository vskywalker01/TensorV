-- Definition of REGISTERS package. It contains:
-- * Definition of circular queue



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package REGISTERS is
    
    component circular_queue is 
        Generic (
            DATA_SIZE:      INTEGER := 8;
            REGISTERS:      INTEGER := 8
        );
        Port (
            -- Control lines 
            clk: in STD_LOGIC;                                          -- clock 
            reset: in STD_LOGIC;                                        -- reset (when '1') 
             
            
            init: in STD_LOGIC; 
            shift: in STD_LOGIC; 
            add: in STD_LOGIC;
    
            
            -- Data lines
            data_in:         in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- input port
            data_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0)           -- output port
        );
    end component;
    
end package;
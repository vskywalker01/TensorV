-- Definition of REGISTERS package. It contains:
-- * Definition of circular queue
-- * Definition of queue
-- * definition of convolutional queue


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.ALL;

package REGISTERS is
    component buffer_unit is
        Generic (
            DATA_SIZE: INTEGER := 8;
            BUFFER_SIZE_BITS: INTEGER := 3
        );
        Port (         
            clk:        in STD_LOGIC;
            reset:      in STD_LOGIC;
            enable:     in STD_LOGIC; 
        
            init:       in STD_LOGIC;
            add_in:     in STD_LOGIC;
            
            step_in:    in STD_LOGIC;
            send_in:    in STD_LOGIC;
            counter_in: in STD_LOGIC_VECTOR(BUFFER_SIZE_BITS-1 downto 0);
            data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
             
            data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            valid_out:  out STD_LOGIC;
            ready_out:  out STD_LOGIC
    
        );
    end component;
end package;


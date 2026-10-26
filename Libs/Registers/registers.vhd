-- Definition of REGISTERS package. It contains:
-- * Definition of circular queue
-- * Definition of queue
-- * definition of convolutional queue


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.ALL;

package REGISTERS is
    component convolutional_queue is 
        Generic (
            DATA_SIZE:      INTEGER := 8;
            COUNTER_BITS:   INTEGER := 3
        );
        Port (
            -- Control lines 
            clk: in STD_LOGIC;                                          -- clock 
            reset: in STD_LOGIC;                                        -- reset (when '1') 
                    
            init_activation: in STD_LOGIC;
            init_weight:    in STD_LOGIC;
    
            add_weight: in STD_LOGIC;
            add_activation: in STD_LOGIC;
            
            move: in STD_LOGIC; 
                    
            -- Data lines
            activation_in:         in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- input port
            activation_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);          -- output port
            
            weight_in:             in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            weight_out:            out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            
            skip_in:         in STD_LOGIC_VECTOR(COUNTER_BITS-1 downto 0);
            
            empty_out:           out STD_LOGIC;         
            done_out:            out STD_LOGIC 
        );
    end component;
    
    component queue is 
        Generic (
            DATA_SIZE:      INTEGER := 8;
            COUNTER_BITS:   INTEGER := 3
        );
        Port (
            -- Control lines 
            clk: in STD_LOGIC;                                          -- clock 
            reset: in STD_LOGIC;                                        -- reset (when '1') 
             
            
            init: in STD_LOGIC; 
            pop: in STD_LOGIC; 
            push: in STD_LOGIC;
    
            
            -- Data lines
            data_in:         in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- input port
            data_out:        out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);           -- output port
            
            empty_out:           out STD_LOGIC
        );
    end component;
    
    function get_register_address_size(
        registers:                  INTEGER
    ) return INTEGER;
    
end package;

package body REGISTERS is
    function get_register_address_size(
        registers:                  INTEGER
    ) return INTEGER is    
    begin 
        return INTEGER(ceil(log2(REAL(REGISTERS))));
    end function;
end package body;

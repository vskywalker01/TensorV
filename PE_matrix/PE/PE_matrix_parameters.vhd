library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all;

package PE_MATRIX_PARAMETERS is 
    constant DEPTH: INTEGER := 8; 
    constant PROCESSING_ELEMENTS: INTEGER := DEPTH**2;
    constant QUEUE_SIZE: INTEGER := 8;
    constant DATA_SIZE: INTEGER := 8;
    constant ACCUMULATOR_SIZE: INTEGER := (DATA_SIZE*2)+INTEGER(ceil(log2(REAL(DEPTH))));
    
    constant CONTROL_SIZE: INTEGER := 7; 
    constant ACTIVATION_INIT_BIT: INTEGER := 6; 
    constant WEIGHT_INIT_BIT: INTEGER := 5;
    constant ACCUMULATOR_INIT_BIT: INTEGER := 4;
    constant ACTIVATION_VALID_BIT: INTEGER := 3; 
    constant WEIGHT_VALID_BIT:   INTEGER := 2; 
    constant ACCUMULATOR_VALID_BIT: INTEGER := 1;
    constant ENABLE_BIT:         INTEGER := 0; 
    
    type MATRIX_INTERCONNECT_DATA is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_ACCUMULATOR is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_CONTROL is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
    
    type MATRIX_ROWS_INTERFACE is array ((DEPTH*2)-2 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    type MATRIX_ROWS_CONTROL_INTERFACE is array ((DEPTH*2)-2 downto 0) of STD_LOGIC; 
    type MATRIX_WEIGHTS_INTERFACE is array (DEPTH-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type MATRIX_WEIGHTS_CONTROL_INTERFACE is array (DEPTH-1 downto 0) of STD_LOGIC; 
    type MATRIX_ACCUMULATORS_INTERFACE is array (DEPTH-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    type MATRIX_ACCUMULATORS_CONTROL_INTERFACE is array (DEPTH-1 downto 0) of STD_LOGIC;
    
    component PE is 
        Port ( 
            clk:                    in STD_LOGIC;  
            reset:                  in STD_LOGIC;                 
            
            control_in:             in STD_LOGIC_VECTOR(6 downto 0); 
            weight_in:              in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
            activation_in:          in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_in:         in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            
            control_out:            out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
            weight_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
            activation_out:         out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_out:        out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0)
            
        );
    end component;
    
end package; 

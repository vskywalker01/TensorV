library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all;
use work.REGISTERS.ALL;

package PE_MATRIX_PARAMETERS is 
    constant DEPTH: INTEGER := 8; 
    constant PROCESSING_ELEMENTS: INTEGER := DEPTH**2;
    
    constant QUEUE_SIZE: INTEGER := 8;
    constant QUEUE_COUNTERS_SIZE: INTEGER := get_register_address_size(QUEUE_SIZE);
    
    constant DATA_SIZE: INTEGER := 8;
    constant ACCUMULATOR_SIZE: INTEGER := (DATA_SIZE*2)+INTEGER(ceil(log2(REAL(DEPTH))));
    
    constant CONTROL_SIZE: INTEGER := (2*QUEUE_COUNTERS_SIZE)+7; 
    
    constant ACTIVATION_SKIP_MS_BIT: INTEGER := CONTROL_SIZE-1;
    constant ACTIVATION_SKIP_LS_BIT: INTEGER := ACTIVATION_SKIP_MS_BIT-QUEUE_COUNTERS_SIZE+1;
    
    constant ACTIVATION_SIZE_MS_BIT: INTEGER := ACTIVATION_SKIP_LS_BIT-1;
    constant ACTIVATION_SIZE_LS_BIT: INTEGER := ACTIVATION_SIZE_MS_BIT-QUEUE_COUNTERS_SIZE+1;
    
    constant ACTIVATION_INIT_BIT:    INTEGER := ACTIVATION_SIZE_LS_BIT-1; 
    constant WEIGHT_INIT_BIT:        INTEGER := ACTIVATION_INIT_BIT-1;
    constant ACCUMULATOR_INIT_BIT:   INTEGER := WEIGHT_INIT_BIT-1;
    
    constant ACTIVATION_VALID_BIT:   INTEGER := ACCUMULATOR_INIT_BIT-1;
    constant WEIGHT_VALID_BIT:       INTEGER := ACTIVATION_VALID_BIT-1; 
    
    constant ENABLE_BIT:             INTEGER := WEIGHT_VALID_BIT-1; 
    constant PROCESS_TYPE_BIT:       INTEGER := ENABLE_BIT-1; 
    
    constant ACTIVATION_LINES:       INTEGER := (DEPTH*2)-1; 
    constant WEIGHT_LINES:           INTEGER := (DEPTH);
    constant ACCUMULATION_LINES:     INTEGER := (DEPTH);
    
    type MATRIX_INTERCONNECT_DATA is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_ACCUMULATOR is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    type MATRIX_INTERCONNECT_CONTROL is array (DEPTH-1 downto 0, DEPTH-1 downto 0) of STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
    
    type MATRIX_ROWS_INTERFACE is array (ACTIVATION_LINES-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    type MATRIX_ROWS_CONTROL_INTERFACE is array (WEIGHT_LINES-1 downto 0) of STD_LOGIC; 
    type MATRIX_WEIGHTS_INTERFACE is array (WEIGHT_LINES-1 downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    --type MATRIX_WEIGHTS_CONTROL_INTERFACE is array (WEIGHT_LINES-1 downto 0) of STD_LOGIC; 
    type MATRIX_WEIGHTS_CONTROL_INTERFACE is array (ACTIVATION_LINES-1 downto 0) of STD_LOGIC; 
    type MATRIX_ACCUMULATORS_INTERFACE is array (ACCUMULATION_LINES-1 downto 0) of STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    --type MATRIX_ACCUMULATORS_CONTROL_INTERFACE is array (ACCUMULATION_LINES-1 downto 0) of STD_LOGIC;
    type MATRIX_ACCUMULATORS_CONTROL_INTERFACE is array (ACTIVATION_LINES-1 downto 0) of STD_LOGIC;
    
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

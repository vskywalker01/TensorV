library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package REDUCTORS is
    type MATRIX is array (natural range <>, natural range <>) of STD_LOGIC;

    component adder_reductor is
        Generic (
            MATRIX_ROWS_IN:         INTEGER;
            MATRIX_ROWS_OUT:        INTEGER;
            MATRIX_WIDTH:           INTEGER; 
            MATRIX_HEIGHT:          INTEGER; 
            MATRIX_STEP_LENGTH:     INTEGER;
            MATRIX_PARTIAL_SIZE:    INTEGER
        );
        Port ( 
            input: in MATRIX;
            output: out MATRIX
        );
    end component;

    
    function get_matrix_width(
        partial_size:               INTEGER;
        partials:                   INTEGER
    ) return INTEGER;
    
    function get_adder_matrix_height( 
        c:                          INTEGER;        -- column selected 
        matrix_rows_in:             INTEGER;        -- Number of input partials 
        matrix_width:               INTEGER; 
        matrix_height:              INTEGER;
        matrix_partial_size:        INTEGER; 
        matrix_step_length:         INTEGER 
        
    ) return                INTEGER;
end package;

package body REDUCTORS is
    function get_matrix_width(
        partial_size:               INTEGER;
        partials:            INTEGER) 
        return  INTEGER is 
    begin 
        return partial_size+(partials-1);
    end function; 

    function get_adder_matrix_height( 
        c:                          INTEGER;
        matrix_rows_in:             INTEGER;
        matrix_width:               INTEGER; 
        matrix_height:              INTEGER;
        matrix_partial_size:        INTEGER; 
        matrix_step_length:         INTEGER)
        return  INTEGER is 
        
        constant ASCENDING_HEIGHT:      INTEGER:= (c+matrix_step_length)/matrix_step_length;
        constant DESCENDING_HEIGHT:     INTEGER:= (MATRIX_WIDTH + matrix_step_length -c -1)/matrix_step_length;
        constant CONSTANT_HEIGHT:       INTEGER:= matrix_rows_in;
        constant LAST_CARRY_POS:        INTEGER:= (matrix_step_length*(matrix_height-matrix_rows_in))+(matrix_partial_size);
    begin         
        if (c<0 or c>(MATRIX_WIDTH-1)) then
            return 0; 
        end if; 
        
        if (ASCENDING_HEIGHT < matrix_rows_in) then 
            return ASCENDING_HEIGHT;
        elsif ((DESCENDING_HEIGHT < matrix_rows_in) and ((c>LAST_CARRY_POS) or (matrix_rows_in=matrix_height))) then 
            return DESCENDING_HEIGHT;
        else
            return CONSTANT_HEIGHT;
        end if;
            
    end function;
    
    
    
    

end package body;


-- This package contains the definition of tree reductors which can be used for carry save additions (multiple input additions or multiplication). 
-- It contains: 
-- * Definition of parametric adder reductor (a tree reductor based on half adder and full adders). 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package REDUCTORS is
    -- type used for interfacing with a reductor. The rows corresponds to the lines to reduce.
    type MATRIX is array (natural range <>, natural range <>) of STD_LOGIC;
    
    -- Definition of adder reductor 
    component adder_reductor is
        Generic (
            MATRIX_ROWS_IN:         INTEGER;    -- Number of valid rows in the matrix to reduce 
            MATRIX_ROWS_OUT:        INTEGER;    -- Number of target rows to reach after the reduction in the specific layer 
            MATRIX_WIDTH:           INTEGER;    -- Width of the entire matrix (used for the definition of the size of the input/output matrix)
            MATRIX_HEIGHT:          INTEGER;    -- Height of the entire matrix (used for the definition of the size of the input/output matrix)
            MATRIX_STEP_LENGTH:     INTEGER;    -- Shift value of the partials in the matrix (it is used to estimate which bits in the matrix are valid or not)
            MATRIX_PARTIAL_SIZE:    INTEGER     -- Size of the partials in the matrix (for example a baugh-wooley reductor generates partials of 9 bits )
        );
        Port ( 
            input: in MATRIX;
            output: out MATRIX
        );
    end component;

    -- The input and the output matrices are declared in with the partials already reordered into a tree format (the partial sshould be reordered manually)

    -- For example, given a matrix obtained from the generation of 8 partials of 9 bits (MATRIX_PARTIAL_SIZE = 9) shifted of 1 bit (MATRIX_STEP_LENGTH=1), the costants used from the initial matrix are the following: 
    -- | ------- matrix_width ------ |                          | ------- matrix_width ------ |  
    -- * * * * * * * * * * * * * * * *  -                       * * * * * * * * * * * * * * * *  -                  - 
    --   * * * * * * * * * * * * * *    |                         * * * * * * * * * * * * * *    |                  |
    --     * * * * * * * * * * * *      |                           * * * * * * * * * * * *      |                  - Matrix rows out 
    --       * * * * * * * * * *        |                             * * * * * * * * * *        |                  |
    --         * * * * * * * *          - Matrix height    ->           * * * * * * * *          - Matrix height    | 
    --           * * * * * *            - MAtrix partials in            * * * * * * *            |                  -
    --             * * * *              |                                                        |
    --               * *                -                                                        - 
    --                             | | 
    --                             Matrix step length 

    -- Note: * indicates valid bits and the spaces bits are not used (they will assume 'U' in the simulations) 

    -- This function are used to estimate the width and the height of the matrix for a specific reduction layer. 

    -- get_matrix_width estimates the width of the matris that should be used for interfacing the reductor layers.
    function get_matrix_width(
        partial_size:               INTEGER;
        partials:                   INTEGER; 
        partial_shift:              INTEGER 
    ) return INTEGER;
    
    -- get matrix_height estimates the height of the tree for the specific column given the number of rows valid in the matrix to reduce in the next step.
    -- This function is useful when dealing with pipelined reductions, because it indicates where latches should be placed between one matrix and another in two different stages.. 
    function get_adder_matrix_height( 
        c:                          INTEGER;        -- column position  
        matrix_rows_in:             INTEGER;        -- Number of input partials 
        matrix_width:               INTEGER;        -- original matrix width 
        matrix_height:              INTEGER;        -- original matrix height 
        matrix_partial_size:        INTEGER;        -- size of the partials 
        matrix_step_length:         INTEGER         -- shift of the partials 
        
    ) return                INTEGER;
end package;

package body REDUCTORS is
    function get_matrix_width(
        partial_size:               INTEGER;
        partials:                   INTEGER;
        partial_shift:              INTEGER) 
        return  INTEGER is 
    begin 
        return partial_size+(partial_shift*(partials-1));
    end function; 

    -- | ------- matrix_width ------ |  
    -- * * * * * * * * * * * * * * * *  -                  - 
    --   * * * * * * * * * * * * * *    |                  |
    --     * * * * * * * * * * * *      |                  - Matrix rows out 
    --       * * * * * * * * * *        |                  |
    --         * * * * * * * *          - Matrix height    | 
    --         * * * * * * *            |                  -
    --                                  |                                                        
    --                                  -                                                        
    --                     |         |  <- Ascending phase 
    --         |           |            <- Constant phase 
    -- |       |                        <- descending phase 
    --         ^ 
    --         Last carry pos 
    
    -- get_adder_matrix_height returns the height of the specific column in the given layer of the tree reduction  
    function get_adder_matrix_height( 
        c:                          INTEGER;
        matrix_rows_in:             INTEGER;
        matrix_width:               INTEGER; 
        matrix_height:              INTEGER;
        matrix_partial_size:        INTEGER; 
        matrix_step_length:         INTEGER)
        return  INTEGER is 
       
        -- These variables ae used to encode the height of the matrix in different phases
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


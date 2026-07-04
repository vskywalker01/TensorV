-- definition of reduction matrix

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.REDUCTORS.ALL;
use work.ADDERS.full_adder;
use work.ADDERS.half_adder;

entity adder_reductor is
    Generic (
        MATRIX_ROWS_IN:         INTEGER;
        MATRIX_ROWS_OUT:        INTEGER;
        MATRIX_WIDTH:           INTEGER; 
        MATRIX_HEIGHT:          INTEGER; 
        MATRIX_STEP_LENGTH:     INTEGER;
        MATRIX_PARTIAL_SIZE:    INTEGER
    );
    Port ( 
        input: in MATRIX(MATRIX_HEIGHT-1 downto 0,MATRIX_WIDTH-1 downto 0);
        output: out MATRIX(MATRIX_HEIGHT-1 downto 0,MATRIX_WIDTH-1 downto 0)
    );
end adder_reductor;


architecture Behavioral of adder_reductor is
    function get_generated_carrys( 
        c:                  INTEGER;
        matrix_rows_in:     INTEGER;
        matrix_rows_out:    INTEGER 
    ) return                INTEGER is 

        constant ASCENDING_HEIGHT:  INTEGER := (c+MATRIX_STEP_LENGTH)/MATRIX_STEP_LENGTH;
        constant DESCENDING_HEIGHT: INTEGER := (MATRIX_WIDTH + MATRIX_STEP_LENGTH -c -1)/MATRIX_STEP_LENGTH;
        constant LAST_CARRY_POS:    INTEGER := (MATRIX_STEP_LENGTH*(MATRIX_HEIGHT-matrix_rows_in))+(MATRIX_PARTIAL_SIZE);
        constant CONSTANT_HEIGHT:   INTEGER := matrix_rows_in;
    begin              
        if (c<0 or c>(MATRIX_WIDTH-1)) then
            return 0; 
        end if; 
        
        if (ASCENDING_HEIGHT <= matrix_rows_out or DESCENDING_HEIGHT < matrix_rows_out) then 
            return 0;
        else
            if (ASCENDING_HEIGHT < matrix_rows_in) then 
                return ASCENDING_HEIGHT-matrix_rows_out; 
            elsif ((DESCENDING_HEIGHT < matrix_rows_in) and ((c>LAST_CARRY_POS))) then 
                return DESCENDING_HEIGHT+1-matrix_rows_out;
            else
                return CONSTANT_HEIGHT-matrix_rows_out;
            end if;
        end if;
                
    end function;
    
    function get_half_adders( 
        c:                  INTEGER;
        matrix_rows_in:     INTEGER;
        matrix_rows_out:    INTEGER 
    ) return                INTEGER is

        constant PREVIOUS_CARRYS: INTEGER := get_generated_carrys(c-1,matrix_rows_in,matrix_rows_out);
        constant HEIGHT:          INTEGER := get_adder_matrix_height(c,matrix_rows_in,MATRIX_WIDTH,MATRIX_HEIGHT,MATRIX_PARTIAL_SIZE,MATRIX_STEP_LENGTH);
       
    begin      
        
        if (PREVIOUS_CARRYS+HEIGHT<matrix_rows_out) then 
            return 0; 
        else 
            return (PREVIOUS_CARRYS-matrix_rows_out+HEIGHT) mod 2;
        end if;
        
    end function;
    
    function get_full_adders( 
        c:                  INTEGER;
        matrix_rows_in:     INTEGER;
        matrix_rows_out:    INTEGER  
    ) return                INTEGER is 
    
        constant PREVIOUS_CARRYS: INTEGER := get_generated_carrys(c-1,matrix_rows_in,matrix_rows_out);
        constant HEIGHT:          INTEGER := get_adder_matrix_height(c,matrix_rows_in,MATRIX_WIDTH,MATRIX_HEIGHT,MATRIX_PARTIAL_SIZE,MATRIX_STEP_LENGTH);
       
    begin      
        
        if (PREVIOUS_CARRYS+HEIGHT<matrix_rows_out) then 
            return 0;
        else 
            return (PREVIOUS_CARRYS-matrix_rows_out+HEIGHT)/2;
        end if;
    end function;



begin
    routing_cols: for c in 0 to (MATRIX_WIDTH-1) generate          
        -- Carrys generated from the previous column to consider 
        constant PREVIOUS_CARRYS: integer := get_generated_carrys(c-1,MATRIX_ROWS_IN,MATRIX_ROWS_OUT);

        -- Height of the current column 
        constant HEIGHT: integer := get_adder_matrix_height(c,matrix_rows_in,MATRIX_WIDTH,MATRIX_HEIGHT,MATRIX_PARTIAL_SIZE,MATRIX_STEP_LENGTH);
        -- Number of FULL_ADDERS and HALF_ADDERS to instantiate 
        constant FULL_ADDERS: integer := get_full_adders(c,MATRIX_ROWS_IN,MATRIX_ROWS_OUT);
        constant HALF_ADDERS: integer := get_half_adders(c,MATRIX_ROWS_IN,MATRIX_ROWS_OUT);
        
        -- Base position to address the inputs of the full adders and half adders
        constant ADDERS_IN_FULL_BASE: integer := HEIGHT-(FULL_ADDERS*3)-(HALF_ADDERS*2); 
        constant ADDERS_IN_HALF_BASE: integer := HEIGHT-(HALF_ADDERS*2);
         
        -- Base position to address the outputs and the carrys of the full adders and half adders
        constant ADDERS_RES_FULL_BASE: integer := ADDERS_IN_FULL_BASE; 
        constant ADDERS_RES_HALF_BASE: integer := ADDERS_IN_FULL_BASE+FULL_ADDERS; 
        constant ADDERS_CARRYS_FULL_BASE: integer := MATRIX_ROWS_OUT-(FULL_ADDERS+HALF_ADDERS);
        constant ADDERS_CARRYS_HALF_BASE: integer := ADDERS_CARRYS_FULL_BASE + FULL_ADDERS;
        
        begin    
        -- Routing inputs that are untouched by the tree reduction 
        routing_rows: for r in 0 to (ADDERS_IN_FULL_BASE-1) generate  
            output(r,c) <= input(r,c); 
        end generate;

        -- generating eventual full adders
        routing_full_adders: for a in 0 to (FULL_ADDERS-1) generate 
            -- base position of the current full adder input (row index)
            constant ADDR_IN: integer := ADDERS_IN_FULL_BASE + (a*3);
            -- base position of the current full adder's output (row index)
            constant ADDR_CARRY:integer := ADDERS_CARRYS_FULL_BASE + a;
            -- base position of the current full adder's carry (row index)
            constant ADDR_RES: integer := ADDERS_RES_FULL_BASE + a;
            begin 
            full_adders: full_adder
                port map(
                    a => input(ADDR_IN,c),
                    b => input(ADDR_IN+1,c),
                    c_in => input(ADDR_IN+2,c),
                    
                    r => output(ADDR_RES,c), 
                    c_out => output(ADDR_CARRY,c+1)
                );
        end generate; 
        
        -- generating eventual half adders
        routing_half_adders: for a in 0 to (HALF_ADDERS-1) generate 
            -- base position of the current half adder input (row index)
            constant ADDR_IN: integer := ADDERS_IN_HALF_BASE + (a*2);
            -- base position of the current half adder's output (row index)
            constant ADDR_CARRY:integer := ADDERS_CARRYS_HALF_BASE + a;
            -- base position of the current half adder's carry (row index)
            constant ADDR_RES: integer := ADDERS_RES_HALF_BASE + a;
            begin 
            half_adders: half_adder 
                port map(
                    a => input(ADDR_IN,c),
                    b => input(ADDR_IN+1,c),
                    
                    r => output(ADDR_RES,c),
                    c => output(ADDR_CARRY,c+1)
                );
        end generate;
    end generate;
end Behavioral;

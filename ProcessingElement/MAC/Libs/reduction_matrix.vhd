-- definition of reduction matrix

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.PARTIAL_TYPES.ALL;

entity reduction_matrix is
    Generic (
        PARTIALS_IN: INTEGER;
        PARTIALS_OUT: INTEGER
    );
    Port ( 
        input: in PARTIALS_ARRAY(0 to PARTIALS_IN-1);
        output: out PARTIALS_ARRAY(0 to PARTIALS_OUT-1)
    );
end reduction_matrix;


architecture Behavioral of reduction_matrix is    
    component full_adder is
        Port (
            a:      in STD_LOGIC;
            b:      in STD_LOGIC;
            c_in:   in STD_LOGIC;
            
            r:      out STD_LOGIC;
            c_out:  out STD_LOGIC
        );
    end component;
    component half_adder is
        Port (
            a: in STD_LOGIC;
            b: in STD_LOGIC;
            
            r: out STD_LOGIC;
            c: out STD_LOGIC
        );
    end component;
begin
    routing_cols: for c in 0 to (PARTIAL_SIZE-1) generate          
        -- Carrys generated from the previous column to consider 
        constant PREVIOUS_CARRYS: integer := get_tree_column_carrys(c-1,PARTIALS_IN,PARTIALS_OUT);

        -- Height of the current column 
        constant HEIGHT: integer := get_tree_column_height(c,PARTIALS_IN);
        -- Number of FULL_ADDERS and HALF_ADDERS to instantiate 
        constant FULL_ADDERS: integer := get_tree_column_full_adders(c,PARTIALS_IN,PARTIALS_OUT);
        constant HALF_ADDERS: integer := get_tree_column_half_adders(c,PARTIALS_IN,PARTIALS_OUT);
        
        -- Base position to address the inputs of the full adders and half adders
        constant ADDERS_IN_FULL_BASE: integer := HEIGHT-(FULL_ADDERS*3)-(HALF_ADDERS*2); 
        constant ADDERS_IN_HALF_BASE: integer := HEIGHT-(HALF_ADDERS*2);
         
        -- Base position to address the outputs and the carrys of the full adders and half adders
        constant ADDERS_RES_FULL_BASE: integer := ADDERS_IN_FULL_BASE; 
        constant ADDERS_RES_HALF_BASE: integer := ADDERS_IN_FULL_BASE+FULL_ADDERS; 
        constant ADDERS_CARRYS_FULL_BASE: integer := PARTIALS_OUT-(FULL_ADDERS+HALF_ADDERS);
        constant ADDERS_CARRYS_HALF_BASE: integer := ADDERS_CARRYS_FULL_BASE + FULL_ADDERS;
        
        begin    
        -- Routing inputs that are untouched by the tree reduction 
        routing_rows: for r in 0 to (ADDERS_IN_FULL_BASE-1) generate  
            output(r)(c) <= input(r)(c); 
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
                    a => input(ADDR_IN)(c),
                    b => input(ADDR_IN+1)(c),
                    c_in => input(ADDR_IN+2)(c),
                    
                    r => output(ADDR_RES)(c), 
                    c_out => output(ADDR_CARRY)(c+1)
                );
        end generate; 
        
        -- generating eventual half adders
        routing_half_adders: for a in 0 to (HALF_ADDERS-1) generate 
            -- base position of the current half adder input (row index)
            constant ADDR_IN: integer := ADDERS_IN_FULL_BASE + (a*2);
            -- base position of the current half adder's output (row index)
            constant ADDR_CARRY:integer := ADDERS_CARRYS_FULL_BASE + a;
            -- base position of the current half adder's carry (row index)
            constant ADDR_RES: integer := ADDERS_RES_FULL_BASE + a;
            begin 
            half_adders: half_adder 
                port map(
                    a => input(ADDR_IN)(c),
                    b => input(ADDR_IN+1)(c),
                    
                    r => output(ADDR_RES)(c),
                    c => output(ADDR_CARRY)(c+1)
                );
        end generate;
    end generate;
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_MATRIX_PARAMETERS.ALL;

entity PE_matrix is 
    Port ( 
        clk:                    in STD_LOGIC;  
        reset:                  in STD_LOGIC;                 
        
        weights_in:                 in MATRIX_WEIGHTS_INTERFACE; 
        rows_in:                    in MATRIX_ROWS_INTERFACE; 
        accumulators_in:            in MATRIX_ACCUMULATORS_INTERFACE; 
        accumulators_out:           out MATRIX_ACCUMULATORS_INTERFACE;
        
        weights_init_in:            in MATRIX_WEIGHTS_CONTROL_INTERFACE;
        weights_valid_in:           in MATRIX_WEIGHTS_CONTROL_INTERFACE; 
        
        rows_init_in:               in MATRIX_ROWS_CONTROL_INTERFACE; 
        rows_valid_in:              in MATRIX_ROWS_CONTROL_INTERFACE; 
        
        accumulators_init_in:       in MATRIX_ACCUMULATORS_CONTROL_INTERFACE; 
        accumulators_valid_in:      in MATRIX_ACCUMULATORS_CONTROL_INTERFACE; 
        accumulators_valid_out:     out MATRIX_ACCUMULATORS_CONTROL_INTERFACE; 
        
        enables_in:                 in MATRIX_ACCUMULATORS_CONTROL_INTERFACE

    );
end PE_matrix;


architecture Behavioral of PE_matrix is 
    signal weight_interconnect_ports_in,weight_interconnect_ports_out: MATRIX_INTERCONNECT_DATA; 
    signal row_interconnect_ports_in,row_interconnect_ports_out: MATRIX_INTERCONNECT_DATA; 
    signal accumulator_interconnect_ports_in,accumulator_interconnect_ports_out: MATRIX_INTERCONNECT_ACCUMULATOR;
    signal control_interconnect_ports_in,control_interconnect_ports_out: MATRIX_INTERCONNECT_CONTROL; 
    
begin 

    matrix_rows: for r in 0 to (DEPTH-1) generate 
        matrix_columns: for c in 0 to (DEPTH-1) generate
        begin  
            processing_element: PE 
                Port map (
                    clk => clk, 
                    reset => reset,       
                    control_in => control_interconnect_ports_in(r,c),
                    control_out => control_interconnect_ports_out(r,c),
                    
                    
                    weight_in => weight_interconnect_ports_in(r,c), 
                    weight_out => weight_interconnect_ports_out(r,c), 
                    
                    activation_in => row_interconnect_ports_in(r,c),
                    activation_out => row_interconnect_ports_out(r,c),
                    
                    accumulator_in => accumulator_interconnect_ports_in(r,c),
                    accumulator_out => accumulator_interconnect_ports_out(r,c)
                );
                
            weight_routing: if (c+1<DEPTH) generate 
                weight_interconnect_ports_in(r,c+1) <= weight_interconnect_ports_out(r,c);
                control_interconnect_ports_in(r,c+1)(WEIGHT_INIT_BIT) <= control_interconnect_ports_out(r,c)(WEIGHT_INIT_BIT);
                control_interconnect_ports_in(r,c+1)(WEIGHT_VALID_BIT) <= control_interconnect_ports_out(r,c)(WEIGHT_VALID_BIT);
            end generate; 
            
            accumulators_routing: if (r+1<DEPTH) generate 
                accumulator_interconnect_ports_in(r+1,c) <= accumulator_interconnect_ports_out(r,c);
                control_interconnect_ports_in(r+1,c)(ACCUMULATOR_VALID_BIT) <= control_interconnect_ports_out(r,c)(ACCUMULATOR_VALID_BIT);
                control_interconnect_ports_in(r+1,c)(ENABLE_BIT) <= control_interconnect_ports_out(r,c)(ENABLE_BIT);
            end generate; 
            
            rows_routing: if (r>0 and c+1<DEPTH) generate 
                row_interconnect_ports_in(r-1,c+1) <= row_interconnect_ports_out(r,c);
                control_interconnect_ports_in(r-1,c+1)(ACTIVATION_INIT_BIT) <= control_interconnect_ports_out(r,c)(ACTIVATION_INIT_BIT);
                control_interconnect_ports_in(r-1,c+1)(ACTIVATION_VALID_BIT) <= control_interconnect_ports_out(r,c)(ACTIVATION_VALID_BIT);
            end generate; 
            
        end generate; 
    end generate;
    
    accumulators_routing: for i in 0 to (DEPTH-1) generate 
        accumulators_out(i) <= accumulator_interconnect_ports_out(DEPTH-1,i);
        accumulator_interconnect_ports_in(0,i) <= accumulators_in(i); 
        control_interconnect_ports_in(0,i)(ACCUMULATOR_INIT_BIT) <= accumulators_init_in(i);
        control_interconnect_ports_in(0,i)(ACCUMULATOR_VALID_BIT) <= accumulators_valid_in(i);
        control_interconnect_ports_in(0,i)(ENABLE_BIT) <= enables_in(i);
    end generate; 
    
    weights_routing: for i in 0 to (DEPTH-1) generate 
        weight_interconnect_ports_in(i,0) <= weights_in(i);
        control_interconnect_ports_in(i,0)(WEIGHT_INIT_BIT) <= weights_init_in(i);
        control_interconnect_ports_in(i,0)(WEIGHT_VALID_BIT) <= weights_valid_in(i);
    end generate; 
    
    rows_routing: for i in 0 to (DEPTH*2)-2 generate 
        constant C: INTEGER := 0 when (i<DEPTH) else (i-DEPTH+1);
        constant R: INTEGER := i when (i<DEPTH) else (DEPTH-1);
    begin 
        row_interconnect_ports_in(R,C) <= rows_in(i); 
        control_interconnect_ports_in(R,C)(ACTIVATION_INIT_BIT) <= rows_init_in(i);
        control_interconnect_ports_in(R,C)(ACTIVATION_VALID_BIT) <= rows_valid_in(i);
    end generate; 
    
end architecture;
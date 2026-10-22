library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_MATRIX_PARAMETERS.ALL;

entity PE_matrix is 
    Port ( 
        clk:                    in STD_LOGIC;  
        reset:                  in STD_LOGIC;                 
        
        weights_in:                 in MATRIX_WEIGHTS_INTERFACE; 
        activations_in:             in MATRIX_ACTIVATION_INTERFACE; 
        accumulators_in:            in MATRIX_ACCUMULATORS_INTERFACE; 
        controls_in:                in MATRIX_CONTROL_INTERFACE;
        status_in:                  in MATRIX_STATUS_INTERFACE;
        
        accumulators_out:           out MATRIX_ACCUMULATORS_INTERFACE;
        status_out:                 out MATRIX_STATUS_INTERFACE
    );
end PE_matrix;


architecture Behavioral of PE_matrix is 
    signal weight_interconnect_ports_in,weight_interconnect_ports_out: MATRIX_INTERCONNECT_DATA; 
    signal activation_interconnect_ports_in,activation_interconnect_ports_out: MATRIX_INTERCONNECT_DATA; 
    signal accumulator_interconnect_ports_in,accumulator_interconnect_ports_out: MATRIX_INTERCONNECT_ACCUMULATOR;
    signal control_interconnect_ports_in,control_interconnect_ports_out: MATRIX_INTERCONNECT_CONTROL; 
    signal status_interconnect_ports_in, status_interconnect_ports_out: MATRIX_INTERCONNECT_STATUS;
    
begin 

    matrix_rows: for r in 0 to (DEPTH-1) generate 
        matrix_columns: for c in 0 to (DEPTH-1) generate
            pe_entity: PE 
                Port map (
                    clk => clk, 
                    reset => reset,       
                    control_in => control_interconnect_ports_in(r,c),
                    control_out => control_interconnect_ports_out(r,c),
                    status_in => status_interconnect_ports_in(r,c),
                    status_out => status_interconnect_ports_out(r,c),
                    
                    weight_in => weight_interconnect_ports_in(r,c), 
                    weight_out => weight_interconnect_ports_out(r,c), 
                    
                    activation_in => activation_interconnect_ports_in(r,c),
                    activation_out => activation_interconnect_ports_out(r,c),
                    
                    accumulator_in => accumulator_interconnect_ports_in(r,c),
                    accumulator_out => accumulator_interconnect_ports_out(r,c)
                );
           
            
            weight_routing: if (c+1<DEPTH) generate 
                weight_interconnect_ports_in(r,c+1) <= weight_interconnect_ports_out(r,c);
            end generate; 
            
            accumulators_routing: if (r+1<DEPTH) generate 
                accumulator_interconnect_ports_in(r+1,c) <= accumulator_interconnect_ports_out(r,c);
                status_interconnect_ports_in(r+1,c)<= status_interconnect_ports_out(r,c);
            end generate; 
            
            activation_routing: if (r>0 and (c+1<DEPTH)) generate 
                activation_interconnect_ports_in(r-1,c+1) <= activation_interconnect_ports_out(r,c);
            end generate; 
            
            control_routing: if (c+1<DEPTH) generate 
                control_interconnect_ports_in(r,c+1) <= control_interconnect_ports_out(r,c);
            end generate; 
            
            
             
        end generate;
    end generate;
    
    accumulator_interfaces_routing: for i in 0 to (ACCUMULATION_LINES-1) generate 
        accumulators_out(i) <= accumulator_interconnect_ports_out(DEPTH-1,i);
        accumulator_interconnect_ports_in(0,i) <= accumulators_in(i); 
        status_out(i) <= status_interconnect_ports_out(DEPTH-1,i);
        status_interconnect_ports_in(0,i) <= status_in(i);
    end generate; 
    
    weight_interface_routing: for i in 0 to (WEIGHT_LINES-1) generate 
        weight_interconnect_ports_in(i,0) <= weights_in(i);
    end generate; 
    
    activation_interface_routing: for i in 0 to (ACTIVATION_LINES-1) generate 
        constant ROW: INTEGER := i when (i<DEPTH) else (DEPTH-1); 
        constant COL: INTEGER := 0 when (i<DEPTH) else (i-DEPTH+1);
    begin 
        activation_interconnect_ports_in(ROW,COL) <= activations_in(i); 
    end generate; 
    
    control_interface_routing: for i in 0 to (CONTROL_LINES-1) generate 
        control_interconnect_ports_in(i,0) <= controls_in(i);             
    end generate; 
    
end architecture;
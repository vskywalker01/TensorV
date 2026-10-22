library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use work.PE_matrix_parameters.ALL;

entity PE is 
    Port ( 
        clk:                    in STD_LOGIC;  
        reset:                  in STD_LOGIC;                 
        
        control_in:             in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
        status_in:              in STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
        weight_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
        activation_in:          in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
        accumulator_in:         in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        
        control_out:            out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
        status_out:             out STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
        weight_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
        activation_out:         out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_out:        out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0)
        
    );
end PE;


architecture Behavioral of PE is
    component PE_stage1 is
        Port (
            clk:                        in STD_LOGIC;  
            reset:                      in STD_LOGIC;                 
            
            -- matrix forward lines
            
            control_forward_in:                 in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
            weight_forward_in:                  in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
            status_forward_in:                  in STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
            activation_forward_in:              in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_forward_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
           
            
            control_forward_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
            status_forward_out:                 out STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
            weight_forward_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
            activation_forward_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_forward_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            -- Internal connections (From stage 1 to stage 2)
            
            accumulator_loopback_in:            in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            accumulator_loopback_valid_in:      in STD_LOGIC;
           
            -- Queue I/Os
            
            weight_queue_out:                   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_queue_out:               out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_queue_out:              out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            -- Queue Control signals 
            queue_empty_out:                    out STD_LOGIC;
            row_done_out:                       out STD_LOGIC;
            accumulator_empty_out:              out STD_LOGIC
        );
    end component;
    component PE_stage2 is
        Port ( 
            clk:                        in STD_LOGIC;  
            reset:                      in STD_LOGIC;     
                        
            -- matrix forward lines
            
            control_forward_in:                 in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
            status_forward_in:                  in STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
            weight_forward_in:                  in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
            activation_forward_in:              in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_forward_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            
            control_forward_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);   
            status_forward_out:                 out STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);               
            weight_forward_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_forward_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_forward_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            -- Queue Input lines (Stage 1)
            
            weight_queue_in:          in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_queue_in:      in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_queue_in:     in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            
            -- Queue control lines (Stage 1)
            
            queue_empty_in:                     in STD_LOGIC;
            accumulator_empty_in:               in STD_LOGIC;
            
            row_done_in:                        in STD_LOGIC;
            
            -- Reduction I/O and control lines 
            
            reduction_partial1_out:             out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            reduction_partial2_out:             out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            reduction_valid_out:            out STD_LOGIC;
            reduction_type_out:             out STD_LOGIC
        );
    end component;
    component PE_stage3 is
        Port ( 
            clk:                        in STD_LOGIC;  
            reset:                      in STD_LOGIC;     
            
            -- matrix forward lines             
            
            control_forward_in:                 in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
            status_forward_in:                  in STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
            accumulator_forward_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            weight_forward_in:                  in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_forward_in:              in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            
            control_forward_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
            status_forward_out:                 out STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
            weight_forward_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_forward_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_forward_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            -- control lines and I/O from stage 2
            reduction_partial1_in:              in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            reduction_partial2_in:              in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            reduction_valid_in:                 in STD_LOGIC;
            reduction_type_in:                  in STD_LOGIC;
            
            -- loopback control lines and I/O (to stage 1)
            
            accumulator_loopback_out:           out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            accumulator_loopback_valid_out:     out STD_LOGIC
        );
    end component;
    
    -- forward signals
    signal control_forward_12, control_forward_23:            STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
    signal status_forward_12, status_forward_23:              STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
    signal weight_forward_12, weight_forward_23:              STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    signal activation_forward_12, activation_forward_23:      STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal accumulator_forward_12, accumulator_forward_23:    STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    
    -- signals from stage 3 to stage 1 
    signal accumulator_loopback:                    STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal accumulator_loopback_valid:              STD_LOGIC;
    
    -- signals from stage 1 to stage 2 
    signal weight_queue, activation_queue:                              STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal accumulator_queue:                                           STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal queue_empty, accumulator_empty, row_done: STD_LOGIC; 
    
    --signals from stage 2 to stage 3 
    signal reduction_partial1, reduction_partial2:          STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal reduction_valid, reduction_type:                 STD_LOGIC;
    
begin
    stage1: PE_stage1 
        port map(
            clk => clk, 
            reset => reset, 
            
            control_forward_in => control_in,
            status_forward_in => status_in,
            weight_forward_in => weight_in,
            activation_forward_in => activation_in,
            accumulator_forward_in => accumulator_in, 
            control_forward_out => control_forward_12,
            status_forward_out => status_forward_12,
            weight_forward_out => weight_forward_12,
            activation_forward_out => activation_forward_12,
            accumulator_forward_out => accumulator_forward_12,
            
            accumulator_loopback_in => accumulator_loopback,
            accumulator_loopback_valid_in => accumulator_loopback_valid,
            
            weight_queue_out => weight_queue,
            activation_queue_out => activation_queue,
            accumulator_queue_out => accumulator_queue,
            queue_empty_out => queue_empty, 
            accumulator_empty_out => accumulator_empty,
            row_done_out => row_done
            
        );
    stage2: PE_stage2
        port map(
            clk => clk, 
            reset => reset, 
            
            control_forward_in => control_forward_12,
            status_forward_in => status_forward_12,
            weight_forward_in => weight_forward_12,
            activation_forward_in => activation_forward_12,
            accumulator_forward_in => accumulator_forward_12, 
            control_forward_out => control_forward_23,
            status_forward_out => status_forward_23,
            weight_forward_out => weight_forward_23,
            activation_forward_out => activation_forward_23,
            accumulator_forward_out => accumulator_forward_23,
            
            weight_queue_in => weight_queue,
            activation_queue_in => activation_queue,
            accumulator_queue_in => accumulator_queue,
            queue_empty_in => queue_empty, 
            accumulator_empty_in => accumulator_empty,
            row_done_in => row_done,
            
            reduction_partial1_out => reduction_partial1,
            reduction_partial2_out => reduction_partial2, 
            reduction_valid_out => reduction_valid, 
            reduction_type_out => reduction_type
        );
    stage3: PE_stage3
        port map(
            clk => clk, 
            reset => reset,
              
            control_forward_in => control_forward_23,
            weight_forward_in => weight_forward_23,
            activation_forward_in => activation_forward_23,
            accumulator_forward_in => accumulator_forward_23, 
            control_forward_out => control_out,
            status_forward_in => status_forward_23,
            status_forward_out => status_out,
            weight_forward_out => weight_out,
            activation_forward_out => activation_out,
            accumulator_forward_out => accumulator_out,
            
            reduction_partial1_in => reduction_partial1,
            reduction_partial2_in => reduction_partial2, 
            reduction_valid_in => reduction_valid, 
            reduction_type_in => reduction_type,
            
            accumulator_loopback_out => accumulator_loopback,
            accumulator_loopback_valid_out => accumulator_loopback_valid
            
        );    
end architecture; 



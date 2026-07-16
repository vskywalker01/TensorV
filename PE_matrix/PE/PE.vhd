library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 
use work.PE_matrix_parameters.ALL;

entity PE is 
    Port ( 
        clk:                    in STD_LOGIC;  
        reset:                  in STD_LOGIC;                 
        
        control_in:             in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
        weight_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
        activation_in:          in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
        accumulator_in:         in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        
        control_out:            out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
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
            
            control_in:                 in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
            weight_in:                  in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            
            control_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
            weight_forward_out:         out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_forward_out:     out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            weight_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            weight_empty_out:           out STD_LOGIC;
            activation_empty_out:       out STD_LOGIC
            
        );
    end component;
    component PE_stage2 is
        Port ( 
            clk:                        in STD_LOGIC;  
            reset:                      in STD_LOGIC;                 
            
            control_in:                 in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
            weight_in:                  in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            weight_empty_in:            in STD_LOGIC;
            activation_empty_in:        in STD_LOGIC;
            
            weight_forward_in:          in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_forward_in:      in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            
            control_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
            weight_forward_out:         out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_forward_out:     out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            
            reduction1_out:             out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            reduction2_out:             out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            reduction_valid_out:        out STD_LOGIC

        );
    end component;
    component PE_stage3 is
        Port ( 
            clk:                        in STD_LOGIC;  
            reset:                      in STD_LOGIC;                 
            
            control_in:                 in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
            
            weight_forward_in:          in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_forward_in:      in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            
            control_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
            weight_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            reduction1_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            reduction2_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            reduction_valid_in:        in STD_LOGIC 
            
        );
    end component;
    
    signal control12, control23:                            STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
    signal weight_forward12, weight_forward23:              STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    signal activation_forward12, activation_forward23:      STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal accumulator_out12, reduction1_23, reduction2_23: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal weight12, activation12:                          STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal weight_empty12,activation_empty12,reduction_valid23: STD_LOGIC;
    
--    attribute DONT_TOUCH : string;
--    attribute DONT_TOUCH of control12, control23 : signal is "true";
--    attribute DONT_TOUCH of weight_forward12, weight_forward23 : signal is "true";
--    attribute DONT_TOUCH of activation_forward12, activation_forward23 : signal is "true";
--    attribute DONT_TOUCH of accumulator_out12, reduction1_23, reduction2_23 : signal is "true";
--    attribute DONT_TOUCH of weight12, activation12 : signal is "true";
--    attribute DONT_TOUCH of weight_empty12,activation_empty12,reduction_valid23: signal is "true";
    
begin
    stage1: PE_stage1 
        port map(
            clk => clk, 
            reset => reset, 
            control_in => control_in,
            weight_in => weight_in,
            activation_in => activation_in,
            accumulator_in => accumulator_in, 
            
            control_out => control12,
            weight_forward_out => weight_forward12,
            activation_forward_out => activation_forward12,
            accumulator_out => accumulator_out12,
            
            weight_out => weight12,
            activation_out => activation12,
            weight_empty_out => weight_empty12,
            activation_empty_out => activation_empty12
        );
    stage2: PE_stage2
        port map(
            clk => clk, 
            reset => reset, 
            control_in => control12,
            weight_in => weight12,
            activation_in => activation12,
            accumulator_in => accumulator_out12, 
            weight_forward_in => weight_forward12,
            activation_forward_in => activation_forward12,
            weight_empty_in => weight_empty12,
            activation_empty_in => activation_empty12,
            
            control_out => control23,
            weight_forward_out => weight_forward23,
            activation_forward_out => activation_forward23,

            reduction1_out => reduction1_23, 
            reduction2_out => reduction2_23,
            reduction_valid_out => reduction_valid23
        );
    stage3: PE_stage3
        port map(
            clk => clk, 
            reset => reset, 
            control_in => control23,

            weight_forward_in => weight_forward23,
            activation_forward_in => activation_forward23,
            
            reduction1_in => reduction1_23, 
            reduction2_in => reduction2_23,
            reduction_valid_in => reduction_valid23,
            
            control_out => control_out,
            weight_out => weight_out,
            activation_out => activation_out,
            accumulator_out => accumulator_out
        );    
end architecture; 



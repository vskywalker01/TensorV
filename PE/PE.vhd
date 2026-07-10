library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.REGISTERS.ALL; 

-- control -> (activation_init, weight_init, accumulator_init, activation_valid, weight_valid, process_element, process_accumulator)

entity PE is 
    Generic (
        DATA_SIZE: INTEGER := 8; 
        ACCUMULATOR_SIZE: INTEGER := 20; 
        QUEUE_SIZE: INTEGER := 8;
        
        ACTIVATION_INIT_BIT: INTEGER := 6; 
        WEIGHT_INIT_BIT: INTEGER := 5;
        ACCUMULATOR_INIT_BIT: INTEGER := 4;
        ACTIVATION_VALID_BIT: INTEGER := 3; 
        WEIGHT_VALID_BIT:   INTEGER := 2; 
        PROCESS_ELEMENT_BIT: INTEGER := 1; 
        PROCESS_ACCUMULATOR_BIT: INTEGER := 0
        
    );
    Port ( 
        clk:                    in STD_LOGIC;  
        reset:                  in STD_LOGIC;                 
        
        control_in:             in STD_LOGIC_VECTOR(6 downto 0); 
        weight_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
        activation_in:          in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
        accumulator_in:         in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        
        control_out:            out STD_LOGIC_VECTOR(6 downto 0);
        weight_out:             out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
        activation_out:         out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
        accumulator_out:        out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0)
        
    );
end PE;


architecture Behavioral of PE is 
    component PE_stage1 is
        Generic (
            DATA_SIZE: INTEGER := 8; 
            ACCUMULATOR_SIZE: INTEGER := 20; 
            QUEUE_SIZE: INTEGER := 8;
            
            ACTIVATION_INIT_BIT: INTEGER := 6; 
            WEIGHT_INIT_BIT: INTEGER := 5;
            ACCUMULATOR_INIT_BIT: INTEGER := 4;
            ACTIVATION_VALID_BIT: INTEGER := 3; 
            WEIGHT_VALID_BIT:   INTEGER := 2; 
            PROCESS_ELEMENT_BIT: INTEGER := 1; 
            PROCESS_ACCUMULATOR_BIT: INTEGER := 0
            
        );
        Port ( 
            clk:                        in STD_LOGIC;  
            reset:                      in STD_LOGIC;                 
            
            control_in:                 in STD_LOGIC_VECTOR(6 downto 0); 
            weight_in:                  in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            
            control_out:                out STD_LOGIC_VECTOR(6 downto 0);
            weight_forward_out:         out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_forward_out:     out STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            weight_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0)
            
        );
    end component;
    component PE_stage2 is
        Generic (
            DATA_SIZE: INTEGER := 8; 
            ACCUMULATOR_SIZE: INTEGER := 20; 
            QUEUE_SIZE: INTEGER := 8;
            
            ACTIVATION_INIT_BIT: INTEGER := 6; 
            WEIGHT_INIT_BIT: INTEGER := 5;
            ACCUMULATOR_INIT_BIT: INTEGER := 4;
            ACTIVATION_VALID_BIT: INTEGER := 3; 
            WEIGHT_VALID_BIT:   INTEGER := 2; 
            PROCESS_ELEMENT_BIT: INTEGER := 1; 
            PROCESS_ACCUMULATOR_BIT: INTEGER := 0
            
        );
        Port ( 
            clk:                        in STD_LOGIC;  
            reset:                      in STD_LOGIC;                 
            
            control_in:                 in STD_LOGIC_VECTOR(6 downto 0); 
            weight_in:                  in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
            activation_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
            accumulator_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            
            weight_forward_in:          in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_forward_in:      in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            
            control_out:                out STD_LOGIC_VECTOR(6 downto 0);
            weight_forward_out:         out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_forward_out:     out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            
            reduction1_out:             out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            reduction2_out:             out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0)
            
        );
    end component;
    component PE_stage3 is
        Generic (
            DATA_SIZE: INTEGER := 8; 
            ACCUMULATOR_SIZE: INTEGER := 20; 
            QUEUE_SIZE: INTEGER := 8;
            
            ACTIVATION_INIT_BIT: INTEGER := 6; 
            WEIGHT_INIT_BIT: INTEGER := 5;
            ACCUMULATOR_INIT_BIT: INTEGER := 4;
            ACTIVATION_VALID_BIT: INTEGER := 3; 
            WEIGHT_VALID_BIT:   INTEGER := 2; 
            PROCESS_ELEMENT_BIT: INTEGER := 1; 
            PROCESS_ACCUMULATOR_BIT: INTEGER := 0
            
        );
        Port ( 
            clk:                        in STD_LOGIC;  
            reset:                      in STD_LOGIC;                 
            
            control_in:                 in STD_LOGIC_VECTOR(6 downto 0); 
            
            weight_forward_in:          in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_forward_in:      in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            
            control_out:                out STD_LOGIC_VECTOR(6 downto 0);
            weight_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            activation_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            accumulator_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
            
            reduction1_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
            reduction2_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0)
            
        );
    end component;
    
    signal control12, control23:                            STD_LOGIC_VECTOR(6 downto 0);
    signal weight_forward12, weight_forward23:              STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
    signal activation_forward12, activation_forward23:      STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
    signal accumulator_out12, reduction1_23, reduction2_23: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal weight12, activation12:                          STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
    
begin
    stage1: PE_stage1 
        generic map (
            DATA_SIZE => DATA_SIZE, 
            ACCUMULATOR_SIZE => ACCUMULATOR_SIZE,
            QUEUE_SIZE => QUEUE_SIZE,
            
            ACTIVATION_INIT_BIT => ACTIVATION_INIT_BIT,
            WEIGHT_INIT_BIT => WEIGHT_INIT_BIT,
            ACCUMULATOR_INIT_BIT => ACCUMULATOR_INIT_BIT,
            ACTIVATION_VALID_BIT => ACTIVATION_VALID_BIT,
            WEIGHT_VALID_BIT => WEIGHT_VALID_BIT,
            PROCESS_ELEMENT_BIT => PROCESS_ELEMENT_BIT,
            PROCESS_ACCUMULATOR_BIT => PROCESS_ACCUMULATOR_BIT
        )
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
            activation_out => activation12
        );
    stage2: PE_stage2
        generic map (
            DATA_SIZE => DATA_SIZE, 
            ACCUMULATOR_SIZE => ACCUMULATOR_SIZE,
            QUEUE_SIZE => QUEUE_SIZE,
            
            ACTIVATION_INIT_BIT => ACTIVATION_INIT_BIT,
            WEIGHT_INIT_BIT => WEIGHT_INIT_BIT,
            ACCUMULATOR_INIT_BIT => ACCUMULATOR_INIT_BIT,
            ACTIVATION_VALID_BIT => ACTIVATION_VALID_BIT,
            WEIGHT_VALID_BIT => WEIGHT_VALID_BIT,
            PROCESS_ELEMENT_BIT => PROCESS_ELEMENT_BIT,
            PROCESS_ACCUMULATOR_BIT => PROCESS_ACCUMULATOR_BIT
        )
        port map(
            clk => clk, 
            reset => reset, 
            control_in => control12,
            weight_in => weight12,
            activation_in => activation12,
            accumulator_in => accumulator_in, 
            weight_forward_in => weight_forward12,
            activation_forward_in => activation_forward12,
            
            control_out => control23,
            weight_forward_out => weight_forward23,
            activation_forward_out => activation_forward23,

            reduction1_out => reduction1_23, 
            reduction2_out => reduction2_23
        );
    stage3: PE_stage3
        generic map (
            DATA_SIZE => DATA_SIZE, 
            ACCUMULATOR_SIZE => ACCUMULATOR_SIZE,
            QUEUE_SIZE => QUEUE_SIZE,
            
            ACTIVATION_INIT_BIT => ACTIVATION_INIT_BIT,
            WEIGHT_INIT_BIT => WEIGHT_INIT_BIT,
            ACCUMULATOR_INIT_BIT => ACCUMULATOR_INIT_BIT,
            ACTIVATION_VALID_BIT => ACTIVATION_VALID_BIT,
            WEIGHT_VALID_BIT => WEIGHT_VALID_BIT,
            PROCESS_ELEMENT_BIT => PROCESS_ELEMENT_BIT,
            PROCESS_ACCUMULATOR_BIT => PROCESS_ACCUMULATOR_BIT
        )
        port map(
            clk => clk, 
            reset => reset, 
            control_in => control23,

            weight_forward_in => weight_forward23,
            activation_forward_in => activation_forward23,
            
            reduction1_in => reduction1_23, 
            reduction2_in => reduction2_23,
            
            control_out => control_out,
            weight_out => weight_out,
            activation_out => activation_out,
            accumulator_out => accumulator_out
        );
    
    
end architecture; 



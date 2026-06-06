library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MATRIX_REDUCTION_PARAMETERS.ALL;


entity MAC is 
    Generic (
        ACC_SIZE: INTEGER := 20
    );
    Port ( 
        clk: in STD_LOGIC; 
        reset: in STD_LOGIC; 
    
        data_a:         in STD_LOGIC_VECTOR(7 downto 0);
        data_b:         in STD_LOGIC_VECTOR(7 downto 0); 
        data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
        
        r_out:          out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
    );
end MAC;

architecture Behavioral of MAC is
    component MAC_stage1 is
        Generic (
            ACC_SIZE: INTEGER := 32
        );
        Port ( 
            clk: in STD_LOGIC; 
            reset: in STD_LOGIC; 
    
            data_a:         in STD_LOGIC_VECTOR(7 downto 0);
            data_b:         in STD_LOGIC_VECTOR(7 downto 0); 
            data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
        
            matrix_out:     out MATRIX(0 to 1);
            data_acc_out:   out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;
    component MAC_stage2 is
        Generic (
            ACC_SIZE: integer := 32
        );
        Port ( 
            clk:            in STD_LOGIC; 
            reset:          in STD_LOGIC; 
        
            matrix_in:      in MATRIX(0 to 1);
            data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
            
            data_mul_out:   out STD_LOGIC_VECTOR(MATRIX_OUTPUT_SIZE-1 downto 0);
            data_acc_out:   out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;
    component MAC_stage3 is
        Generic (
            ACC_SIZE: integer := 32
        );
        Port ( 
            clk:            in STD_LOGIC; 
            reset:          in STD_LOGIC; 
        
            data_mul_in:    in STD_LOGIC_VECTOR(MATRIX_OUTPUT_SIZE-1 downto 0);
            data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
            
            r_out:          out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;
    

    signal matrix_out: MATRIX(0 to 1);
    signal multiplication_23: STD_LOGIC_VECTOR(MATRIX_OUTPUT_SIZE-1 downto 0);
    signal accumulator_12: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    signal accumulator_23: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
    
    
begin
    stage1: MAC_stage1 
        Generic map (
            ACC_SIZE => ACC_SIZE
        )
        Port map (
            clk => clk, 
            reset => reset,
        
            data_a => data_a,
            data_b => data_b,
            data_acc_in => data_acc_in,
            
            matrix_out => matrix_out,
            data_acc_out => accumulator_12
        );

    stage3: MAC_stage2
        Generic map (
            ACC_SIZE => ACC_SIZE
        ) 
        Port map (
            clk => clk, 
            reset => reset,
        
            matrix_in => matrix_out,
            data_acc_in => accumulator_12,
            
            data_mul_out => multiplication_23,
            data_acc_out => accumulator_23
        );
    stage4: MAC_stage3
        Generic map (
            ACC_SIZE => ACC_SIZE
        ) 
        Port map (
            clk => clk, 
            reset => reset,
        
            data_mul_in => multiplication_23,
            data_acc_in => accumulator_23,
            
            r_out => r_out
        );
end Behavioral;

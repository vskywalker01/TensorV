library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.MULTIPLIER_PARAMETERS.ALL;


entity MAC is 
    Generic (
        ACC_SIZE: INTEGER := 32
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
        
            p_out:          out PARTIALS_ARRAY(0 to 3);
            data_acc_out:   out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;
    component MAC_stage2 is
        Generic (
            ACC_SIZE: INTEGER := 32
        );
        Port ( 
            clk:            in STD_LOGIC; 
            reset:          in STD_LOGIC; 
        
            p_in:           in PARTIALS_ARRAY(0 to 3);
            data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
            
            p_out:          out PARTIALS_ARRAY(0 to 1);
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
        
            p_in:           in PARTIALS_ARRAY(0 to 1);
            data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
            
            r_out:          out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;
    
    signal partials_12: PARTIALS_ARRAY(0 to 3);
    signal partials_23: PARTIALS_ARRAY(0 to 1);
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
            
            p_out => partials_12,
            data_acc_out => accumulator_12
        );
    stage2: MAC_stage2 
        Generic map (
            ACC_SIZE => ACC_SIZE 
        ) 
        Port map (
            clk => clk, 
            reset => reset,
        
            p_in => partials_12,
            data_acc_in => accumulator_12,
            
            p_out => partials_23,
            data_acc_out => accumulator_23
        );
    stage3: MAC_stage3 
        Generic map (
            ACC_SIZE => ACC_SIZE
        ) 
        Port map (
            clk => clk, 
            reset => reset,
        
            p_in => partials_23,
            data_acc_in => accumulator_23,
            
            r_out => r_out
        );
        
end Behavioral;

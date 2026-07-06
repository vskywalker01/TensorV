-- Declaration of MAC unit for DNN accelerators. It performs:
-- * Multiplication between two 8-bit signed values 
-- * Accumulation in parametric size (for example 20 bits or 32 bits). 

-- The unit is pipelined and performs one operation in two clock cycle s(two stage pipeline) with a maximum clock frequency of 200mhz (on basys 3)


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity MAC is 
    Generic (
        ACC_SIZE: INTEGER := 20
    );
    Port ( 
        clk: in STD_LOGIC;                                          -- clock 
        reset: in STD_LOGIC;                                        -- reset (when '1') 
    
        data_a:         in STD_LOGIC_VECTOR(7 downto 0);            -- first value (multiplication) 
        data_b:         in STD_LOGIC_VECTOR(7 downto 0);            -- second value (multiplication)
        data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);   -- accumulator input 
        
        r_out:          out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)   -- result (multiplication + accumulation)
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
            
            matrix_out1:    out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
            matrix_out2:    out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
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
        
            matrix_in1:     in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
            matrix_in2:     in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
            data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
            
            data_out:   out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;

    signal matrix_out1: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    signal matrix_out2: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);    
    signal accumulator12: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    
begin
    reduce: MAC_stage1 
        Generic map (
            ACC_SIZE => ACC_SIZE
        )
        Port map (
            clk => clk, 
            reset => reset,
        
            data_a => data_a,
            data_b => data_b,
            data_acc_in => data_acc_in,
            
            matrix_out1 => matrix_out1,
            matrix_out2 => matrix_out2,
            data_acc_out => accumulator12
        );

    sum: MAC_stage2
        Generic map (
            ACC_SIZE => ACC_SIZE
        ) 
        Port map (
            clk => clk, 
            reset => reset,
        
            matrix_in1 => matrix_out1,
            matrix_in2 => matrix_out2,
            data_acc_in => accumulator12,
            
            data_out => r_out
        );
end Behavioral;

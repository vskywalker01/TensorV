library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reduction_stage_test is
--  Port ( );
end reduction_stage_test;

architecture Behavioral of reduction_stage_test is
    component reduction_stage is
        Generic (
            ACC_SIZE: INTEGER := 32
        );
        Port (         
            data_a:         in STD_LOGIC_VECTOR(7 downto 0);
            data_b:         in STD_LOGIC_VECTOR(7 downto 0); 
            
            overflow:       out STD_LOGIC; 
            matrix_out1:    out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
            matrix_out2:    out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;
    constant ACC_SIZE: INTEGER := 8;
    signal overflow: STD_LOGIC; 
    signal data_a: STD_LOGIC_VECTOR(7 downto 0); 
    signal data_b: STD_LOGIC_VECTOR(7 downto 0); 
    signal matrix_out1: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
    signal matrix_out2: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
    
begin
    stage: reduction_stage 
        Generic map ( 
            ACC_SIZE => ACC_SIZE
        )
        Port map ( 
            data_a => data_a,
            data_b => data_b,
            overflow => overflow,
            matrix_out1 => matrix_out1,
            matrix_out2 => matrix_out2
        );

   
    process 
    begin 
        data_a <= "00000011"; -- 
        data_b <= "00001000"; -- 
        wait for 30ns; 
        data_a <= "11111111"; -- 
        data_b <= "11111010"; -- 
        wait for 50ns; 
        data_a <= "00000010"; -- 
        data_b <= "01111010"; -- 
        --data_a <= "00001111"; -- 
        --data_b <= "11111110"; --- 
        --wait for 200ns;
    end process; 

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MATRIX_REDUCTION_PARAMETERS.ALL;

entity MAC_stage1_test is
--  Port ( );
end MAC_stage1_test;

architecture Behavioral of MAC_stage1_test is
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
            
            matrix_out:     out MATRIX(0 to 5);
            data_acc_out:   out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;
    constant ACC_SIZE: INTEGER := 32;
    signal clk: STD_LOGIC; 
    signal RESET: STD_LOGIC; 
    signal data_a: STD_LOGIC_VECTOR(7 downto 0); 
    signal data_b: STD_LOGIC_VECTOR(7 downto 0); 
    signal data_acc_in: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    signal data_acc_out: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    signal matrix_out: MATRIX(0 to 5);
begin
    stage: MAC_stage1 
        Port map ( 
            clk => clk,
            reset => reset, 
            data_a => data_a,
            data_b => data_b,
            data_acc_in => data_acc_in,
            matrix_out => matrix_out, 
            data_acc_out => data_acc_out
        );

    process 
    begin 
        clk <= '1';
        wait for 5ns;
        clk <= '0';
        wait for 5ns; 
    end process; 
    process 
    begin 
        reset <= '1'; 
        wait for 30ns; 
        reset <= '0'; 
        data_acc_in <= x"00000000";
        data_a <= "11111111"; -- 
        data_b <= "11111010"; -- 
        wait for 50ns; 
        --data_a <= "00001111"; -- 
        --data_b <= "11111110"; --- 
        --wait for 200ns;
    end process; 

end Behavioral;

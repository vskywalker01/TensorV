library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MAC_stage2_test is
--  Port ( );
end MAC_stage2_test;

architecture Behavioral of MAC_stage2_test is
    constant ACC_SIZE: INTEGER := 32;

    component MAC_stage2 is
        Generic (
            ACC_SIZE: INTEGER := 32
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
    
    signal clk: STD_LOGIC; 
    signal RESET: STD_LOGIC; 
    signal matrix_in1: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    signal matrix_in2: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    signal data_acc_in: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    signal data_out: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
   
begin
    stage: MAC_stage2 
        Port map ( 
            clk => clk,
            reset => reset, 
            matrix_in1 => matrix_in1,
            matrix_in2 => matrix_in2,
            data_acc_in => data_acc_in,
            data_out => data_out
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
        data_acc_in <= (others => '0');
        for c in 0 to (ACC_SIZE-1) loop 
            matrix_in1(c) <= '0';
            matrix_in2(c) <= '0';
            data_acc_in(c) <= '0';
        end loop;
        wait for 50ns; 
        for c in 0 to (ACC_SIZE-1) loop 
            matrix_in1(c) <= '1';
            matrix_in2(c) <= '1';
            data_acc_in(c) <= '1';
        end loop;
        wait for 50ns;
    end process; 

end Behavioral;

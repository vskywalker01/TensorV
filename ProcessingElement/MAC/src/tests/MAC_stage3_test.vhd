library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MULTIPLIER_PARAMETERS.ALL;

entity MAC_stage3_test is
--  Port ( );
end MAC_stage3_test;

architecture Behavioral of MAC_stage3_test is
    component MAC_stage3 is
        Generic (
            ACC_SIZE: INTEGER := 32
        );
        Port ( 
            clk:            in STD_LOGIC; 
            reset:          in STD_LOGIC; 
        
            p_in:           in PARTIALS_ARRAY(0 to 1);
            data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
            
            r_out:          out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;
    
    signal clk: STD_LOGIC; 
    signal RESET: STD_LOGIC; 
    signal p_in: PARTIALS_ARRAY(0 to 1);
    signal data_acc_in: STD_LOGIC_VECTOR(31 downto 0);
    signal r_out: STD_LOGIC_VECTOR(31 downto 0);
    
    constant pt1: STD_LOGIC_VECTOR(16 downto 0) := "10110111110100010";
    constant pt2: STD_LOGIC_VECTOR(16 downto 0) := "U00110000000001UU";

begin
    stage: MAC_stage3 
        Port map ( 
            clk => clk,
            reset => reset, 
            p_in => p_in,
            data_acc_in => data_acc_in,
            r_out => r_out
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
        data_acc_in <= "00000000000000001001000001011101";
        for c in 0 to (PARTIAL_SIZE-1) loop 
            p_in(0)(c) <= pt1(c);
            p_in(1)(c) <= pt2(c);
        end loop;

        wait for 50ns; 
    end process; 

end Behavioral;
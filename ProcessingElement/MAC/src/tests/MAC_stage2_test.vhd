library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MULTIPLIER_PARAMETERS.ALL;

entity MAC_stage2_test is
--  Port ( );
end MAC_stage2_test;

architecture Behavioral of MAC_stage2_test is
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
    
    signal clk: STD_LOGIC; 
    signal RESET: STD_LOGIC; 
    signal p_in: PARTIALS_ARRAY(0 to 3);
    signal data_acc_in: STD_LOGIC_VECTOR(31 downto 0);
    signal data_acc_out: STD_LOGIC_VECTOR(31 downto 0);
    signal p_out: PARTIALS_ARRAY(0 to 1);
    
    constant pt1: STD_LOGIC_VECTOR(16 downto 0) := "00111100000000010";
    constant pt2: STD_LOGIC_VECTOR(16 downto 0) := "UU0011110000001UU";
    constant pt3: STD_LOGIC_VECTOR(16 downto 0) := "UUUU001111110UUUU";
    constant pt4: STD_LOGIC_VECTOR(16 downto 0) := "UUUUU000111UUUUUU";

begin
    stage: MAC_stage2 
        Port map ( 
            clk => clk,
            reset => reset, 
            p_in => p_in,
            data_acc_in => data_acc_in,
            p_out => p_out, 
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
        data_acc_in <= (others => '0');
        for c in 0 to (PARTIAL_SIZE-1) loop 
            p_in(0)(c) <= pt1(c);
            p_in(1)(c) <= pt2(c);
            p_in(2)(c) <= pt3(c);
            p_in(3)(c) <= pt4(c);
        end loop;
         -- p_out(0) = "00110111110100010"
         -- p_out(1) = "U00110000000001UU"
        wait for 50ns; 
    end process; 

end Behavioral;

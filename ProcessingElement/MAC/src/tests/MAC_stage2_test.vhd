library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MATRIX_REDUCTION_PARAMETERS.ALL;

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
        
            matrix_in:      in MATRIX(0 to 5);
            data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
            
            matrix_out:     out MATRIX(0 to 1);
            data_acc_out:   out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;
    
    signal clk: STD_LOGIC; 
    signal RESET: STD_LOGIC; 
    signal matrix_in: MATRIX(0 to 5);
    signal data_acc_in: STD_LOGIC_VECTOR(31 downto 0);
    signal data_acc_out: STD_LOGIC_VECTOR(31 downto 0);
    signal matrix_out: MATRIX(0 to 1);
    
    constant pt1: STD_LOGIC_VECTOR(15 downto 0) := "0111100000000010";
    constant pt2: STD_LOGIC_VECTOR(15 downto 0) := "U0011110000001UU";
    constant pt3: STD_LOGIC_VECTOR(15 downto 0) := "UUU001111110UUUU";
    constant pt4: STD_LOGIC_VECTOR(15 downto 0) := "UUUU000111UUUUUU";
    constant pt5: STD_LOGIC_VECTOR(15 downto 0) := "UUUU000111UUUUUU";
    constant pt6: STD_LOGIC_VECTOR(15 downto 0) := "UUUU000111UUUUUU";

begin
    stage: MAC_stage2 
        Port map ( 
            clk => clk,
            reset => reset, 
            matrix_in => matrix_in,
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
        data_acc_in <= (others => '0');
        for c in 0 to (MATRIX_OUTPUT_SIZE-1) loop 
            matrix_in(0)(c) <= pt1(c);
            matrix_in(1)(c) <= pt2(c);
            matrix_in(2)(c) <= pt3(c);
            matrix_in(3)(c) <= pt4(c);
            matrix_in(4)(c) <= pt5(c);
            matrix_in(5)(c) <= pt6(c);
        end loop;
         -- p_out(0) = "00110111110100010"
         -- p_out(1) = "U00110000000001UU"
        wait for 50ns; 
    end process; 

end Behavioral;

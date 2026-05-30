library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MAC_test is
--  Port ( );
end MAC_test;

architecture Behavioral of MAC_test is
    component MAC is 
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
    end component;
    signal clk: STD_LOGIC; 
    signal reset: STD_LOGIC; 
        
    signal data_a: STD_LOGIC_VECTOR(7 downto 0);
    signal data_b: STD_LOGIC_VECTOR(7 downto 0); 
    signal data_acc_in: STD_LOGIC_VECTOR(31 downto 0); 
            
    signal r_out:STD_LOGIC_VECTOR(31 downto 0);
begin
    MAC_test: MAC 
        port map (
            clk => clk,
            reset => reset,
            data_a => data_a,
            data_b => data_b, 
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
        data_acc_in <= x"00000005";
        data_a <= x"10"; -- 
        data_b <= x"02"; -- 
        wait for 100ns; 
    end process; 

end Behavioral;

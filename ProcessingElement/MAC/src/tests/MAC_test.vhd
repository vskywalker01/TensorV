library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MAC_test is
--  Port ( );
end MAC_test;

architecture Behavioral of MAC_test is
    component MAC is 
        Port ( 
            clk: in STD_LOGIC; 
            reset: in STD_LOGIC; 
        
            data_a:         in STD_LOGIC_VECTOR(7 downto 0);
            data_b:         in STD_LOGIC_VECTOR(7 downto 0); 
            data_acc_in:    in STD_LOGIC_VECTOR(31 downto 0); 
            
            r_out:          out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    signal clk: STD_LOGIC; 
    signal reset: STD_LOGIC; 
        
    signal data_a: STD_LOGIC_VECTOR(7 downto 0);
    signal data_b: STD_LOGIC_VECTOR(7 downto 0); 
    signal data_acc_in: STD_LOGIC_VECTOR(31 downto 0); 
            
    signal r_out:STD_LOGIC_VECTOR(31 downto 0);
    
    shared variable acc_error_count: integer := 0;
    shared variable mul_error_count: integer := 0;
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
        data_acc_in <= x"00000000";
        for i in -128 to 127 loop 
            for j in -128 to 127 loop 
                data_a <= STD_LOGIC_VECTOR(to_signed(i,8));
                data_b <= STD_LOGIC_VECTOR(to_signed(j,8));
                wait for 50ns; 
                if not(signed(r_out) = to_signed(i,32)*to_signed(j,32)) then
                    report "Error during estimation of 0 + (" 
                        & integer'image(i) 
                        & "*" 
                        & integer'image(j) 
                        & ") " 
                        & "got " 
                        & integer'image(to_integer(signed(r_out)))
                    severity error; 
                    mul_error_count:=mul_error_count+1;
                end if;
            end loop;
        end loop;
        
        for j in -128 to 127 loop 
            for i in -128 to 127 loop 
                data_a <= STD_LOGIC_VECTOR(to_signed(i,8));
                data_b <= STD_LOGIC_VECTOR(to_signed(i,8));
                data_acc_in <= STD_LOGIC_VECTOR(to_signed(j,32));
                wait for 50ns; 
                if not(signed(r_out) = (to_signed(i,32)*to_signed(i,32))+to_signed(j,32)) then
                    report "Error during estimation of "
                        & integer'image(j) 
                        & " + (" 
                        & integer'image(i) 
                        & "*" 
                        & integer'image(i) 
                        & ") got " 
                        & integer'image(to_integer(signed(r_out)))
                    severity error; 
                    acc_error_count:=acc_error_count+1;
                end if;
            end loop;
        end loop;
       
        report "=============================================";
        report "Test terminated";
        report "Multiplication test terminated with "  & integer'image(mul_error_count) & " errors"; 
        report "Accumulation test terminated with "  & integer'image(acc_error_count) & " errors"; 
        
        if (acc_error_count+mul_error_count = 0) then
            report "Test completed successfully! :)";
        else 
            report "Test failed :(";
        end if;
        report "=============================================";
        
        wait; 
        
    end process; 

end Behavioral;

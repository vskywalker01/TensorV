-- Exaustive test for MAC unit. The test performs two steps: 
-- * Multiplication test, where every combination between the 8-bit inputs is tested for the multiplication 
-- * Accumulation test: where all the possible values of the accumulator input are summed with the multiplication between inputs with the same value. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MAC_test is
--  Port ( );
end MAC_test;

architecture Behavioral of MAC_test is
    constant ACC_SIZE: INTEGER := 20;

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
    signal data_acc_in: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
            
    signal r_out: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    
    shared variable acc_error_count: integer := 0;
    shared variable mul_error_count: integer := 0;
begin
    MAC_test: MAC 
        generic map (
            ACC_SIZE => ACC_SIZE
        )
        
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
        
        -- Reset 
        reset <= '1'; 
        wait for 30ns; 
        reset <= '0'; 
        
        -- Setting accumulator to 0
        data_acc_in <= (others => '0');
        
        -- testing all combinations between A and B
        for i in -128 to 127 loop 
            for j in -128 to 127 loop 
                data_a <= STD_LOGIC_VECTOR(to_signed(i,8));
                data_b <= STD_LOGIC_VECTOR(to_signed(j,8));
                wait for 50ns; 
                if not(signed(r_out) = to_signed(i,ACC_SIZE)*to_signed(j,ACC_SIZE)) then
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
        
        -- Setting A=B and testing all combinations 
        for i in -524288 to 524288 loop 
            for j in -128 to 127 loop 
                data_a <= STD_LOGIC_VECTOR(to_signed(j,8));
                data_b <= STD_LOGIC_VECTOR(to_signed(j,8));
                data_acc_in <= STD_LOGIC_VECTOR(to_signed(i,ACC_SIZE));
                wait for 50ns; 
                if not(signed(r_out) = ((to_signed(j,ACC_SIZE)*to_signed(j,ACC_SIZE)))+to_signed(i,ACC_SIZE)) then
                    report "Error during estimation of "
                        & integer'image(i) 
                        & " + (" 
                        & integer'image(j) 
                        & "*" 
                        & integer'image(j) 
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

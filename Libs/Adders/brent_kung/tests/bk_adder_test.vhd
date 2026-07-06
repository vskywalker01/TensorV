-- Exaustive testbench of the Brent-Kung adder.

library IEEE; 

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ADDERS.bk_adder;

entity bk_adder_test is
--  Port ( );
end bk_adder_test;

architecture Behavioral of bk_adder_test is

    -- Edit this value to change the size of the vectors 
    CONSTANT DIM: INTEGER := 8;

    signal a,b,r: STD_LOGIC_VECTOR(DIM-1 downto 0);
    signal c_in, c_out: STD_LOGIC;
    
    shared variable sum_error_count: integer := 0;
begin
    adder: bk_adder
        generic map (
            DIM => DIM
        )
        port map (        
            a => a,
            b => b,
            c_in => C_in,
            
            r => r,
            c_out => c_out
        );
        
    process 
    begin 
        -- Setting carry in fixed to 0
        c_in <= '0';
        wait for 10ns; 
        
        -- Testing all the combinations of the inputs 
        for i in 0 to (2**DIM) loop 
            for j in 0 to (2**DIM) loop 
                a <= STD_LOGIC_VECTOR(to_signed(i,DIM));
                b <= STD_LOGIC_VECTOR(to_signed(j,DIM));
                wait for 10ns; 
                if not(unsigned(r) = to_unsigned(i,DIM)+to_unsigned(j,DIM)) then
                    report "Error during estimation of (" 
                        & integer'image(i) 
                        & "+" 
                        & integer'image(j) 
                        & ") " 
                        & "got " 
                        & integer'image(to_integer(unsigned(r)))
                    severity error; 
                    sum_error_count:=sum_error_count+1;
                end if;
            end loop;
        end loop;
        
        report "=============================================";
        report "Test terminated";
        report "Errors: "  & integer'image(sum_error_count) & " errors"; 
        
        if (sum_error_count = 0) then
            report "Test completed successfully! :)";
        else 
            report "Test failed :(";
        end if;
        report "=============================================";
        
        wait;
    end process;
end Behavioral;

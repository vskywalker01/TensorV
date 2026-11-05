library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity or_reductor_test is
--  Port ( );
end or_reductor_test;

architecture Behavioral of or_reductor_test is
    component or_reductor is
        Generic(
            DATA_SIZE: INTEGER := 20
        );
        Port (
            data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            result:     out STD_LOGIC
        );
    end component;
    
    constant DATA_SIZE: INTEGER := 16; 
    signal data_in: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal result: STD_LOGIC;
    
begin
    reductor: or_reductor 
        Generic map (
            DATA_SIZE => DATA_SIZE
        )
        Port map (
            data_in => data_in,
            result => result
        );
        
    test: process is 
        variable error_counter: INTEGER := 0;
    begin 
        data_in <= (others => '0'); 
        wait for 10ns; 
        
        for s in 0 to (2 ** DATA_SIZE)-1 loop             
            data_in <= STD_LOGIC_VECTOR(to_unsigned(s, DATA_SIZE));
            
            wait for 5ns; 
            if ((s>0 and result='0') or (s=0 and result='1')) then 
                report "Error during bitwise or (" 
                    & integer'image(to_integer(UNSIGNED(data_in)))
                severity error; 
                error_counter := error_counter +1;
            end if;
            wait for 5ns; 

        end loop; 
        
        if (error_counter = 0) then 
            report "test completed successfully :)";
        else 
            report "Test failed. Got "
                & integer'image(error_counter) 
                & " errors :("
            severity error;
        end if;
        
        wait;

    end process;

end Behavioral;

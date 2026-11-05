library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity barrel_right_shifter_test is
--  Port ( );
end barrel_right_shifter_test;

architecture Behavioral of barrel_right_shifter_test is
    component barrel_right_shifter is
        Generic (
            DATA_SIZE: INTEGER := 32;
            SHIFT_SIZE: INTEGER := 5
        );
        Port (
            data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            shift:      in STD_LOGIC_VECTOR(SHIFT_SIZE-1 downto 0); 
            logic:      in STD_LOGIC;
            
            data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0)
        );
    end component;
    constant DATA_SIZE: INTEGER := 20; 
    constant SHIFT_SIZE: INTEGER := 5;
    
    signal data_in, data_out:   STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    signal shift:               STD_LOGIC_VECTOR(SHIFT_SIZE-1 downto 0);
    signal logic:               STD_LOGIC;
begin
    shifter: barrel_right_shifter 
        generic map (
            DATA_SIZE => DATA_SIZE,
            SHIFT_SIZE => SHIFT_SIZE
        )
        port map (
            data_in => data_in, 
            data_out => data_out, 
            shift => shift,
            logic => logic
        );

    test: process is 
        constant SHIFT_MAX: INTEGER := 2 ** SHIFT_SIZE;
        variable error_counter: INTEGER := 0;
    begin 
        data_in <= (others => '0'); 
        shift <= (others => '0'); 
        logic <= '0';
        wait for 10ns; 
        
        for s in 0 to (2 ** SHIFT_SIZE)-1 loop 
            for b in 0 to DATA_SIZE-1 loop
                data_in <= (DATA_SIZE-1 downto b => '1', others => '0');
                shift <= STD_LOGIC_VECTOR(to_unsigned(s, SHIFT_SIZE));
                
                wait for 5ns; 
                if not(SIGNED(data_out) = shift_right(SIGNED(data_in),s)) then 
                    report "Error during estimation of arithmetic right shift" 
                        & integer'image(to_integer(UNSIGNED(data_in))) 
                        & " of "
                        & integer'image(s) 
                        & "got " 
                        & integer'image(to_integer(UNSIGNED(data_out)))
                    severity error; 
                    error_counter := error_counter +1;
                end if;
                wait for 5ns; 
            end loop; 
        end loop; 
        
        logic <= '1';
        wait for 10ns;
        for s in 0 to (2 ** SHIFT_SIZE)-1 loop 
            for b in 0 to DATA_SIZE-1 loop
                data_in <= (DATA_SIZE-1 downto b => '1', others => '0');
                shift <= STD_LOGIC_VECTOR(to_unsigned(s, SHIFT_SIZE));
                
                wait for 5ns; 
                if not(UNSIGNED(data_out) = shift_right(UNSIGNED(data_in),s)) then 
                    report "Error during estimation of logic right shift" 
                        & integer'image(to_integer(UNSIGNED(data_in))) 
                        & " of "
                        & integer'image(s) 
                        & "got " 
                        & integer'image(to_integer(UNSIGNED(data_out)))
                    severity error; 
                    error_counter := error_counter +1;
                end if;
                wait for 5ns; 
            end loop; 
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

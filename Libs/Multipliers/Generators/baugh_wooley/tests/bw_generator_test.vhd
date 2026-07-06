-- Testbench of the bw_generator.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.GENERATORS.ALL; 

entity bw_generator_test is
--  Port ( );
end bw_generator_test;

architecture Behavioral of bw_generator_test is
    constant DATA_SIZE: INTEGER := 8;
    
    signal a: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal b: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal partials_out: PARTIALS(DATA_SIZE-1 downto 0, DATA_SIZE downto 0);
begin
    generator: bw_generator 
        generic map (
            DATA_SIZE => DATA_SIZE
        )
        port map (
            data_a => a,
            data_b => b,
            partials_out => partials_out
        );
    test: process
    begin

        -- Setting two random variables to verify the mapping of the generator
        a <= "11111111";
        b <= "01011010";
        wait for 10ns;        
    end process; 


end Behavioral;

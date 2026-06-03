library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MATRIX_REDUCTION_PARAMETERS.ALL;


entity partials_generator_test is
--  Port ( );
end partials_generator_test;

architecture Behavioral of partials_generator_test is
    component partials_generator is
      Port (
        data_a: in STD_LOGIC_VECTOR(7 downto 0);
        data_b: in STD_LOGIC_VECTOR(7 downto 0);
    
        matrix_out: out MATRIX(0 to 7)
      );
    end component;
    signal a: STD_LOGIC_VECTOR(7 downto 0);
    signal b: STD_LOGIC_VECTOR(7 downto 0);
    signal matrix_out: MATRIX(0 to 7);
begin
    generator: partials_generator 
        port map (
            data_a => a,
            data_b => b,
            matrix_out => matrix_out
        );
    test: process
    begin 
        a <= "11111111";
        b <= "01011010";
        wait for 10ns;        
    end process; 


end Behavioral;

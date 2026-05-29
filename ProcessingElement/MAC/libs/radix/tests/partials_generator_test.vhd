library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MULTIPLIER_PARAMETERS.ALL;


entity partials_generator_test is
--  Port ( );
end partials_generator_test;

architecture Behavioral of partials_generator_test is
    component partials_generator is
      Port (
        data_a: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        data_b: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        
        partials_out: out PARTIALS_ARRAY(0 to PARTIALS_TO_REDUCE-1)
      );
    end component;
    signal a: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal b: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal partials: PARTIALS_ARRAY(0 to PARTIALS_TO_REDUCE-1);
begin
    generator: partials_generator 
        port map (
            data_a => a,
            data_b => b,
            partials_out => partials
        );
    test: process
    begin 
        a <= "11111111";
        b <= "01011010";
        wait for 10ns;
        assert(STD_LOGIC_VECTOR(partials(0))="00111100000000010") report "partial 1 not valid";
        assert(STD_LOGIC_VECTOR(partials(1))="UU0011110000001UU") report "partial 2 not valid";
        assert(STD_LOGIC_VECTOR(partials(2))="UUUU001111110UUUU") report "partial 3 not valid";
        assert(STD_LOGIC_VECTOR(partials(3))="UUUUUU00111UUUUUU") report "partial 4 not valid";
        assert(STD_LOGIC_VECTOR(partials(4))="UUUUUUUU0UUUUUUUU") report "partial 5 not valid";
        
    end process; 


end Behavioral;

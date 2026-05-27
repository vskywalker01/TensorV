library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.PARTIAL_TYPES.ALL;


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
        b <= "00000011";
        wait for 10ns;
    end process; 


end Behavioral;

-- Implementation of booth radix-4 partial generator for hardware multiplication 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.PARTIAL_TYPES.ALL;

entity radix4_generator is
  Port (
    data_a: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    window: in STD_LOGIC_VECTOR(1 downto 0);
    
    data_out: out STD_LOGIC_VECTOR(DATA_SIZE downto 0)
  );
end radix4_generator;

architecture Behavioral of radix4_generator is
    signal a: signed(DATA_SIZE-1 downto 0);
    signal ma: signed(DATA_SIZE-1 downto 0);

begin
    a <= signed(data_a);
    ma <= - signed(data_a);
    data_out <= std_logic_vector(a) when window="001" or window="010" else
                std_logic_vector(a sll 1) when window="011" else 
                std_logic_vector(ma sll 1) when window="100" else
                std_logic_vector(ma) when window="101" or window="110" else  
                (others => '0');
end Behavioral;

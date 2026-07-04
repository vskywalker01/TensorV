-- baugh-wooley partial generator based on hantamian's organization

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.GENERATORS.ALL;

entity bw_generator is
    Generic ( 
        DATA_SIZE: INTEGER := 8
    );
    Port (
        data_a: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        data_b: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);

        partials_out: out PARTIALS(DATA_SIZE-1 downto 0,DATA_SIZE downto 0)
    );
end bw_generator;

architecture Behavioral of bw_generator is
    signal partial_b1: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    signal partial_b0: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    

begin
    partial_b1(DATA_SIZE-2 downto 0) <= data_a(DATA_SIZE-2 downto 0);
    partial_b0(DATA_SIZE-2 downto 0) <= (others => '0');
    partial_b1(7) <= not(data_a(7));
    partial_b0(7) <= '1';
    
    row: for p in 0 to (DATA_SIZE-1) generate
        col: for c in 0 to (DATA_SIZE) generate             
        begin
            last_bit: if (c=DATA_SIZE) generate 
                partials_out(p,c) <= '1' when (p = 0) else '0';
            end generate;
            
            first_bits: if (c<DATA_SIZE) generate
                partials_out(p,c) <= 
                    partial_b1(c)       when (data_b(p)='1' and p < (DATA_SIZE-1)) else 
                    not(partial_b1(c))  when (data_b(p)='1' and p = (DATA_SIZE-1)) else 
                    partial_b0(c)       when (data_b(p)='0' and p < (DATA_SIZE-1)) else 
                    not(partial_b0(c));
            end generate;
        end generate; 
    end generate;  
end Behavioral;

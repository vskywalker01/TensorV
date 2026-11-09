library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL; 

entity or_reductor is
    Generic(
        DATA_SIZE: INTEGER := 20
    );
    Port (
        data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        result:     out STD_LOGIC
    );
end or_reductor;

architecture Behavioral of or_reductor is
    constant LEVELS_NUMBER:     INTEGER := INTEGER(ceil(log2(REAL(DATA_SIZE))));
    
    type OR_LEVELS is array (LEVELS_NUMBER downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal levels: OR_LEVELS; 

begin

    levels(0) <= data_in;

    or_level: for l in 0 to LEVELS_NUMBER-1 generate 
        constant DEPTH: INTEGER := 2 ** l;
        constant STEP: INTEGER := 2 ** (l+1); 
    begin
        level_bit: for b in 0 to DATA_SIZE-1 generate 
            or_port: if (b mod STEP = 0) generate
                constant BIT1: INTEGER := b; 
                constant BIT2: INTEGER := b+DEPTH;
            begin             
                valid_bit: if BIT2 < DATA_SIZE generate
                begin
                    levels(l+1)(b) <= levels(l)(BIT1) or levels(l)(BIT2);
                end generate;
    
                invalid_bit: if BIT2 >= DATA_SIZE generate
                begin
                    levels(l+1)(b) <= levels(l)(BIT1);
                end generate;
            end generate;        
        end generate;
    end generate; 
    
    result <= levels(LEVELS_NUMBER)(0);
    
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.REDUCTORS.ALL;

entity adder_reductor_test is
--  Port ( );
end adder_reductor_test;

architecture Behavioral of adder_reductor_test is
    constant MATRIX_ROWS_IN:         INTEGER := 8;
    constant MATRIX_ROWS_OUT:        INTEGER := 6;
    constant MATRIX_HEIGHT:          INTEGER := 8;
    constant MATRIX_PARTIAL_SIZE:    INTEGER := 9;
    constant MATRIX_STEP_LENGTH:     INTEGER := 1;
    constant MATRIX_WIDTH:           INTEGER := get_matrix_width(MATRIX_PARTIAL_SIZE,MATRIX_HEIGHT);
      
    signal input: MATRIX(MATRIX_HEIGHT-1 downto 0, MATRIX_WIDTH-1 downto 0);
    signal output: MATRIX(MATRIX_HEIGHT-1 downto 0,MATRIX_WIDTH-1 downto 0); 
    signal clk: std_logic;
begin
    reductor: adder_reductor 
        generic map (
            MATRIX_ROWS_IN => MATRIX_ROWS_IN,
            MATRIX_ROWS_OUT => MATRIX_ROWS_OUT, 
            MATRIX_HEIGHT => MATRIX_HEIGHT,
            MATRIX_PARTIAL_SIZE =>  MATRIX_PARTIAL_SIZE,
            MATRIX_STEP_LENGTH => MATRIX_STEP_LENGTH,
            MATRIX_WIDTH => MATRIX_WIDTH
        ) 
        port map (
            input => input,
            output => output
        );
    test: process
    begin 
        for r in 0 to (MATRIX_ROWS_IN-1) loop
            for c in 0 to (MATRIX_WIDTH-1) loop
                input(r,c) <= '0';
            end loop;
        end loop;
        wait for 10ns;
        for r in 0 to (MATRIX_ROWS_IN-1) loop
            for c in 0 to (MATRIX_WIDTH-1) loop
                input(r,c) <= '1';
            end loop;
        end loop;
        wait for 10ns;
    end process; 

end Behavioral;

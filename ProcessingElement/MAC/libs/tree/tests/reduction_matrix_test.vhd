library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MATRIX_REDUCTION_PARAMETERS.ALL;

entity reduction_matrix_test is

--  Port ( );
end reduction_matrix_test;

architecture Behavioral of reduction_matrix_test is
    constant IN_DIM: INTEGER := 8;
    constant OUT_DIM: INTEGER := 6;
        
    component reduction_matrix is
        Generic (
            MATRIX_ROWS_IN: INTEGER;
            MATRIX_ROWS_OUT: INTEGER
        );
        Port ( 
            input: in MATRIX(0 to MATRIX_ROWS_IN-1);
            output: out MATRIX(0 to MATRIX_ROWS_OUT-1)
        );
    end component;
    
    signal input: MATRIX(0 to IN_DIM-1);
    signal output: MATRIX(0 to OUT_DIM-1); 
    signal clk: std_logic;
begin
    matrix: reduction_matrix 
        generic map (
            MATRIX_ROWS_IN => IN_DIM,
            MATRIX_ROWS_OUT => OUT_DIM
        ) 
        port map (
            input => input,
            output => output
        );
    test: process
    begin 
        for r in 0 to (IN_DIM-1) loop
            input(r) <= "0000000000000000";
        end loop;
        wait for 10ns;
        for r in 0 to (IN_DIM-1) loop
            input(r) <= "1111111111111111";
        end loop;
        wait for 10ns;
    end process; 

end Behavioral;

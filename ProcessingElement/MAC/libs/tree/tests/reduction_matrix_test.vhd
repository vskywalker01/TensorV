library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MULTIPLIER_PARAMETERS.ALL;

entity reduction_matrix_test is

--  Port ( );
end reduction_matrix_test;

architecture Behavioral of reduction_matrix_test is
    constant IN_DIM: INTEGER := 5;
    constant OUT_DIM: INTEGER := 4;
        
    component reduction_matrix is
        Generic (
            PARTIALS_IN: INTEGER;
            PARTIALS_OUT: INTEGER
        );
        Port ( 
            input: in PARTIALS_ARRAY(0 to PARTIALS_IN-1);
            output: out PARTIALS_ARRAY(0 to PARTIALS_OUT-1)
        );
    end component;
    
    signal input: PARTIALS_ARRAY(0 to IN_DIM-1);
    signal output: PARTIALS_ARRAY(0 to OUT_DIM-1); 
    signal clk: std_logic;
begin
    matrix: reduction_matrix 
        generic map (
            PARTIALS_IN => IN_DIM,
            PARTIALS_OUT => OUT_DIM
        ) 
        port map (
            input => input,
            output => output
        );
    test: process
    begin 
        for r in 0 to (IN_DIM-1) loop
            input(r) <= "00000000000000000";
        end loop;
        wait for 10ns;
        for r in 0 to (IN_DIM-1) loop
            input(r) <= "11111111111111111";
        end loop;
        wait for 10ns;
    end process; 

end Behavioral;

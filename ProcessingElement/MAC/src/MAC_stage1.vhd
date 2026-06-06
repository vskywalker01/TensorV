
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MATRIX_REDUCTION_PARAMETERS.ALL;

entity MAC_stage1 is
    Generic (
        ACC_SIZE: INTEGER := 32
    );
    Port ( 
        clk: in STD_LOGIC; 
        reset: in STD_LOGIC; 
    
        data_a:         in STD_LOGIC_VECTOR(7 downto 0);
        data_b:         in STD_LOGIC_VECTOR(7 downto 0); 
        data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
        
        matrix_out:     out MATRIX(0 to 1);
        data_acc_out:   out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
    );
end MAC_stage1;

architecture Behavioral of MAC_stage1 is 
    component partials_generator is
        Port (
            data_a: in STD_LOGIC_VECTOR(7 downto 0);
            data_b: in STD_LOGIC_VECTOR(7 downto 0);
        
            matrix_out: out MATRIX(0 to 7)
        );
    end component;
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
    signal matrix_r0: MATRIX(0 to 7);
    signal matrix_r1: MATRIX(0 to 5);
    signal matrix_r2: MATRIX(0 to 3);
    signal matrix_r3: MATRIX(0 to 2);
    signal matrix_r4: MATRIX(0 to 1);

begin 
    generator: partials_generator
        port map(
            data_a => data_a,
            data_b => data_b,
            
            matrix_out => matrix_r0
        );
    matrix_86: reduction_matrix
        generic map(
            MATRIX_ROWS_IN => 8,
            MATRIX_ROWS_OUT => 6
        )
        port map (
            input => matrix_r0,
            output => matrix_r1
        );
    matrix_64: reduction_matrix
        generic map(
            MATRIX_ROWS_IN => 6,
            MATRIX_ROWS_OUT => 4
        )
        port map (
            input => matrix_r1,
            output => matrix_r2
        );
    matrix_43: reduction_matrix
        generic map(
            MATRIX_ROWS_IN => 4,
            MATRIX_ROWS_OUT => 3
        )
        port map (
            input => matrix_r2,
            output => matrix_r3
        );
    matrix_32: reduction_matrix
        generic map(
            MATRIX_ROWS_IN => 3,
            MATRIX_ROWS_OUT => 2
        )
        port map (
            input => matrix_r3,
            output => matrix_r4
        );
        
    pipeline_latch: process(clk) 
        variable TREE_HEIGHT: integer;
    begin 
        if (rising_edge(clk)) then
            if (reset='1') then 
                data_acc_out <= (others => '0');
            else 
                data_acc_out <= data_acc_in; 
            end if;
        
            for c in 0 to MATRIX_OUTPUT_SIZE-1 loop 
                TREE_HEIGHT:= get_matrix_column_height(c,2); 
                
                for r in 0 to TREE_HEIGHT-1 loop
                    if (reset = '1') then 
                        matrix_out(r)(c) <= '0'; 
                    else 
                        matrix_out(r)(c) <= matrix_r4(r)(c); 
                    end if;
                end loop;
            end loop;
        end if; 
    end process;     
end architecture;

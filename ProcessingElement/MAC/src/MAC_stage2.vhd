
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MULTIPLIER_PARAMETERS.ALL;

entity MAC_stage2 is
    Port ( 
        clk:            in STD_LOGIC; 
        reset:          in STD_LOGIC; 
    
        p_in:           in PARTIALS_ARRAY(0 to 3);
        data_acc_in:    in STD_LOGIC_VECTOR(7 downto 0); 
        
        p_out:          out PARTIALS_ARRAY(0 to 1);
        data_acc_out:   out STD_LOGIC_VECTOR(7 downto 0)
    );
end MAC_stage2;

architecture Behavioral of MAC_stage2 is 
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
    
    signal partials_r2: PARTIALS_ARRAY(0 to 3);
    signal partials_r3: PARTIALS_ARRAY(0 to 1);
    
begin 

    matrix_43: reduction_matrix
        generic map(
            PARTIALS_IN => 4,
            PARTIALS_OUT => 3
        )
        port map (
            input => p_in,
            output => partials_r2
        );
    matrix_32: reduction_matrix
        generic map(
            PARTIALS_IN => 4,
            PARTIALS_OUT => 3
        )
        port map (
            input => partials_r2,
            output => partials_r3
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
        
            for c in 0 to PARTIAL_SIZE-1 loop 
                TREE_HEIGHT:= get_tree_column_height(c,4); 
                
                for r in 0 to TREE_HEIGHT-1 loop
                    if (reset = '1') then 
                        p_out(r)(c) <= '0'; 
                    else 
                        p_out(r)(c) <= partials_r3(r)(c); 
                    end if;
                end loop;
            end loop;
        end if; 
    end process;     
end architecture;
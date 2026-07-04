
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.REDUCTORS.ALL;
use work.GENERATORS.ALL;

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
        
        matrix_out1:    out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
        matrix_out2:    out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
        data_acc_out:   out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
    );
end MAC_stage1;

architecture Behavioral of MAC_stage1 is     
    signal partials: PARTIALS(7 downto 0,8 downto 0);

    signal matrix_r0: MATRIX(7 downto 0,15 downto 0);
    signal matrix_r1: MATRIX(7 downto 0,15 downto 0);
    signal matrix_r2: MATRIX(7 downto 0,15 downto 0);
    signal matrix_r3: MATRIX(7 downto 0,15 downto 0);
    signal matrix_r4: MATRIX(7 downto 0,15 downto 0);

begin 
    generator: bw_generator
        port map(
            data_a => data_a,
            data_b => data_b,
            
            partials_out => partials
        );
        
    partials_routing: for p in 0 to 7 generate
        col: for c in 0 to 8 generate 
            constant SHIFT_LENGTH: INTEGER := 1; 
            constant SHIFT: INTEGER := p*SHIFT_LENGTH;  
            constant COL_POS: INTEGER := c + SHIFT;
            constant ROW_POS: INTEGER := p when (COL_POS<9) else (p-COL_POS+8);
        begin 
            matrix_r0(ROW_POS,COL_POS) <= partials(p,c);
        end generate; 
    end generate;  

    matrix_86: adder_reductor
        generic map(
            MATRIX_ROWS_IN => 8,
            MATRIX_ROWS_OUT => 6, 
            MATRIX_HEIGHT => 8,
            MATRIX_PARTIAL_SIZE => 9,
            MATRIX_STEP_LENGTH => 1,
            MATRIX_WIDTH => 16
        )
        port map (
            input => matrix_r0,
            output => matrix_r1
        );
    matrix_64: adder_reductor
        generic map(
            MATRIX_ROWS_IN => 6,
            MATRIX_ROWS_OUT => 4, 
            MATRIX_HEIGHT => 8,
            MATRIX_PARTIAL_SIZE => 9,
            MATRIX_STEP_LENGTH => 1,
            MATRIX_WIDTH => 16
        )
        port map (
            input => matrix_r1,
            output => matrix_r2
        );
    matrix_43: adder_reductor
        generic map(
            MATRIX_ROWS_IN => 4,
            MATRIX_ROWS_OUT => 3, 
            MATRIX_HEIGHT => 8,
            MATRIX_PARTIAL_SIZE => 9,
            MATRIX_STEP_LENGTH => 1,
            MATRIX_WIDTH => 16
        )
        port map (
            input => matrix_r2,
            output => matrix_r3
        );
    matrix_32: adder_reductor
        generic map(
            MATRIX_ROWS_IN => 3,
            MATRIX_ROWS_OUT => 2, 
            MATRIX_HEIGHT => 8,
            MATRIX_PARTIAL_SIZE => 9,
            MATRIX_STEP_LENGTH => 1,
            MATRIX_WIDTH => 16
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
            
            if (reset = '1') then 
                matrix_out1(0) <= '0'; 
                for c in 1 to (ACC_SIZE-1) loop
                    matrix_out1(c) <= '0'; 
                    matrix_out2(c) <= '0'; 
                end loop; 
            else
                matrix_out1(0) <= matrix_r4(0,0); 
                for c in 1 to 15 loop
                    matrix_out1(c) <= matrix_r4(0,c);
                    matrix_out2(c) <= matrix_r4(1,c);
                end loop; 
                 
                for c in 15 to (ACC_SIZE-1) loop 
                    matrix_out1(c) <= matrix_r4(0,15);
                    matrix_out2(c) <= not(matrix_r4(1,15));
                end loop;
            end if; 
            
          
        end if; 
    end process;     
end architecture;

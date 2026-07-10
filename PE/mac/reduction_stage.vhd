-- Definition of MAC reduction stage. 

-- This stage performs a multiplication and reduction between the two 8-bit inputs into two rows ready to be summed by the second stage. 
-- At the same time, it propagates the values of the accumulator input to the next stage to maintain coherenc eof the pipeline.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.REDUCTORS.ALL;
use work.GENERATORS.ALL;

entity reduction_stage is
    Generic (
        ACC_SIZE: INTEGER := 32
    );
    Port ( 
        clk: in STD_LOGIC; 
        reset: in STD_LOGIC; 
    
        data_a:                 in STD_LOGIC_VECTOR(7 downto 0);
        data_b:                 in STD_LOGIC_VECTOR(7 downto 0);  
        valid_in:               in STD_LOGIC; 

        matrix_out1:            out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
        matrix_out2:            out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
        valid_out:              out STD_LOGIC

    );
end reduction_stage;

architecture Behavioral of reduction_stage is     
    constant DATA_SIZE: INTEGER := 8;
    
    -- Choosing Baugh-Wooley generator for the partials 
    constant MATRIX_PARTIAL_SIZE: INTEGER := get_bw_partial_size(DATA_SIZE);
    constant MATRIX_PARTIAL_SHIFT: INTEGER := get_bw_partial_shift;
    constant MATRIX_HEIGHT: INTEGER := get_bw_partials_to_reduce(DATA_SIZE);
    constant MATRIX_WIDTH: INTEGER := get_matrix_width(MATRIX_PARTIAL_SIZE, MATRIX_HEIGHT, MATRIX_PARTIAL_SHIFT);
    
    signal partials: PARTIALS(MATRIX_HEIGHT-1 downto 0,MATRIX_PARTIAL_SIZE-1 downto 0);
    
    -- Performing 5 reduction steps: 8->6->4->3->2
    signal matrix_r0: MATRIX(MATRIX_HEIGHT-1 downto 0,MATRIX_WIDTH-1 downto 0);
    signal matrix_r1: MATRIX(MATRIX_HEIGHT-1 downto 0,MATRIX_WIDTH-1 downto 0);
    signal matrix_r2: MATRIX(MATRIX_HEIGHT-1 downto 0,MATRIX_WIDTH-1 downto 0);
    signal matrix_r3: MATRIX(MATRIX_HEIGHT-1 downto 0,MATRIX_WIDTH-1 downto 0);
    signal matrix_r4: MATRIX(MATRIX_HEIGHT-1 downto 0,MATRIX_WIDTH-1 downto 0);

begin 
    
    -- Assigning the generator component 
    generator: bw_generator
        port map(
            data_a => data_a,
            data_b => data_b,
            
            partials_out => partials
        );
    
    -- Performing routing from the PARTIAL type to the MATRIX type (applying shifting to the partials)
    partials_routing: for p in 0 to 7 generate
        col: for c in 0 to 8 generate 
            constant SHIFT: INTEGER := p*MATRIX_PARTIAL_SHIFT;  
            constant COL_POS: INTEGER := c + SHIFT;
            constant ROW_POS: INTEGER := p when (COL_POS<MATRIX_PARTIAL_SIZE) else (p-COL_POS+(MATRIX_PARTIAL_SIZE-1));
        begin 
            matrix_r0(ROW_POS,COL_POS) <= partials(p,c);
        end generate; 
    end generate;  

    -- Placing layer reductions
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
        
    -- Main pipeline process
    pipeline_latch: process(clk) 
    begin 
        if (rising_edge(clk)) then
        
            -- If reset=1 -> force outputs to '0's
            
            if (reset = '1') then 
                for c in 0 to (ACC_SIZE-1) loop
                    matrix_out1(c) <= '0'; 
                    matrix_out2(c) <= '0'; 
                end loop; 
                valid_out <= '0';
            else
                if (valid_in = '1') then
                    -- the two rows obtained by the reduction are enlarget to match the size of the accumulator 
                    
                    -- Because the sum between the two rows will result in the last bit inverted (BW generator), the last bits of the second row are inverted in order to avoid 
                    -- an adjustment in the pipeline second stage
                    matrix_out1(0) <= matrix_r4(0,0); 
                    matrix_out2(0) <= '0';
                    
                    for c in 1 to 15 loop
                        matrix_out1(c) <= matrix_r4(0,c);
                        matrix_out2(c) <= matrix_r4(1,c);
                    end loop; 
                     
                    for c in 15 to (ACC_SIZE-1) loop 
                        matrix_out1(c) <= matrix_r4(0,15);
                        matrix_out2(c) <= not(matrix_r4(1,15));
                    end loop;
                end if; 
                valid_out <= valid_in;
                
            end if; 
            
          
        end if; 
    end process;     
end architecture;

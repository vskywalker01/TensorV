library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_MATRIX_PARAMETERS.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PE_matrix_test is
--  Port ( );
end PE_matrix_test;

architecture Behavioral of PE_matrix_test is
    component PE_matrix is 
        Port ( 
            clk:                    in STD_LOGIC;  
            reset:                  in STD_LOGIC;                 
            
            weights_in:                 in MATRIX_WEIGHTS_INTERFACE; 
            rows_in:                    in MATRIX_ROWS_INTERFACE; 
            accumulators_in:            in MATRIX_ACCUMULATORS_INTERFACE; 
            accumulators_out:           out MATRIX_ACCUMULATORS_INTERFACE;
            
            weights_init_in:            in MATRIX_WEIGHTS_CONTROL_INTERFACE;
            weights_valid_in:           in MATRIX_WEIGHTS_CONTROL_INTERFACE; 
            
            rows_init_in:               in MATRIX_ROWS_CONTROL_INTERFACE; 
            rows_valid_in:              in MATRIX_ROWS_CONTROL_INTERFACE; 
            
            accumulators_init_in:       in MATRIX_ACCUMULATORS_CONTROL_INTERFACE; 
            accumulators_valid_in:      in MATRIX_ACCUMULATORS_CONTROL_INTERFACE; 
            accumulators_valid_out:     out MATRIX_ACCUMULATORS_CONTROL_INTERFACE; 
            
            enables_in:                 in MATRIX_ACCUMULATORS_CONTROL_INTERFACE
    
        );
    end component;
    
    signal clk, reset: STD_LOGIC;
    signal weights_in:                 MATRIX_WEIGHTS_INTERFACE; 
    signal rows_in:                    MATRIX_ROWS_INTERFACE; 
    signal accumulators_in:            MATRIX_ACCUMULATORS_INTERFACE; 
    signal accumulators_out:           MATRIX_ACCUMULATORS_INTERFACE;
            
    signal weights_init_in:            MATRIX_WEIGHTS_CONTROL_INTERFACE;
    signal weights_valid_in:           MATRIX_WEIGHTS_CONTROL_INTERFACE; 
            
    signal rows_init_in:               MATRIX_ROWS_CONTROL_INTERFACE; 
    signal rows_valid_in:              MATRIX_ROWS_CONTROL_INTERFACE; 
            
    signal accumulators_init_in:       MATRIX_ACCUMULATORS_CONTROL_INTERFACE; 
    signal accumulators_valid_in:      MATRIX_ACCUMULATORS_CONTROL_INTERFACE; 
    signal accumulators_valid_out:     MATRIX_ACCUMULATORS_CONTROL_INTERFACE; 
            
    signal enables_in:                 MATRIX_ACCUMULATORS_CONTROL_INTERFACE;
    
begin
    
    matrix: PE_matrix 
        port map (
            clk => clk,  
            reset => reset,               
            
            weights_in => weights_in,
            rows_in => rows_in,
            accumulators_in => accumulators_in,
            accumulators_out => accumulators_out,
            
            weights_init_in => weights_init_in,
            weights_valid_in => weights_valid_in, 
            
            rows_init_in => rows_init_in, 
            rows_valid_in => rows_valid_in, 
            
            accumulators_init_in => accumulators_init_in, 
            accumulators_valid_in => accumulators_valid_in, 
            accumulators_valid_out => accumulators_valid_out, 
            
            enables_in => enables_in 
        );

    clock: process 
    begin 
        loop 
            clk <= '1';
            wait for 5ns; 
            clk <= '0'; 
            wait for 5ns;
        end loop; 
    end process; 
    
    test: process 
        type SAMPLE_MATRIX is array (natural range <>,natural range <>) of INTEGER; 
        constant TEST_MATRIX: SAMPLE_MATRIX(0 to 4, 0 to 4) := (
            ( 20, -10,   5,  12,  -7),
            (  3,   8, -15,   6,  11),
            ( -4,   9,  13,  -2,  10),
            (  7,  -6,   4,  14, -12),
            (  5,   3,  -8,   6,   9)
        );
        constant TEST_WEIGHT: SAMPLE_MATRIX(0 to 2, 0 to 2) := (
            ( 12,  -5,   7),
            ( -3,   9, -11),
            (  4,   6,  -8)
        );
        constant SAMPLE_RESULTS: SAMPLE_MATRIX(0 to 2, 0 to 2) := (
            ( 487, -156,  -41),
            ( -23,   53,  124),
            ( -72,  102,   35)
        );
        constant TEST_MATRIX_SIZE: INTEGER := 5;
        constant TEST_WEIGHT_SIZE: INTEGER := 3;
        constant accumulators: INTEGER := 0;

    begin 
        reset <= '1'; 
        wait until falling_edge(clk);
        
        reset <= '0'; 
        
        wait until falling_edge(clk);
        
        for i in 0 to DEPTH-1 loop 
            weights_in(i) <= (others => '0');
            accumulators_in(i) <= STD_LOGIC_VECTOR(TO_UNSIGNED(accumulators,ACCUMULATOR_SIZE));
            accumulators_init_in(i) <= '1'; 
            weights_init_in(i) <= '1';
            accumulators_valid_in(i) <= '0';
            weights_valid_in(i) <= '0';
            enables_in(i) <= '0';
        end loop; 
        
        for i in 0 to (DEPTH*2)-2 loop 
            rows_in(i) <= (others => '0');
            rows_init_in(i) <= '1';
            rows_valid_in(i) <= '0';
        end loop; 
        
        wait until falling_edge(clk); 

        for i in 0 to (TEST_WEIGHT_SIZE-1) loop 
            for e in 0 to DEPTH-1 loop 
                weights_in(e) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(e mod TEST_WEIGHT_SIZE,i),DATA_SIZE));
                accumulators_init_in(e) <= '0'; 
                weights_init_in(e) <= '0';
                accumulators_valid_in(e) <= '0';
                weights_valid_in(e) <= '1';
                enables_in(e) <= '0';
            end loop; 

            for e in 0 to (TEST_MATRIX_SIZE-1) loop 
                rows_in(e) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(e,i),DATA_SIZE));
                rows_init_in(e) <= '0';
                rows_valid_in(e) <= '1';
            end loop;
            wait until falling_edge(clk);   
        end loop; 
        

        
        for r in 0 to TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE loop 
            if (r<TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE) then 
                for e in 0 to DEPTH-1 loop 
                    accumulators_init_in(e) <= '0'; 
                    weights_init_in(e) <= '0';
                    accumulators_valid_in(e) <= '0';
                    weights_valid_in(e) <= '0';
                    enables_in(e) <= '1';
                end loop; 
                
                for e in 0 to (TEST_MATRIX_SIZE-1) loop 
                    rows_in(r) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(e,TEST_WEIGHT_SIZE+r),DATA_SIZE));
                    rows_init_in(e) <= '0';
                    rows_valid_in(e) <= '1';
                end loop;
            else 
                for e in 0 to DEPTH-1 loop 
                    accumulators_init_in(e) <= '0'; 
                    weights_init_in(e) <= '0';
                    accumulators_valid_in(e) <= '0';
                    weights_valid_in(e) <= '0';
                    enables_in(e) <= '1';
                end loop; 
                for e in 0 to (TEST_MATRIX_SIZE-1) loop 
                    rows_init_in(e) <= '0';
                    rows_valid_in(e) <= '0';
                end loop;
            end if;
            
            wait until falling_edge(clk);
            
            for e in 0 to DEPTH-1 loop 
                accumulators_init_in(e) <= '0'; 
                weights_init_in(e) <= '0';
                accumulators_valid_in(e) <= '0';
                weights_valid_in(e) <= '0';
                enables_in(e) <= '1';
            end loop; 
            for e in 0 to (TEST_MATRIX_SIZE-1) loop 
                rows_init_in(e) <= '0';
                rows_valid_in(e) <= '0';
            end loop;
            
            for i in 0 to TEST_WEIGHT_SIZE-2 loop
                wait until falling_edge(clk);
            end loop;
            
            for e in 0 to DEPTH-1 loop 
                accumulators_init_in(e) <= '1'; 
                weights_init_in(e) <= '0';
                accumulators_valid_in(e) <= '1';
                weights_valid_in(e) <= '0';
                enables_in(e) <= '1';
            end loop; 
            for e in 0 to (TEST_MATRIX_SIZE-1) loop 
                rows_init_in(e) <= '0';
                rows_valid_in(e) <= '0';
            end loop;
           
            wait until falling_edge(clk);
            
        end loop;
        
        for e in 0 to DEPTH-1 loop 
            accumulators_init_in(e) <= '0'; 
            weights_init_in(e) <= '0';
            accumulators_valid_in(e) <= '0';
            weights_valid_in(e) <= '0';
            enables_in(e) <= '0';
        end loop; 
        for e in 0 to (TEST_MATRIX_SIZE-1) loop 
            rows_init_in(e) <= '0';
            rows_valid_in(e) <= '0';
        end loop;
        
        wait;
           
    end process; 

end Behavioral;

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
            ( 487, -156,  -111),
            ( -199, 213,  -104),
            ( -19,  -155,   414)
        );
        constant TEST_MATRIX_SIZE: INTEGER := 5;
        constant TEST_WEIGHT_SIZE: INTEGER := 3;
        constant accumulators: INTEGER := 0;

    begin 
    
        reset <= '1'; 
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        reset <= '0'; 
        
        -- reset phase 
        for l in 0 to (ACTIVATION_LINES-1) loop
            rows_init_in(l) <= '1';
            rows_valid_in(l) <= '0';
            weights_init_in(l) <= '1';
            weights_valid_in(l) <= '0';
            accumulators_init_in(l) <= '1';
            accumulators_valid_in(l) <= '0';
            enables_in(l) <= '0';
        
            rows_in(l) <= (others => '0');
            
            if (l<WEIGHT_LINES) then 
                weights_in(l) <= (others => '0');
            end if;
            
            if (l<ACCUMULATION_LINES) then 
                accumulators_in(l) <= STD_LOGIC_VECTOR(TO_UNSIGNED(accumulators,ACCUMULATOR_SIZE));
            end if; 
        end loop; 
        
        wait until falling_edge(clk); 

        --loading phase 
        for e in 0 to (TEST_WEIGHT_SIZE-1) loop 
            for l in 0 to (ACTIVATION_LINES-1) loop
                if (l<TEST_MATRIX_SIZE) then 
                    rows_valid_in(l) <= '1';
                    rows_in(l) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(l,e),DATA_SIZE));
                else 
                    rows_valid_in(l) <= '0';
                end if; 
                if (l<TEST_WEIGHT_SIZE and l<WEIGHT_LINES) then 
                    weights_valid_in(l) <= '1';
                    weights_in(l) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(l,e),DATA_SIZE));
                else 
                    weights_valid_in(l) <= '0';
                end if;
                if (l<ACCUMULATION_LINES) then 
                    accumulators_in(l) <= STD_LOGIC_VECTOR(TO_UNSIGNED(accumulators,ACCUMULATOR_SIZE));
                end if; 
                
                rows_init_in(l) <= '0';
                weights_init_in(l) <= '0';
                accumulators_init_in(l) <= '0';
            end loop; 
            
            wait until falling_edge(clk);
        end loop;  
        
        for c in 0 to (WEIGHT_LINES-1) loop 
            weights_valid_in(c) <= '0';
        end loop;

        --computing phase 
        for round in 0 to ((TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE)*2) loop 
            for l in 0 to (ACTIVATION_LINES-1) loop
                if ((round-l) >= 0 and (round-l)<(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE) and l<TEST_WEIGHT_SIZE) then 
                    rows_valid_in(l) <= '1';
                    rows_in(l) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(l,TEST_WEIGHT_SIZE+round-l),DATA_SIZE));
                    enables_in(l) <= '1';
                else 
                    rows_valid_in(l) <= '0';
                end if; 
                if (l<ACCUMULATION_LINES) then 
                    accumulators_in(l) <= STD_LOGIC_VECTOR(TO_UNSIGNED(accumulators,ACCUMULATOR_SIZE));
                end if; 
                
                accumulators_init_in(l) <= '0';
                accumulators_valid_in(l) <= '0';
            end loop; 
                 
            wait until falling_edge(clk);
            
            for l in 0 to (ACTIVATION_LINES-1) loop 
                rows_valid_in(l) <= '0';
            end loop;  
            
            for i in 0 to TEST_WEIGHT_SIZE-2 loop
                wait until falling_edge(clk);
            end loop;
            
            for l in 0 to (ACTIVATION_LINES-1) loop
                if ((round-l) >= 0 and (round-l)<=(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE) and l<TEST_WEIGHT_SIZE) then 
                    accumulators_init_in(l) <= '1';
                    accumulators_valid_in(l) <= '1';
                else 
                    accumulators_init_in(l) <= '0';
                    accumulators_valid_in(l) <= '0';
                    enables_in(l) <= '0';
                end if; 
            end loop; 
            
            wait until falling_edge(clk);
            
        end loop;
        
        for l in 0 to (ACTIVATION_LINES-1) loop 
            rows_init_in(l) <= '0';
            rows_valid_in(l) <= '0';
            weights_init_in(l) <= '0';
            weights_valid_in(l) <= '0';
            accumulators_init_in(l) <= '0';
            enables_in(l) <= '0';
        end loop;
    
    
--        reset <= '1'; 
--        wait until falling_edge(clk);
--        wait until falling_edge(clk);
--        reset <= '0'; 
        
--        -- reset phase 
--        for r in 0 to (ACTIVATION_LINES-1) loop 
--            rows_in(r) <= (others => '0');
--            rows_init_in(r) <= '1';
--            rows_valid_in(r) <= '0';
--        end loop; 
--        for w in 0 to (WEIGHT_LINES-1) loop
--            weights_in(w) <= (others => '0');
--            weights_init_in(w) <= '1';
--            weights_valid_in(w) <= '0';
--        end loop; 
--        for a in 0 to (ACCUMULATION_LINES-1) loop 
--            accumulators_in(a) <= STD_LOGIC_VECTOR(TO_UNSIGNED(accumulators,ACCUMULATOR_SIZE));
--            accumulators_init_in(a) <= '1';
--            accumulators_valid_in(a) <= '0';
--            enables_in(a) <= '0';
--        end loop; 
        
--        wait until falling_edge(clk); 

--        --loading phase 
--        for e in 0 to (TEST_WEIGHT_SIZE-1) loop 
--            for r in 0 to (ACTIVATION_LINES-1) loop 
--                if (r<TEST_MATRIX_SIZE and r<ACTIVATION_LINES) then 
--                    rows_in(r) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(r,e),DATA_SIZE));
--                    rows_init_in(r) <= '0';
--                    rows_valid_in(r) <= '1';
--                end if; 
--            end loop; 
--            for w in 0 to (WEIGHT_LINES-1) loop
--                if (w<TEST_WEIGHT_SIZE and w<WEIGHT_LINES) then 
--                    weights_in(w) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(w,e),DATA_SIZE));
--                    weights_init_in(w) <= '0';
--                    weights_valid_in(w) <= '1';
--                end if; 
--            end loop; 
--            for a in 0 to (ACCUMULATION_LINES-1) loop 
--                accumulators_init_in(a) <= '0';
--            end loop;
--            wait until falling_edge(clk);
--        end loop;  
        
--        for w in 0 to (WEIGHT_LINES-1) loop
--            weights_in(w) <= (others => '0');
--            weights_init_in(w) <= '0';
--            weights_valid_in(w) <= '0';
--        end loop; 

--        --computing phase 
--        for round in 0 to ((TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE)*2) loop 
--            for r in 0 to (ACTIVATION_LINES-1) loop 
--                if (round-r<(TEST_MATRIX_SIZE-TEST_WEIGHT_SIZE) and (round-r)>=0 and (round-r)<TEST_MATRIX_SIZE) then 
--                    rows_in(r) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(r,TEST_WEIGHT_SIZE+round-r),DATA_SIZE));
--                    rows_valid_in(r) <= '1';
--                else 
--                    rows_in(r) <= (others => '0');
--                    rows_valid_in(r) <= '0';
--                end if; 
--            end loop; 
--            for a in 0 to (ACCUMULATION_LINES-1) loop 
----                if (a<TEST_WEIGHT_SIZE) then 
----                    accumulators_init_in(a) <= '0';
----                    accumulators_valid_in(a) <= '0';
----                    enables_in(a) <= '1';
----                end if;
--                if (round-a<TEST_WEIGHT_SIZE and round-a>=0 and a<TEST_WEIGHT_SIZE) then 
--                    accumulators_init_in(a) <= '0';
--                    accumulators_valid_in(a) <= '0';
--                    enables_in(a) <= '1';
--                end if;
--            end loop;
            
--            wait until falling_edge(clk);
            
--            for r in 0 to (ACTIVATION_LINES-1) loop 
--                rows_valid_in(r) <= '0';
--            end loop;  
            
--            --wait until falling_edge(clk);
            
--            for i in 0 to TEST_WEIGHT_SIZE-2 loop
--                wait until falling_edge(clk);
--            end loop;
            
--            for a in 0 to (ACCUMULATION_LINES-1) loop 
--                if (round-a<TEST_WEIGHT_SIZE and round-a>=0 and a<TEST_WEIGHT_SIZE) then 
--                    accumulators_init_in(a) <= '1';
--                    accumulators_valid_in(a) <= '1';
--                end if;
--            end loop;
           
--            wait until falling_edge(clk);
            
--        end loop;
        
--        for r in 0 to (ACTIVATION_LINES-1) loop 
--            rows_init_in(r) <= '0';
--            rows_valid_in(r) <= '0';
--        end loop; 
--        for w in 0 to (WEIGHT_LINES-1) loop
--            weights_init_in(w) <= '0';
--            weights_valid_in(w) <= '0';
--        end loop; 
--        for a in 0 to (ACCUMULATION_LINES-1) loop 
--            accumulators_init_in(a) <= '0';
--            accumulators_valid_in(a) <= '0';
--            enables_in(a) <= '0';
--        end loop; 
        
        
        wait;
           
    end process; 
end Behavioral;

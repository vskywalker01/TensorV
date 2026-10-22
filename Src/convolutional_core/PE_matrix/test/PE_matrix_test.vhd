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
            activations_in:             in MATRIX_ACTIVATION_INTERFACE; 
            accumulators_in:            in MATRIX_ACCUMULATORS_INTERFACE; 
            controls_in:                in MATRIX_CONTROL_INTERFACE;
            status_in:                  in MATRIX_STATUS_INTERFACE;
            
            accumulators_out:           out MATRIX_ACCUMULATORS_INTERFACE;
            status_out:                 out MATRIX_STATUS_INTERFACE
        );
    end component;
    
    signal clk, reset: STD_LOGIC;
    signal weights_in:                          MATRIX_WEIGHTS_INTERFACE; 
    signal activations_in:                      MATRIX_ACTIVATION_INTERFACE; 
    signal accumulators_in, accumulators_out:   MATRIX_ACCUMULATORS_INTERFACE; 
            
    signal controls_in:                         MATRIX_CONTROL_INTERFACE;
    signal status_in, status_out:               MATRIX_STATUS_INTERFACE;
    
begin
    
    matrix: PE_matrix 
        port map (
            clk => clk,  
            reset => reset,               
            
            weights_in => weights_in,
            activations_in => activations_in,
            accumulators_in => accumulators_in,
            accumulators_out => accumulators_out,
            
            controls_in => controls_in,
            status_in => status_in,
            status_out => status_out
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
        constant skip: INTEGER := 1;

    begin 
    
        reset <= '1'; 
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        reset <= '0'; 
        
        -- reset phase 
        for l in 0 to (CONTROL_LINES-1) loop
            controls_in(l)(ACTIVATION_INIT_BIT) <= '1';
            controls_in(l)(WEIGHT_INIT_BIT) <= '1';
            controls_in(l)(ACCUMULATOR_INIT_BIT) <= '1';
            controls_in(l)(WEIGHT_VALID_BIT) <= '0';
            controls_in(l)(ACTIVATION_VALID_BIT) <= '0';
            controls_in(l)(ENABLE_BIT) <= '0';
            controls_in(l)(PROCESS_TYPE_BIT) <= '0';
            controls_in(l)(ACTIVATION_SKIP_MS_BIT downto ACTIVATION_SKIP_LS_BIT) <= STD_LOGIC_VECTOR(to_unsigned(1,QUEUE_COUNTERS_SIZE));
        end loop; 
        
        for l in 0 to (STATUS_LINES-1) loop 
            status_in(l)(ACCUMULATOR_VALID_BIT) <= '0';
        end loop;
        
        wait until falling_edge(clk); 

        --loading phase 
        for e in 0 to (TEST_MATRIX_SIZE-1) loop
            for l in 0 to (CONTROL_LINES-1) loop
                controls_in(l)(ACTIVATION_INIT_BIT) <= '0';
                controls_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
                controls_in(l)(WEIGHT_INIT_BIT) <= '0';
                controls_in(l)(ENABLE_BIT) <= '0';
                controls_in(l)(PROCESS_TYPE_BIT) <= '0';
                
                if (l<TEST_MATRIX_SIZE and l<ACTIVATION_LINES) then 
                    controls_in(l)(ACTIVATION_VALID_BIT) <= '1';
                else 
                    controls_in(l)(ACTIVATION_VALID_BIT) <= '0';
                end if;
                if (l<TEST_WEIGHT_SIZE and e<TEST_WEIGHT_SIZE) then 
                    controls_in(l)(WEIGHT_VALID_BIT) <= '1';
                else
                    controls_in(l)(WEIGHT_VALID_BIT) <= '0';
                end if;
            end loop; 
            for l in 0 to (TEST_MATRIX_SIZE-1) loop 
                activations_in(l) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_MATRIX(l,e),DATA_SIZE));
            end loop;
            
            if (e<TEST_WEIGHT_SIZE) then 
                for l in 0 to (TEST_WEIGHT_SIZE-1) loop 
                    weights_in(l) <= STD_LOGIC_VECTOR(TO_SIGNED(TEST_WEIGHT(l,e),DATA_SIZE));
                end loop;
            end if;
            
            wait until falling_edge(clk);
        end loop;

        --processing phase 
        
        for l in 0 to (CONTROL_LINES-1) loop
            controls_in(l)(ACTIVATION_INIT_BIT) <= '0';
            controls_in(l)(WEIGHT_INIT_BIT) <= '0';
            controls_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
            controls_in(l)(WEIGHT_VALID_BIT) <= '0';
            controls_in(l)(ACTIVATION_VALID_BIT) <= '0';
            controls_in(l)(PROCESS_TYPE_BIT) <= '0';
            
            if (l < TEST_WEIGHT_SIZE) then 
                controls_in(l)(ENABLE_BIT) <= '1';
            else 
                controls_in(l)(ENABLE_BIT) <= '0';
            end if;
            
        end loop; 
        
        for i in 0 to (TEST_WEIGHT_SIZE*8) loop 
            wait until falling_edge(clk);  
        end loop;
            
        -- unloading phase 
        
        for l in 0 to (CONTROL_LINES-1) loop
            controls_in(l)(ACTIVATION_INIT_BIT) <= '0';
            controls_in(l)(WEIGHT_INIT_BIT) <= '0';
            controls_in(l)(ACCUMULATOR_INIT_BIT) <= '0';
            controls_in(l)(WEIGHT_VALID_BIT) <= '0';
            controls_in(l)(ACTIVATION_VALID_BIT) <= '0';
            controls_in(l)(PROCESS_TYPE_BIT) <= '1';
            
            if (l < TEST_WEIGHT_SIZE) then 
                controls_in(l)(ENABLE_BIT) <= '1';
            else 
                controls_in(l)(ENABLE_BIT) <= '0';
            end if;
        end loop; 
        
        for l in 0 to (STATUS_LINES-1) loop 
            if (l < TEST_WEIGHT_SIZE) then 
                status_in(l)(ACCUMULATOR_VALID_BIT) <= '1';
            else 
                status_in(l)(ACCUMULATOR_VALID_BIT) <= '0';
            end if;
           
        end loop;
        
        for l in 0 to (ACCUMULATION_LINES-1) loop 
            accumulators_in(l) <= (others => '0');
        end loop;
        wait;
           
    end process; 
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MATRIX_REDUCTION_PARAMETERS.ALL;

entity MAC_stage2 is
    Generic (
        ACC_SIZE: integer := 32
    );
    Port ( 
        clk:            in STD_LOGIC; 
        reset:          in STD_LOGIC; 
    
        matrix_in:      in MATRIX(0 to 1);
        data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
        
        data_mul_out:   out STD_LOGIC_VECTOR(MATRIX_OUTPUT_SIZE-1 downto 0);
        data_acc_out:   out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
    );
end MAC_stage2;

architecture Behavioral of MAC_stage2 is     
    signal mul_p1:      STD_LOGIC_VECTOR(MATRIX_OUTPUT_SIZE-1 downto 0);
    signal mul_p2:      STD_LOGIC_VECTOR(MATRIX_OUTPUT_SIZE-1 downto 0);
    signal mul_out:     STD_LOGIC_VECTOR(MATRIX_OUTPUT_SIZE-1 downto 0);
    
begin 
    partials_routing: for c in 0 to (MATRIX_OUTPUT_SIZE-1) generate 
        constant HEIGHT: INTEGER := get_matrix_column_height(c,2);
    begin 
        mul_p1(c) <= matrix_in(0)(c);
        mul_p2(c) <= matrix_in(1)(c) when (HEIGHT = 2) else '0';
    end generate; 
    mul_out <= STD_LOGIC_VECTOR(SIGNED(mul_p1)+SIGNED(mul_p2)); 
    
    pipeline_latch: process(clk) 
    begin 
        if (rising_edge(clk)) then
            if (reset='1') then 
                data_mul_out <= (others => '0');
                data_acc_out <= (others => '0');
            else 
                data_mul_out(MATRIX_OUTPUT_SIZE-2 downto 0) <= mul_out(MATRIX_OUTPUT_SIZE-2 downto 0);
                data_mul_out(MATRIX_OUTPUT_SIZE-1) <= not(mul_out(MATRIX_OUTPUT_SIZE-1));
                data_acc_out <= data_acc_in;
            end if;
        end if; 
    end process;     
    
    
end architecture;
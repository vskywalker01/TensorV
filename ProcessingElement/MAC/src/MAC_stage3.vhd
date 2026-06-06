library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MATRIX_REDUCTION_PARAMETERS.ALL;

entity MAC_stage3 is
    Generic (
        ACC_SIZE: integer := 32
    );
    Port ( 
        clk:            in STD_LOGIC; 
        reset:          in STD_LOGIC; 
    
        data_mul_in:    in STD_LOGIC_VECTOR(MATRIX_OUTPUT_SIZE-1 downto 0);
        data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
        
        r_out:          out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
    );
end MAC_stage3;

architecture Behavioral of MAC_stage3 is
    signal mul_in: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
begin
    sign_extension: for c in 0 to (ACC_SIZE-1) generate 
        mul_in(c) <= data_mul_in(c) when (c<MATRIX_OUTPUT_SIZE-1) else 
                     data_mul_in(MATRIX_OUTPUT_SIZE-1);  
    end generate;  
    pipeline_latch: process(clk) 
    begin 
        if (rising_edge(clk)) then
            if (reset='1') then 
                r_out <= (others => '0');
            else 
                r_out <= STD_LOGIC_VECTOR(UNSIGNED(mul_in)+UNSIGNED(data_acc_in)); 
            end if;
        end if; 
    end process;     
    
    

end Behavioral;

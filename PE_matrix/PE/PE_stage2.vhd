library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_MATRIX_PARAMETERS.ALL; 

entity PE_stage2 is
    Port ( 
        clk:                        in STD_LOGIC;  
        reset:                      in STD_LOGIC;                 
        
        control_in:                 in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
        weight_in:                  in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0); 
        activation_in:              in STD_LOGIC_VECTOR( DATA_SIZE-1 downto 0);
        accumulator_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        weight_empty_in:            in STD_LOGIC;
        activation_empty_in:        in STD_LOGIC;
        
        weight_forward_in:          in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_forward_in:      in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        
        control_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
        weight_forward_out:         out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_forward_out:     out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        
        reduction1_out:             out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        reduction2_out:             out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        reduction_valid_out:        out STD_LOGIC
        
    );
end PE_stage2;

architecture Behavioral of PE_stage2 is    
    component reduction_stage is
        Generic (
                ACC_SIZE: INTEGER := 32
            );
        Port ( 
            data_a:                 in STD_LOGIC_VECTOR(7 downto 0);
            data_b:                 in STD_LOGIC_VECTOR(7 downto 0);  
    
            matrix_out1:            out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
            matrix_out2:            out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
    
        );
    end component;
    signal reduction1, reduction2: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
begin
    reduction: reduction_stage 
        generic map (
            ACC_SIZE => ACCUMULATOR_SIZE
        )
        port map (
            data_a => weight_in, 
            data_b => activation_in, 

            matrix_out1 => reduction1, 
            matrix_out2 => reduction2
        );

    stage2: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1') then 
                weight_forward_out <= (others => '0');
                activation_forward_out <= (others => '0');
                control_out <= (others => '0');
                reduction_valid_out <= '0';
                
            else 
                weight_forward_out <= weight_forward_in;
                activation_forward_out <= activation_forward_in;
                control_out <= control_in;
                
                if (control_in(ENABLE_BIT)='1') then 
                    if (control_in(ACCUMULATOR_VALID_BIT) = '0') then 
                        reduction1_out <= reduction1;
                        reduction2_out <= reduction2;
                        reduction_valid_out <= not(weight_empty_in) and not(activation_empty_in); 
                    else 
                        reduction1_out <= accumulator_in; 
                        reduction2_out <= (others => '0');
                        reduction_valid_out <= '0';
                    end if;
                else 
                    reduction_valid_out <= '0';
                end if;
            end if;
        end if; 
    end process;

end Behavioral;
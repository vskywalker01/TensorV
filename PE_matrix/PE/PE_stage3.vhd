library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_MATRIX_PARAMETERS.ALL;

entity PE_stage3 is
    Port ( 
        clk:                        in STD_LOGIC;  
        reset:                      in STD_LOGIC;                 
        
        control_in:                 in STD_LOGIC_VECTOR(6 downto 0); 
        
        weight_forward_in:          in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_forward_in:      in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        
        control_out:                out STD_LOGIC_VECTOR(6 downto 0);
        weight_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        reduction1_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        reduction2_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        reduction_valid_in:        in STD_LOGIC 
        
    );
end PE_stage3;

architecture Behavioral of PE_stage3 is    
    component accumulation_stage is
        Generic (
            ACC_SIZE: integer := 32
        );
        Port ( 
        
            matrix_in1:             in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
            matrix_in2:             in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
            data_acc_in:            in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
            
            data_out:               out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
        );
    end component;
    
    signal accumulator, accumulation_out: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal valid_in,valid_out: STD_LOGIC;
begin
    accumulation: accumulation_stage
        generic map (
            ACC_SIZE => ACCUMULATOR_SIZE
        ) 
        port map (
            data_acc_in => accumulator,
            matrix_in1 => reduction1_in, 
            matrix_in2 => reduction2_in, 
            
            data_out => accumulation_out
            
        ); 

    stage3: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1') then 
                weight_out <= (others => '0');
                activation_out <= (others => '0');
                control_out <= (others => '0');
                accumulator_out <= (others => '0');
                accumulator <= (others => '0');
            else 
                if (control_in(ACCUMULATOR_INIT_BIT) = '1') then
                    accumulator <= (others => '0');
                else    
                    if (reduction_valid_in = '1')  then 
                        accumulator <= accumulation_out;   
                    end if;                  
                end if;
                
                if (control_in(ACCUMULATOR_VALID_BIT) = '1' and control_in(ENABLE_BIT) = '1') then 
                    accumulator_out <= accumulation_out; 
                end if; 
                
                weight_out <= weight_forward_in;
                activation_out <= activation_forward_in;
                control_out <= control_in;
               
            end if;
        end if; 
    end process;

end Behavioral;
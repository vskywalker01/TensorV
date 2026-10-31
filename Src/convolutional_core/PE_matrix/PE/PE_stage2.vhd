library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PE_MATRIX_PARAMETERS.ALL; 

entity PE_stage2 is
    Port ( 
        clk:                        in STD_LOGIC;  
        reset:                      in STD_LOGIC;     

        -- matrix forward lines
        
        control_forward_in:                 in PE_CONTROL_INTERFACE;
        status_forward_in:                  in PE_STATUS_INTERFACE;
        weight_forward_in:                  in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
        activation_forward_in:              in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_forward_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        
        control_forward_out:                out PE_CONTROL_INTERFACE;
        status_forward_out:                 out PE_STATUS_INTERFACE;
        weight_forward_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_forward_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_forward_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        -- Queue Input lines (Stage 1)
        
        weight_queue_in:          in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_queue_in:      in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_queue_in:     in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        
        -- Queue control lines (Stage 1)
        
        queue_empty_in:                    in STD_LOGIC;
        accumulator_empty_in:               in STD_LOGIC;
        
        row_done_in:                        in STD_LOGIC;
        
        -- Reduction I/O and control lines 
        
        reduction_partial1_out:             out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        reduction_partial2_out:             out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        reduction_valid_out:            out STD_LOGIC;
        reduction_type_out:             out STD_LOGIC
        
    );
end PE_stage2;

architecture Behavioral of PE_stage2 is    

    -- The reduction stage processes the multiplication between two inputs (activation and weight) 
    -- The outputs of the stage will be summed in the stage 3 of the PE
    component reduction_stage is
        Generic (
                ACC_SIZE: INTEGER := ACCUMULATOR_SIZE
            );
        Port ( 
            data_a:                 in STD_LOGIC_VECTOR(7 downto 0);
            data_b:                 in STD_LOGIC_VECTOR(7 downto 0);  
    
            matrix_out1:            out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
            matrix_out2:            out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
    
        );
    end component;
    
    -- output signals from the reduction stage 
    signal mul_partial1, mul_partial2: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
begin
    reduction: reduction_stage 
        generic map (
            ACC_SIZE => ACCUMULATOR_SIZE
        )
        port map (
            data_a => weight_queue_in, 
            data_b => activation_queue_in, 

            matrix_out1 => mul_partial1, 
            matrix_out2 => mul_partial2
        );

    -- PE process execution section 
    stage2: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1' or status_forward_in(PE_ACTIVE) = '0') then 
                
                control_forward_out <= (others => '0');
                reduction_valid_out <= '0';
                reduction_type_out <= '0';
                
                -- The status lines assumes the PE as always ready and always with a valid output
                status_forward_out(PE_OUTPUT_VALID) <= '1';
                status_forward_out(PE_READY) <= '1';
                status_forward_out(PE_ACTIVE) <= '0';
            else

                -- Matrix forward lines
                control_forward_out <= control_forward_in;
                status_forward_out <= status_forward_in;
                accumulator_forward_out <= accumulator_forward_in;
                
                
                -- if the PE is currently processing a row (not done yet), the reduction_partial lines will assume the result of the multiplication between 
                -- a valid weight and a valid activation coming from the queues in the first stage
                
                if (status_forward_in(PE_READY)='0' and status_forward_in(PE_STATUS) = '0' and row_done_in = '0' and queue_empty_in = '0') then 
                    reduction_partial1_out <= mul_partial1;
                    reduction_partial2_out <= mul_partial2;
                    reduction_valid_out <= '1';
                    reduction_type_out <= '1';
                
                -- if the PE should process the accumulation stored in the accumulator queue from stage 1 (unloading phase), 
                -- the reduction_partial1 line will assume the accumulation from the queue and reduction_partial2 line will assume 0.
                -- This is done only when there is a valid accumulator input (data available from past PE).
                
                elsif (status_forward_in(PE_READY)='0' and status_forward_in(PE_STATUS) = '1' and status_forward_in(PE_OUTPUT_VALID)= '1' and accumulator_empty_in = '0') then
                    reduction_partial1_out <= accumulator_queue_in;
                    reduction_partial2_out <= (others => '0');
                    reduction_valid_out <= '1';           
                    reduction_type_out <= '0';
                    
               -- if the PE has processed a row, the accumulator will be pushed inside its queue in the third stage (the reduction is not valid)
 
                elsif (status_forward_in(PE_READY)='0' and status_forward_in(PE_STATUS) = '0' and row_done_in = '1') then 
                    reduction_valid_out <= '0';
                    reduction_type_out <= '1';
 
                else 
                    reduction_valid_out <= '0';   
                    reduction_type_out <= '0';
                end if;
            end if;
        end if; 
    end process;
    
    -- PE data forward registers
    stage2_forward: process(clk) is 
    begin 
        if rising_edge(clk) then
            if (reset = '1') then 
                weight_forward_out <= (others => '0');
                activation_forward_out <= (others => '0');
            else 
                weight_forward_out <= weight_forward_in;   
                activation_forward_out <= activation_forward_in;
            end if; 
        end if;
     end process;

end Behavioral;
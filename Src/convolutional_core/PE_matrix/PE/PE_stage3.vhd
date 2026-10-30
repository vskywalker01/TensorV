library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.PE_MATRIX_PARAMETERS.ALL;

entity PE_stage3 is
    Port ( 
        clk:                        in STD_LOGIC;  
        reset:                      in STD_LOGIC;     
        
        -- matrix forward lines             
        
        control_forward_in:                 in STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0); 
        status_forward_in:                  in STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
        accumulator_forward_in:             in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        weight_forward_in:                  in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_forward_in:              in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        
        control_forward_out:                out STD_LOGIC_VECTOR(CONTROL_SIZE-1 downto 0);
        status_forward_out:                 out STD_LOGIC_VECTOR(STATUS_SIZE-1 downto 0);
        weight_forward_out:                 out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        activation_forward_out:             out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        accumulator_forward_out:            out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        -- control lines and I/O from stage 2
        reduction_partial1_in:              in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0); 
        reduction_partial2_in:              in STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        
        reduction_valid_in:                 in STD_LOGIC;
        reduction_type_in:                  in STD_LOGIC;
        
        -- loopback control lines and I/O (to stage 1)
        
        accumulator_loopback_out:           out STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
        accumulator_loopback_valid_out:     out STD_LOGIC
        
        
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
    
    signal accumulator, accumulation_stage_mux, accumulation_stage_out: STD_LOGIC_VECTOR(ACCUMULATOR_SIZE-1 downto 0);
    signal valid_in,valid_out: STD_LOGIC;
    
begin
    accumulation: accumulation_stage
        generic map (
            ACC_SIZE => ACCUMULATOR_SIZE
        ) 
        port map (
            data_acc_in => accumulation_stage_mux,
            matrix_in1 => reduction_partial1_in, 
            matrix_in2 => reduction_partial2_in, 
            
            data_out => accumulation_stage_out
            
        ); 
    
    -- the accumulator multiplexer chooses from the local accumulator (while processing a row) and the accumulator_forward_in (during the deloading phase)
    
    accumulation_stage_mux <= accumulator when (reduction_type_in = '1') else 
                              accumulator_forward_in;
    
    stage3: process(clk) is 
    begin 
        if (rising_edge(clk)) then 
            if (reset = '1' or status_forward_in(ACTIVE_BIT) = '0') then 
                control_forward_out <= (others => '0');
                accumulator_forward_out <= (others => '0');
                status_forward_out(ACCUMULATOR_VALID_BIT) <= '1';
                status_forward_out(DONE_BIT) <= '1';
                status_forward_out(ACTIVE_BIT) <= '0';
                -- the accumulator is initialized to 0
                accumulator <= (others => '0');
                
            else
                
                control_forward_out <= control_forward_in; 
                status_forward_out(DONE_BIT) <= status_forward_in(DONE_BIT);
                status_forward_out(ACTIVE_BIT) <= status_forward_in(ACTIVE_BIT);
                status_forward_out(TYPE_BIT) <= status_forward_in(TYPE_BIT);
                
                -- if the PE is enabled and it is processing a row (reduction_valid = '1' and reduction_type = '1'), the accumulation result will be saved into the internal
                -- accumulator 
                if (status_forward_in(DONE_BIT)='0' and status_forward_in(TYPE_BIT) = '0' and reduction_valid_in = '1' and reduction_type_in = '1') then 
                    accumulator <= accumulation_stage_out; 
                    accumulator_loopback_valid_out <= '0';
                    status_forward_out(ACCUMULATOR_VALID_BIT) <= '0';
                    
                -- if the PC is enabled and had processed a row (reduction_valid = '0' and reduction_type = '1'), the result will be forwarded in the internal loopback of the Pe and the 
                -- internal accumulator will be initialized
                
                elsif (status_forward_in(DONE_BIT)='0' and status_forward_in(TYPE_BIT) = '0' and reduction_valid_in = '0' and reduction_type_in = '1') then 
                    accumulator <= (others => '0'); 
                    accumulator_loopback_valid_out <= '1';
                    accumulator_loopback_out <= accumulator; 
                    status_forward_out(ACCUMULATOR_VALID_BIT) <= '0';
                
                -- if the PC is enabled and is performing an unloading phase, the past accumulation (from the accumulation queue) is summed with the value coming from the past PE.
                -- the result will be then forwarded to the next PE.
                    
                elsif (status_forward_in(DONE_BIT)='0' and status_forward_in(TYPE_BIT) = '1' and reduction_valid_in = '1' and reduction_type_in = '0') then 
                    --accumulator <= (others => '0'); 
                    accumulator_loopback_valid_out <= '0';
                    accumulator_forward_out <= accumulation_stage_out;
                    status_forward_out(ACCUMULATOR_VALID_BIT) <= '1';
                   
                else 
                    if (control_forward_in(ACCUMULATOR_INIT_BIT) = '1') then 
                        accumulator <= (others => '0'); 
                       
                    end if; 
                    
                    status_forward_out(ACCUMULATOR_VALID_BIT) <= '0';
                    accumulator_loopback_valid_out <= '0';
                end if; 

            end if;
        end if; 
    end process;
    
    stage3_forward: process(clk) is 
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
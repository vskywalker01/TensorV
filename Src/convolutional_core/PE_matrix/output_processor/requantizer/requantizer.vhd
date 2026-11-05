
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 
use work.SHIFTERS.ALL; 
use work.BIT_REDUCTORS.ALL;

entity requantizer is
    Generic (
        DATA_SIZE:          INTEGER := 20; 
        OUTPUT_SIZE:        INTEGER := 8;
        SHIFT_VALUE_BITS:   INTEGER := 5
    );
    Port ( 
        clk:        in STD_LOGIC; 
        reset:      in STD_LOGIC; 
    
        data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        shift:      in STD_LOGIC_VECTOR(SHIFT_VALUE_BITS-1 downto 0);
        valid_in:   in STD_LOGIC;  
        
        data_out:   out STD_LOGIC_VECTOR(OUTPUT_SIZE-1 downto 0); 
        valid_out:  out STD_LOGIC
        
    );
end requantizer;

architecture Behavioral of requantizer is
    signal input_sign: STD_LOGIC; 
    signal shifted_input: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    signal zero: STD_LOGIC; 

begin
    right_shifter: barrel_right_shifter 
        Generic map (
            DATA_SIZE => DATA_SIZE,
            SHIFT_SIZE => SHIFT_VALUE_BITS
        )
        port map(
            data_in => data_in, 
            logic => '0',
            data_out => shifted_input,
            shift => shift
        );
    zero <= '0';   
    overflow_detector: or_reductor 
        Generic map (
            DATA_SIZE => DATA_SIZE-OUTPUT_SIZE+1
        )
        Port map (
            data_in => shifted_input(DATA_SIZE-1 downto OUTPUT_SIZE-1),
            result => zero
        );

    input_sign <= data_in(DATA_SIZE-1);
    
    requantizer: process(clk) is         

    begin 
        if (rising_edge(clk)) then 
            if (reset = '1') then
                valid_out <= '0'; 
                data_out <= (others => '0');
            else 
                if (valid_in = '1') then 
                    if (input_sign = '1') then 
                        -- if the input value is less than 0 => ReLU function (the output is forced to 0)
                        data_out <= (others => '0');
                    else 
                        -- if the input value is greater or equal to 0 => shift and clamp 
                        if (zero = '0') then 
                            data_out <= shifted_input(OUTPUT_SIZE-1 downto 0);
                        else 
                            data_out <= (OUTPUT_SIZE-1 => '0', others => '1');
                        end if; 
                                
                    end if; 
                    valid_out <= '1';
                else 
                    valid_out <= '0'; 
                end if; 
            end if; 
        end if;
    end process;

end Behavioral;

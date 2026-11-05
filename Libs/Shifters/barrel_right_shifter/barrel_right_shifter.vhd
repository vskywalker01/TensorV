library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity barrel_right_shifter is
    Generic (
        DATA_SIZE: INTEGER := 32;
        SHIFT_SIZE: INTEGER := 5
    );
    Port (
        data_in:    in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        shift:      in STD_LOGIC_VECTOR(SHIFT_SIZE-1 downto 0); 
        logic:      in STD_LOGIC; 
        
        data_out:   out STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0)
    );
end barrel_right_shifter;

architecture Behavioral of barrel_right_shifter is
    type SHIFT_LEVELS is array (SHIFT_SIZE downto 0) of STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
    signal stages: SHIFT_LEVELS; 
    signal sign_bit: STD_LOGIC; 
begin
    stages(SHIFT_SIZE) <= data_in;
    sign_bit <= data_in(DATA_SIZE-1) when (logic = '0') else '0';
    
    level: for l in SHIFT_SIZE-1 downto 0 generate
        constant LEVEL_DATA_SIZE: INTEGER := 2 ** (l); 
    begin     
        multiplexer: for b in 0 to DATA_SIZE-1 generate 
            stages(l)(b) <= sign_bit when (shift(l) = '1' and b+LEVEL_DATA_SIZE >= DATA_SIZE) else 
                            stages(l+1)(b+LEVEL_DATA_SIZE) when (shift(l) = '1' and b+LEVEL_DATA_SIZE < DATA_SIZE) else
                            stages(l+1)(b);
        end generate; 
    end generate; 
    
    data_out <= stages(0);

end Behavioral;

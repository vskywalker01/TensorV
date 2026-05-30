library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MULTIPLIER_PARAMETERS.ALL;

entity MAC_stage3 is
    Generic (
        ACC_SIZE: integer := 32
    );
    Port ( 
        clk:            in STD_LOGIC; 
        reset:          in STD_LOGIC; 
    
        p_in:           in PARTIALS_ARRAY(0 to 1);
        data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
        
        r_out:          out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
    );
end MAC_stage3;

architecture Behavioral of MAC_stage3 is 
    type ACCUMULATION_PARTIALS is ARRAY (natural range <>) of STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    
    signal partial1: SIGNED(PARTIAL_SIZE-1 downto 0); 
    signal partial2: SIGNED(PARTIAL_SIZE-1 downto 0);
    signal mul_result: SIGNED(ACC_SIZE-1 downto 0); 
    signal result: SIGNED(ACC_SIZE-1 downto 0);
    
begin 
    partials_routing: for c in 0 to (PARTIAL_SIZE-1) generate
        constant HEIGHT: INTEGER := get_tree_column_height(c,2);
    begin
        partial1(c) <= p_in(0)(c); 
        partial2(c) <= p_in(1)(c) when (HEIGHT>1) else '0';
    end generate; 
    mul_result(PARTIAL_SIZE-1 downto 0) <= partial1+partial2;
    
    sign_extension: for c in PARTIAL_SIZE to (ACC_SIZE-1) generate
        mul_result(c) <= mul_result(PARTIAL_SIZE-1);
    end generate;
    
    result <= mul_result+SIGNED(data_acc_in);
    
    pipeline_latch: process(clk) 
    begin 
        if (rising_edge(clk)) then
            if (reset='1') then 
                r_out <= (others => '0');
            else 
                r_out <= STD_LOGIC_VECTOR(result); 
            end if;
        end if; 
    end process;     
    
    
end architecture;
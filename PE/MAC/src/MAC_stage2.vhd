-- Definition of the final sum stage for the MAC pipeline. 

-- In this stage, the two rows generated from the reduction stage are summed together with the accumulator using a Brent-kung adder

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ADDERS.ALL;

entity MAC_stage2 is
    Generic (
        ACC_SIZE: integer := 32
    );
    Port ( 
        clk:            in STD_LOGIC; 
        reset:          in STD_LOGIC; 
    
        matrix_in1:     in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
        matrix_in2:     in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
        data_acc_in:    in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
        
        data_out:   out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)
    );
end MAC_stage2;

architecture Behavioral of MAC_stage2 is     
    signal r_line: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
    signal c_line: STD_LOGIC_VECTOR(ACC_SIZE downto 0); 
    
    signal res: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
    
begin 
    -- Instead of using two adders (sum the first two rows and then the accumulator), another reduction based on carry save approach is used to avoid complexity. 

    -- * * * * * * * * * * * * * * * *  <- accumulator   
    -- * * * * * * * * * * * * * * * *  <- first row (from reduction)
    -- * * * * * * * * * * * * * * *    <- recond row (from reduction) 
    -- |     full adders           |     
    --                               ^ 
    --                             half adder
    
    first_reduction: for c in 0 to (ACC_SIZE-1) generate 
    
        -- The first bits (one from the accumulator and one from the first row) are processed using an half adder
        c0: if (c=0) generate 
            half: half_adder 
                port map (
                    a => data_acc_in(0),
                    b => matrix_in1(0), 
                    
                    r => r_line(0),
                    c => c_line(1)   
                );    
        end generate; 
        
        -- The other bits are processed using full adders (the final carry is discarded because we do not take account for overflows)
        cn: if (c>0) generate
            full: full_adder 
                port map (
                    a => data_acc_in(c), 
                    b => matrix_in1(c),
                    c_in => matrix_in2(c),
                    
                    r => r_line(c),
                    c_out => c_line(c+1)
                );
        end generate; 
    end generate; 
    
    -- The outputs of the preliminar carry save reduction (one result line and one carry line) are processed using a Brent-Kung adder with carry in = 0
    
    c_line(0) <= '0';
    
    adder: bk_adder
        generic map (
            DIM => ACC_SIZE
        ) 
        port map (
            a => r_line, 
            b => c_line(ACC_SIZE-1 downto 0),
            c_in => '0', 
            
            r => res,
            c_out => open
        );
    
    -- The output is simply latched
    pipeline_latch: process(clk) 
    begin 
        if (rising_edge(clk)) then
            if (reset='1') then 
                data_out <= (others => '0');
            else 
                data_out <= res;
            end if;
        end if; 
    end process;     
    
    
end architecture;
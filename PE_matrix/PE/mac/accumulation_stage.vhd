-- Definition of the final sum stage for the MAC pipeline. 

-- In this stage, the two rows generated from the reduction stage are summed together with the accumulator using a Brent-kung adder

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ADDERS.ALL;

entity accumulation_stage is
    Generic (
        ACC_SIZE: integer := 32
    );
    Port ( 
        matrix_in1:             in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
        matrix_in2:             in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0);
        data_acc_in:            in STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
        
        data_out:               out STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0)   
    );
end accumulation_stage;

architecture Behavioral of accumulation_stage is     
    signal r_line: STD_LOGIC_VECTOR(ACC_SIZE-1 downto 0); 
    signal c_line: STD_LOGIC_VECTOR(ACC_SIZE downto 0); 
    
begin 
    -- Instead of using two adders (sum the first two rows and then the accumulator), another reduction based on carry save approach is used to avoid complexity. 

    -- * * * * * * * * * * * * * * * *  <- accumulator   
    -- * * * * * * * * * * * * * * * *  <- first row (from reduction)
    -- * * * * * * * * * * * * * * *    <- recond row (from reduction) 
    -- |     full adders           |     
    --                               ^ 
    --                             half adder
    
    preprocessing: for c in 0 to (ACC_SIZE-1) generate  
        -- The bits are processed using full adders (the final carry is discarded because we do not take account for overflows)
        
         
        
        full: full_adder 
            port map (
                a => data_acc_in(c), 
                b => matrix_in1(c),
                c_in => matrix_in2(c),
                
                r => r_line(c),
                c_out => c_line(c+1)
            );
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
            
            r => data_out,
            c_out => open
        );    
end architecture;
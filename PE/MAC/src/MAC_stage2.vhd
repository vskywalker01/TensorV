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
    first_reduction: for c in 0 to (ACC_SIZE-1) generate 
        c0: if (c=0) generate 
            half: half_adder 
                port map (
                    a => data_acc_in(0),
                    b => matrix_in1(0), 
                    
                    r => r_line(0),
                    c => c_line(1)   
                );    
        end generate; 
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
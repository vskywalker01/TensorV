-- Definition of Baugh-Wooley partial generator based on hantamian's organization for hardware multiplication 

-- The generator elaborates the partials that should be summed to obtain a multiplication between two signed inputs A and B. 
-- This format is convenient when processing low bit signed values (for example 8-bits) because it does not introduce much complexity.

--                                   1 /p70  p60  p50  p40  p30  p20  p10  p00 
--                              0 /p71  p61  p51  p41  p31  p21  p11  p01
--                         0 /p72  p62  p52  p42  p32  p22  p12  p02
--                    0 /p73  p63  p53  p43  p33  p23  p13  p03
--               0 /p74  p64  p54  p44  p34  p24  p14  p04
--          0 /p75  p65  p55  p45  p35  p25  p15  p05
--     0 /p76  p66  p56  p46  p36  p26  p16  p06
-- 0 p77 /p67 /p57 /p47 /p37 /p27 /p17 /p07

-- The output will be a 16-bit signed with the most significant one inverted:
--      /r15 r14 r13 r12 r11 r10 r9 r8 r7 r6 r5 r4 r3 r2 r1 r0 
-- Remmeber to invert the last bit again!

-- Note:
-- * PNM indicates the multiplication between the bit N in the first input and the bit M in the second input (/ indicates an inversion)
-- * This is a rielaboration of the original Baugh-Wooley organization (used by H. Hantamian in the paper "A 70-MHz 8-bit x 8-bit Parallel Pipelined Multiplier in2.5-μm CMOS")
-- * To avoid the generation of unbalanced trees, one bit is added to take account fot the bit '1' in the first partial
-- * the output of the generator is not shifted. To achieve the shift, the user must shift the bits manually using the function get_bw_generator_shift in the GENERATORS package.



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.GENERATORS.ALL;

entity bw_generator is
    Generic ( 
        DATA_SIZE: INTEGER := 8                             -- Input size 
    );
    Port (
        -- Inputs 
        data_a: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);  -- Vector a 
        data_b: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);  -- Vector b 

        -- Outputs 
        partials_out: out PARTIALS(DATA_SIZE-1 downto 0,DATA_SIZE downto 0)
    );
end bw_generator;

architecture Behavioral of bw_generator is
    signal partial_b1: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    signal partial_b0: STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0); 
    

begin
    partial_b1(DATA_SIZE-2 downto 0) <= data_a(DATA_SIZE-2 downto 0);
    partial_b0(DATA_SIZE-2 downto 0) <= (others => '0');
    partial_b1(7) <= not(data_a(7));
    partial_b0(7) <= '1';
    
    row: for p in 0 to (DATA_SIZE-1) generate
        col: for c in 0 to (DATA_SIZE) generate             
        begin
            last_bit: if (c=DATA_SIZE) generate 
                partials_out(p,c) <= '1' when (p = 0) else '0';
            end generate;
            
            first_bits: if (c<DATA_SIZE) generate
                partials_out(p,c) <= 
                    partial_b1(c)       when (data_b(p)='1' and p < (DATA_SIZE-1)) else 
                    not(partial_b1(c))  when (data_b(p)='1' and p = (DATA_SIZE-1)) else 
                    partial_b0(c)       when (data_b(p)='0' and p < (DATA_SIZE-1)) else 
                    not(partial_b0(c));
            end generate;
        end generate; 
    end generate;  
end Behavioral;

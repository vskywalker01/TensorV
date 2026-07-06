-- Implementation of unpipelined brent-kung parametric adder for general purpose. 
-- The adder is based on more components: 
-- * Encode layer, where initial signals are encoded in generate/propagate signals 
-- * Reduction layers, where the generate and propagate signal are combined to generate intermediate signals 
-- * Decode layer, where the carry contained in the generate lines are combined with the initial propagate signals for encoding the output. 

--
--  a ->    ************ -> generate  -> **********|     |*********** -> generate  -> ********** -> r 
--  b ->    *  encode  *                 * layer 1 | ... | layer n  *                 * decode *
--          ************ -> propagate -> **********|     |*********** -> propagate    ********** -> c_out 
--                              |                                                         *  
--  c_in ---------------------------------------------------------------------------------|        

-- The complete architecture is generated automatically using the parameter N (size of the inputs and the output) 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity bk_adder is
        Generic (
            DIM: INTEGER := 20
        );
        Port (             
            -- Inputs 
            a: in STD_LOGIC_VECTOR(DIM-1 downto 0);     -- Vector a 
            b: in STD_LOGIC_VECTOR(DIM-1 downto 0);     -- Vector b 
            c_in: in STD_LOGIC;                         -- Can be set to 0 to have a normal adder 
            
            -- Outputs 
            r: out STD_LOGIC_VECTOR(DIM-1 downto 0);    -- Result vector 
            c_out: out STD_LOGIC                        -- Can be used as overflow bit 
            
        );
end bk_adder;

architecture Behavioral of bk_adder is
    
    -- Including necessary components 

    component bk_adder_encode is
        Generic (
            DIM: INTEGER := 8
        );
        Port ( 
            a: in STD_LOGIC_VECTOR(DIM-1 downto 0);
            b: in STD_LOGIC_VECTOR(DIM-1 downto 0);
          
            g_out: out STD_LOGIC_VECTOR(DIM-1 downto 0); 
            p_out: out STD_LOGIC_VECTOR(DIM-1 downto 0)
        );
    end component;
    component bk_adder_level is
        Generic (
            DIM: INTEGER := 8;
            LEVEL: INTEGER
        );
        Port ( 
            g_in: in STD_LOGIC_VECTOR(DIM-1 downto 0); 
            p_in: in STD_LOGIC_VECTOR(DIM-1 downto 0);
          
            g_out: out STD_LOGIC_VECTOR(DIM-1 downto 0); 
            p_out: out STD_LOGIC_VECTOR(DIM-1 downto 0)
        );
    end component;
    component bk_adder_decode is
        Generic (
            DIM: INTEGER := 8
        );
        Port ( 
            c_in: in STD_LOGIC;
            g_in: in STD_LOGIC_VECTOR(DIM-1 downto 0); 
            p_in: in STD_LOGIC_VECTOR(DIM-1 downto 0);
            
            r: out STD_LOGIC_VECTOR(DIM-1 downto 0);
            c_out: out STD_LOGIC
            
        );
    end component;

    -- The number of intermediate layers is given by: 2*log(N)-1 
    constant DEPTH: INTEGER :=  (2*INTEGER(ceil(log2(REAL(DIM)))))-1;

    -- Intermediate vectors for connecting multiple layers 
    type INTERMEDIATE is array (0 to DEPTH) of STD_LOGIC_VECTOR (DIM-1 downto 0); 
    signal p,g: INTERMEDIATE;
    
begin

    -- The encode layer generates results on the first line of the arrays p and g
    encode: bk_adder_encode 
        generic map (
            DIM => DIM
        )
        port map (
            a => a,
            b => b,
            g_out => g(0),
            p_out => p(0)
        );

    -- The intermediate levels are generated and connected to the other lines of the array in cascade 
    levels: for l in 0 to (DEPTH-1) generate
        level: bk_adder_level 
            generic map(
                DIM => DIM,
                LEVEL => l
            )
            port map (
                g_in => g(l),
                p_in => p(l),
                
                g_out => g(l+1),
                p_out => p(l+1)
            );
    end generate;
    
    -- The decode level takes the propagate lines from the encode layer and the carrys from the final generate line
    decode: bk_adder_decode 
        generic map ( 
            DIM => DIM
        ) 
        port map (
            g_in => g(DEPTH),
            p_in => p(0),
            c_in => c_in,
            r => r,
            c_out => c_out
        ); 
    
end Behavioral;

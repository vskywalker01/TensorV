library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity bk_adder is
        Generic (
            DIM: INTEGER := 20
        );
        Port (             
            a: in STD_LOGIC_VECTOR(DIM-1 downto 0);
            b: in STD_LOGIC_VECTOR(DIM-1 downto 0);
            c_in: in STD_LOGIC;
            
            r: out STD_LOGIC_VECTOR(DIM-1 downto 0);
            c_out: out STD_LOGIC
            
        );
end bk_adder;

architecture Behavioral of bk_adder is
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

    constant DEPTH: INTEGER :=  (2*INTEGER(ceil(log2(REAL(DIM)))))-1;
    type INTERMEDIATE is array (0 to DEPTH) of STD_LOGIC_VECTOR (DIM-1 downto 0); 
    
    signal p,g: INTERMEDIATE;
    
begin
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

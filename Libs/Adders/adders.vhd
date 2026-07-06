-- Definition of ADDERS package. It includes: 
-- * Definition of full adder 
-- * Definition of half adder 
-- * Definition of Brent-Kung adder 

-- To use one of this componens import this package in your compiler (for example VIVADO) and add the following line 
-- use work.ADDERS.ALL 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package ADDERS is
    component full_adder is
        Port (
            a:      in STD_LOGIC;
            b:      in STD_LOGIC;
            c_in:   in STD_LOGIC;
        
            r:      out STD_LOGIC;
            c_out:  out STD_LOGIC
        );
    end component;

    component half_adder is
        Port (
            a: in STD_LOGIC;
            b: in STD_LOGIC;
            
            r: out STD_LOGIC;
            c: out STD_LOGIC
        );
    end component;

    component bk_adder is
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
    end component;
end package; 

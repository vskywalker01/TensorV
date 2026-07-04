library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package GENERATORS is
    type PARTIALS is array (natural range <>, natural range <>) of STD_LOGIC; 

    component bw_generator is
        Generic ( 
            DATA_SIZE: INTEGER := 8
        );
        Port (
            data_a: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
            data_b: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
            partials_out: out PARTIALS(DATA_SIZE-1 downto 0,DATA_SIZE downto 0)
        );
    end component;
    
    function get_bw_partial_size (
        DATA_SIZE:  INTEGER 
    ) return        INTEGER;
    
    function get_bw_partials_to_reduce (
        DATA_SIZE:  INTEGER 
    ) return        INTEGER;
    
    function get_bw_partial_shift
      return        INTEGER;
 
    
end package; 

package body GENERATORS is 
    function get_bw_partial_size (
        DATA_SIZE:      INTEGER)
        return          INTEGER is 
    begin 
        return 2*DATA_SIZE;
    end function;
    
    function get_bw_partials_to_reduce (
        DATA_SIZE:      INTEGER) 
        return          INTEGER is 
    begin 
        return DATA_SIZE; 
    end function; 
    
    function get_bw_partial_shift 
        return        INTEGER is 
    begin 
        return 1;
    end function; 
end package body; 
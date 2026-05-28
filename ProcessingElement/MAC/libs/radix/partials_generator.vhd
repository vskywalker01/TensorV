library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MULTIPLIER_PARAMETERS.ALL;

entity partials_generator is
  Port (
    data_a: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    data_b: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
    
    partials_out: out PARTIALS_ARRAY(0 to PARTIALS_TO_REDUCE-1)
  );
end partials_generator;

architecture Behavioral of partials_generator is
    component radix4_generator is
      Port (
        data_a: in STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
        window: in STD_LOGIC_VECTOR(2 downto 0);
        
        data_out: out STD_LOGIC_VECTOR(DATA_SIZE downto 0)
      );
    end component;
    signal partials: PARTIALS_ARRAY(0 to PARTIALS_TO_REDUCE-1);

    signal b: STD_LOGIC_VECTOR(DATA_SIZE+RADIX_WINDOW_SIZE downto 0);
begin
    b(DATA_SIZE-1 downto 0) <= data_b;
    sign_extension: for i in 0 to (RADIX_WINDOW_SIZE) generate 
        b(DATA_SIZE+i) <= '0';
    end generate;
    
    radix4: if (RADIX_WINDOW_SIZE=2) generate 
        partial_windows: for r in 0 to (PARTIALS_TO_REDUCE-1) generate 
            constant WINDOW_BASE: integer := r*(RADIX_WINDOW_SIZE+1);
            constant WINDOW_END: integer := window_base+RADIX_WINDOW_SIZE+1; 
            constant PARTIAL_OUT_BASE: integer := r*(RADIX_WINDOW_SIZE+1); 
            constant PARTIAL_OUT_END: integer := PARTIAL_OUT_BASE +(DATA_SIZE+RADIX_MAX_SHIFT);
            
            signal partial_out: STD_LOGIC_VECTOR ((DATA_SIZE + RADIX_MAX_SHIFT)-1 downto 0);
            begin 
            
                partial_generator: radix4_generator 
                        port map(
                            data_a => data_a,
                            window => b(WINDOW_END-1 downto WINDOW_BASE),
                            data_out => partial_out
                        );
                
                partial_touting: for c in 0 to (DATA_SIZE+RADIX_MAX_SHIFT-1) generate 
                    constant PARTIALS_C_COORDINATE: integer := c+ PARTIAL_OUT_BASE;
                    constant DATA_ALIGN_SHIFT: integer := 0 when (PARTIALS_C_COORDINATE<(DATA_SIZE + RADIX_MAX_SHIFT)) else (((PARTIALS_C_COORDINATE-DATA_SIZE-RADIX_MAX_SHIFT)+RADIX_WINDOW_SIZE+)/RADIX_WINDOW_SIZE);
                    begin 
                        partials_out(r-DATA_ALIGN_SHIFT)(PARTIALS_C_COORDINATE)<=partial_out(c);
                end generate; 
        end generate; 
    end generate;
end Behavioral;

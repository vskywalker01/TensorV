library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.PARTIAL_TYPES.ALL;

entity multiplier_stage1_tb is
end multiplier_stage1_tb;

architecture Behavioral of multiplier_stage1_tb is
  component multiplier_stage1 is
      Port ( 
        data_a: in STD_LOGIC_VECTOR(63 downto 0);
        data_b: in STD_LOGIC_VECTOR(63 downto 0);
        
        partials_out: out PARTIALS(0 to 18);
        
        clk: in STD_LOGIC;
        reset: in STD_LOGIC
      );
    end component;
    signal data_a: STD_LOGIC_VECTOR(63 downto 0);
    signal data_b: STD_LOGIC_VECTOR(63 downto 0);
    signal partials_out: PARTIALS(0 to 18);
    signal clk,reset: STD_LOGIC;
begin
    ms1: multiplier_stage1
        port map (
            data_a => data_a,
            data_b => data_b,
            partials_out => partials_out,
            clk => clk,
            reset => reset
        );
    clock: process
    begin 
        while true loop
            clk <= '1';
            wait for 5ns;
            clk <= '0';
            wait for 5ns; 
        end loop; 
    end process;
    
    test: process 
    begin 
        reset <= '0';
        wait for 30ns;
        reset <= '1';
        data_a <= x"0000000000001234";
        data_b <= x"0000000000450020";
        wait for 100ns;
        
    end process;

end Behavioral;

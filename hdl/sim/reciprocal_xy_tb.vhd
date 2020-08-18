---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee_proposed;                      
use ieee_proposed.fixed_float_types.all; 
use ieee_proposed.fixed_pkg.all;         

library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity reciprocal_xy_tb is
end reciprocal_xy_tb;

------------------
-- Architecture --
------------------
architecture testbench of reciprocal_xy_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                        : time     := 10 ns; -- 100 MHz
    
    constant INPUT_WIDTH                       : positive := 10;
    constant RECIPROCAL_INTEGER_PART           : natural  := 1;
    constant RECIPROCAL_FRAC_PART              : integer  := -10;
    constant RECIPROCAL_NB_ITERATIONS          : positive := 11;

    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';

    signal strb_i                              : std_logic := '0';
    signal x_i                                 : std_logic_vector((INPUT_WIDTH - 1) downto 0);
    signal y_i                                 : std_logic_vector((INPUT_WIDTH - 1) downto 0);

    signal strb_o                              : std_logic := '0';
    signal reciprocal_xy                       : sfixed(RECIPROCAL_INTEGER_PART downto RECIPROCAL_FRAC_PART);
   
begin

    -- clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
   end process;

   UUT: entity work.reciprocal_xy 
   generic map (
       INPUT_WIDTH                          => INPUT_WIDTH,
       RECIPROCAL_INTEGER_PART              => RECIPROCAL_INTEGER_PART,
       RECIPROCAL_FRAC_PART                 => RECIPROCAL_FRAC_PART,
       RECIPROCAL_NB_ITERATIONS             => RECIPROCAL_NB_ITERATIONS
    )
    port map(
        -- Clock interface
        clock_i                             => clk,
        areset_i                            => areset,

        -- Input interface
        strb_i                              => strb_i,
        x_i                                 => x_i,
        y_i                                 => y_i,
         
        -- Output interface
        strb_o                              => strb_o,
        reciprocal_xy_o                     => reciprocal_xy
    );

    stim_proc : process
    begin
        areset <= '1';
        strb_i <= '0';
        
        for I in 0 to 3 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;
        
        areset <= '0';

        for I in 1 to 1000 loop

            strb_i      <= '1';
            x_i         <=  std_logic_vector(to_unsigned( 1, INPUT_WIDTH )); 
            y_i         <=  std_logic_vector(to_unsigned( I, INPUT_WIDTH ));

            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;
        
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';

        wait;
    end process;

end testbench;
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
use work.sim_input_pkg.all;

------------
-- Entity --
------------

entity phase_adjust_tb is
end phase_adjust_tb;

------------------
-- Architecture --
------------------
architecture testbench of phase_adjust_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant    CLK_PERIOD                        : time     := 10 ns; -- 100 MHz
    
    -- Behavioral 
    --constant    PHASE_INTEGER_PART              : natural  := 4;
    --constant    PHASE_FRAC_PART                 : integer  := -27;
    --constant    NB_POINTS_WIDTH                 : positive := 13;
    constant    SIDEBAND_WIDTH                  : natural := 0;
    constant    FACTOR                          : positive := 3;

    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';
    
    signal valid_i                              : std_logic; -- Valid in
    signal phase_in                            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal nb_cycles_in                        : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal sideband_data_i                     : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal valid_o                              : std_logic; -- Valid in
    signal phase_out                           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal nb_cycles_out                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_rept_out_o                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    
begin

    -- clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
   end process;

   UUT: entity work.phase_adjust
    generic map (
        PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
        PHASE_FRAC_PART                     => PHASE_FRAC_PART,
        NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
        FACTOR                              => FACTOR,
        SIDEBAND_WIDTH                      => SIDEBAND_WIDTH
    )
    port map(
        -- Clock interface
        clock_i                             => clk,
        areset_i                            => areset,

        -- Input interface
        valid_i                              => valid_i,
        phase_in_i                          => phase_in,
        nb_cycles_in_i                      => nb_cycles_in,
        
        -- Sideband interface
        sideband_data_i                     => sideband_data_i,
        sideband_data_o                     => open,
        
        -- Output interface
        valid_o                              => valid_o,
        phase_out_o                         => phase_out,
        nb_cycles_out_o                     => nb_cycles_out,
        nb_rept_out_o                       => nb_rept_out_o
    );

    stim_proc : process
    begin
        areset <= '1';
        valid_i <= '0';
        
        for I in 0 to 3 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;
        
        areset <= '0';
        valid_i <= '1';

        -- Inputs --
        phase_in        <=  to_ufixed(         SIM_INPUT_PHASE_TERM            , phase_in        ); 
        nb_cycles_in    <=  std_logic_vector(  to_unsigned( SIM_INPUT_NBPOINTS , NB_POINTS_WIDTH ) ); 
        -- Inputs --
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        valid_i <= '0';

        wait;
        
    end process;

end testbench;
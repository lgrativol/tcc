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

entity hh_win_tb is
end hh_win_tb;

------------------
-- Architecture --
------------------
architecture testbench of hh_win_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant    CLK_PERIOD                        : time     := 10 ns; -- 100 MHz
    
    -- Behavioral 
    constant    WIN_PHASE_INTEGER_PART             : natural  := PHASE_INTEGER_PART;
    constant    WIN_PHASE_FRAC_PART                : integer  := PHASE_FRAC_PART;
    constant    HH_INTEGER_PART                    : positive := 1;
    constant    HH_FRAC_PART                       : integer  := -15;
    constant    HH_NB_ITERATIONS                   : positive := 10;          
    
    -- Phase term generation 
    constant    TWO_PI                             : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART) := resize( (2.0 * PI) ,
                                                                                                                    WIN_PHASE_INTEGER_PART,
                                                                                                                    WIN_PHASE_FRAC_PART);

    constant    SYSTEM_FREQUENCY                    : positive  := 100e6;
    constant    TARGET_FREQUENCY                    : positive  := 500e3;
    constant    NB_CYCLES                           : positive  := 1;   
    
    -- Write txt
    -- constant    CORDIC_OUTPUT_WIDTH               : positive := ( );

    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';

    signal strb_i                              : std_logic := '0';
    signal phase_term                          : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);  

    signal restart_cycles                      : std_logic;

    signal done_cycles                         : std_logic;

    signal strb_o                              : std_logic := '0';
    signal hh_result                           : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);

    -- Simulation
    --signal write_data_in                       : std_logic_vector((CORDIC_OUTPUT_WIDTH - 1) downto 0);
    
begin

    -- clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
   end process;

   UUT: entity work.hh_win
    generic map(
        HH_MODE                            => "HAMM", -- or HAMM
        WIN_PHASE_INTEGER_PART             => WIN_PHASE_INTEGER_PART,
        WIN_PHASE_FRAC_PART                => WIN_PHASE_FRAC_PART,
        HH_INTEGER_PART                    => HH_INTEGER_PART,
        HH_FRAC_PART                       => HH_FRAC_PART,
        HH_NB_ITERATIONS                   => HH_NB_ITERATIONS
   )
    port map(
        -- Clock interface
        clock_i                             => clk,
        areset_i                            => areset,

        -- Input interface
        strb_i                              => strb_i,
        phase_term_i                        => phase_term,
        restart_cycles_i                    => restart_cycles,
        
        -- Output interface
        strb_o                              => strb_o,
        hh_result_o                         => hh_result
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
        strb_i <= '1';
        restart_cycles  <= '0';

        -- Inputs --
        phase_term <= resize(  TWO_PI * ( real(TARGET_FREQUENCY) / real(SYSTEM_FREQUENCY) )*  (1.0/ real(NB_CYCLES)),phase_term);
        -- Inputs --
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));

        wait;
        
    end process;

    -- Simulation 
    
    --write_data_in <= to_slv(sine_phase);

    --write2file : entity work.sim_write2file
    --    generic map (
    --        FILE_NAME    => "./output.txt", 
    --        INPUT_WIDTH  => CORDIC_OUTPUT_WIDTH
    --    )
    --    port map (
    --        clock           => clk,
    --        hold            => '0',
    --        data_valid      => strb_o,
    --        data_in         => write_data_in
    --    ); 

end testbench;
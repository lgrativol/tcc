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

entity dds_cordic_win_tb is
end dds_cordic_win_tb;

------------------
-- Architecture --
------------------
architecture testbench of dds_cordic_win_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                        : time     := 10 ns; -- 100 MHz
    
    -- Write txt
    constant CORDIC_OUTPUT_WIDTH               : positive := (N_CORDIC_ITERATIONS );

    --constant PHASE_INTEGER_PART                : natural  :=   4;
    --constant PHASE_FRAC_PART                   : integer  := -27;
    --constant CORDIC_INTEGER_PART               : natural  :=   1; 
    --constant CORDIC_FRAC_PART                  : integer  := -19;
    --constant N_CORDIC_ITERATIONS               : natural  :=  21;
    --constant NB_POINTS_WIDTH                   : natural  :=  10;  
    constant MODE_TIME                         : boolean  := SIM_INPUT_MODE_TIME;
    constant WIN_MODE                          : string   := SIM_INPUT_WIN_MODE; -- or "HAMM"
    constant WIN_INTEGER_PART                  : positive := 1;
    constant WIN_FRAC_PART                     : integer  := -19;
    constant WIN_NB_ITERATIONS                 : positive := 21;  

    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';

    signal strb_i                              : std_logic := '0';
    signal phase_term                          : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal window_term                         : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal nb_points                           : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_repetitions                      : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal initial_phase                       : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal restart_cycles                      : std_logic;

    signal strb_o                              : std_logic := '0';
    signal sine_win_phase                      : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    -- Simulation
    signal sim_sine_strb_o                     : std_logic := '0';
    signal sim_sine_phase_o                    : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    signal sim_win_strb_o                      : std_logic := '0';
    signal sim_win_result_o                    : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    signal write_data_in                       : std_logic_vector((CORDIC_OUTPUT_WIDTH - 1) downto 0);
    signal write_sine_data_in                  : std_logic_vector((CORDIC_OUTPUT_WIDTH - 1) downto 0);
    signal write_win_data_in                   : std_logic_vector((CORDIC_OUTPUT_WIDTH - 1) downto 0);
    
begin

    -- clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    UUT: entity work.dds_cordic_win
        generic map(
            PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                    => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS                 => N_CORDIC_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            MODE_TIME                           => MODE_TIME,
            WIN_MODE                            => WIN_MODE,
            WIN_INTEGER_PART                    => WIN_INTEGER_PART,
            WIN_FRAC_PART                       => WIN_FRAC_PART,
            WIN_NB_ITERATIONS                   => WIN_NB_ITERATIONS  
        )
        port map(
            -- Clock interface
            clock_i                             => clk,
            areset_i                            => areset,
    
            -- Input interface
            strb_i                              => strb_i,
            phase_term_i                        => phase_term,
            window_term_i                       => window_term,
            initial_phase_i                     => initial_phase,
            nb_points_i                         => nb_points,
            nb_repetitions_i                    => nb_repetitions,
            restart_cycles_i                    => restart_cycles, 
            
            -- Output interface
            strb_o                              => strb_o,
            sine_win_phase_o                    => sine_win_phase,
            
            -- Debug only interface
            sine_strb_o                         => sim_sine_strb_o,
            sine_phase_o                        => sim_sine_phase_o,
            
            win_result_strb_o                   => sim_win_strb_o,
            win_result_o                        => sim_win_result_o
        );

    stim_proc : process
    begin
        areset <= '1';
        strb_i <= '0';
        
        for I in 0 to 3 loop
            wait for CLK_PERIOD;
            wait until ( rising_edge(clk) );
        end loop;
        
        areset <= '0';
        strb_i <= '1';
        restart_cycles  <= '0';

        -- Inputs --
        phase_term      <=  to_ufixed(         SIM_INPUT_PHASE_TERM            , phase_term        ); 
        window_term     <=  to_ufixed(         SIM_INPUT_WIN_TERM              , window_term       ); 
        nb_points       <=  std_logic_vector(  to_unsigned( SIM_INPUT_NBPOINTS , NB_POINTS_WIDTH ) ); 
        nb_repetitions  <=  std_logic_vector(  to_unsigned( SIM_INPUT_NBREPET  , NB_POINTS_WIDTH ) ); 
        initial_phase   <=  to_ufixed(         SIM_INPUT_INIT_PHASE            , initial_phase     );
        -- Inputs --
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));

        wait;
        
    end process;

    -- Simulation 
    
    write_data_in <= to_slv(sine_win_phase);

    write2file : entity work.sim_write2file
        generic map (
            FILE_NAME    => "./output_sine_win.txt", 
            INPUT_WIDTH  => CORDIC_OUTPUT_WIDTH
        )
        port map (
            clock           => clk,
            hold            => '0',
            data_valid      => strb_o,
            data_in         => write_data_in
        ); 

    write_sine_data_in <= to_slv(sim_sine_phase_o);

    write2file_sine : entity work.sim_write2file
        generic map (
            FILE_NAME    => "./output_sine.txt", 
            INPUT_WIDTH  => CORDIC_OUTPUT_WIDTH
        )
        port map (
            clock           => clk,
            hold            => '0',
            data_valid      => sim_sine_strb_o,
            data_in         => write_sine_data_in
        ); 
    write_win_data_in <= to_slv(sim_win_result_o);

    write2file_win : entity work.sim_write2file
        generic map (
            FILE_NAME    => "./output_win.txt", 
            INPUT_WIDTH  => CORDIC_OUTPUT_WIDTH
        )
        port map (
            clock           => clk,
            hold            => '0',
            data_valid      => sim_win_strb_o,
            data_in         => write_win_data_in
        ); 

end testbench;
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
use work.sim_input_pkg.all;

------------
-- Entity --
------------

entity dds_cordic_tb is
end dds_cordic_tb;

------------------
-- Architecture --
------------------
architecture testbench of dds_cordic_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                        : time     := 10 ns; -- 100 MHz
       
    -- Phase accumulator phase 
    constant PHASE_INTEGER_PART                : natural  := 4; 
    constant PHASE_FRAC_PART                   : integer  := -27; 
    constant PHASE_WIDTH                       : positive := PHASE_INTEGER_PART + (-PHASE_FRAC_PART) + 1;

    constant NB_POINTS_WIDTH                   : positive := 10;
    constant NB_REPT_WIDTH                     : positive := 10;

    -- Cordic
    constant CORDIC_INTEGER_PART               : natural  := 1;
    constant N_CORDIC_ITERATIONS               : natural  := 10;
    constant CORDIC_FRAC_PART                  : integer  := -(N_CORDIC_ITERATIONS - (CORDIC_INTEGER_PART + 1));
    
    -- Write txt
    constant CORDIC_OUTPUT_WIDTH               : positive := (N_CORDIC_ITERATIONS );

    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';

    signal valid_i                             : std_logic := '0';
    signal phase_term                          : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal nb_points                           : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_repetitions                      : std_logic_vector((NB_REPT_WIDTH - 1) downto 0);
    signal initial_phase                       : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal mode_time                           : std_logic;

    signal restart_cycles                      : std_logic;

    signal done_cycles                         : std_logic;

    signal valid_o                             : std_logic := '0';
    signal sine_phase                          : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal cos_phase                           : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal flag_full_cycle                     : std_logic;

    -- Simulation
    signal write_data_in                       : std_logic_vector((CORDIC_OUTPUT_WIDTH - 1) downto 0);
    
begin
    ------------
    -- Clock  --
    ------------

    clk_process :process
    begin
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
    end process;

    ---------
    -- UUT --
    ---------

    UUT: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                    => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS                 => N_CORDIC_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => NB_REPT_WIDTH,
            EN_POSPROC                          => TRUE
        )
        port map(
            -- Clock interface
            clock_i                             => clk,  
            areset_i                            => areset,
    
            -- Input interface
            valid_i                             => valid_i,
            phase_term_i                        => phase_term,
            initial_phase_i                     => initial_phase,
            nb_points_i                         => nb_points,
            nb_repetitions_i                    => nb_repetitions,
            mode_time_i                         => mode_time,
           
            -- Control interface
            restart_cycles_i                    => restart_cycles,
            
            -- Output interface
            valid_o                             => valid_o,
            sine_phase_o                        => sine_phase,
            cos_phase_o                         => cos_phase,
            done_cycles_o                       => done_cycles,
            flag_full_cycle_o                   => flag_full_cycle
        );

    --------------
    -- Stimulus --
    --------------

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
        restart_cycles  <= '0';

        -- Inputs --
        phase_term      <=  to_ufixed(         SIM_INPUT_PHASE_TERM            , phase_term        ); 
        nb_points       <=  std_logic_vector(  to_unsigned( SIM_INPUT_NBPOINTS , NB_POINTS_WIDTH ) ); 
        nb_repetitions  <=  std_logic_vector(  to_unsigned( SIM_INPUT_NBREPET  , NB_REPT_WIDTH   ) ); 
        initial_phase   <=  to_ufixed(         SIM_INPUT_INIT_PHASE            , initial_phase     );
        mode_time       <= SIM_INPUT_MODE_TIME;
        -- Inputs --
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        valid_i <= '0';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));

        wait;
        
    end process;

    --------------------
    -- To file output --
    --------------------
    
    write_data_in <= to_slv(sine_phase);

    write2file : entity work.sim_write2file
        generic map (
            FILE_NAME    => "./output_dds_cordic_sine.txt", 
            INPUT_WIDTH  => CORDIC_OUTPUT_WIDTH
        )
        port map (
            clock           => clk,
            hold            => '0',
            data_valid      => valid_o,
            data_in         => write_data_in
        ); 

end testbench;
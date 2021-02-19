---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ieee_proposed;                      
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;         

library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity double_driver is
    generic(
        PHASE_INTEGER_PART                  : natural;
        PHASE_FRAC_PART                     : integer;
        CORDIC_INTEGER_PART                 : integer; 
        CORDIC_FRAC_PART                    : integer;
        N_CORDIC_ITERATIONS                 : natural;
        NB_POINTS_WIDTH                     : natural;  
        NB_REPT_WIDTH                       : natural;  
        EN_POSPROC                          : boolean
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Valid in
        phase_term_i                        : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
        initial_phase_i                     : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); 
        nb_points_i                         : in  std_logic_vector( (NB_POINTS_WIDTH - 1) downto 0);
        nb_repetitions_i                    : in  std_logic_vector( (NB_REPT_WIDTH - 1) downto 0);  
        mode_time_i                         : in  std_logic;

        -- Control Interface
        tx_time_i                           : in  std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
        tx_off_time_i                       : in  std_logic_vector(( DEADZONE_TIME_WIDTH - 1) downto 0);
        rx_time_i                           : in  std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
        off_time_i                          : in  std_logic_vector(( IDLE_TIME_WIDTH - 1) downto 0);
        
        -- Output driver A interface
        A_valid_o                           : out std_logic;
        A_sine_phase_o                      : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        A_done_cycles_o                     : out std_logic;
        A_flag_full_cycle_o                 : out std_logic;
        
        -- Output driver B interface
        B_valid_o                           : out std_logic;
        B_sine_phase_o                      : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        B_done_cycles_o                     : out std_logic;
        B_flag_full_cycle_o                 : out std_logic;

        -- Output Control
        end_zones_cycle_o                   : out std_logic
    );
end double_driver;

------------------
-- Architecture --
------------------
architecture behavioral of double_driver is

    -------------
    -- Signals --
    -------------

    -- Stage 1 Control
    signal control_valid_i                      : std_logic;
    signal control_tx_time                      : std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
    signal control_tx_off_time                  : std_logic_vector(( DEADZONE_TIME_WIDTH - 1) downto 0);
    signal control_rx_time                      : std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
    signal control_off_time                     : std_logic_vector(( IDLE_TIME_WIDTH - 1) downto 0);
    signal control_output_valid                  : std_logic;

    signal control_restart_cycles               : std_logic;
    signal control_end_zones_cycle              : std_logic;

    -- Stage 2 Driver A
    signal driver_a_valid_i                     : std_logic;
    signal driver_a_phase_term                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal driver_a_nb_points                   : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal driver_a_nb_repetitions              : std_logic_vector((NB_REPT_WIDTH - 1) downto 0);
    signal driver_a_initial_phase               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal driver_a_restart_cycles              : std_logic;
    
    signal driver_a_valid_o                     : std_logic;
    signal driver_a_sine_phase                  : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal driver_a_done_cycles                 : std_logic;
    signal driver_a_flag_full_cycle             : std_logic;

    -- Stage 2 Driver B
    signal driver_b_valid_i                     : std_logic;
    signal driver_b_phase_term                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal driver_b_nb_points                   : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal driver_b_nb_repetitions              : std_logic_vector((NB_REPT_WIDTH - 1) downto 0);
    signal driver_b_initial_phase               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal driver_b_restart_cycles              : std_logic;
    signal driver_b_mode_time                   : std_logic;
    
    signal driver_b_valid_o                     : std_logic;
    signal driver_b_sine_phase                  : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal driver_b_done_cycles                 : std_logic;
    signal driver_b_flag_full_cycle             : std_logic;

begin

    -------------
    -- Stage 1 --
    -------------

    control_valid_i       <=   valid_i;
    control_tx_time       <=   tx_time_i;
    control_tx_off_time   <=   tx_off_time_i;
    control_rx_time       <=   rx_time_i;
    control_off_time      <=   off_time_i;
    control_output_valid  <=   driver_b_valid_o;

    stage_1_control: entity work.fsm_time_zones
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,

            -- Input interface
            valid_i                              => control_valid_i,
            tx_time_i                           => control_tx_time,
            tx_off_time_i                       => control_tx_off_time,
            rx_time_i                           => control_rx_time,
            off_time_i                          => control_off_time,
            output_valid_i                       => control_output_valid,
            
            -- Control Interface
            restart_cycles_o                    => control_restart_cycles,
            end_zones_cycle_o                   => control_end_zones_cycle
        );

    ----------------------
    -- Stage 2 Driver A --
    ----------------------

    driver_a_valid_i         <= valid_i;
    driver_a_phase_term     <= phase_term_i;
    driver_a_nb_points      <= nb_points_i;
    driver_a_nb_repetitions <= nb_repetitions_i;
    driver_a_initial_phase  <= (others => '0');
    driver_a_restart_cycles <= control_restart_cycles;

    stage_2_driver_a: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                    => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS                 => N_CORDIC_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => NB_REPT_WIDTH,
            EN_POSPROC                          => FALSE
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            valid_i                              => driver_a_valid_i,
            phase_term_i                        => driver_a_phase_term,
            initial_phase_i                     => driver_a_initial_phase,
            nb_points_i                         => driver_a_nb_points,
            nb_repetitions_i                    => driver_a_nb_repetitions,
            mode_time_i                         => '0', -- Forced FALSE
           
            -- Control interface
            restart_cycles_i                    => driver_a_restart_cycles,
            
            -- Output interface
            valid_o                              => driver_a_valid_o,
            sine_phase_o                        => driver_a_sine_phase,
            cos_phase_o                         => open,
            done_cycles_o                       => driver_a_done_cycles,
            flag_full_cycle_o                   => driver_a_flag_full_cycle
        );
        
    ----------------------
    -- Stage 2 Driver B --
    ----------------------

    driver_b_valid_i         <= valid_i;
    driver_b_phase_term     <= phase_term_i;
    driver_b_nb_points      <= nb_points_i;
    driver_b_nb_repetitions <= nb_repetitions_i;
    driver_b_initial_phase  <= initial_phase_i;
    driver_b_mode_time      <= mode_time_i;
    driver_b_restart_cycles <= control_restart_cycles;

    stage_2_driver_b: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                    => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS                 => N_CORDIC_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => NB_REPT_WIDTH,
            EN_POSPROC                          => FALSE
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            valid_i                              => driver_b_valid_i,
            phase_term_i                        => driver_b_phase_term,
            initial_phase_i                     => driver_b_initial_phase,
            nb_points_i                         => driver_b_nb_points,
            nb_repetitions_i                    => driver_b_nb_repetitions,
            mode_time_i                         => driver_b_mode_time,
           
            -- Control interface
            restart_cycles_i                    => driver_b_restart_cycles,
            
            -- Output interface
            valid_o                              => driver_b_valid_o,
            sine_phase_o                        => driver_b_sine_phase,
            cos_phase_o                         => open,
            done_cycles_o                       => driver_b_done_cycles,
            flag_full_cycle_o                   => driver_b_flag_full_cycle
        );

    ------------
    -- Output --
    ------------
   
    -- Output driver A interface
    A_valid_o                            <= driver_a_valid_o;
    A_sine_phase_o                      <= driver_a_sine_phase;
    A_done_cycles_o                     <= driver_a_done_cycles;
    A_flag_full_cycle_o                 <= driver_a_flag_full_cycle;
    
    -- Output driver B interface
    B_valid_o                            <= driver_b_valid_o;
    B_sine_phase_o                      <=              driver_b_sine_phase     when (driver_b_valid_o = '1') -- Idle mode => output = 0
                                                else    (others => '0');     -- TODO: check output register need (probably a yes)
    B_done_cycles_o                     <= driver_b_done_cycles;
    B_flag_full_cycle_o                 <= driver_b_flag_full_cycle;

    end_zones_cycle_o                   <= control_end_zones_cycle;

end behavioral;
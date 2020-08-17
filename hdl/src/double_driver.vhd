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
        SYSTEM_FREQUENCY                    : positive := 100E6, -- 100 MHz
        MODE_TIME                           : boolean  := FALSE
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        target_frequency_i                  : in  std_logic_vector((ceil_log2(SYSTEM_FREQUENCY + 1) - 1) downto 0);
        nb_cycles_i                         : in  std_logic_vector((NB_CYCLES_WIDTH - 1) downto 0);
        phase_diff_i                        : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  

        -- Control Interface
        tx_time_i                           : in  std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
        tx_off_time_i                       : in  std_logic_vector(( TX_OFF_TIME_WIDTH - 1) downto 0);
        rx_time_i                           : in  std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
        off_time_i                          : in  std_logic_vector(( OFF_TIME_WIDTH - 1) downto 0);
        
        -- Output driver A interface
        A_strb_o                            : out std_logic;
        A_sine_phase_o                      : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        A_done_cycles_o                     : out std_logic;
        A_flag_full_cycle_o                 : out std_logic;
        
        -- Output driver B interface
        B_strb_o                            : out std_logic;
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

    ---------------
    -- Constants --
    ---------------
    constant    FREQUENCY_WIDTH     : positive := target_frequency_i'length;

    -------------
    -- Signals --
    -------------

    -- Control
    signal control_strb_i                       : std_logic;
    signal control_tx_time                      : std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
    signal control_tx_off_time                  : std_logic_vector(( TX_OFF_TIME_WIDTH - 1) downto 0);
    signal control_rx_time                      : std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
    signal control_off_time                     : std_logic_vector(( OFF_TIME_WIDTH - 1) downto 0);
    signal control_output_strb                  : std_logic;

    signal control_restart_cycles               : std_logic;
    signal control_end_zones_cycle              : std_logic;

    -- Driver A

    signal driver_a_strb_i                      : std_logic;
    signal driver_a_target_freq                 : std_logic_vector((FREQUENCY_WIDTH - 1) downto 0);
    signal driver_a_nb_cycles                   : std_logic_vector((NB_CYCLES_WIDTH - 1) downto 0);
    signal driver_a_phase_diff                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    
    signal driver_a_restart_cycles              : std_logic;
    
    signal driver_a_strb_o                      : std_logic;
    signal driver_a_sine_phase                  : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal driver_a_done_cycles                 : std_logic;
    signal driver_a_flag_full_cycle             : std_logic;

    -- Driver B
    signal driver_b_strb_i                      : std_logic;
    signal driver_b_target_freq                 : std_logic_vector((FREQUENCY_WIDTH - 1) downto 0);
    signal driver_b_nb_cycles                   : std_logic_vector((NB_CYCLES_WIDTH - 1) downto 0);
    signal driver_b_phase_diff                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    
    signal driver_b_restart_cycles              : std_logic;
    
    signal driver_b_strb_o                      : std_logic;
    signal driver_b_sine_phase                  : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal driver_b_done_cycles                 : std_logic;
    signal driver_b_flag_full_cycle             : std_logic;

begin

    -------------
    -- Stage 1 --
    -------------

    control_strb_i        <=   strb_i;
    control_tx_time       <=   tx_time_i;
    control_tx_off_time   <=   tx_off_time_i;
    control_rx_time       <=   rx_time_i;
    control_off_time      <=   off_time_i;
    control_output_strb   <=   driver_a_strb_o;

    stage_1_control: entity work.fsm_time_zones
    generic map(
        SYSTEM_FREQUENCY                    => SYSTEM_FREQUENCY
    )
    port map(
        -- Clock interface
        clock_i                             => clock_i,
        areset_i                            => areset_i,

        -- Input interface
        strb_i                              => control_strb_i,
        tx_time_i                           => control_tx_time,
        tx_off_time_i                       => control_tx_off_time,
        rx_time_i                           => control_rx_time,
        off_time_i                          => control_off_time,
        output_strb_i                       => control_output_strb,
        
        -- Control Interface
        restart_cycles_o                    => control_restart_cycles,
        end_zones_cycle_o                   => control_end_zones_cycle
    );

    --------------
    -- Driver A --
    --------------

    driver_a_strb_i         <= strb_i;
    driver_a_target_freq    <= target_frequency_i;
    driver_a_nb_cycles      <= nb_cycles_i;
    driver_a_phase_diff     <= (others => '0');
    driver_a_restart_cycles <= control_restart_cycles;

    driver_a : entity work.dds_cordic
        generic map (
            SYSTEM_FREQUENCY                    => SYSTEM_FREQUENCY,
            MODE_TIME                           => FALSE
        )
        port map(
            clock_i                             => clock_i,  
            areset_i                            => areset_i,

            strb_i                              => driver_a_strb_i,
            target_frequency_i                  => driver_a_target_freq,
            nb_cycles_i                         => driver_a_nb_cycles,
            phase_diff_i                        => driver_a_phase_diff,
            restart_cycles_i                    => driver_a_restart_cycles,

            strb_o                              => driver_a_strb_o,
            sine_phase_o                        => driver_a_sine_phase,
            done_cycles_o                       => driver_a_done_cycles,
            flag_full_cycle_o                   => driver_a_flag_full_cycle

        );

    --------------
    -- Driver B --
    --------------
    
    driver_b_strb_i         <= strb_i;
    driver_b_target_freq    <= target_frequency_i;
    driver_b_nb_cycles      <= nb_cycles_i;
    driver_b_phase_diff     <= phase_diff_i;
    driver_b_restart_cycles <= control_restart_cycles;

    driver_b : entity work.dds_cordic
        generic map (
            SYSTEM_FREQUENCY                    => SYSTEM_FREQUENCY,
            MODE_TIME                           => MODE_TIME
        )
        port map(
            clock_i                             => clock_i,  
            areset_i                            => areset_i,

            strb_i                              => driver_b_strb_i,
            target_frequency_i                  => driver_b_target_freq,
            nb_cycles_i                         => driver_b_nb_cycles,
            phase_diff_i                        => driver_b_phase_diff,
            restart_cycles_i                    => driver_b_restart_cycles,

            strb_o                              => driver_b_strb_o,
            sine_phase_o                        => driver_b_sine_phase,
            done_cycles_o                       => driver_b_done_cycles,
            flag_full_cycle_o                   => driver_b_flag_full_cycle        
        );

    ------------
    -- Output --
    ------------
   
    -- Output driver A interface
    A_strb_o                            <= driver_a_strb_o;
    A_sine_phase_o                      <= driver_a_sine_phase;
    A_done_cycles_o                     <= driver_a_done_cycles;
    A_flag_full_cycle_o                 <= driver_a_flag_full_cycle;
    
    -- Output driver B interface
    B_strb_o                            <= driver_b_strb_o;
    B_sine_phase_o                      <=              driver_b_sine_phase     when (driver_b_strb_o = '1') -- Idle mode => output = 0
                                                else    (others => '0');     -- TODO: check output register need (probably a yes)
    B_done_cycles_o                     <= driver_b_done_cycles;
    B_flag_full_cycle_o                 <= driver_b_flag_full_cycle;

    end_zones_cycle_o                   <= control_end_zones_cycle;

end behavioral;
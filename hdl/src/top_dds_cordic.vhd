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

entity top_dds_cordic is
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
        restart_cycles_i                    : in  std_logic;
        done_cycles_o                       : out std_logic;

        -- Output interface
        strb_o                              : out std_logic;
        sine_phase_o                        : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        flag_full_cycle_o                   : out std_logic
    );
end top_dds_cordic;

------------------
-- Architecture --
------------------
architecture behavioral of top_dds_cordic is

    ---------------
    -- Constants --
    ---------------
    constant    FREQUENCY_WIDTH     : positive := target_frequency_i'length;
    constant    CORDIC_FACTOR       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART) := to_sfixed( (0.607253) , CORDIC_INTEGER_PART, CORDIC_FRAC_PART);

    -------------
    -- Signals --
    -------------
  
    -- Stage 1 DDS Cordic
    signal      dds_cordic_strb_i               : std_logic;
    signal      dds_cordic_target_freq          : std_logic_vector( (FREQUENCY_WIDTH - 1) downto 0);
    signal      dds_cordic_nb_cycles            : std_logic_vector((NB_CYCLES_WIDTH - 1) downto 0);
    signal      dds_cordic_phase_diff           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_cordic_restart_cycles       : std_logic;
   
    signal      dds_cordic_strb_o               : std_logic;
    signal      dds_cordic_sine_phase           : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      dds_cordic_done_cycles          : std_logic;
    signal      dds_cordic_flag_full_cycle      : std_logic;

begin

    -------------
    -- Stage 1 --
    -------------

    dds_cordic_strb_i               <= strb_i;
    dds_cordic_target_freq          <= target_frequency_i;
    dds_cordic_nb_cycles            <= nb_cycles_i;
    dds_cordic_phase_diff           <= phase_diff_i;
    dds_cordic_restart_cycles       <= restart_cycles_i;

    stage_2_dds_cordic: entity work.dds_cordic
        generic map(
            SYSTEM_FREQUENCY                    => SYSTEM_FREQUENCY,
            MODE_TIME                           => MODE_TIME
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i, 
    
            -- Input interface
            strb_i                              => dds_cordic_strb_i,
            target_frequency_i                  => dds_cordic_target_freq,
            nb_cycles_i                         => dds_cordic_nb_cycles,
            phase_diff_i                        => dds_cordic_phase_diff,
            restart_cycles_i                    => dds_cordic_restart_cycles,
            
            -- Output interface
            strb_o                              => dds_cordic_strb_o,
            sine_phase_o                        => dds_cordic_sine_phase,
            done_cycles_o                       => dds_cordic_done_cycles,
            flag_full_cycle_o                   => dds_cordic_flag_full_cycle
        );

    ------------
    -- Output --
    ------------
    strb_o              <= dds_cordic_strb_o;
    sine_phase_o        <= dds_cordic_sine_phase;
    done_cycles_o       <= dds_cordic_done_cycles;
    flag_full_cycle_o   <= dds_cordic_flag_full_cycle;

    end behavioral;

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.utils_pkg.all;

package wave_gen_index_pkg is

    ---------------
    -- Wave type --
    ---------------

    constant    TYPE_PULSER                     : std_logic_vector := x"1";
    constant    TYPE_CORDIC                     : std_logic_vector := x"2";

    ------------
    -- CORDIC --
    ------------
    constant    CORDIC_PHASE_WIDTH              : positive := PHASE_INTEGER_PART + (-PHASE_FRAC_PART + 1) ; --pkg
    constant    CORDIC_PHASE_TERM_START         : natural  := 0;
    constant    CORDIC_PHASE_TERM_END           : natural  := ( CORDIC_PHASE_TERM_START + (CORDIC_PHASE_WIDTH - 1) );

    constant    CORDIC_INIT_PHASE_WIDTH         : positive := CORDIC_PHASE_WIDTH; 
    constant    CORDIC_INIT_PHASE_START         : natural  := (CORDIC_PHASE_TERM_END + 1);
    constant    CORDIC_INIT_PHASE_END           : natural  := ( CORDIC_INIT_PHASE_START + (CORDIC_INIT_PHASE_WIDTH - 1) );
    
    constant    CORDIC_NB_POINTS_WIDTH          : positive := NB_POINTS_WIDTH; -- pkg
    constant    CORDIC_NB_POINTS_START          : natural  := (CORDIC_INIT_PHASE_END + 1);
    constant    CORDIC_NB_POINTS_END            : natural  := ( CORDIC_NB_POINTS_START + (CORDIC_NB_POINTS_WIDTH - 1) );  

    constant    CORDIC_NB_REPETITIONS_WIDTH     : positive := CORDIC_NB_POINTS_WIDTH; --TODO: separate points and repetitions
    constant    CORDIC_NB_REPETITIONS_START     : natural  := (CORDIC_NB_POINTS_END + 1);
    constant    CORDIC_NB_REPETITIONS_END       : natural  := ( CORDIC_NB_REPETITIONS_START + (CORDIC_NB_REPETITIONS_WIDTH - 1) ); 

    constant    CORDIC_MODE_TIME_WIDTH          : positive := 1;
    constant    CORDIC_MODE_TIME_START          : natural  := ( CORDIC_NB_REPETITIONS_END + 1 );
    constant    CORDIC_MODE_TIME_END            : natural  := ( CORDIC_MODE_TIME_START +  (CORDIC_MODE_TIME_WIDTH - 1) );
    
    ------------
    -- Pulser --
    ------------

    constant    PULSER_NB_REPETITIONS_WIDTH     : positive := NB_POINTS_WIDTH;
    constant    PULSER_NB_REPETITIONS_START     : natural  := 0;
    constant    PULSER_NB_REPETITIONS_END       : natural  := ( PULSER_NB_REPETITIONS_START + (PULSER_NB_REPETITIONS_WIDTH - 1) ); 

    constant    PULSER_TIMER_WIDTH              : positive := TIMER_WIDTH; --pkg
    constant    PULSER_T1_START                 : natural  := (PULSER_NB_REPETITIONS_END + 1);
    constant    PULSER_T1_END                   : natural  := ( PULSER_T1_START + (PULSER_TIMER_WIDTH - 1) );

    constant    PULSER_T2_START                 : natural  := ( PULSER_T1_END + 1 );
    constant    PULSER_T2_END                   : natural  := ( PULSER_T2_START + (PULSER_TIMER_WIDTH - 1) );

    constant    PULSER_T3_START                 : natural  := ( PULSER_T2_END + 1 );
    constant    PULSER_T3_END                   : natural  := ( PULSER_T3_START + (PULSER_TIMER_WIDTH - 1) );

    constant    PULSER_T4_START                 : natural  := ( PULSER_T3_END + 1 );
    constant    PULSER_T4_END                   : natural  := ( PULSER_T4_START  + (PULSER_TIMER_WIDTH - 1) );
    
    constant    PULSER_TDAMP_START              : natural  := ( PULSER_T4_END + 1 );
    constant    PULSER_TDAMP_END                : natural  := ( PULSER_TDAMP_START +  (PULSER_TIMER_WIDTH - 1) );

    constant    PULSER_INVERT_PULSER_WIDTH      : positive := 1;
    constant    PULSER_INVERT_PULSER_START      : natural  := ( PULSER_TDAMP_END + 1 );
    constant    PULSER_INVERT_PULSER_END        : natural  := ( PULSER_INVERT_PULSER_START +  (PULSER_INVERT_PULSER_WIDTH - 1) );
    
    constant    PULSER_TRIPLE_PULSER_WIDTH      : positive := 1;
    constant    PULSER_TRIPLE_PULSER_START      : natural  := ( PULSER_INVERT_PULSER_END + 1 );
    constant    PULSER_TRIPLE_PULSER_END        : natural  := ( PULSER_TRIPLE_PULSER_START +  (PULSER_TRIPLE_PULSER_WIDTH - 1) );

end wave_gen_index_pkg;

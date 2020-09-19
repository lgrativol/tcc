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

entity blackman_harris_win is
    generic( 
        WIN_PHASE_INTEGER_PART             : natural  := 0;
        WIN_PHASE_FRAC_PART                : integer  := -1;
        BLKH_INTEGER_PART                  : positive := 2;
        BLKH_FRAC_PART                     : integer  := -4;
        BLKH_NB_ITERATIONS                 : positive := 10;
        NB_POINTS_WIDTH                    : positive := 17             
   );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        phase_term_i                        : in  ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
        nb_points_i                         : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0 );
        restart_cycles_i                    : in  std_logic; 
        
        -- Output interface
        strb_o                              : out std_logic;
        blkh_result_o                       : out sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART)
    );
end blackman_harris_win;

------------------
-- Architecture --
------------------
architecture behavioral of blackman_harris_win is
    
    
    ---------------
    -- Constants --
    ---------------
    constant    CORDIC_FACTOR       : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART) := to_sfixed( (0.607253) , BLKH_INTEGER_PART, BLKH_FRAC_PART);
    constant    SIDEBAND_WIDTH      : natural  := 2;
    constant    DDS_WORD_WIDTH      : natural  := (BLKH_INTEGER_PART - BLKH_FRAC_PART + 1);
    
    -- Phase adjust
    constant    PHASE_FACTOR_A2     : positive := 2; -- From 2pi to 4Pi
    constant    PHASE_FACTOR_A3     : positive := 3; -- From 2pi to 6Pi

    -- Generic Shift
    constant    LATENCY             : positive := 2; -- Used because the phase adjust has 2 registers, sync a1 and a2 cos
    
    -- Windows constantss
    constant    WIN_A0                          : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART) := to_sfixed(0.35875 , BLKH_INTEGER_PART,BLKH_FRAC_PART );
    constant    WIN_A1                          : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART) := to_sfixed(0.48829 ,WIN_A0);   
    constant    WIN_A2                          : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART) := to_sfixed(0.14128 ,WIN_A0);   
    constant    WIN_A3                          : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART) := to_sfixed(0.01168 ,WIN_A0);   
    constant    WIN_MINUS_A1                    : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART) := resize(- WIN_A1 , WIN_A0);
    constant    WIN_MINUS_A3                    : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART) := resize(- WIN_A3 , WIN_A0);

    -------------
    -- Signals --
    -------------
    
    -- Stage 1 DDS a1
    signal      dds_2pi_strb_i                           : std_logic;
    signal      dds_2pi_phase_term                       : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_2pi_nb_points                        : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_2pi_nb_repetitions                   : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_2pi_initial_phase                    : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_2pi_restart_cycles                   : std_logic;
    
    signal      dds_2pi_strb_o                           : std_logic;
    signal      dds_2pi_cos_phase                        : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    -- Stage 2 Generic Shift DDS a1
    signal      dds_2pi_generic_shift_strb_i            : std_logic;
    signal      dds_2pi_generic_shift_input_data        : std_logic_vector((DDS_WORD_WIDTH - 1) downto 0);
    signal      dds_2pi_generic_shift_sideband_data_i   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal      dds_2pi_generic_shift_strb_o            : std_logic;
    signal      dds_2pi_generic_shift_output_data       : std_logic_vector((DDS_WORD_WIDTH - 1) downto 0);

    -- Stage 3 Phase adjust
    signal      phase_adjust_4pi_strb_i                 : std_logic;  
    signal      phase_adjust_4pi_phase_term             : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);    
    signal      phase_adjust_4pi_nb_points              : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_adjust_4pi_sideband_data_i        : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    
    signal      phase_adjust_4pi_strb_o                 : std_logic;
    signal      phase_adjust_4pi_phase_term_o           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      phase_adjust_4pi_nb_points_o            : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_adjust_4pi_nb_rept_o              : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);

    -- Stage 4 DDS a2
    signal      dds_4pi_strb_i                          : std_logic;
    signal      dds_4pi_phase_term                      : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_4pi_nb_points                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_4pi_nb_repetitions                  : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_4pi_initial_phase                   : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_4pi_restart_cycles                  : std_logic;
    
    signal      dds_4pi_strb_o                          : std_logic;
    signal      dds_4pi_cos_phase                       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    
    -- Stage 5 Phase adjust
    signal      phase_adjust_6pi_strb_i                 : std_logic;  
    signal      phase_adjust_6pi_phase_term             : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);    
    signal      phase_adjust_6pi_nb_points              : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_adjust_6pi_sideband_data_i        : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    
    signal      phase_adjust_6pi_strb_o                 : std_logic;
    signal      phase_adjust_6pi_phase_term_o           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      phase_adjust_6pi_nb_points_o            : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_adjust_6pi_nb_rept_o              : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);

    -- Stage 6 DDS a3
    signal      dds_6pi_strb_i                          : std_logic;
    signal      dds_6pi_phase_term                      : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_6pi_nb_points                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_6pi_nb_repetitions                  : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_6pi_initial_phase                   : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_6pi_restart_cycles                  : std_logic;
    
    signal      dds_6pi_strb_o                          : std_logic;
    signal      dds_6pi_cos_phase                       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    -- Stage 7 Window result
    signal      win_strb_i                              : std_logic;
    signal      win_cos_2pi_phase                       : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART);
    signal      win_cos_4pi_phase                       : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART);
    signal      win_cos_6pi_phase                       : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART);

    signal      win_strb_1_reg                          : std_logic;
    signal      win_minus_a1_cos_reg                    : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART);
    signal      win_a2_cos_reg                          : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART);
    signal      win_minus_a3_cos_reg                    : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART);
    
    signal      win_strb_2_reg                          : std_logic;
    signal      win_minus_a1_plus_a2_reg                : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART);    
    signal      win_a0_minus_a3_reg                     : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART);    

    signal      win_strb_3_reg                          : std_logic;
    signal      win_a0_minus_a1_plus_a2_minus_a3reg     : sfixed(BLKH_INTEGER_PART downto BLKH_FRAC_PART);    

begin

    --------------
    -- Stage 1  --
    --------------

    dds_2pi_strb_i         <= strb_i;
    dds_2pi_phase_term     <= phase_term_i;
    dds_2pi_nb_points      <= nb_points_i;
    dds_2pi_nb_repetitions <= std_logic_vector( to_unsigned( 1, dds_2pi_nb_repetitions'length));
    dds_2pi_initial_phase  <= (others => '0');
    dds_2pi_restart_cycles <= restart_cycles_i;

    stage_1_dds_2pi: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => BLKH_INTEGER_PART,
            CORDIC_FRAC_PART                    => BLKH_FRAC_PART,
            N_CORDIC_ITERATIONS                 => BLKH_NB_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            EN_POSPROC                          => TRUE
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            strb_i                              => dds_2pi_strb_i,
            phase_term_i                        => dds_2pi_phase_term,
            initial_phase_i                     => dds_2pi_initial_phase,
            nb_points_i                         => dds_2pi_nb_points,
            nb_repetitions_i                    => dds_2pi_nb_repetitions,
            mode_time_i                         => '0', -- Forced FALSE
           
            -- Control interface
            restart_cycles_i                    => dds_2pi_restart_cycles,
            
            -- Output interface
            strb_o                              => dds_2pi_strb_o,
            sine_phase_o                        => open,
            cos_phase_o                         => dds_2pi_cos_phase,
            done_cycles_o                       => open,
            flag_full_cycle_o                   => open
        );
    
    -------------
    -- Stage 2 --
    -------------

    dds_2pi_generic_shift_strb_i            <= dds_2pi_strb_o;
    dds_2pi_generic_shift_input_data        <= to_slv(dds_2pi_cos_phase);
    --dds_2pi_generic_shift_sideband_data_i   <= ;

    stage_2_dds_generic_shift: entity work.generic_shift_reg 
        generic map(
            WORD_WIDTH                          => DDS_WORD_WIDTH,
            SHIFT_SIZE                          => LATENCY,
            SIDEBAND_WIDTH                      => SIDEBAND_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,

            -- Input interface
            strb_i                              => dds_2pi_generic_shift_strb_i,
            input_data_i                        => dds_2pi_generic_shift_input_data,
            sideband_data_i                     => dds_2pi_generic_shift_sideband_data_i,
            
            -- Output interface
            strb_o                              => dds_2pi_generic_shift_strb_o,
            output_data_o                       => dds_2pi_generic_shift_output_data,
            sideband_data_o                     => open
        );

    -------------
    -- Stage 3 --
    -------------

    phase_adjust_4pi_strb_i         <= strb_i;
    phase_adjust_4pi_phase_term     <= phase_term_i;
    phase_adjust_4pi_nb_points      <= nb_points_i;
    --phase_adjust_4pi_sideband_data_i <= ;

    stage_3_phase_adjust_4pi: entity work.phase_adjust
        generic map (
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            FACTOR                              => PHASE_FACTOR_A2,
            SIDEBAND_WIDTH                      => SIDEBAND_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,
    
            -- Input interface
            strb_i                              => phase_adjust_4pi_strb_i,
            phase_in_i                          => phase_adjust_4pi_phase_term,
            nb_cycles_in_i                      => phase_adjust_4pi_nb_points,
            
            -- Sideband interface
            sideband_data_i                     => phase_adjust_4pi_sideband_data_i,
            sideband_data_o                     => open,
            
            -- Output interface
            strb_o                              => phase_adjust_4pi_strb_o,
            phase_out_o                         => phase_adjust_4pi_phase_term_o,
            nb_cycles_out_o                     => phase_adjust_4pi_nb_points_o,
            nb_rept_out_o                       => phase_adjust_4pi_nb_rept_o
        );

    --------------
    -- Stage 4  --
    --------------

    dds_4pi_strb_i         <= phase_adjust_4pi_strb_o;
    dds_4pi_phase_term     <= phase_adjust_4pi_phase_term_o;
    dds_4pi_nb_points      <= phase_adjust_4pi_nb_points_o;
    dds_4pi_nb_repetitions <= phase_adjust_4pi_nb_rept_o;
    dds_4pi_initial_phase  <= (others => '0');
    dds_4pi_restart_cycles <= restart_cycles_i;

    stage_4_dds_4pi: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => BLKH_INTEGER_PART,
            CORDIC_FRAC_PART                    => BLKH_FRAC_PART,
            N_CORDIC_ITERATIONS                 => BLKH_NB_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            EN_POSPROC                          => TRUE
       )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            strb_i                              => dds_4pi_strb_i,
            phase_term_i                        => dds_4pi_phase_term,
            initial_phase_i                     => dds_4pi_initial_phase,
            nb_points_i                         => dds_4pi_nb_points,
            nb_repetitions_i                    => dds_4pi_nb_repetitions,
            mode_time_i                         => '0', -- Forced FALSE

            -- Control interface
            restart_cycles_i                    => dds_4pi_restart_cycles,
            
            -- Output interface
            strb_o                              => dds_4pi_strb_o,
            sine_phase_o                        => open,
            cos_phase_o                         => dds_4pi_cos_phase,
            done_cycles_o                       => open,
            flag_full_cycle_o                   => open
        );

    -------------
    -- Stage 5 --
    -------------

    phase_adjust_6pi_strb_i         <= strb_i;
    phase_adjust_6pi_phase_term     <= phase_term_i;
    phase_adjust_6pi_nb_points      <= nb_points_i;
    --phase_adjust_6pi_sideband_data_i <= ;

    stage_5_phase_adjust_6pi: entity work.phase_adjust
        generic map (
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            FACTOR                              => PHASE_FACTOR_A3,
            SIDEBAND_WIDTH                      => SIDEBAND_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,
    
            -- Input interface
            strb_i                              => phase_adjust_6pi_strb_i,
            phase_in_i                          => phase_adjust_6pi_phase_term,
            nb_cycles_in_i                      => phase_adjust_6pi_nb_points,
            
            -- Sideband interface
            sideband_data_i                     => phase_adjust_6pi_sideband_data_i,
            sideband_data_o                     => open,
            
            -- Output interface
            strb_o                              => phase_adjust_6pi_strb_o,
            phase_out_o                         => phase_adjust_6pi_phase_term_o,
            nb_cycles_out_o                     => phase_adjust_6pi_nb_points_o,
            nb_rept_out_o                       => phase_adjust_6pi_nb_rept_o
        );

    --------------
    -- Stage 6  --
    --------------

    dds_6pi_strb_i         <= phase_adjust_6pi_strb_o;
    dds_6pi_phase_term     <= phase_adjust_6pi_phase_term_o;
    dds_6pi_nb_points      <= phase_adjust_6pi_nb_points_o;
    dds_6pi_nb_repetitions <= phase_adjust_6pi_nb_rept_o;
    dds_6pi_initial_phase  <= (others => '0');
    dds_6pi_restart_cycles <= restart_cycles_i;

    stage_6_dds_6pi: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => BLKH_INTEGER_PART,
            CORDIC_FRAC_PART                    => BLKH_FRAC_PART,
            N_CORDIC_ITERATIONS                 => BLKH_NB_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            EN_POSPROC                          => TRUE
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            strb_i                              => dds_6pi_strb_i,
            phase_term_i                        => dds_6pi_phase_term,
            initial_phase_i                     => dds_6pi_initial_phase,
            nb_points_i                         => dds_6pi_nb_points,
            nb_repetitions_i                    => dds_6pi_nb_repetitions,
            mode_time_i                         => '0', -- Forced FALSE
           
            -- Control interface
            restart_cycles_i                    => dds_6pi_restart_cycles,
            
            -- Output interface
            strb_o                              => dds_6pi_strb_o,
            sine_phase_o                        => open,
            cos_phase_o                         => dds_6pi_cos_phase,
            done_cycles_o                       => open,
            flag_full_cycle_o                   => open
        );

    -------------
    -- Stage 6 --
    -------------

    win_strb_i          <= dds_2pi_generic_shift_strb_o;
    win_cos_2pi_phase   <= to_sfixed(dds_2pi_generic_shift_output_data , win_cos_2pi_phase);
    win_cos_4pi_phase   <= dds_4pi_cos_phase;
    win_cos_6pi_phase   <= dds_6pi_cos_phase;
    
    minus_a1_cos_and_a2_cos_and_minus_a3 : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            win_strb_1_reg  <= '0';
        elsif (rising_edge(clock_i)) then

            win_strb_1_reg  <= win_strb_i;

            if (win_strb_i = '1') then
                win_minus_a1_cos_reg <= resize ( WIN_MINUS_A1 *  win_cos_2pi_phase , win_minus_a1_cos_reg);
                win_a2_cos_reg       <= resize ( WIN_A2 * win_cos_4pi_phase , win_a2_cos_reg);
                win_minus_a3_cos_reg <= resize ( WIN_MINUS_A3 *  win_cos_6pi_phase , win_minus_a3_cos_reg);
            end if;
        end if;
    end process;

    minus_a1_plus_a2_and_a0_minus_a3 : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            win_strb_2_reg  <= '0';
        elsif (rising_edge(clock_i)) then

            win_strb_2_reg  <= win_strb_1_reg;

            if (win_strb_1_reg = '1') then
                win_minus_a1_plus_a2_reg    <= resize ( win_minus_a1_cos_reg + win_a2_cos_reg , win_minus_a1_plus_a2_reg);
                win_a0_minus_a3_reg         <= resize ( WIN_A0 +  win_minus_a3_cos_reg , win_a0_minus_a3_reg);
            end if;
        end if;
    end process;

    a0_minus_a1_plus_a2_minus_a3 : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            win_strb_3_reg  <= '0';
        elsif (rising_edge(clock_i)) then

            win_strb_3_reg  <= win_strb_2_reg;

            if (win_strb_2_reg = '1') then
                win_a0_minus_a1_plus_a2_minus_a3reg    <= resize ( win_minus_a1_plus_a2_reg + win_a0_minus_a3_reg , win_a0_minus_a1_plus_a2_minus_a3reg);
            end if;
        end if;
    end process;

    ------------
    -- Output --
    ------------
    strb_o              <= win_strb_3_reg;
    blkh_result_o       <= win_a0_minus_a1_plus_a2_minus_a3reg ;

end behavioral;
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

entity dds_cordic_win_v2 is
    generic(
        PHASE_INTEGER_PART                  : natural  :=   4;
        PHASE_FRAC_PART                     : integer  := -27;
        CORDIC_INTEGER_PART                 : natural  :=   1; 
        CORDIC_FRAC_PART                    : integer  := -19;
        N_CORDIC_ITERATIONS                 : natural  :=  21;
        NB_POINTS_WIDTH                     : natural  :=  10;  
        WIN_INTEGER_PART                    : positive := 1;
        WIN_FRAC_PART                       : integer  := -19;
        WIN_NB_ITERATIONS                   : positive := 10    
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Valid in
        win_mode_i                          : in  std_logic_vector(2 downto 0);
        phase_term_i                        : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
        window_term_i                       : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
        initial_phase_i                     : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); 
        nb_points_i                         : in  std_logic_vector( (NB_POINTS_WIDTH - 1) downto 0);
        nb_repetitions_i                    : in  std_logic_vector( (NB_POINTS_WIDTH - 1) downto 0);
        mode_time_i                         : in  std_logic; 
        restart_cycles_i                    : in  std_logic; 
        
        -- Output interface
        valid_o                             : out std_logic;
        sine_win_phase_o                    : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        last_word_o                         : out std_logic
    );
end dds_cordic_win_v2;

------------------
-- Architecture --
------------------
architecture behavioral of dds_cordic_win_v2 is
    
    -- -- TOTAL LATENCY =  PHASE_ACC + PREPROCESSOR +      CORDIC         
    -- --                  2         +      2       +  N_CORDIC_ITERATIONS
    -- constant    DDS_CORDIC_LATENCY                  : positive := 2 +  2 + N_CORDIC_ITERATIONS;

    -- -- PHASE_CORRECTION + WIN_PHASE_ACC + PREPROCESSOR +      CORDIC       + POSPROCESSOR + WINDOW OPERATION 
    -- --         2        +      2        +      2       + WIN_NB_ITERATIONS +       2      +        3
    -- constant    HH_BLKM_BLKH_LATENCY    : natural := 2 + 2 + 2 + WIN_NB_ITERATIONS + 2 + 3; --
    
    -- -- + WIN_PHASE_ACC + PREPROCESSOR +      CORDIC       + POSPROCESSOR + WINDOW OPERATION 
    -- --        4        +      2       + WIN_NB_ITERATIONS +       2      +        2
    -- constant    TKEY_LATENCY    : natural := 4 + 2  + WIN_NB_ITERATIONS + 2 + 2; -- Tukey window 

    ---------------
    -- Constants --
    ---------------

    -- DDS cordic
    constant    CORDIC_FACTOR                       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART)   := to_sfixed( (0.607253) , CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
    constant    DDS_WORD_WIDTH                      : natural := (CORDIC_INTEGER_PART - CORDIC_FRAC_PART + 1);

    -- Windows Win Mode Code
    constant    WIN_MODE_NONE                       : std_logic_vector := "000";
    constant    WIN_MODE_HANN                       : std_logic_vector := "001";
    constant    WIN_MODE_HAMM                       : std_logic_vector := "010";
    constant    WIN_MODE_BLKM                       : std_logic_vector := "011";
    constant    WIN_MODE_BLKH                       : std_logic_vector := "100";
    constant    WIN_MODE_TUKEY                      : std_logic_vector := "101";

    -- Window phase
    constant    WIN_PHASE_INTEGER_PART              : natural := PHASE_INTEGER_PART;
    constant    WIN_PHASE_FRAC_PART                 : integer := PHASE_FRAC_PART;    
    constant    WIN_NB_POINTS_WIDTH                 : natural := 17; 
    constant    WIN_WORD_WIDTH                      : natural := (WIN_INTEGER_PART - WIN_FRAC_PART + 1);
   
    -- Shift register
    constant    SIDEBAND_WIDTH                      : natural  := 1;

    -- Latency
    constant    WIN_LATENCY                         : natural  := 11; -- Max entre HH e Tukey

    -------------
    -- Signals --
    -------------
  
    -- Stage 1 DDS Cordic
    signal      dds_cordic_valid_i                  : std_logic;
    signal      dds_cordic_phase_term               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_cordic_nb_points                : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_cordic_nb_repetitions           : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_cordic_initial_phase            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_cordic_mode_time                : std_logic;
    signal      dds_cordic_restart_cycles           : std_logic;

    signal      dds_cordic_valid_o                  : std_logic;
    signal      dds_cordic_sine_phase               : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      dds_cordic_done                     : std_logic;
    signal      dds_cordic_flag_full_cycle          : std_logic;
    
    -- Stage 2 Window 
    signal      win_hh_blkm_blkh_valid_i            : std_logic;
    signal      win_hh_blkm_blkh_restart_cycles     : std_logic;
    signal      win_hh_blkm_blkh_valid_o            : std_logic;
    signal      win_hh_blkm_blkh_result             : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);
    signal      sync_win_hh_blkm_blkh_valid_o       : std_logic;
    signal      sync_win_hh_blkm_blkh_result        : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);
    
    signal      win_tukey_valid_i                   : std_logic;
    signal      win_tukey_valid_o                   : std_logic;
    signal      win_tukey_result                    : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);
    signal      win_tukey_restart_cycles            : std_logic;

    signal      win_window_term                     : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);  
    signal      win_nb_points                       : std_logic_vector((WIN_NB_POINTS_WIDTH - 1) downto 0);

    -- Stage 3 Shift Reg
    signal      dds_generic_shift_valid_i           : std_logic;
    signal      dds_generic_shift_input_data        : std_logic_vector((DDS_WORD_WIDTH - 1) downto 0);
    signal      dds_generic_shift_sideband_data_i   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal      dds_generic_shift_valid_o           : std_logic;
    signal      dds_generic_shift_output_data       : std_logic_vector((DDS_WORD_WIDTH - 1) downto 0);
    signal      dds_generic_shift_sideband_data_o   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 4 Multiply
    signal      stage_4_valid_i                     : std_logic;
    signal      stage_4_sine_phase                  : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      stage_4_win_result                  : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);

    signal      stage_4_valid_reg                   : std_logic;
    signal      stage_4_result                      : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); 
    signal      stage_4_done                        : std_logic;

begin

    -------------
    -- Stage 1 --
    -------------
    
    dds_cordic_valid_i        <= valid_i;
    dds_cordic_phase_term     <= phase_term_i;
    dds_cordic_nb_points      <= nb_points_i;
    dds_cordic_nb_repetitions <= nb_repetitions_i;
    dds_cordic_initial_phase  <= initial_phase_i;
    dds_cordic_mode_time      <= mode_time_i;
    dds_cordic_restart_cycles <= restart_cycles_i;

    stage_1_dds_cordic: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                    => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS                 => N_CORDIC_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            EN_POSPROC                          => FALSE
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            valid_i                             => dds_cordic_valid_i,
            phase_term_i                        => dds_cordic_phase_term,
            initial_phase_i                     => dds_cordic_initial_phase,
            nb_points_i                         => dds_cordic_nb_points,
            nb_repetitions_i                    => dds_cordic_nb_repetitions,
            mode_time_i                         => dds_cordic_mode_time,
           
            -- Control interface
            restart_cycles_i                    => dds_cordic_restart_cycles,
            
            -- Output interface
            valid_o                             => dds_cordic_valid_o,
            sine_phase_o                        => dds_cordic_sine_phase,
            cos_phase_o                         => open,
            done_cycles_o                       => dds_cordic_done,
            flag_full_cycle_o                   => open
        );

    -------------
    -- Stage 2 --
    -------------

    win_hh_blkm_blkh_valid_i            <=          valid_i             when (      win_mode_i = WIN_MODE_HANN  
                                                                                or  win_mode_i = WIN_MODE_HAMM  
                                                                                or  win_mode_i = WIN_MODE_BLKM  
                                                                                or  win_mode_i = WIN_MODE_BLKH )  
                                            else    '0';

    win_tukey_valid_i                   <=          valid_i             when (      win_mode_i = WIN_MODE_TUKEY)
                                            else    '0';

    win_hh_blkm_blkh_restart_cycles     <=          restart_cycles_i    when (      win_mode_i = WIN_MODE_HANN  
                                                                                or  win_mode_i = WIN_MODE_HAMM  
                                                                                or  win_mode_i = WIN_MODE_BLKM  
                                                                                or  win_mode_i = WIN_MODE_BLKH )
                                            else    '0';

    win_tukey_restart_cycles            <=          restart_cycles_i    when (win_mode_i = WIN_MODE_TUKEY)
                                            else    '0';
    
    win_window_term                     <= window_term_i;
    win_nb_points                       <= std_logic_vector( resize( unsigned(nb_points_i) * unsigned(nb_repetitions_i) , WIN_NB_POINTS_WIDTH));

    stage_2_hh_blkm_blkh_win : entity work.hh_blkm_blkh_win
        generic map( 
            WIN_PHASE_INTEGER_PART             => WIN_PHASE_INTEGER_PART,
            WIN_PHASE_FRAC_PART                => WIN_PHASE_FRAC_PART,
            WORD_INTEGER_PART                  => WIN_INTEGER_PART,
            WORD_FRAC_PART                     => WIN_FRAC_PART,
            NB_ITERATIONS                      => WIN_NB_ITERATIONS,
            NB_POINTS_WIDTH                    => WIN_NB_POINTS_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                            => clock_i,
            areset_i                           => areset_i,

            -- Input interface
            valid_i                            => win_hh_blkm_blkh_valid_i,
            win_type_i                         => win_mode_i(1 downto 0),
            phase_term_i                       => win_window_term,
            nb_points_i                        => win_nb_points,
            restart_cycles_i                   => win_hh_blkm_blkh_restart_cycles,
            
            -- Output interface
            valid_o                            => win_hh_blkm_blkh_valid_o,
            win_result_o                       => win_hh_blkm_blkh_result
        );

        stage_2_tukey_window : entity work.tukey_win 
            generic map(
                WIN_PHASE_INTEGER_PART              => WIN_PHASE_INTEGER_PART,
                WIN_PHASE_FRAC_PART                 => WIN_PHASE_FRAC_PART,
                TK_INTEGER_PART                     => WIN_INTEGER_PART,
                TK_FRAC_PART                        => WIN_FRAC_PART,
                TK_NB_ITERATIONS                    => WIN_NB_ITERATIONS,
                NB_POINTS_WIDTH                     => WIN_NB_POINTS_WIDTH
            )
            port map(
                -- Clock interface
                clock_i                             => clock_i,
                areset_i                            => areset_i,

                -- Input interface
                valid_i                             => win_tukey_valid_i,
                phase_term_i                        => win_window_term,
                nb_points_i                         => win_nb_points,
                restart_cycles_i                    => win_tukey_restart_cycles,
                
                -- Output interface
                valid_o                             => win_tukey_valid_o,
                tk_result_o                         => win_tukey_result
            );

    sync_windows_latency : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            sync_win_hh_blkm_blkh_valid_o <= '0';
        elsif(rising_edge(clock_i)) then

            sync_win_hh_blkm_blkh_valid_o <= win_hh_blkm_blkh_valid_o;

            if (win_hh_blkm_blkh_valid_o = '1') then
                sync_win_hh_blkm_blkh_result    <= win_hh_blkm_blkh_result;
            end if;
        end if;
    end process;

    -------------
    -- Stage 3 --
    -------------

    dds_generic_shift_valid_i               <= dds_cordic_valid_o;
    dds_generic_shift_input_data            <= to_slv(dds_cordic_sine_phase);
    dds_generic_shift_sideband_data_i(0)    <= dds_cordic_done;

    stage_3_dds_generic_shift: entity work.generic_shift_reg 
        generic map(
            WORD_WIDTH                          => DDS_WORD_WIDTH,
            SHIFT_SIZE                          => WIN_LATENCY,
            SIDEBAND_WIDTH                      => SIDEBAND_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,

            -- Input interface
            valid_i                             => dds_generic_shift_valid_i,
            input_data_i                        => dds_generic_shift_input_data,
            sideband_data_i                     => dds_generic_shift_sideband_data_i,
            
            -- Output interface
            valid_o                             => dds_generic_shift_valid_o,
            output_data_o                       => dds_generic_shift_output_data,
            sideband_data_o                     => dds_generic_shift_sideband_data_o
        );

    -------------
    -- Stage 4 --
    -------------

    stage_4_valid_i     <=      sync_win_hh_blkm_blkh_valid_o
                            or  win_tukey_valid_o; 

    stage_4_sine_phase  <= to_sfixed( dds_generic_shift_output_data, stage_4_sine_phase);

    stage_4_win_result  <=          win_tukey_result                when(win_mode_i = WIN_MODE_TUKEY)
                            else    sync_win_hh_blkm_blkh_result ;
    
    stage_4_result_proc : process(clock_i,areset_i)
    begin
        if ( areset_i = '1') then
            stage_4_valid_reg <= '0';
        elsif (rising_edge(clock_i)) then
            
            stage_4_valid_reg <= stage_4_valid_i;

            if (stage_4_valid_i = '1') then

                stage_4_result  <= resize( (stage_4_sine_phase *  stage_4_win_result) ,stage_4_result);
                stage_4_done    <= dds_generic_shift_sideband_data_o(0);
            end if;
        end if;
    end process;

    ------------
    -- Output --
    ------------
    valid_o             <=          dds_cordic_valid_o      when (win_mode_i = WIN_MODE_NONE)
                            else    stage_4_valid_reg;
                                
    sine_win_phase_o    <=          dds_cordic_sine_phase   when (win_mode_i = WIN_MODE_NONE)
                            else    stage_4_result;

    last_word_o         <=          dds_cordic_done         when (win_mode_i = WIN_MODE_NONE)
                            else    stage_4_done;
end behavioral;
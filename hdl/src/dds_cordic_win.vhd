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

entity dds_cordic_win is
    generic(
        PHASE_INTEGER_PART                  : natural  :=   4;
        PHASE_FRAC_PART                     : integer  := -27;
        CORDIC_INTEGER_PART                 : natural  :=   1; 
        CORDIC_FRAC_PART                    : integer  := -19;
        N_CORDIC_ITERATIONS                 : natural  :=  21;
        NB_POINTS_WIDTH                     : natural  :=  10;  
        MODE_TIME                           : boolean  := FALSE;
        WIN_MODE                            : string   := "HANN"; -- or "HAMM"
        WIN_INTEGER_PART                    : positive := 1;
        WIN_FRAC_PART                       : integer  := -19;
        WIN_NB_ITERATIONS                   : positive := 10    
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        phase_term_i                        : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
        window_term_i                       : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
        initial_phase_i                     : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); 
        nb_points_i                         : in  std_logic_vector( (NB_POINTS_WIDTH - 1) downto 0);
        nb_repetitions_i                    : in  std_logic_vector( (NB_POINTS_WIDTH - 1) downto 0);
        restart_cycles_i                    : in  std_logic; 
        
        -- Output interface
        strb_o                              : out std_logic;
        sine_win_phase_o                    : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        
        -- Debug only interface
        sine_strb_o                         : out std_logic;
        sine_phase_o                        : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        
        win_result_strb_o                   : out std_logic;
        win_result_o                        : out sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART)

    );
end dds_cordic_win;

------------------
-- Architecture --
------------------
architecture behavioral of dds_cordic_win is

    ---------------
    -- Constants --
    ---------------

    -- DDS cordic
    constant    CORDIC_FACTOR                       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART)   := to_sfixed( (0.607253) , CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
    constant    DDS_WORD_WIDTH                      : natural := (CORDIC_INTEGER_PART - CORDIC_FRAC_PART + 1);

    -- Window phase
    constant    WIN_PHASE_INTEGER_PART              : natural  := PHASE_INTEGER_PART;
    constant    WIN_PHASE_FRAC_PART                 : integer  := PHASE_FRAC_PART;    
    constant    WIN_NB_POINTS_WIDTH                 : natural  := 17; 
    constant    WIN_WORD_WIDTH                      : natural := (WIN_INTEGER_PART - WIN_FRAC_PART + 1);
   
    -- Shift register
    constant    SIDEBAND_WIDTH                      : natural  := 0;

    -- Latency

        -- TOTAL LATENCY =  PHASE_ACC + PREPROCESSOR +      CORDIC         
        --                  2         +      2       +  N_CORDIC_ITERATIONS
    constant    DDS_CORDIC_LATENCY                  : positive := 2 +  2 + N_CORDIC_ITERATIONS;

        -- TOTAL LATENCY =  WIN_PHASE_ACC + PREPROCESSOR +      CORDIC      + POSPROCESSOR + WINDOW OPERATION 
        --                      2         +      2       + HH_NB_ITERATIONS +       2      +        2         
    constant    WIN_LATENCY                         : positive := 2 + 2 + WIN_NB_ITERATIONS + 2 + 2;

    constant    WIN_TO_DDS_LATENCY                  : integer  := (WIN_LATENCY  -  DDS_CORDIC_LATENCY );
    constant    DDS_TO_WIN_LATENCY                  : integer  := (- WIN_TO_DDS_LATENCY );

    -------------
    -- Signals --
    -------------
  
    -- Stage 1 DDS Cordic
    signal      dds_cordic_strb_i                   : std_logic;
    signal      dds_cordic_phase_term               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_cordic_nb_points                : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_cordic_nb_repetitions           : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_cordic_initial_phase            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_cordic_restart_cycles           : std_logic;

    signal      dds_cordic_strb_o                   : std_logic;
    signal      dds_cordic_sine_phase               : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      dds_cordic_done_cycles              : std_logic;
    signal      dds_cordic_flag_full_cycle          : std_logic;
    
    -- Stage 2 Window 
    signal      win_strb_i                          : std_logic;
    signal      win_window_term                     : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);  
    signal      win_nb_points                       : std_logic_vector((WIN_NB_POINTS_WIDTH - 1) downto 0);
    signal      win_restart_cycles                  : std_logic;

    signal      win_strb_o                          : std_logic;
    signal      win_result                          : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);

    -- Stage 3 Shift Reg
    signal      dds_generic_shift_strb_i            : std_logic;
    signal      dds_generic_shift_input_data        : std_logic_vector((DDS_WORD_WIDTH - 1) downto 0);
    signal      dds_generic_shift_sideband_data_i   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal      dds_generic_shift_strb_o            : std_logic;
    signal      dds_generic_shift_output_data       : std_logic_vector((DDS_WORD_WIDTH - 1) downto 0);
    signal      dds_generic_shift_sideband_data_o   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal      win_generic_shift_strb_i            : std_logic;
    signal      win_generic_shift_input_data        : std_logic_vector((WIN_WORD_WIDTH - 1) downto 0);
    signal      win_generic_shift_sideband_data_i   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal      win_generic_shift_strb_o            : std_logic;
    signal      win_generic_shift_output_data       : std_logic_vector((WIN_WORD_WIDTH - 1) downto 0);
    signal      win_generic_shift_sideband_data_o   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 4 Multiply
    signal      stage_4_strb_i                      : std_logic;
    signal      stage_4_sine_phase                  : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      stage_4_win_result                  : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);

    signal      stage_4_strb_reg                    : std_logic;
    signal      stage_4_result                      : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); -- TODO review size

begin

    -------------
    -- Stage 1 --
    -------------
    
    dds_cordic_strb_i         <= strb_i;
    dds_cordic_phase_term     <= phase_term_i;
    dds_cordic_nb_points      <= nb_points_i;
    dds_cordic_nb_repetitions <= nb_repetitions_i;
    dds_cordic_initial_phase  <= initial_phase_i;
    dds_cordic_restart_cycles <= restart_cycles_i;

    stage_1_dds_cordic: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                    => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS                 => N_CORDIC_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            EN_POSPROC                          => FALSE,
            MODE_TIME                           => MODE_TIME
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            strb_i                              => dds_cordic_strb_i,
            phase_term_i                        => dds_cordic_phase_term,
            initial_phase_i                     => dds_cordic_initial_phase,
            nb_points_i                         => dds_cordic_nb_points,
            nb_repetitions_i                    => dds_cordic_nb_repetitions,
           
            -- Control interface
            restart_cycles_i                    => dds_cordic_restart_cycles,
            
            -- Output interface
            strb_o                              => dds_cordic_strb_o,
            sine_phase_o                        => dds_cordic_sine_phase,
            cos_phase_o                         => open,
            done_cycles_o                       => open,
            flag_full_cycle_o                   => open
        );

    -------------
    -- Stage 2 --
    -------------

    win_strb_i              <= strb_i;
    win_window_term         <= window_term_i;
    win_nb_points           <= std_logic_vector( resize( unsigned(nb_points_i) * unsigned(nb_repetitions_i) , WIN_NB_POINTS_WIDTH));
    win_restart_cycles      <= restart_cycles_i;

    stage_2_window : entity work.hh_win 
        generic map(
            HH_MODE                             => WIN_MODE, -- or HAMM
            WIN_PHASE_INTEGER_PART              => WIN_PHASE_INTEGER_PART,
            WIN_PHASE_FRAC_PART                 => WIN_PHASE_FRAC_PART,
            HH_INTEGER_PART                     => WIN_INTEGER_PART,
            HH_FRAC_PART                        => WIN_FRAC_PART,
            HH_NB_ITERATIONS                    => WIN_NB_ITERATIONS,
            NB_POINTS_WIDTH                     => WIN_NB_POINTS_WIDTH
    )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,

            -- Input interface
            strb_i                              => win_strb_i,
            phase_term_i                        => win_window_term,
            nb_points_i                         => win_nb_points,
            restart_cycles_i                    => win_restart_cycles,
            
            -- Output interface
            strb_o                              => win_strb_o,
            hh_result_o                         => win_result
        );

    -------------
    -- Stage 3 --
    -------------

    dds_generic_shift_strb_i            <= dds_cordic_strb_o;
    dds_generic_shift_input_data        <= to_slv(dds_cordic_sine_phase);
    --generic_shift_sideband_data_i   <= ;

    stage_3_dds_generic_shift: entity work.generic_shift_reg 
        generic map(
            WORD_WIDTH                          => DDS_WORD_WIDTH,
            SHIFT_SIZE                          => WIN_TO_DDS_LATENCY,
            SIDEBAND_WIDTH                      => SIDEBAND_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,

            -- Input interface
            strb_i                              => dds_generic_shift_strb_i,
            input_data_i                        => dds_generic_shift_input_data,
            sideband_data_i                     => dds_generic_shift_sideband_data_i,
            
            -- Output interface
            strb_o                              => dds_generic_shift_strb_o,
            output_data_o                       => dds_generic_shift_output_data,
            sideband_data_o                     => dds_generic_shift_sideband_data_o
        );

    win_generic_shift_strb_i            <= win_strb_o;
    win_generic_shift_input_data        <= to_slv(win_result);
    --generic_shift_sideband_data_i   <= ;
    
    stage_3_win_generic_shift: entity work.generic_shift_reg 
        generic map(
            WORD_WIDTH                          => DDS_WORD_WIDTH,
            SHIFT_SIZE                          => DDS_TO_WIN_LATENCY,
            SIDEBAND_WIDTH                      => SIDEBAND_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,

            -- Input interface
            strb_i                              => win_generic_shift_strb_i,
            input_data_i                        => win_generic_shift_input_data,
            sideband_data_i                     => win_generic_shift_sideband_data_i,
            
            -- Output interface
            strb_o                              => win_generic_shift_strb_o,
            output_data_o                       => win_generic_shift_output_data,
            sideband_data_o                     => win_generic_shift_sideband_data_o
        );

    -------------
    -- Stage 4 --
    -------------

    stage_4_strb_i      <= dds_generic_shift_strb_o; -- TODO: check with generic_shift
    stage_4_sine_phase  <= to_sfixed( dds_generic_shift_output_data, stage_4_sine_phase);
    stage_4_win_result  <= to_sfixed( win_generic_shift_output_data, stage_4_win_result);
    
    stage_4_result_proc : process(clock_i,areset_i)
    begin
        if ( areset_i = '1') then
            stage_4_strb_reg <= '0';
        elsif (rising_edge(clock_i)) then
            
            stage_4_strb_reg <= stage_4_strb_i;

            if (stage_4_strb_i = '1') then

                stage_4_result  <= resize( (stage_4_sine_phase *  stage_4_win_result) ,stage_4_result);
            end if;
        end if;

    end process;

    ------------
    -- Output --
    ------------
    strb_o              <= stage_4_strb_reg;
    sine_win_phase_o    <= stage_4_result;
    
    sine_strb_o         <= dds_cordic_strb_o;
    sine_phase_o        <= dds_cordic_sine_phase;
    
    win_result_strb_o   <= win_strb_o;
    win_result_o        <= win_result;

end behavioral;

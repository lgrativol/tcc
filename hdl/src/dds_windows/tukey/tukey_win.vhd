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

entity tukey_win is
    generic(
        WIN_PHASE_INTEGER_PART             : natural  := 0;
        WIN_PHASE_FRAC_PART                : integer  := -1;
        TK_INTEGER_PART                    : positive := 2;
        TK_FRAC_PART                       : integer  := -4;
        TK_NB_ITERATIONS                   : positive := 10;
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
        tk_result_o                         : out sfixed(TK_INTEGER_PART downto TK_FRAC_PART)
    );
end tukey_win;

------------------
-- Architecture --
------------------
architecture behavioral of tukey_win is
    
    
    ---------------
    -- Constants --
    ---------------
    constant    CORDIC_FACTOR           : sfixed(TK_INTEGER_PART downto TK_FRAC_PART) := to_sfixed( (0.607253) , TK_INTEGER_PART, TK_FRAC_PART);
    constant    SIDEBAND_WIDTH          : natural  := 2;
    constant    NOT_USED_SIDEBAND_WIDTH : integer := -1;
    
    -- Tukey constants
    constant    WIN_A0              : sfixed(TK_INTEGER_PART downto TK_FRAC_PART) := to_sfixed( (0.5) , TK_INTEGER_PART, TK_FRAC_PART);
    constant    WIN_A1              : sfixed(TK_INTEGER_PART downto TK_FRAC_PART) := to_sfixed( (0.5) , TK_INTEGER_PART, TK_FRAC_PART);
    constant    WIN_MINUS_A1        : sfixed(TK_INTEGER_PART downto TK_FRAC_PART) := resize( (-WIN_A1) , TK_INTEGER_PART, TK_FRAC_PART);
    
    -------------
    -- Signals --
    -------------
    
    -- Stage 1 Phase accumulator (Tukey)
    signal      phase_acc_strb_i                : std_logic;
    signal      phase_acc_phase_term            : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);   
    signal      phase_acc_nb_points             : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_acc_nb_repetitions        : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);

    signal      phase_acc_restart_cycles        : std_logic;
    signal      phase_acc_done_cycles           : std_logic;
    signal      phase_acc_flag_full_cycle       : std_logic;

    signal      phase_acc_strb_o                : std_logic;
    signal      phase_acc_phase                 : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
    
    -- Stage 2 Preprocessor
    signal      preproc_strb_i                  : std_logic;
    signal      preproc_phase                   : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
    
    signal      preproc_phase_info              : std_logic_vector(1 downto 0);
    
    signal      preproc_strb_o                  : std_logic;
    signal      preproc_reduced_phase           : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);

    signal      preproc_sideband_i              : std_logic_vector((NOT_USED_SIDEBAND_WIDTH - 1) downto 0);
    signal      preproc_sideband_o              : std_logic_vector((NOT_USED_SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 3 Cordic Core
    signal      cordic_core_strb_i              : std_logic;
    signal      cordic_core_x_i                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      cordic_core_y_i                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      cordic_core_z_i                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    
    signal      cordic_core_strb_o              : std_logic;
    signal      cordic_core_x_o                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      cordic_core_y_o                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      cordic_core_z_o                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);

    signal      cordic_core_sideband_i          : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    signal      cordic_core_sideband_o          : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 4 Posprocessor
    signal      posproc_strb_i                  : std_logic;
    signal      posproc_sin_phase_i             : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      posproc_cos_phase_i             : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      posproc_phase_info              : std_logic_vector(1 downto 0);

    signal      posproc_strb_o                  : std_logic;
    signal      posproc_sin_phase_o             : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      posproc_cos_phase_o             : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);

    signal      posproc_sideband_i              : std_logic_vector((NOT_USED_SIDEBAND_WIDTH - 1) downto 0);
    signal      posproc_sideband_o              : std_logic_vector((NOT_USED_SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 5 Window result
    signal      win_strb_i                      : std_logic;
    signal      win_sin_phase                   : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      win_cos_phase                   : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);

    signal      win_strb_1_reg                  : std_logic;
    signal      win_minus_a1_cos_reg            : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    
    signal      win_strb_2_reg                  : std_logic;
    signal      win_a0_minus_a1_cos_reg         : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);    

begin

    -------------
    -- Stage 1 --
    -------------

    phase_acc_strb_i            <= strb_i;
    phase_acc_phase_term        <= phase_term_i;
    phase_acc_nb_points         <= nb_points_i;
    phase_acc_nb_repetitions    <= std_logic_vector( to_unsigned( 1, phase_acc_nb_repetitions'length));  
    phase_acc_restart_cycles    <= restart_cycles_i;

    stage_1_phase_acc : entity work.tukey_phase_acc
        generic map(
            WIN_ALFA                           => 0.5,
            PHASE_INTEGER_PART                 => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                    => WIN_PHASE_FRAC_PART,
            NB_POINTS_WIDTH                    => NB_POINTS_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                            => clock_i,
            areset_i                           => areset_i,
    
            -- Input interface
            strb_i                             => phase_acc_strb_i,
            phase_term_i                       => phase_acc_phase_term,
            nb_points_one_period_i             => phase_acc_nb_points,
            nb_repetitions_i                   => phase_acc_nb_repetitions,
    
            -- Control interface
            restart_acc_i                      => phase_acc_restart_cycles,
            
            -- Debug interface
            flag_done_o                        => open,
            flag_period_o                      => open,
    
            -- Output interface
            strb_o                             => phase_acc_strb_o,
            phase_o                            => phase_acc_phase
        ); 

    -------------
    -- Stage 2 --
    -------------

    preproc_strb_i  <= phase_acc_strb_o;
    preproc_phase   <= phase_acc_phase;

    stage_2_preproc : entity work.preproc
        generic map(
            SIDEBAND_WIDTH                      => NOT_USED_SIDEBAND_WIDTH,
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            OUTPUT_INTEGER_PART                 => TK_INTEGER_PART,
            OUTPUT_FRAC_PART                    => TK_FRAC_PART
        )
        port map(
            -- Clock interface
            clock_i                            =>  clock_i, 
            areset_i                           =>  areset_i, -- Positive async reset

            sideband_data_i                    => preproc_sideband_i,
            sideband_data_o                    => preproc_sideband_o,

            -- Input interface
            strb_i                             =>  preproc_strb_i, -- Valid in
            phase_i                            =>  preproc_phase,
            
            -- Control Interface
            phase_info_o                       =>  preproc_phase_info,

            -- Output interface
            strb_o                             => preproc_strb_o,
            reduced_phase_o                    => preproc_reduced_phase
        ); 

    --------------
    -- Stage 3  --
    --------------
    
    cordic_core_strb_i <= preproc_strb_o;

    cordic_core_x_i <= CORDIC_FACTOR;
    cordic_core_y_i <= (others => '0');
    cordic_core_z_i <= preproc_reduced_phase;

    cordic_core_sideband_i <= preproc_phase_info;

    stage_3_cordic_core : entity work.cordic_core
        generic map(
            SIDEBAND_WIDTH                  => SIDEBAND_WIDTH,
            CORDIC_INTEGER_PART             => TK_INTEGER_PART,
            CORDIC_FRAC_PART                => TK_FRAC_PART,
            N_CORDIC_ITERATIONS             => TK_NB_ITERATIONS
        )
        port map (
            clock_i                         => clock_i, 
            areset_i                        => areset_i, -- Positive async reset

            sideband_data_i                 => cordic_core_sideband_i,
            sideband_data_o                 => cordic_core_sideband_o,
            
            strb_i                          => cordic_core_strb_i, -- Valid in
            
            X_i                             => cordic_core_x_i,   -- X initial coordinate
            Y_i                             => cordic_core_y_i,   -- Y initial coordinate
            Z_i                             => cordic_core_z_i,   -- angle to rotate
            
            strb_o                          => cordic_core_strb_o,
            X_o                             => cordic_core_x_o, -- cossine NOTE: to use the cossine a posprocessor is needed 
            Y_o                             => cordic_core_y_o, -- sine
            Z_o                             => cordic_core_z_o  -- angle after rotation
        );

    -------------
    -- Stage 4 --
    -------------

    posproc_strb_i        <=  cordic_core_strb_o;
    posproc_sin_phase_i   <=  cordic_core_y_o;
    posproc_cos_phase_i   <=  cordic_core_x_o;
    posproc_phase_info    <=  cordic_core_sideband_o;

    stage_4_posproc : entity work.posproc
        generic map(
            SIDEBAND_WIDTH                      => NOT_USED_SIDEBAND_WIDTH,
            WORD_INTEGER_PART                   => TK_INTEGER_PART,
            WORD_FRAC_PART                      => TK_FRAC_PART
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i, 
            areset_i                            => areset_i, -- Positive async reset
            
            sideband_data_i                    => posproc_sideband_i,
            sideband_data_o                    => posproc_sideband_o,

            -- Input interface
            strb_i                              => posproc_strb_i,
            sin_phase_i                         => posproc_sin_phase_i,
            cos_phase_i                         => posproc_cos_phase_i,

            -- Control Interface
            phase_info_i                        => posproc_phase_info,

            -- Output interface
            strb_o                              => posproc_strb_o,
            sin_phase_o                         => posproc_sin_phase_o,
            cos_phase_o                         => posproc_cos_phase_o
        ); 


    -------------
    -- Stage 5 --
    -------------

    win_strb_i    <= posproc_strb_o;
    win_cos_phase <= posproc_cos_phase_o;
  
    a1_minus_cos : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            win_strb_1_reg  <= '0';
        elsif (rising_edge(clock_i)) then

            win_strb_1_reg  <= win_strb_i;

            if (win_strb_i = '1') then
                win_minus_a1_cos_reg <= resize ( WIN_MINUS_A1 *  win_cos_phase ,win_minus_a1_cos_reg);
            end if;
        end if;
    end process;

    a0_minus_a1_cos : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            win_strb_2_reg  <= '0';
        elsif (rising_edge(clock_i)) then

            win_strb_2_reg  <= win_strb_1_reg;

            if (win_strb_1_reg = '1') then
                win_a0_minus_a1_cos_reg <= resize ( WIN_A0 +  win_minus_a1_cos_reg ,win_a0_minus_a1_cos_reg);
            end if;
        end if;
    end process;

    ------------
    -- Output --
    ------------
    strb_o              <= win_strb_2_reg;
    tk_result_o         <= win_a0_minus_a1_cos_reg ;

    end behavioral;

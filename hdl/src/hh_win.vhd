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

entity hh_win is
    generic(
        HH_MODE                            : string   := "HANN"; -- or HAMM
        WIN_PHASE_INTEGER_PART             : natural  := 0;
        WIN_PHASE_FRAC_PART                : integer  := -1;
        HH_INTEGER_PART                    : positive := 2;
        HH_FRAC_PART                       : integer  := -4;
        HH_NB_ITERATIONS                   : positive := 10             
   );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        phase_term_i                        : in  ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
        restart_cycles_i                    : in  std_logic; 
        
        -- Output interface
        strb_o                              : out std_logic;
        hh_result_o                         : out sfixed(HH_INTEGER_PART downto HH_FRAC_PART)
    );
end hh_win;

------------------
-- Architecture --
------------------
architecture behavioral of hh_win is
    
    
    ---------------
    -- Constants --
    ---------------
    constant    CORDIC_FACTOR       : sfixed(HH_INTEGER_PART downto HH_FRAC_PART) := to_sfixed( (0.607253) , HH_INTEGER_PART, HH_FRAC_PART);
    constant    MULT_FACTOR         : positive := 1;
    constant    SIDEBAND_WIDTH      : natural  := 2;
    
    -- Hanning
    constant    A0_HANN             : sfixed(HH_INTEGER_PART downto HH_FRAC_PART) := to_sfixed( (0.5) , HH_INTEGER_PART, HH_FRAC_PART);
    constant    A1_HANN             : sfixed(HH_INTEGER_PART downto HH_FRAC_PART) := to_sfixed( (0.5) , HH_INTEGER_PART, HH_FRAC_PART);
    constant    MINUS_A1_HANN       : sfixed(HH_INTEGER_PART downto HH_FRAC_PART) := resize( (-A1_HANN) , HH_INTEGER_PART, HH_FRAC_PART);
    
    -- Hamming
    constant    A0_HAMM             : sfixed(HH_INTEGER_PART downto HH_FRAC_PART) := to_sfixed( (0.53836) , HH_INTEGER_PART, HH_FRAC_PART); -- "optimal" parametrs from wikipedia
    constant    A1_HAMM             : sfixed(HH_INTEGER_PART downto HH_FRAC_PART) := to_sfixed( (0.46164) , HH_INTEGER_PART, HH_FRAC_PART); -- "optimal" parametrs from wikipedia
    constant    MINUS_A1_HAMM       : sfixed(HH_INTEGER_PART downto HH_FRAC_PART) := resize( (-A1_HAMM) , HH_INTEGER_PART, HH_FRAC_PART);
    
    ---------------
    -- Functions --
    ---------------
    
    function choose_a0 (mode : string) 
        return sfixed is
    begin
        if(mode = "HANN") then
            return A0_HANN;
        else
            return A0_HAMM;
        end if;
    end function choose_a0;

    function choose_a1 (mode : string) 
        return sfixed is
    begin
        if(mode = "HANN") then
            return MINUS_A1_HANN;
        else
            return MINUS_A1_HAMM;
        end if;
    end function choose_a1;
    
    constant    WIN_A0                          : sfixed(HH_INTEGER_PART downto HH_FRAC_PART) := choose_a0(HH_MODE);
    constant    WIN_MINUS_A1                    : sfixed(HH_INTEGER_PART downto HH_FRAC_PART) := choose_a1(HH_MODE);

    -------------
    -- Signals --
    -------------
    
    -- Stage 1 Hann/Hamm phase acc
    signal      win_phase_acc_strb_i            : std_logic;
    signal      win_phase_acc_phase_term        : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
    
    signal      win_phase_acc_restart_cycles    : std_logic;
    signal      win_phase_acc_done_cycles       : std_logic;
    signal      win_phase_acc_flag_full_cycle   : std_logic;
    
    signal      win_phase_acc_strb_o            : std_logic;
    signal      win_phase_acc_phase             : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
    -- Stage 2 Preprocessor
    signal      preproc_strb_i                  : std_logic;
    signal      preproc_phase                   : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
    signal      preproc_phase_info              : std_logic_vector(1 downto 0);
    
    signal      preproc_strb_o                  : std_logic;
    signal      preproc_reduced_phase           : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);

    -- Stage 3 Cordic Core
    signal      cordic_core_strb_i              : std_logic;
    signal      cordic_core_x_i                 : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    signal      cordic_core_y_i                 : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    signal      cordic_core_z_i                 : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    
    signal      cordic_core_strb_o              : std_logic;
    signal      cordic_core_x_o                 : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    signal      cordic_core_y_o                 : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    signal      cordic_core_z_o                 : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);

    signal      cordic_core_sideband_i          : std_logic_vector((SIDEBAND_WIDTH -1) downto 0);
    signal      cordic_core_sideband_o          : std_logic_vector((SIDEBAND_WIDTH -1) downto 0);

    -- Stage 4 Posprocessor
    signal      posproc_strb_i                  : std_logic;
    signal      posproc_sin_phase_i             : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    signal      posproc_cos_phase_i             : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    signal      posproc_phase_info              : std_logic_vector(1 downto 0);

    signal      posproc_strb_o                  : std_logic;
    signal      posproc_sin_phase_o             : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    signal      posproc_cos_phase_o             : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);

    -- Stage 5 Window result
    signal      win_strb_i                      : std_logic;
    signal      win_sin_phase                   : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    signal      win_cos_phase                   : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);

    signal      win_strb_1_reg                  : std_logic;
    signal      win_minus_a1_cos_reg            : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    
    signal      win_strb_2_reg                  : std_logic;
    signal      win_a0_minus_a1_cos_reg         : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);    

begin

    -------------
    -- Stage 1 --
    -------------

    win_phase_acc_strb_i            <= strb_i;
    win_phase_acc_phase_term        <= phase_term_i;
    win_phase_acc_restart_cycles    <= restart_cycles_i;

    stage_1_win_phase_acc : entity work.win_phase_acc 
        generic map(
            MULT_FACTOR                         => 1,
            WIN_PHASE_INTEGER_PART              => WIN_PHASE_INTEGER_PART,
            WIN_PHASE_FRAC_PART                 => WIN_PHASE_FRAC_PART
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,
    
            -- Input interface
            strb_i                              => win_phase_acc_strb_i,
            phase_term_i                        => win_phase_acc_phase_term,
    
            -- Control interface
            restart_cycles_i                    => win_phase_acc_restart_cycles,
            flag_full_cycle_o                   => win_phase_acc_flag_full_cycle,
    
            -- Output interface
            strb_o                              => win_phase_acc_strb_o,
            phase_o                             => win_phase_acc_phase
        ); 

    -------------
    -- Stage 2 --
    -------------

    preproc_strb_i  <= win_phase_acc_strb_o;
    preproc_phase   <= win_phase_acc_phase;

    stage_2_preproc : entity work.preproc
        generic map(
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            OUTPUT_INTEGER_PART                 => HH_INTEGER_PART,
            OUTPUT_FRAC_PART                    => HH_FRAC_PART
        )
        port map(
            -- Clock interface
            clock_i                            =>  clock_i, 
            areset_i                           =>  areset_i, -- Positive async reset

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
            CORDIC_INTEGER_PART             => HH_INTEGER_PART,
            CORDIC_FRAC_PART                => HH_FRAC_PART,
            N_CORDIC_ITERATIONS             => HH_NB_ITERATIONS
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
            WORD_INTEGER_PART                   => HH_INTEGER_PART,
            WORD_FRAC_PART                      => HH_FRAC_PART
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i, 
            areset_i                            => areset_i, -- Positive async reset

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
    hh_result_o         <= win_a0_minus_a1_cos_reg ;

    end behavioral;
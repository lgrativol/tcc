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

entity dds_cordic is
    generic(
        EN_POSPROC                          : boolean  := FALSE;
        SYSTEM_FREQUENCY                    : positive := 100E6; -- 100 MHz
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
        restart_cycles_i                    : in  std_logic; 
        
        -- Output interface
        strb_o                              : out std_logic;
        sine_phase_o                        : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        done_cycles_o                       : out std_logic;
        flag_full_cycle_o                   : out std_logic
    );
end dds_cordic;

------------------
-- Architecture --
------------------
architecture behavioral of dds_cordic is

    ---------------
    -- Constants --
    ---------------
    constant    FREQUENCY_WIDTH     : positive := target_frequency_i'length;
    constant    CORDIC_FACTOR       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART) := to_sfixed( (0.607253) , CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
    constant    SIDEBAND_WIDTH      : natural  := 2;

    -------------
    -- Signals --
    -------------
    
    -- Stage 1 Phase accumulator
    signal      phase_acc_strb_i            : std_logic;
    signal      phase_acc_target_freq       : std_logic_vector( (FREQUENCY_WIDTH - 1) downto 0);
    signal      phase_acc_nb_cycles         : std_logic_vector((NB_CYCLES_WIDTH - 1) downto 0);
    signal      phase_acc_phase_diff        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  

    signal      phase_acc_restart_cycles    : std_logic;
    signal      phase_acc_done_cycles       : std_logic;
    signal      phase_acc_flag_full_cycle   : std_logic;

    signal      phase_acc_strb_o            : std_logic;
    signal      phase_acc_phase             : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);

    -- Stage 2 Preprocessor
    signal      preproc_strb_i              : std_logic;
    signal      preproc_phase               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
       
    signal      preproc_phase_info          : std_logic_vector(1 downto 0);
    
    signal      preproc_strb_o              : std_logic;
    signal      preproc_reduced_phase       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    -- Stage 3 Cordic Core
    signal      cordic_core_strb_i          : std_logic;
    signal      cordic_core_x_i             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      cordic_core_y_i             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      cordic_core_z_i             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    
    signal      cordic_core_strb_o          : std_logic;
    signal      cordic_core_x_o             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      cordic_core_y_o             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      cordic_core_z_o             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    signal      cordic_core_sideband_i      : std_logic_vector((SIDEBAND_WIDTH -1) downto 0);
    signal      cordic_core_sideband_o      : std_logic_vector((SIDEBAND_WIDTH -1) downto 0);

    -- Stage 4 Posprocessor
    signal      posproc_strb_i              : std_logic;
    signal      posproc_sin_phase_i         : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      posproc_cos_phase_i         : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      posproc_phase_info          : std_logic_vector(1 downto 0);

    signal      posproc_strb_o              : std_logic;
    signal      posproc_sin_phase_o         : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      posproc_cos_phase_o         : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    
    
begin


    -------------
    -- Stage 1 --
    -------------

    phase_acc_strb_i            <= strb_i;
    phase_acc_target_freq       <= target_frequency_i;
    phase_acc_nb_cycles         <= nb_cycles_i;
    phase_acc_phase_diff        <= phase_diff_i; 

    phase_acc_restart_cycles    <= restart_cycles_i;

    stage_1_phase_acc : entity work.phase_acc 
        generic map(
            SAMPLING_FREQUENCY                  => SYSTEM_FREQUENCY,
            MODE_TIME                           => MODE_TIME
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,
    
            -- Input interface
            strb_i                              => phase_acc_strb_i,
            target_frequency_i                  => phase_acc_target_freq,
            nb_cycles_i                         => phase_acc_nb_cycles,
            phase_diff_i                        => phase_acc_phase_diff,
    
            -- Control interface
            restart_cycles_i                    => phase_acc_restart_cycles,
            done_cycles_o                       => phase_acc_done_cycles,
            flag_full_cycle_o                   => phase_acc_flag_full_cycle,
    
            -- Output interface
            strb_o                              => phase_acc_strb_o,
            phase_o                             => phase_acc_phase
        ); 

    -------------
    -- Stage 2 --
    -------------

    preproc_strb_i  <= phase_acc_strb_o;
    preproc_phase   <= phase_acc_phase;

    stage_2_preproc : entity work.preproc
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
            strb_o                             =>  preproc_strb_o,
            reduced_phase_o                    =>  preproc_reduced_phase
        ); 

    --------------
    -- Stage 3  --
    --------------
    
    cordic_core_strb_i      <= preproc_strb_o;

    cordic_core_x_i         <= CORDIC_FACTOR;
    cordic_core_y_i         <= (others => '0');
    cordic_core_z_i         <= preproc_reduced_phase;
    cordic_core_sideband_i  <= preproc_phase_info;

    stage_3_cordic_core : entity work.cordic_core
        generic map(
            SIDEBAND_WIDTH         => SIDEBAND_WIDTH,
            CORDIC_INTEGER_PART    => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART       => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS    => N_CORDIC_ITERATIONS
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

    --------------
    -- Stage 4  --
    --------------

    posproc_strb_i        <=  cordic_core_strb_o;
    posproc_sin_phase_i   <=  cordic_core_y_o;
    posproc_cos_phase_i   <=  cordic_core_x_o;
    posproc_phase_info    <=  cordic_core_sideband_o;

    
    POSPROC_GEN_TRUE: 
        if (EN_POSPROC) generate
            stage_4_posproc : entity work.posproc
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
        end generate POSPROC_GEN_TRUE;
    
    POSPROC_GEN_FALSE: 
        if (not EN_POSPROC) generate
            posproc_strb_o          <= posproc_strb_i;
            posproc_sin_phase_o     <= posproc_sin_phase_i;
            posproc_cos_phase_o     <= posproc_cos_phase_o;
        end generate POSPROC_GEN_FALSE;
    
    ------------
    -- Output --
    ------------

    strb_o              <= posproc_strb_o;
    flag_full_cycle_o   <= phase_acc_flag_full_cycle;
    sine_phase_o        <= posproc_sin_phase_o;
    done_cycles_o       <= phase_acc_done_cycles;

    end behavioral;

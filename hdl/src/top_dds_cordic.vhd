---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
--use ieee.fixed_float_types.all; -- only synthesis
--use ieee.fixed_pkg.all;         -- only synthesis

library ieee_proposed;                      -- only simulation
use ieee_proposed.fixed_float_types.all;    -- only simulation
use ieee_proposed.fixed_pkg.all;            -- only simulation

library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity top_dds_cordic is
    generic(
        SYSTEM_FREQUENCY                    : positive := 100E6 -- 100 MHz
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset
        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        target_frequency_i                  : in  std_logic_vector((ceil_log2(SYSTEM_FREQUENCY + 1) - 1) downto 0);
        
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
    
    -- Stage 1 Phase accumulator
    signal      phase_acc_strb_i            : std_logic;
    signal      phase_acc_target_freq       : std_logic_vector( (FREQUENCY_WIDTH - 1) downto 0);

    signal      phase_acc_strb_o            : std_logic;
    signal      phase_acc_flag_full_cycle   : std_logic;
    signal      phase_acc_phase             : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);

    -- Stage 2 Preprocessor
    signal      preproc_strb_i              : std_logic;
    signal      preproc_phase               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
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

begin

    -------------
    -- Stage 1 --
    -------------

    phase_acc_strb_i        <= strb_i;
    phase_acc_target_freq   <= target_frequency_i;

    stage_1_phase_acc : entity work.phase_acc 
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,
    
            -- Input interface
            strb_i                              => phase_acc_strb_i,
            target_frequency_i                  => phase_acc_target_freq,
    
            -- Output interface
            strb_o                              => phase_acc_strb_o,
            flag_full_cycle_o                   => phase_acc_flag_full_cycle,
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

    stage_3_cordic_core : entity work.cordic_core
        port map (
            clock_i                         => clock_i, 
            areset_i                        => areset_i, -- Positive async reset
            
            strb_i                          => cordic_core_strb_i, -- Valid in
            X_i                             => cordic_core_x_i,   -- X initial coordinate
            Y_i                             => cordic_core_y_i,   -- Y initial coordinate
            Z_i                             => cordic_core_z_i,   -- angle to rotate

            strb_o                          => cordic_core_strb_o,
            X_o                             => cordic_core_x_o, -- cossine TODO: to use the cossine a posprocessor is needed 
            Y_o                             => cordic_core_y_o, -- sine
            Z_o                             => cordic_core_z_o  -- angle after rotation
        );

    ------------
    -- Output --
    ------------
    strb_o              <= cordic_core_strb_o;
    flag_full_cycle_o   <= phase_acc_flag_full_cycle;
    sine_phase_o        <= cordic_core_y_o;

    end behavioral;

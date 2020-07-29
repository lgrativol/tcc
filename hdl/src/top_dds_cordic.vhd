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
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset
        strb_frequency_i                    : in  std_logic; -- Valid in
        target_frequency_i                  : in  std_logic_vector((ceil_log2(SYSTEM_FREQUENCY + 1) - 1) downto 0);
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
    constant    FREQUENCY_WIDTH      : positive := target_frequency_i'length;
    
    constant    PHASE_INTEGER_PART   : natural  := 3;
    constant    PHASE_FRAC_PART      : integer  := -30;

    constant    CORDIC_INTEGER_PART  : natural  := 1;
    constant    CORDIC_FRAC_PART     : integer  := -19;

    constant    N_CORDIC_ITERATIONS  : positive := 20;

    constant    CORDIC_FACTOR        : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART) := to_sfixed( (0.607253) , CORDIC_INTEGER_PART, CORDIC_FRAC_PART);

    
    -------------
    -- Signals --
    -------------
    
    -- Stage 1
    signal      strb_delta          : std_logic;
    signal      delta_phase         : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);

    -- Stage 2
    signal      strb_phase          : std_logic;
    signal      phase               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);

    -- Stage 3
    signal      strb_reduc_phase    : std_logic;
    signal      reduc_phase         : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    -- Stage 4
    signal      strb_o              : std_logic;

    signal      x_i                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      y_i                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      z_i                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    signal      x_o                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      y_o                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      z_o                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

begin
    stage_1_frequency_definer : entity work.frequency_definer
        generic map (
            SAMPLING_FREQUENCY                 => SYSTEM_FREQUENCY, -- 100 MHz
            FREQUENCY_WIDTH                    => FREQUENCY_WIDTH, --  log2(100 MHz)            
            PHASE_INTEGER_PART                 => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                    => PHASE_FRAC_PART -- PI precision
        )
        port map(
            -- Clock interface
            clock_i                            => clock_i,
            areset_i                           => areset_i,
            
            strb_frequency_i                   => strb_frequency_i,
            target_frequency_i                 => target_frequency_i,
    
            -- Output interface
            strb_delta_o                        => strb_delta,
            delta_phase_o                       => delta_phase
        );

    stage_2_phase_acc : entity work.phase_acc 
        generic map (
            PHASE_INTEGER_PART                 => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                    => PHASE_FRAC_PART
        )
        port map(
            -- Clock interface
            clock_i                            => clock_i,
            areset_i                           => areset_i,
    
            -- Input interface
            strb_phase_i                        => strb_delta,
            delta_phase_i                       => delta_phase,
    
            -- Output interface
            strb_phase_o                        => strb_phase,
            flag_full_cycle_o                   => flag_full_cycle_o,
            phase_o                             => phase
        ); 

    stage_3_pre_proc : entity work.pre_proc
        generic map(
            CORDIC_INTEGER_PART                => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                   => CORDIC_FRAC_PART,
            PHASE_INTEGER_PART                 => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                    => PHASE_FRAC_PART
        )
        port map(
            -- Clock interface
            clock_i                            =>  clock_i, 
            areset_i                           =>  areset_i, -- Positive async reset

            -- Input interface
            strb_phase_i                       =>  strb_phase, -- Valid in
            phase_i                            =>  phase,

            -- Output interface
            strb_reduc_phase_o                 => strb_reduc_phase,
            reduc_phase_o                      => reduc_phase
        ); 


        x_i <= CORDIC_FACTOR;
        y_i <= (others => '0');
        z_i <= reduc_phase;

        stage_4 : entity work.cordic_core
            generic map(
                CORDIC_INTEGER_PART             => CORDIC_INTEGER_PART,
                CORDIC_FRAC_PART                => CORDIC_FRAC_PART,
                N_CORDIC_ITERATIONS             => N_CORDIC_ITERATIONS 
            )
            port map (
                clock_i                         => clock_i, 
                areset_i                        => areset_i, -- Positive async reset
                
                strb_i                          => strb_reduc_phase, -- Valid in
                strb_o                          => strb_o,
                
                X_i                             => x_i,
                Y_i                             => y_i,
                Z_i                             => z_i,
        
                X_o                             => x_o,
                Y_o                             => y_o,
                Z_o                             => z_o
            );

end behavioral;

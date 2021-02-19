---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Outubro/2020                                                                         
-- Module Name: hh_win_v2                                                                      
-- Author Name: Lucas Grativol Ribeiro                          
--                                                                                         
-- Revision Date: 24/11/2020                                                                         
-- Tool version: Vivado 2017.4                                                                           
--                                                                      
-- Goal: Gerador dsa janelas hamming e hanning ("hh")       
--
-- Description:  Segunda versão do arquivo que gera as janelas. Instância só as duas
--               janelas. O arquivo "hh_blkm_blkh_win" possui todas as janelas de uma vez.
--------------------------------------------------------------------------------------------

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

entity hh_win_v2 is
    generic(
        PHASE_INTEGER_PART                 : natural; 
        PHASE_FRAC_PART                    : integer; 
        CORDIC_INTEGER_PART                : natural; 
        CORDIC_FRAC_PART                   : integer;     
        HH_MODE                            : string; -- String que define se a janela é Hamming ("HAMM") 
                                                     -- ou Hanning "HANN"
        WIN_PHASE_INTEGER_PART             : natural;
        WIN_PHASE_FRAC_PART                : integer;
        HH_INTEGER_PART                    : positive;
        HH_FRAC_PART                       : integer;
        HH_NB_ITERATIONS                   : positive;
        NB_POINTS_WIDTH                    : positive             
   );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Valid in
        phase_term_i                        : in  ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
        nb_points_i                         : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0 );
        restart_cycles_i                    : in  std_logic; 
        
        -- Output interface
        valid_o                             : out std_logic;
        hh_result_o                         : out sfixed(HH_INTEGER_PART downto HH_FRAC_PART)
    );
end hh_win_v2;

------------------
-- Architecture --
------------------
architecture behavioral of hh_win_v2 is
    
    
    ---------------
    -- Constants --
    ---------------

    constant    REPT_WIDTH          : natural := 4; -- Hardcode

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
    
    -- Stage 1 DDS CORDIC
    signal      dds_hh_valid_i                   : std_logic;
    signal      dds_hh_phase_term               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);   
    signal      dds_hh_initial_phase            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_hh_nb_points                : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_hh_nb_repetitions           : std_logic_vector((REPT_WIDTH - 1) downto 0);

    signal      dds_hh_restart_cycles           : std_logic;
    signal      dds_hh_done_cycles              : std_logic;

    signal      dds_hh_valid_o                   : std_logic;
    signal      dds_hh_cos_phase                : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    
    -- Stage 2 Window result
    signal      win_valid_i                      : std_logic;
    signal      win_sin_phase                   : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    signal      win_cos_phase                   : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);

    signal      win_valid_1_reg                  : std_logic;
    signal      win_minus_a1_cos_reg            : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);
    
    signal      win_valid_2_reg                  : std_logic;
    signal      win_a0_minus_a1_cos_reg         : sfixed(HH_INTEGER_PART downto HH_FRAC_PART);    

begin

    -------------
    -- Stage 1 --
    -------------
    
    dds_hh_valid_i              <= valid_i;
    dds_hh_phase_term          <= phase_term_i;
    dds_hh_initial_phase       <= (others => '0');
    dds_hh_nb_points           <= nb_points_i;
    dds_hh_nb_repetitions      <= std_logic_vector( to_unsigned( 1, dds_hh_nb_repetitions'length));
    dds_hh_restart_cycles      <= restart_cycles_i;

    stage_1_dds_hh: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => HH_INTEGER_PART,
            CORDIC_FRAC_PART                    => HH_FRAC_PART,
            N_CORDIC_ITERATIONS                 => HH_NB_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => REPT_WIDTH,
            EN_POSPROC                          => TRUE
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            valid_i                              => dds_hh_valid_i,
            phase_term_i                        => dds_hh_phase_term,
            initial_phase_i                     => dds_hh_initial_phase,
            nb_points_i                         => dds_hh_nb_points,
            nb_repetitions_i                    => dds_hh_nb_repetitions,
            mode_time_i                         => '0', -- Forced FALSE
           
            -- Control interface
            restart_cycles_i                    => dds_hh_restart_cycles,
            
            -- Output interface
            valid_o                              => dds_hh_valid_o,
            sine_phase_o                        => open,
            cos_phase_o                         => dds_hh_cos_phase,
            done_cycles_o                       => dds_hh_done_cycles,
            flag_full_cycle_o                   => open
        );

    -------------
    -- Stage 2 --
    -------------

    win_valid_i    <= dds_hh_valid_o;
    win_cos_phase <= dds_hh_cos_phase;
  
    a1_minus_cos : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            win_valid_1_reg  <= '0';
        elsif (rising_edge(clock_i)) then

            win_valid_1_reg  <= win_valid_i;

            if (win_valid_i = '1') then
                win_minus_a1_cos_reg <= resize ( WIN_MINUS_A1 *  win_cos_phase ,win_minus_a1_cos_reg);
            end if;
        end if;
    end process;

    a0_minus_a1_cos : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            win_valid_2_reg  <= '0';
        elsif (rising_edge(clock_i)) then

            win_valid_2_reg  <= win_valid_1_reg;

            if (win_valid_1_reg = '1') then
                win_a0_minus_a1_cos_reg <= resize ( WIN_A0 +  win_minus_a1_cos_reg ,win_a0_minus_a1_cos_reg);
            end if;
        end if;
    end process;

    ------------
    -- Output --
    ------------
    valid_o              <= win_valid_2_reg;
    hh_result_o         <= win_a0_minus_a1_cos_reg ;

    end behavioral;

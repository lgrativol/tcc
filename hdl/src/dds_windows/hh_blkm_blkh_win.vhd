---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: 12/11/2020                                                                         
-- Module Name: hh_blkm_blkh_win 
--              ( O nome abreviado significa : Hanning, Hamming, Blackman e Blackman-Harris)                                                                           
-- Author Name: Lucas Grativol Ribeiro                          
--                                                                                         
-- Revision Date: 24/11/2020                                                                         
-- Tool version: Vivado 2017.4                                                                           
--                                                                      
-- Goal: Gerar a janela desejada entre as opções        
--
-- Description:  O módulo possibilita a escolha entre 6 tipos de janelas
--               * 01 : Hanning window          
--               * 10 : Hamming window         
--               * 11 : Blackman         
--               * 00 : Blackman-Harris         
--              
--               O tipo de janela é fornecido pelo sinal "win_type_i"
--               e o resto é multiplexado para obter a janela desejada;
--
--               Para o bloco é fornecido:
--               * phase_term : a variação de fase usada para pelo acumulador de fase para gerar os ângulos
--                              phase_term = 2pi/(nb_points da janela)
--                 Obs.: É fornecido a fase em 2pi, as outras fases necessárias 4pi e 6pi
--                       são geradas pelo módulo
--               * nb_points  : Número de pontos da janela
--
---------------------------------------------------------------------------------------------
---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee_proposed;                      
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;         

library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity hh_blkm_blkh_win is
    generic( 
        PHASE_INTEGER_PART                 : natural; -- phase integer part
        PHASE_FRAC_PART                    : integer; -- phase fractional part
        CORDIC_INTEGER_PART                : natural; -- Cordic integer part
        CORDIC_FRAC_PART                   : integer; -- Cordic frac part
        WIN_PHASE_INTEGER_PART             : natural; -- phase integer part
        WIN_PHASE_FRAC_PART                : integer; -- phase fractional part
        WORD_INTEGER_PART                  : natural; -- Windows integer part
        WORD_FRAC_PART                     : integer; -- Windows frac part
        NB_ITERATIONS                      : positive; -- Número de iterações das janelas (tamanho do pipeline)
        NB_POINTS_WIDTH                    : positive -- Número de bits de nb_points           
   );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Indica que todos os parâmetros abaixo são válidos no ciclo atual e inicia o sinal
        win_type_i                          : in  std_logic_vector(1 downto 0); -- Ver descrição acima
        phase_term_i                        : in  ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART); -- Ver descrição acima
        nb_points_i                         : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0 ); -- Ver descrição acima
        restart_cycles_i                    : in  std_logic; -- Restart a geração da onda definina nos parâmetros anteriores
                                                             -- todos os parâmetros são salvos, com um tick de restart
                                                             -- a onda é gerada com os últimos parâmetros, não depende do "valid_i"
        -- Output interface
        valid_o                             : out std_logic; -- Indica que as saída abaixo são válidas no ciclo atual
        win_result_o                        : out sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) -- valor da janela[k]
    );
end hh_blkm_blkh_win;

------------------
-- Architecture --
------------------
architecture behavioral of hh_blkm_blkh_win is
    
    ---------------
    -- Constants --
    ---------------

    constant    REPT_WIDTH          : natural := 4;

    -- Windows Win Mode Code
    constant    WIN_MODE_HANN       : std_logic_vector := "01";
    constant    WIN_MODE_HAMM       : std_logic_vector := "10";
    constant    WIN_MODE_BLKM       : std_logic_vector := "11";
    constant    WIN_MODE_BLKH       : std_logic_vector := "00";

    -- CORDIC
    -- 0,607253 = 1/Ak = limit(k->+infinito) prod(k=0)^(k=infinito) cos(arctg(2^-k))
    constant    CORDIC_FACTOR       : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed( (0.607253) , WORD_INTEGER_PART, WORD_FRAC_PART);
    constant    SIDEBAND_WIDTH      : natural  := 2;
    constant    DDS_WORD_WIDTH      : natural  := (WORD_INTEGER_PART - WORD_FRAC_PART + 1);
    
    -- Phase adjust
    constant    PHASE_FACTOR_A2     : positive := 2; -- From 2pi to 4Pi
    constant    PHASE_FACTOR_A3     : positive := 3; -- From 2pi to 6Pi

    -- Generic Shift
    constant    LATENCY             : positive := 2; -- Used because the phase adjust has 2 registers, sync a1 and a2 cos
    
    -- Windows coefs.
   
    ---- Hanning
    constant    WIN_HANN_A0         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed( (0.5) , WORD_INTEGER_PART, WORD_FRAC_PART);
    constant    WIN_HANN_A1         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed( (0.5) , WORD_INTEGER_PART, WORD_FRAC_PART);
    constant    WIN_HANN_MINUS_A1   : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := resize( (-WIN_HANN_A1) , WORD_INTEGER_PART, WORD_FRAC_PART);
    
    ---- Hamming
    constant    WIN_HAMM_A0         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed( (0.53836) , WORD_INTEGER_PART, WORD_FRAC_PART); -- "optimal" parametrs from wikipedia
    constant    WIN_HAMM_A1         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed( (0.46164) , WORD_INTEGER_PART, WORD_FRAC_PART); -- "optimal" parametrs from wikipedia
    constant    WIN_HAMM_MINUS_A1   : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := resize( (-WIN_HAMM_A1) , WORD_INTEGER_PART, WORD_FRAC_PART);
    
    ---- Blackman
    constant    WIN_BLKM_ALFA       : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed(0.16,WORD_INTEGER_PART,WORD_FRAC_PART);
    constant    WIN_BLKM_A0         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := resize((1.0 - WIN_BLKM_ALFA)/2.0 , WIN_BLKM_ALFA);
    constant    WIN_BLKM_A1         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed(0.5,WIN_BLKM_ALFA);   
    constant    WIN_BLKM_A2         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := resize((WIN_BLKM_ALFA)/2.0 , WIN_BLKM_ALFA);
    constant    WIN_BLKM_MINUS_A1   : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := resize(- WIN_BLKM_A1 , WIN_BLKM_ALFA);

    ----Blackman-Harris
    constant    WIN_BLKH_A0         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed(0.35875 , WORD_INTEGER_PART,WORD_FRAC_PART );
    constant    WIN_BLKH_A1         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed(0.48829 ,WIN_BLKH_A0);   
    constant    WIN_BLKH_A2         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed(0.14128 ,WIN_BLKH_A0);   
    constant    WIN_BLKH_A3         : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := to_sfixed(0.01168 ,WIN_BLKH_A0);   
    constant    WIN_BLKH_MINUS_A1   : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := resize(- WIN_BLKH_A1 , WIN_BLKH_A0);
    constant    WIN_BLKH_MINUS_A3   : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART) := resize(- WIN_BLKH_A3 , WIN_BLKH_A0);

    -------------
    -- Signals --
    -------------

    -- Register type
    signal      win_type                                 : std_logic_vector((win_type_i'length - 1) downto 0);
    
    -- Stage 1 DDS a1
    signal      dds_2pi_valid_i                          : std_logic;
    signal      dds_2pi_phase_term                       : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_2pi_nb_points                        : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_2pi_nb_repetitions                   : std_logic_vector((REPT_WIDTH - 1) downto 0);
    signal      dds_2pi_initial_phase                    : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_2pi_restart_cycles                   : std_logic;
    
    signal      dds_2pi_valid_o                          : std_logic;
    signal      dds_2pi_cos_phase                        : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    -- Stage 2 Generic Shift DDS a1
    signal      dds_2pi_generic_shift_valid_i           : std_logic;
    signal      dds_2pi_generic_shift_input_data        : std_logic_vector((DDS_WORD_WIDTH - 1) downto 0);
    signal      dds_2pi_generic_shift_sideband_data_i   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal      dds_2pi_generic_shift_valid_o           : std_logic;
    signal      dds_2pi_generic_shift_output_data       : std_logic_vector((DDS_WORD_WIDTH - 1) downto 0);

    -- Stage 3 Phase adjust
    signal      phase_adjust_4pi_valid_i                : std_logic;  
    signal      phase_adjust_4pi_phase_term             : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);    
    signal      phase_adjust_4pi_nb_points              : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_adjust_4pi_sideband_data_i        : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    
    signal      phase_adjust_4pi_valid_o                : std_logic;
    signal      phase_adjust_4pi_phase_term_o           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      phase_adjust_4pi_nb_points_o            : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_adjust_4pi_nb_rept_o              : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);

    -- Stage 4 DDS a2
    signal      dds_4pi_valid_i                         : std_logic;
    signal      dds_4pi_phase_term                      : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_4pi_nb_points                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_4pi_nb_repetitions                  : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_4pi_initial_phase                   : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_4pi_restart_cycles                  : std_logic;
    
    signal      dds_4pi_valid_o                         : std_logic;
    signal      dds_4pi_cos_phase                       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    
    -- Stage 5 Phase adjust
    signal      phase_adjust_6pi_valid_i                : std_logic;  
    signal      phase_adjust_6pi_phase_term             : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);    
    signal      phase_adjust_6pi_nb_points              : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_adjust_6pi_sideband_data_i        : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    
    signal      phase_adjust_6pi_valid_o                : std_logic;
    signal      phase_adjust_6pi_phase_term_o           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      phase_adjust_6pi_nb_points_o            : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_adjust_6pi_nb_rept_o              : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);

    -- Stage 6 DDS a3
    signal      dds_6pi_valid_i                         : std_logic;
    signal      dds_6pi_phase_term                      : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_6pi_nb_points                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_6pi_nb_repetitions                  : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_6pi_initial_phase                   : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_6pi_restart_cycles                  : std_logic;
    
    signal      dds_6pi_valid_o                         : std_logic;
    signal      dds_6pi_cos_phase                       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    -- Stage 7 Window result
    signal      win_a0                                  : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
    signal      win_minus_a1                            : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
    signal      win_a2                                  : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
    signal      win_minus_a3                            : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);

    signal      win_valid_i                             : std_logic;
    signal      win_cos_2pi_phase                       : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
    signal      win_cos_4pi_phase                       : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
    signal      win_cos_6pi_phase                       : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);

    signal      win_valid_1_reg                         : std_logic;
    signal      win_minus_a1_cos2pi_reg                 : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
    signal      win_a2_cos4pi_reg                       : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
    signal      win_minus_a3_cos6pi_reg                 : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);

    signal      win_valid_2_reg                         : std_logic;
    signal      win_a0_minus_a1_reg                     : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);    
    signal      win_a2_minus_a3_reg                     : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);    
    signal      win_a2_cos4pi_sync_reg                  : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);

    signal      win_valid_3_reg                         : std_logic;
    signal      win_a0_minus_a1_sync_reg                : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);    
    signal      win_a0_minus_a1_plus_a2_reg             : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);    
    signal      win_a0_minus_a1_plus_a2_minus_a3_reg    : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);    
    
    -- Output
    signal      output_valid                            : std_logic;
    signal      output_result                           : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);    
    signal      output_result_reg                       : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);    

begin

    ------------------------------------------------------------------
    --                     Window Mode registering                           
    --                                                                
    --   Goal: Registrar o valor do tipo da janela
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: win_type_i;
    --          win_mode_i;
    --
    --   Output: win_type;
    --           
    --   Result: Salva o win_mode em um registro
    ------------------------------------------------------------------
    register_win_type : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            win_type <= (others => '0');
        elsif(rising_edge(clock_i)) then
            if (valid_i = '1') then
                win_type    <= win_type_i;
            end if;
        end if;
    end process;

    --------------
    -- Stage 1  --
    --------------

    dds_2pi_valid_i        <= valid_i;
    dds_2pi_phase_term     <= phase_term_i;
    dds_2pi_nb_points      <= nb_points_i;
    dds_2pi_nb_repetitions <= std_logic_vector( to_unsigned( 1, dds_2pi_nb_repetitions'length));
    dds_2pi_initial_phase  <= (others => '0');
    dds_2pi_restart_cycles <= restart_cycles_i;

    stage_1_dds_2pi: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => WORD_INTEGER_PART,
            CORDIC_FRAC_PART                    => WORD_FRAC_PART,
            N_CORDIC_ITERATIONS                 => NB_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => REPT_WIDTH,
            EN_POSPROC                          => TRUE
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            valid_i                              => dds_2pi_valid_i,
            phase_term_i                        => dds_2pi_phase_term,
            initial_phase_i                     => dds_2pi_initial_phase,
            nb_points_i                         => dds_2pi_nb_points,
            nb_repetitions_i                    => dds_2pi_nb_repetitions,
            mode_time_i                         => '0', -- Force FALSE
           
            -- Control interface
            restart_cycles_i                    => dds_2pi_restart_cycles,
            
            -- Output interface
            valid_o                              => dds_2pi_valid_o,
            sine_phase_o                        => open,
            cos_phase_o                         => dds_2pi_cos_phase,
            done_cycles_o                       => open,
            flag_full_cycle_o                   => open
        );
    
    -------------
    -- Stage 2 --
    -------------

    dds_2pi_generic_shift_valid_i           <= dds_2pi_valid_o;
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
            valid_i                              => dds_2pi_generic_shift_valid_i,
            input_data_i                        => dds_2pi_generic_shift_input_data,
            sideband_data_i                     => dds_2pi_generic_shift_sideband_data_i,
            
            -- Output interface
            valid_o                              => dds_2pi_generic_shift_valid_o,
            output_data_o                       => dds_2pi_generic_shift_output_data,
            sideband_data_o                     => open
        );

    -------------
    -- Stage 3 --
    -------------

    phase_adjust_4pi_valid_i        <= valid_i;
    phase_adjust_4pi_phase_term     <= phase_term_i;
    phase_adjust_4pi_nb_points      <= nb_points_i;
    --phase_adjust_4pi_sideband_data_i <= ;

    stage_3_phase_adjust_4pi: entity work.phase_adjust
        generic map (
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => REPT_WIDTH,
            FACTOR                              => PHASE_FACTOR_A2,
            SIDEBAND_WIDTH                      => SIDEBAND_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,
    
            -- Input interface
            valid_i                             => phase_adjust_4pi_valid_i,
            phase_in_i                          => phase_adjust_4pi_phase_term,
            nb_cycles_in_i                      => phase_adjust_4pi_nb_points,
            
            -- Sideband interface
            sideband_data_i                     => phase_adjust_4pi_sideband_data_i,
            sideband_data_o                     => open,
            
            -- Output interface
            valid_o                              => phase_adjust_4pi_valid_o,
            phase_out_o                         => phase_adjust_4pi_phase_term_o,
            nb_cycles_out_o                     => phase_adjust_4pi_nb_points_o,
            nb_rept_out_o                       => phase_adjust_4pi_nb_rept_o
        );

    --------------
    -- Stage 4  --
    --------------

    dds_4pi_valid_i        <= phase_adjust_4pi_valid_o;
    dds_4pi_phase_term     <= phase_adjust_4pi_phase_term_o;
    dds_4pi_nb_points      <= phase_adjust_4pi_nb_points_o;
    dds_4pi_nb_repetitions <= phase_adjust_4pi_nb_rept_o;
    dds_4pi_initial_phase  <= (others => '0');
    dds_4pi_restart_cycles <= restart_cycles_i;

    stage_4_dds_4pi: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => WORD_INTEGER_PART,
            CORDIC_FRAC_PART                    => WORD_FRAC_PART,
            N_CORDIC_ITERATIONS                 => NB_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => REPT_WIDTH,
            EN_POSPROC                          => TRUE
       )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            valid_i                             => dds_4pi_valid_i,
            phase_term_i                        => dds_4pi_phase_term,
            initial_phase_i                     => dds_4pi_initial_phase,
            nb_points_i                         => dds_4pi_nb_points,
            nb_repetitions_i                    => dds_4pi_nb_repetitions,
            mode_time_i                         => '0', -- Forced FALSE

            -- Control interface
            restart_cycles_i                    => dds_4pi_restart_cycles,
            
            -- Output interface
            valid_o                              => dds_4pi_valid_o,
            sine_phase_o                        => open,
            cos_phase_o                         => dds_4pi_cos_phase,
            done_cycles_o                       => open,
            flag_full_cycle_o                   => open
        );

    -------------
    -- Stage 5 --
    -------------

    phase_adjust_6pi_valid_i        <= valid_i;
    phase_adjust_6pi_phase_term     <= phase_term_i;
    phase_adjust_6pi_nb_points      <= nb_points_i;
    --phase_adjust_6pi_sideband_data_i <= ;

    stage_5_phase_adjust_6pi: entity work.phase_adjust
        generic map (
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => REPT_WIDTH,
            FACTOR                              => PHASE_FACTOR_A3,
            SIDEBAND_WIDTH                      => SIDEBAND_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,
    
            -- Input interface
            valid_i                             => phase_adjust_6pi_valid_i,
            phase_in_i                          => phase_adjust_6pi_phase_term,
            nb_cycles_in_i                      => phase_adjust_6pi_nb_points,
            
            -- Sideband interface
            sideband_data_i                     => phase_adjust_6pi_sideband_data_i,
            sideband_data_o                     => open,
            
            -- Output interface
            valid_o                             => phase_adjust_6pi_valid_o,
            phase_out_o                         => phase_adjust_6pi_phase_term_o,
            nb_cycles_out_o                     => phase_adjust_6pi_nb_points_o,
            nb_rept_out_o                       => phase_adjust_6pi_nb_rept_o
        );

    --------------
    -- Stage 6  --
    --------------

    dds_6pi_valid_i        <= phase_adjust_6pi_valid_o;
    dds_6pi_phase_term     <= phase_adjust_6pi_phase_term_o;
    dds_6pi_nb_points      <= phase_adjust_6pi_nb_points_o;
    dds_6pi_nb_repetitions <= phase_adjust_6pi_nb_rept_o;
    dds_6pi_initial_phase  <= (others => '0');
    dds_6pi_restart_cycles <= restart_cycles_i;

    stage_6_dds_6pi: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => WIN_PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => WIN_PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => WORD_INTEGER_PART,
            CORDIC_FRAC_PART                    => WORD_FRAC_PART,
            N_CORDIC_ITERATIONS                 => NB_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => REPT_WIDTH,
            EN_POSPROC                          => TRUE
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            valid_i                             => dds_6pi_valid_i,
            phase_term_i                        => dds_6pi_phase_term,
            initial_phase_i                     => dds_6pi_initial_phase,
            nb_points_i                         => dds_6pi_nb_points,
            nb_repetitions_i                    => dds_6pi_nb_repetitions,
            mode_time_i                         => '0', -- Forced FALSE
           
            -- Control interface
            restart_cycles_i                    => dds_6pi_restart_cycles,
            
            -- Output interface
            valid_o                             => dds_6pi_valid_o,
            sine_phase_o                        => open,
            cos_phase_o                         => dds_6pi_cos_phase,
            done_cycles_o                       => open,
            flag_full_cycle_o                   => open
        );

    -------------
    -- Stage 6 --
    -------------

    -- Coef. MUXs
    win_a0              <=              WIN_HANN_A0         when(win_type = WIN_MODE_HANN)
                                else    WIN_HAMM_A0         when(win_type = WIN_MODE_HAMM)    
                                else    WIN_BLKM_A0         when(win_type = WIN_MODE_BLKM)    
                                else    WIN_BLKH_A0; --     when(win_type = WIN_MODE_BLKH)

    win_minus_a1        <=              WIN_HANN_MINUS_A1   when(win_type = WIN_MODE_HANN)
                                else    WIN_HAMM_MINUS_A1   when(win_type = WIN_MODE_HAMM)    
                                else    WIN_BLKM_MINUS_A1   when(win_type = WIN_MODE_BLKM)    
                                else    WIN_BLKH_MINUS_A1;--when(win_type = WIN_MODE_BLKH)
    
    win_a2              <=              WIN_BLKM_A2         when(win_type = WIN_MODE_BLKM)
                                else    WIN_BLKH_A2;--      when(win_type = WIN_MODE_BLKH)    
    
    win_minus_a3        <=              WIN_BLKH_MINUS_A3;
    
    win_valid_i         <= dds_2pi_generic_shift_valid_o;
    win_cos_2pi_phase   <= to_sfixed(dds_2pi_generic_shift_output_data , win_cos_2pi_phase);
    win_cos_4pi_phase   <= dds_4pi_cos_phase;
    win_cos_6pi_phase   <= dds_6pi_cos_phase;

    ------------------------------------------------------------------
    --                     Grupo Equação 1                           
    --                                                                
    --   Goal: Calcular os termos -a1.cos(2pi);a2.cos(4pi);-a3.cos(6pi)
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: win_valid_i;
    --          win_minus_a1;
    --          win_a2;
    --          win_minus_a3;
    --          win_cos_2pi_phase;
    --          win_cos_4pi_phase;
    --          win_cos_6pi_phase;
    --
    --   Output: win_valid_1_reg;
    --           win_minus_a1_cos2pi_reg;
    --           win_a2_cos4pi_reg;
    --           win_minus_a3_cos6pi_reg;
    --           
    --   Result: Os termos usados em todas as janelas são calculados com os coeficientes
    ------------------------------------------------------------------
    eq_part_1 : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            win_valid_1_reg  <= '0';
        elsif (rising_edge(clock_i)) then

            win_valid_1_reg  <= win_valid_i;

            if (win_valid_i = '1') then
                win_minus_a1_cos2pi_reg <= resize ( win_minus_a1 *  win_cos_2pi_phase , win_minus_a1_cos2pi_reg);
                win_a2_cos4pi_reg       <= resize ( win_a2       *  win_cos_4pi_phase , win_a2_cos4pi_reg);
                win_minus_a3_cos6pi_reg <= resize ( win_minus_a3 *  win_cos_6pi_phase , win_minus_a3_cos6pi_reg);
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    --                     Grupo Equação 2                          
    --                                                                
    --   Goal: Calcular os termos -> a0 - a1.cos(2pi)
    --                            -> a2.cos(4pi) - a3.cos(6pi)
    --         Registrar o termo  -> a2.cos(4pi)
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: win_valid_1_reg;
    --          win_a0;
    --          win_a2;
    --          win_minus_a1_cos2pi_reg;
    --          win_minus_a3_cos6pi_reg;
    --          win_a2_cos4pi_reg;
    --
    --   Output: win_valid_2_reg;
    --           win_a0_minus_a1_reg;
    --           win_a2_minus_a3_reg;
    --           win_a2_cos4pi_sync_reg;
    --           
    --   Result: Os termos usados em todas as janelas são calculados com os coeficientes
    ------------------------------------------------------------------

    eq_part_2 : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            win_valid_2_reg  <= '0';
        elsif (rising_edge(clock_i)) then

            win_valid_2_reg  <= win_valid_1_reg;

            if (win_valid_1_reg = '1') then
                win_a0_minus_a1_reg         <= resize ( win_a0 + win_minus_a1_cos2pi_reg , win_a0_minus_a1_reg);
                win_a2_minus_a3_reg         <= resize ( win_a2_cos4pi_reg + win_minus_a3_cos6pi_reg , win_a2_minus_a3_reg);
                win_a2_cos4pi_sync_reg      <= win_a2_cos4pi_reg;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    --                     Grupo Equação 3                          
    --                                                                
    --   Goal: Calcular os termos -> a0 - a1.cos(2pi) + a2.cos(4pi) - a3.cos(6pi) [Blackman-Harris]
    --                            -> a0 - a1.cos(2pi) + a2.cos(4pi) [Blackman]
    --         Registrar o termo  -> a0 - a1.cos(2pi) [Hanning or Hamming]
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: win_valid_2_reg;
    --          win_a0_minus_a1_reg;
    --          win_a2_cos4pi_sync_reg;
    --          win_a2_minus_a3_reg;
    --
    --   Output: win_valid_3_reg;
    --           win_a0_minus_a1_sync_reg;
    --           win_a0_minus_a1_plus_a2_reg;
    --           win_a0_minus_a1_plus_a2_minus_a3_reg;
    --           
    --   Result: Os termos usados em todas as janelas são calculados com os coeficientes
    ------------------------------------------------------------------
    eq_part_3 : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            win_valid_3_reg  <= '0';
        elsif (rising_edge(clock_i)) then

            win_valid_3_reg  <= win_valid_2_reg;

            if (win_valid_2_reg = '1') then
                win_a0_minus_a1_sync_reg                <= win_a0_minus_a1_reg;
                win_a0_minus_a1_plus_a2_reg             <= resize ( win_a0_minus_a1_reg + win_a2_cos4pi_sync_reg , win_a0_minus_a1_plus_a2_reg);
                win_a0_minus_a1_plus_a2_minus_a3_reg    <= resize ( win_a0_minus_a1_reg + win_a2_minus_a3_reg    , win_a0_minus_a1_plus_a2_minus_a3_reg);
            end if;
        end if;
    end process;

    output_result           <=              win_a0_minus_a1_sync_reg                when(win_type = WIN_MODE_HANN or win_type = WIN_MODE_HAMM) 
                                    else    win_a0_minus_a1_plus_a2_reg             when(win_type = WIN_MODE_BLKM)
                                    else    win_a0_minus_a1_plus_a2_minus_a3_reg;-- when(win_type = WIN_MODE_BLKH)

    output_reg : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            output_valid  <= '0';
        elsif (rising_edge(clock_i)) then

            output_valid  <= win_valid_3_reg;

            if (win_valid_3_reg = '1') then
               output_result_reg <= output_result;
            end if;
        end if;
    end process;

    ------------
    -- Output --
    ------------
    valid_o            <= output_valid;
    win_result_o       <= output_result_reg;
    
end behavioral;
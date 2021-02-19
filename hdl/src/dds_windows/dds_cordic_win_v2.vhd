---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                         
-- Module Name: dds_cordic_win_v2                                                                           
-- Author Name: Lucas Grativol Ribeiro                          
--                                                                                         
-- Revision Date: 24/11/2020                                                                         
-- Tool version: Vivado 2017.4                                                                           
--                                                                      
-- Goal: Gerar um seno múltiplicado por uma das possíveis janelas        
--
-- Description:  O módulo possibilita a escolha entre 6 tipos de janelas
--               * 000 : Nenhuma janela é aplicada, a saída é o seno puro
--               * 001 : Hanning window          
--               * 010 : Hamming window         
--               * 011 : Blackman         
--               * 100 : Blackman-Harris         
--               * 101 : Tukey
--              
--               O tipo de janela é fornecido pelo sinal "win_mode_i"
--               e o resto é multiplexado para obter o sinal janelado desejado;
--
--               Para o bloco é fornecido:
--               * phase_term : a variação de fase usada para pelo acumulador de fase para gerar os ângulos
--                              phase_term = 2pi/(nb_points)
--               * window_term : a variação de fase usada para pelo acumulador de fase para gerar os ângulos
--                              window_term = 2pi/(nb_points da janela)
--                 Obs.: É fornecido a fase em 2pi, as outras fases necessárias 4pi e 6pi
--                       são geradas pelo módulo
--               * nb_points  : Número de pontos do seno/cosseno em 1 período 
--                              nb_points = (f_sampling/f_target)
--                              f_target = frequência desejada para o seno/cosseno
--               * initial_phase : Fase inicial do seno/cosseno
--               * nb_repetitions: Número de períodos do seno/cosseno a serem gerados
--               * mode_time : Modo "especial" que transforma a fase inicial em um delay para o seno
--                             no tempo, da forma : número_de_ciclos_delay = initial_phase / phase_term
--
--
---------------------------------------------------------------------------------------------

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
        PHASE_INTEGER_PART                  : natural; -- phase integer part
        PHASE_FRAC_PART                     : integer; -- phase fractional part
        CORDIC_INTEGER_PART                 : natural; -- Cordic integer part
        CORDIC_FRAC_PART                    : integer; -- Cordic frac part
        N_CORDIC_ITERATIONS                 : natural; -- Número de iterações do CORDIC (tamanho do pipeline)
        NB_POINTS_WIDTH                     : natural; -- Número de bits de nb_points
        NB_REPT_WIDTH                       : natural; -- Número de bits nb_repetitions 
        WIN_INTEGER_PART                    : natural; -- Windows integer part
        WIN_FRAC_PART                       : integer; -- Windows frac part
        WIN_NB_ITERATIONS                   : positive -- Número de iterações das janelas (tamanho do pipeline)
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Indica que todos os parâmetros abaixo são válidos no ciclo atual e inicia o sinal
        win_mode_i                          : in  std_logic_vector(2 downto 0); -- Ver descrição acima
        phase_term_i                        : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); -- Ver descrição acima
        window_term_i                       : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); -- Ver descrição acima
        initial_phase_i                     : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); -- Ver descrição acima 
        nb_points_i                         : in  std_logic_vector( (NB_POINTS_WIDTH - 1) downto 0); -- Ver descrição acima
        nb_repetitions_i                    : in  std_logic_vector( (NB_REPT_WIDTH - 1) downto 0); -- Ver descrição acima
        mode_time_i                         : in  std_logic;  -- Ver descrição acima
        
        restart_cycles_i                    : in  std_logic; -- Restart a geração da onda definina nos parâmetros anteriores
                                                              -- todos os parâmetros são salvos, com um tick de restart
                                                              -- a onda é gerada com os últimos parâmetros, não depende do "valid_i"
        
        -- Output interface
        valid_o                             : out std_logic; -- Indica que as saída abaixo são válidas no ciclo atual
        sine_win_phase_o                    : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); -- Seno[k] * janela[k]
        last_word_o                         : out std_logic -- Indica que é o último clock ("last signal")
    );
end dds_cordic_win_v2;

------------------
-- Architecture --
------------------
architecture behavioral of dds_cordic_win_v2 is
    
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
    constant    WIN_NB_POINTS_WIDTH                 : natural := NB_POINTS_WIDTH; -- Harcode TODO: review 
    constant    WIN_WORD_WIDTH                      : natural := (WIN_INTEGER_PART - WIN_FRAC_PART + 1);
   
    -- Shift register
    constant    SIDEBAND_WIDTH                      : natural  := 1;

    -- -- TOTAL LATENCY =  PHASE_ACC + PREPROCESSOR +      CORDIC         
    -- --                  2         +      2       +  N_CORDIC_ITERATIONS
    constant    DDS_CORDIC_LATENCY                  : natural := 2 +  2 + N_CORDIC_ITERATIONS;

    -- -- PHASE_CORRECTION + WIN_PHASE_ACC + PREPROCESSOR +      CORDIC       + POSPROCESSOR + WINDOW OPERATION 
    -- --         2        +      2        +      2       + WIN_NB_ITERATIONS +       2      +        3
    constant    HH_BLKM_BLKH_LATENCY                : natural := 2 + 2 + 2 + WIN_NB_ITERATIONS + 2 + 3; -- Worst case
    
    -- -- + WIN_PHASE_ACC + PREPROCESSOR +      CORDIC       + POSPROCESSOR + WINDOW OPERATION 
    -- --        4        +      2       + WIN_NB_ITERATIONS +       2      +        2
    constant    TKEY_LATENCY                        : natural := 4 + 2  + WIN_NB_ITERATIONS + 2 + 2; -- Tukey window 
 
    -- Latency
    -- O conjunto de janelas representado por "hh_blkm_blkh" (Haninng, Hamming, Blackman e Blackman-Harris)
    -- possui uma latência fixa de 11 ciclos, ignorando o número de iterações, a janela Tukey possui 10 ciclos fixos. 
    -- Para sincronizar com o CORDIC que possui menos ciclos, é utilizado um shift-register genérico que 
    -- gera toda a sincronia, baseado no tamanhos abaixo. 
    -- Um tamanho zero ou menor, transformar o shift-register genérico em apenas fios, sem registros.
    constant    EXTRA_LATENCY                       : natural  := 4;
    constant    WIN_LATENCY                         : natural  := HH_BLKM_BLKH_LATENCY + EXTRA_LATENCY;
    constant    WIN_TO_DDS_LATENCY                  : integer  := (WIN_LATENCY  -  DDS_CORDIC_LATENCY + 1);
    constant    DDS_TO_WIN_LATENCY                  : integer  := EXTRA_LATENCY;
    constant    WIN_TUKEY_LATENCY                   : integer  := EXTRA_LATENCY + 1;

    -------------
    -- Signals --
    -------------
  
    -- Stage 1 DDS Cordic
    signal      dds_cordic_valid_i                  : std_logic;
    signal      dds_cordic_phase_term               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_cordic_nb_points                : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_cordic_nb_repetitions           : std_logic_vector((NB_REPT_WIDTH - 1) downto 0);
    signal      dds_cordic_initial_phase            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      dds_cordic_mode_time                : std_logic;
    signal      dds_cordic_restart_cycles           : std_logic;

    signal      dds_cordic_valid_o                  : std_logic;
    signal      dds_cordic_sine_phase               : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      dds_cordic_done                     : std_logic;
    signal      dds_cordic_flag_full_cycle          : std_logic;
    
    -- Stage 2 Windows
    signal      valid_reg                           : std_logic;
    signal      win_mode                            : std_logic_vector(2 downto 0);

    signal      win_hh_blkm_blkh_valid_i            : std_logic;
    signal      win_hh_blkm_blkh_restart_cycles     : std_logic;
    signal      win_hh_blkm_blkh_valid_o            : std_logic;
    signal      win_hh_blkm_blkh_result             : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);
    signal      sync_win_tukey_valid_o              : std_logic;
    signal      sync_win_tukey_result               : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);
    
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

    signal      win_generic_shift_valid_i           : std_logic;
    signal      win_generic_shift_input_data        : std_logic_vector((WIN_WORD_WIDTH - 1) downto 0);
    signal      win_generic_shift_sideband_data_i   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal      win_generic_shift_valid_o           : std_logic;
    signal      win_generic_shift_output_data       : std_logic_vector((WIN_WORD_WIDTH - 1) downto 0);
    signal      win_generic_shift_sideband_data_o   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal      tukey_generic_shift_valid_i         : std_logic;
    signal      tukey_generic_shift_input_data      : std_logic_vector((WIN_WORD_WIDTH - 1) downto 0);
    signal      tukey_generic_shift_sideband_data_i : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal      tukey_generic_shift_valid_o         : std_logic;
    signal      tukey_generic_shift_output_data     : std_logic_vector((WIN_WORD_WIDTH - 1) downto 0);
    signal      tukey_generic_shift_sideband_data_o : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 4 Multiply
    signal      stage_4_valid_i                     : std_logic;
    signal      stage_4_sine_phase                  : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      stage_4_win_result                  : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);
    signal      stage_4_tukey_result                : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);

    signal      stage_4_valid_reg                   : std_logic;
    signal      stage_4_sine_reg                    : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      stage_4_win_result_reg              : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);
    signal      stage_4_tukey_result_reg            : sfixed(WIN_INTEGER_PART downto WIN_FRAC_PART);
    signal      stage_4_done                        : std_logic;

    -- Output
    signal      output_valid                        : std_logic;
    signal      output_result                       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); 
    signal      output_last                         : std_logic; 

    signal      output_valid_reg                    : std_logic;
    signal      output_result_reg                   : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); 
    signal      output_last_reg                     : std_logic; 
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
            NB_REPT_WIDTH                       => NB_REPT_WIDTH,
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

    ------------------------------------------------------------------
    --                     Window Mode registering                           
    --                                                                
    --   Goal: Registrar o valor do tipo da janela
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: valid_i;
    --          win_mode_i;
    --
    --   Output:valid_reg; 
    --          win_mode;
    --           
    --   Result: Salva o win_mode em um registro
    ------------------------------------------------------------------
    register_win_mode : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            win_mode <= (others => '0');
        elsif(rising_edge(clock_i)) then
            valid_reg   <= valid_i;

            if (valid_i = '1') then
                win_mode    <= win_mode_i;
            end if;
        end if;
    end process;


    win_hh_blkm_blkh_valid_i            <=          valid_reg           when (      win_mode = WIN_MODE_HANN  
                                                                                or  win_mode = WIN_MODE_HAMM  
                                                                                or  win_mode = WIN_MODE_BLKM  
                                                                                or  win_mode = WIN_MODE_BLKH )  
                                            else    '0';

    win_tukey_valid_i                   <=          valid_reg             when (      win_mode = WIN_MODE_TUKEY)
                                            else    '0';

    win_hh_blkm_blkh_restart_cycles     <=          restart_cycles_i    when (      win_mode = WIN_MODE_HANN  
                                                                                or  win_mode = WIN_MODE_HAMM  
                                                                                or  win_mode = WIN_MODE_BLKM  
                                                                                or  win_mode = WIN_MODE_BLKH )
                                            else    '0';

    win_tukey_restart_cycles            <=          restart_cycles_i    when (win_mode = WIN_MODE_TUKEY)
                                            else    '0';
    
    win_window_term                     <= window_term_i;
    win_nb_points                       <= std_logic_vector( resize( unsigned(nb_points_i) * unsigned(nb_repetitions_i) , WIN_NB_POINTS_WIDTH));

    stage_2_hh_blkm_blkh_win : entity work.hh_blkm_blkh_win
        generic map( 
            PHASE_INTEGER_PART                 => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                    => PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                   => CORDIC_FRAC_PART,
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

    -------------
    -- Stage 3 --
    -------------

    -- Stage 3 serve para sincronizar todos sinais, devido ao tamanho diferente das
    -- janelas e do CORDIC

    dds_generic_shift_valid_i               <= dds_cordic_valid_o;
    dds_generic_shift_input_data            <= to_slv(dds_cordic_sine_phase);
    dds_generic_shift_sideband_data_i(0)    <= dds_cordic_done;

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
            valid_i                             => dds_generic_shift_valid_i,
            input_data_i                        => dds_generic_shift_input_data,
            sideband_data_i                     => dds_generic_shift_sideband_data_i,
            
            -- Output interface
            valid_o                             => dds_generic_shift_valid_o,
            output_data_o                       => dds_generic_shift_output_data,
            sideband_data_o                     => dds_generic_shift_sideband_data_o
        );

    win_generic_shift_valid_i           <=              win_hh_blkm_blkh_valid_o;

    win_generic_shift_input_data        <=              to_slv(win_hh_blkm_blkh_result);
   
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
            valid_i                             => win_generic_shift_valid_i,
            input_data_i                        => win_generic_shift_input_data,
            sideband_data_i                     => win_generic_shift_sideband_data_i,
            
            -- Output interface
            valid_o                             => win_generic_shift_valid_o,
            output_data_o                       => win_generic_shift_output_data,
            sideband_data_o                     => win_generic_shift_sideband_data_o
        );

    tukey_generic_shift_valid_i           <=              win_tukey_valid_o;

    tukey_generic_shift_input_data        <=              to_slv(win_tukey_result);
   
    stage_3_tukey_generic_shift: entity work.generic_shift_reg 
        generic map(
            WORD_WIDTH                          => DDS_WORD_WIDTH,
            SHIFT_SIZE                          => WIN_TUKEY_LATENCY,
            SIDEBAND_WIDTH                      => SIDEBAND_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,

            -- Input interface
            valid_i                             => tukey_generic_shift_valid_i,
            input_data_i                        => tukey_generic_shift_input_data,
            sideband_data_i                     => tukey_generic_shift_sideband_data_i,
            
            -- Output interface
            valid_o                             => tukey_generic_shift_valid_o,
            output_data_o                       => tukey_generic_shift_output_data,
            sideband_data_o                     => tukey_generic_shift_sideband_data_o
        );

    -------------
    -- Stage 4 --
    -------------

    ------------------------------------------------------------------
    --                     Cordic Window multiplier                           
    --                                                                
    --   Goal: Multiplicar o CORDIC e o seno pela janela desejada
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: stage_4_valid_i;
    --          stage_4_sine_phase;
    --          stage_4_win_result;
    --          dds_generic_shift_sideband_data_o(0);
    --
    --   Output: stage_4_valid_reg;
    --           stage_4_result
    --           stage_4_done
    --           
    --   Result: Produz o sinal janelado resultante
    ------------------------------------------------------------------

    stage_4_valid_i     <=   dds_generic_shift_valid_o;   

    stage_4_sine_phase  <= to_sfixed( dds_generic_shift_output_data, stage_4_sine_phase);

    stage_4_win_result      <=  to_sfixed(win_generic_shift_output_data, stage_4_win_result);
    stage_4_tukey_result    <=  to_sfixed(tukey_generic_shift_output_data, stage_4_win_result);
    
    stage_4_result_proc : process(clock_i,areset_i)
    begin
        if ( areset_i = '1') then
            stage_4_valid_reg <= '0';
        elsif (rising_edge(clock_i)) then
            
            stage_4_valid_reg <= stage_4_valid_i;

            if (stage_4_valid_i = '1') then
                -- Hint: Check DSP inference
                stage_4_win_result_reg      <= resize( (stage_4_sine_phase *  stage_4_win_result) ,stage_4_win_result_reg);
                stage_4_tukey_result_reg    <= resize( (stage_4_sine_phase *  stage_4_tukey_result) ,stage_4_tukey_result_reg);
                stage_4_sine_reg            <= resize( (stage_4_sine_phase) ,stage_4_sine_reg);
                stage_4_done                <= dds_generic_shift_sideband_data_o(0);
            end if;
        end if;
    end process;

    output_valid        <=          stage_4_valid_reg;
                                
    output_result       <=          stage_4_tukey_result_reg    when (win_mode = WIN_MODE_TUKEY)
                            else    stage_4_sine_reg            when (win_mode = WIN_MODE_NONE)
                            else    stage_4_win_result_reg;

    output_last         <=          stage_4_done;

    output_reg : process(clock_i,areset_i) -- Improve timming
    begin
        if ( areset_i = '1') then
            output_valid_reg <= '0';
        elsif (rising_edge(clock_i)) then
            output_valid_reg <= output_valid;

            if (output_valid = '1') then
                output_result_reg  <= output_result;
                output_last_reg    <= output_last;
            end if;
        end if;
    end process;

    ------------
    -- Output --
    ------------
    valid_o             <=          output_valid_reg;
    sine_win_phase_o    <=          output_result_reg;
    last_word_o         <=          output_last_reg;

end behavioral;
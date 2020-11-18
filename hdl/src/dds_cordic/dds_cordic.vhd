---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                           
-- Module Name: dds_cordic                                                                           
-- Author Name: Lucas Grativol Ribeiro                                                                           
--                                                                                         
-- Revision Date: 18/11/2020                                                                         
-- Tool version: Vivado 2017.4       
--                                                                    
-- Goal:          Produzir um seno um cosseno usando o algoritmo CORDIC para uma data frequência
--                                                                         
-- Description:   Modulo TOP que instancia:                                                                          
--                phase_acc ==> pre_processador ==> CORDIC ==> pos_processador
--                                                                                         
--                Cada bloco nessa sequência tem sua própria função:                                                                           
--                * phase_acc         : Acumulador de fase que gera ângulos de [0,2pi], podendo repetir 
--                                      esse processo por um número de repetições (ver bloco)
--                * pre_processador   : Como o algoritmo CORDIC só converge entre [-pi/2;pi/2]
--                                      o pre_proc mapeia o ângulo [0;2pi] --> [-pi/2;pi/2]                       
--                * CORDIC            : Bloco que implementa o algoritmo CORDIC com N iterações                       
--                * pos_processador   : O pre_processador causa erros de sinal (+ ou -) nos cossenos 
--                                      e senos, o pos_processador corrige esse sinal                       
--
--
--               Para o bloco é fornecido:
--               * phase_term : a variação de fase usada para pelo acumulador de fase para gerar os ângulos
--                              phase_term = 2pi/(nb_points)
--               * nb_points  : Número de pontos do seno/cosseno em 1 período 
--                              nb_points = (f_sampling/f_target)
--                              f_target = frequência desejada para o seno/cosseno
--               * initial_phase : Fase inicial do seno/cosseno
--               * nb_repetitions: Número de períodos do seno/cosseno a serem gerados
--               * mode_time : Modo "especial" que transforma a fase inicial em um delay
--                             no tempo, da forma : número_de_ciclos_delay = initial_phase / phase_term
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

------------
-- Entity --
------------

entity dds_cordic is
    generic(
        PHASE_INTEGER_PART                  : natural; -- phase integer part
        PHASE_FRAC_PART                     : integer; -- phase fractional part
        CORDIC_INTEGER_PART                 : integer; -- Cordic integer part
        CORDIC_FRAC_PART                    : integer; -- Cordic frac part
        N_CORDIC_ITERATIONS                 : natural; -- Número de iterações do CORDIC (tamanho do pipeline)
        NB_POINTS_WIDTH                     : natural; -- Número de bits de nb_points e nb_repetitions 
        EN_POSPROC                          : boolean -- Enable bloco pos_processador, necessário para o cosseno
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Indica que todos os parâmetros abaixo são válidos no ciclo atual
        phase_term_i                        : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); -- Ver descrição acima
        initial_phase_i                     : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); -- Ver descrição acima
        nb_points_i                         : in  std_logic_vector( (NB_POINTS_WIDTH - 1) downto 0); -- Ver descrição acima
        nb_repetitions_i                    : in  std_logic_vector( (NB_POINTS_WIDTH - 1) downto 0); -- Ver descrição acima
        mode_time_i                         : in  std_logic;  -- Ver descrição acima
        
        restart_cycles_i                    : in  std_logic;  -- Restart a geração da onda definina nos parâmetros anteriores
                                                              -- todos os parâmetros são salvos, com um tick de restart
                                                              -- a onda é gerada com os últimos parâmetros, não depende do "valid_i"
        -- Output interface
        valid_o                             : out std_logic; -- Indica que as saída abaixo são válidas no ciclo atual
        sine_phase_o                        : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); -- Seno
        cos_phase_o                         : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); -- Cosseno (para usar habilite o EN_POSPROC)
        done_cycles_o                       : out std_logic; -- Indica que é o último clock ("last signal")
        flag_full_cycle_o                   : out std_logic -- Indica o fim de um período
    );
end dds_cordic;

------------------
-- Architecture --
------------------
architecture behavioral of dds_cordic is

    ---------------
    -- Constants --
    ---------------
    -- 0,607253 = 1/Ak = limit(k->+infinito) prod(k=0)^(k=infinito) cos(arctg(2^-k))
    constant    CORDIC_FACTOR               : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART) := to_sfixed( (0.607253) , CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
    -- Sideband é usado para conduzir o sinal done_cycles por todo o pipeline do dds_cordic
    constant    PREPROC_SIDEBAND_WIDTH      : natural  := 1;
    constant    CORDIC_SIDEBAND_WIDTH       : natural  := 2 + PREPROC_SIDEBAND_WIDTH ;
    constant    POSPROC_SIDEBAND_WIDTH      : natural  := 1 ;
    
    -------------
    -- Signals --
    -------------
    
    -- Stage 1 Phase accumulator
    signal      phase_acc_valid_i           : std_logic;
    signal      phase_acc_phase_term        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);   
    signal      phase_acc_initial_phase     : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal      phase_acc_nb_points         : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_acc_nb_repetitions    : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_acc_mode_time         : std_logic;

    signal      phase_acc_restart_cycles    : std_logic;
    signal      phase_acc_done_cycles       : std_logic;
    signal      phase_acc_flag_full_cycle   : std_logic;

    signal      phase_acc_valid_o           : std_logic;
    signal      phase_acc_phase             : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);

    -- Stage 2 Preprocessor
    signal      preproc_valid_i             : std_logic;
    signal      preproc_phase               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
       
    signal      preproc_phase_info          : std_logic_vector(1 downto 0);
    
    signal      preproc_valid_o             : std_logic;
    signal      preproc_reduced_phase       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    signal      preproc_sideband_i          : std_logic_vector((PREPROC_SIDEBAND_WIDTH - 1) downto 0);
    signal      preproc_sideband_o          : std_logic_vector((PREPROC_SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 3 Cordic Core
    signal      cordic_core_valid_i         : std_logic;
    signal      cordic_core_x_i             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      cordic_core_y_i             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      cordic_core_z_i             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    
    signal      cordic_core_valid_o         : std_logic;
    signal      cordic_core_x_o             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      cordic_core_y_o             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      cordic_core_z_o             : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    signal      cordic_core_sideband_i      : std_logic_vector((CORDIC_SIDEBAND_WIDTH - 1) downto 0);
    signal      cordic_core_sideband_o      : std_logic_vector((CORDIC_SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 4 Posprocessor
    signal      posproc_valid_i              : std_logic;
    signal      posproc_sin_phase_i         : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      posproc_cos_phase_i         : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      posproc_phase_info          : std_logic_vector(1 downto 0);

    signal      posproc_valid_o              : std_logic;
    signal      posproc_sin_phase_o         : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal      posproc_cos_phase_o         : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    signal      posproc_sideband_i          : std_logic_vector((POSPROC_SIDEBAND_WIDTH - 1) downto 0);
    signal      posproc_sideband_o          : std_logic_vector((POSPROC_SIDEBAND_WIDTH - 1) downto 0);
    
begin

    -------------
    -- Stage 1 --
    -------------

    phase_acc_valid_i           <= valid_i;
    phase_acc_phase_term        <= phase_term_i;
    phase_acc_initial_phase     <= initial_phase_i;
    phase_acc_nb_points         <= nb_points_i;
    phase_acc_nb_repetitions    <= nb_repetitions_i;  
    phase_acc_mode_time         <= mode_time_i;
    phase_acc_restart_cycles    <= restart_cycles_i;

    stage_1_phase_acc : entity work.phase_acc_v2
        generic map(
            PHASE_INTEGER_PART                 => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                    => PHASE_FRAC_PART,
            NB_POINTS_WIDTH                    => NB_POINTS_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                            => clock_i,
            areset_i                           => areset_i,
    
            -- Input interface
            valid_i                            => phase_acc_valid_i,
            phase_term_i                       => phase_acc_phase_term,
            initial_phase_i                    => phase_acc_initial_phase,
            nb_points_one_period_i             => phase_acc_nb_points,
            nb_repetitions_i                   => phase_acc_nb_repetitions,
            mode_time_i                        => phase_acc_mode_time,
    
            -- Control interface
            restart_acc_i                      => phase_acc_restart_cycles,
            
            -- Debug interface
            flag_done_o                        => phase_acc_done_cycles,
            flag_period_o                      => phase_acc_flag_full_cycle,
    
            -- Output interface
            valid_o                            => phase_acc_valid_o,
            phase_o                            => phase_acc_phase
        ); 
        
    -------------
    -- Stage 2 --
    -------------

    preproc_sideband_i(0)       <= phase_acc_done_cycles;
    preproc_valid_i             <= phase_acc_valid_o;
    preproc_phase               <= phase_acc_phase;

    stage_2_preproc : entity work.preproc
        generic map(
            SIDEBAND_WIDTH                      => PREPROC_SIDEBAND_WIDTH,
            PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => PHASE_FRAC_PART,
            OUTPUT_INTEGER_PART                 => CORDIC_INTEGER_PART,
            OUTPUT_FRAC_PART                    => CORDIC_FRAC_PART
        )
        port map(
            -- Clock interface
            clock_i                            =>  clock_i, 
            areset_i                           =>  areset_i, 

            sideband_data_i                    =>  preproc_sideband_i,
            sideband_data_o                    =>  preproc_sideband_o,

            -- Input interface
            valid_i                            =>  preproc_valid_i, 
            phase_i                            =>  preproc_phase,

            -- Control Interface
            phase_info_o                       =>  preproc_phase_info, -- informação sobre a fase usada pelo pos_proc para
                                                                       -- corrigir o sinal (+ ou -) do cosseno
            -- Output interface
            valid_o                            =>  preproc_valid_o,
            reduced_phase_o                    =>  preproc_reduced_phase --conversão da fase de [0;2pi]->[-pi/2;pi/2]
        ); 

    --------------
    -- Stage 3  --
    --------------
    
    cordic_core_valid_i      <= preproc_valid_o;
    -- vetor (cordic_core_x_i,cordic_core_y_i) = (CORDIC_FACTOR;0) está  dentro do círculo unitário
    -- assim a saída é (cosseno(cordic_core_z_i) ; seno(cordic_core_z_i))
    cordic_core_x_i         <= CORDIC_FACTOR; 
    cordic_core_y_i         <= (others => '0');
    cordic_core_z_i         <= preproc_reduced_phase;
    cordic_core_sideband_i  <= (preproc_sideband_o & preproc_phase_info);

    stage_3_cordic_core : entity work.cordic_core
        generic map(
            SIDEBAND_WIDTH         => CORDIC_SIDEBAND_WIDTH,
            CORDIC_INTEGER_PART    => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART       => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS    => N_CORDIC_ITERATIONS
        )
        port map (
            clock_i                         => clock_i, 
            areset_i                        => areset_i, -- Positive async reset

            sideband_data_i                 => cordic_core_sideband_i,
            sideband_data_o                 => cordic_core_sideband_o,
            
            valid_i                          => cordic_core_valid_i, -- Valid in
            
            X_i                             => cordic_core_x_i,   -- X coordenada inicial
            Y_i                             => cordic_core_y_i,   -- Y coordenada inicial
            Z_i                             => cordic_core_z_i,   -- ângulo para rotação
            
            valid_o                          => cordic_core_valid_o, -- Valid out
            X_o                             => cordic_core_x_o, -- cosseno 
            Y_o                             => cordic_core_y_o, -- seno
            Z_o                             => cordic_core_z_o  -- ângulo depois da rotação
        );

    --------------
    -- Stage 4  --
    --------------

    posproc_valid_i        <=  cordic_core_valid_o;
    posproc_sin_phase_i   <=  cordic_core_y_o;
    posproc_cos_phase_i   <=  cordic_core_x_o;
    posproc_phase_info    <=  cordic_core_sideband_o(1 downto 0);
    posproc_sideband_i    <=  cordic_core_sideband_o(2 downto 2);

    POSPROC_GEN_TRUE: 
        if (EN_POSPROC) generate
            stage_4_posproc : entity work.posproc
                generic map(
                    SIDEBAND_WIDTH                      => POSPROC_SIDEBAND_WIDTH,
                    WORD_INTEGER_PART                   => CORDIC_INTEGER_PART,
                    WORD_FRAC_PART                      => CORDIC_FRAC_PART
                )
                port map(
                    -- Clock interface
                    clock_i                             => clock_i, 
                    areset_i                            => areset_i, -- Positive async reset

                    -- Sideband
                    sideband_data_i                     => posproc_sideband_i,
                    sideband_data_o                     => posproc_sideband_o,
        
                    -- Input interface
                    valid_i                             => posproc_valid_i, -- Valid in
                    sin_phase_i                         => posproc_sin_phase_i, 
                    cos_phase_i                         => posproc_cos_phase_i,
        
                    -- Control Interface
                    phase_info_i                        => posproc_phase_info,
        
                    -- Output interface
                    valid_o                             => posproc_valid_o, -- Valid out
                    sin_phase_o                         => posproc_sin_phase_o, -- seno com sinal corrigido
                    cos_phase_o                         => posproc_cos_phase_o -- cosseno com sinal corrigido
                ); 
        end generate POSPROC_GEN_TRUE;
    
    POSPROC_GEN_FALSE: 
        if (not EN_POSPROC) generate
            posproc_valid_o          <= posproc_valid_i;
            posproc_sideband_o      <= posproc_sideband_i;
            posproc_sin_phase_o     <= posproc_sin_phase_i;
            posproc_cos_phase_o     <= posproc_cos_phase_i;
        end generate POSPROC_GEN_FALSE;
    
    ------------
    -- Output --
    ------------

    valid_o             <= posproc_valid_o;
    flag_full_cycle_o   <= phase_acc_flag_full_cycle;
    sine_phase_o        <= posproc_sin_phase_o;
    cos_phase_o         <= posproc_cos_phase_o;
    done_cycles_o       <= posproc_sideband_o(0); -- last signal

    end behavioral;

---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                         
-- Module Name: tukey_win 
-- Author Name: Lucas Grativol Ribeiro                          
--                                                                                         
-- Revision Date: 24/11/2020                                                                         
-- Tool version: Vivado 2017.4                                                                           
--                                                                      
-- Goal: Gerar a janela Tukey  
--
-- Description:   Modulo TOP que instancia:                                                                          
--                tukey_phase_acc ==> pre_processador ==> CORDIC ==> pos_processador
--                                                                                         
--                Cada bloco nessa sequência tem sua própria função:                                                                           
--                * tukey_phase_acc   : Acumulador de fase de acordo com o algoritmo da janela Tukey (ver bloco e algoritmo)
--                * pre_processador   : Como o algoritmo CORDIC só converge entre [-pi/2;pi/2]
--                                      o pre_proc mapeia o ângulo [0;2pi] --> [-pi/2;pi/2]                       
--                * CORDIC            : Bloco que implementa o algoritmo CORDIC com N iterações                       
--                * pos_processador   : O pre_processador causa erros de sinal (+ ou -) nos cossenos 
--                                      e senos, o pos_processador corrige esse sinal                       
--
--
--               Para o bloco é fornecido:
--               * phase_term : a variação de fase usada para pelo acumulador de fase para gerar os ângulos
--                              phase_term = 2pi/(alfa.L)
--               * nb_points  : Número de pontos da janela 
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

entity tukey_win is
    generic(
        WIN_PHASE_INTEGER_PART             : natural; -- phase integer part
        WIN_PHASE_FRAC_PART                : integer; -- phase fractional part
        TK_INTEGER_PART                    : natural; -- tukey word integer part
        TK_FRAC_PART                       : integer; -- tukey word frac part
        TK_NB_ITERATIONS                   : positive; -- Número de iterações do CORDIC (tamanho do pipeline)
        NB_POINTS_WIDTH                    : positive  -- Número de bits de nb_points e nb_repetitions             
   );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Indica que todos os parâmetros abaixo são válidos no ciclo atual
        phase_term_i                        : in  ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART); -- Ver descrição acima
        nb_points_i                         : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0 ); -- Ver descrição acima
        restart_cycles_i                    : in  std_logic; -- Restart a geração da onda definina nos parâmetros anteriores
                                                             -- todos os parâmetros são salvos, com um tick de restart
                                                             -- a onda é gerada com os últimos parâmetros, não depende do "valid_i"
        
        -- Output interface
        valid_o                             : out std_logic;
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
    -- 0,607253 = 1/Ak = limit(k->+infinito) prod(k=0)^(k=infinito) cos(arctg(2^-k))
    constant    CORDIC_FACTOR           : sfixed(TK_INTEGER_PART downto TK_FRAC_PART) := to_sfixed( (0.607253) , TK_INTEGER_PART, TK_FRAC_PART);
    constant    SIDEBAND_WIDTH          : natural := 2;
    constant    NOT_USED_SIDEBAND_WIDTH : integer := -1;
    
    -- Tukey constants
    constant    WIN_A0                  : sfixed(TK_INTEGER_PART downto TK_FRAC_PART) := to_sfixed( (0.5) , TK_INTEGER_PART, TK_FRAC_PART);
    constant    WIN_A1                  : sfixed(TK_INTEGER_PART downto TK_FRAC_PART) := to_sfixed( (0.5) , TK_INTEGER_PART, TK_FRAC_PART);
    constant    WIN_MINUS_A1            : sfixed(TK_INTEGER_PART downto TK_FRAC_PART) := resize( (-WIN_A1) , TK_INTEGER_PART, TK_FRAC_PART);
    
    -------------
    -- Signals --
    -------------
    
    -- Stage 1 Phase accumulator (Tukey)
    signal      phase_acc_valid_i               : std_logic;
    signal      phase_acc_phase_term            : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);   
    signal      phase_acc_nb_points             : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      phase_acc_nb_repetitions        : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);

    signal      phase_acc_restart_cycles        : std_logic;
    signal      phase_acc_done_cycles           : std_logic;
    signal      phase_acc_flag_full_cycle       : std_logic;

    signal      phase_acc_valid_o               : std_logic;
    signal      phase_acc_phase                 : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
    
    -- Stage 2 Preprocessor
    signal      preproc_valid_i                 : std_logic;
    signal      preproc_phase                   : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
    
    signal      preproc_phase_info              : std_logic_vector(1 downto 0);
    
    signal      preproc_valid_o                 : std_logic;
    signal      preproc_reduced_phase           : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);

    signal      preproc_sideband_i              : std_logic_vector((NOT_USED_SIDEBAND_WIDTH - 1) downto 0);
    signal      preproc_sideband_o              : std_logic_vector((NOT_USED_SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 3 Cordic Core
    signal      cordic_core_valid_i             : std_logic;
    signal      cordic_core_x_i                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      cordic_core_y_i                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      cordic_core_z_i                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    
    signal      cordic_core_valid_o             : std_logic;
    signal      cordic_core_x_o                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      cordic_core_y_o                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      cordic_core_z_o                 : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);

    signal      cordic_core_sideband_i          : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    signal      cordic_core_sideband_o          : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 4 Posprocessor
    signal      posproc_valid_i                 : std_logic;
    signal      posproc_sin_phase_i             : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      posproc_cos_phase_i             : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      posproc_phase_info              : std_logic_vector(1 downto 0);

    signal      posproc_valid_o                 : std_logic;
    signal      posproc_sin_phase_o             : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      posproc_cos_phase_o             : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);

    signal      posproc_sideband_i              : std_logic_vector((NOT_USED_SIDEBAND_WIDTH - 1) downto 0);
    signal      posproc_sideband_o              : std_logic_vector((NOT_USED_SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 5 Window result
    signal      win_valid_i                     : std_logic;
    signal      win_sin_phase                   : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    signal      win_cos_phase                   : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);

    signal      win_valid_1_reg                 : std_logic;
    signal      win_minus_a1_cos_reg            : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);
    
    signal      win_valid_2_reg                 : std_logic;
    signal      win_a0_minus_a1_cos_reg         : sfixed(TK_INTEGER_PART downto TK_FRAC_PART);    

begin

    -------------
    -- Stage 1 --
    -------------

    phase_acc_valid_i           <= valid_i;
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
            valid_i                            => phase_acc_valid_i,
            phase_term_i                       => phase_acc_phase_term,
            nb_points_one_period_i             => phase_acc_nb_points,
            nb_repetitions_i                   => phase_acc_nb_repetitions,
    
            -- Control interface
            restart_acc_i                      => phase_acc_restart_cycles,
            
            -- Debug interface
            flag_done_o                        => open,
            flag_period_o                      => open,
    
            -- Output interface
            valid_o                            => phase_acc_valid_o,
            phase_o                            => phase_acc_phase
        ); 

    -------------
    -- Stage 2 --
    -------------

    preproc_valid_i  <= phase_acc_valid_o;
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
            valid_i                            =>  preproc_valid_i,
            phase_i                            =>  preproc_phase,
            
            -- Control Interface
            phase_info_o                       =>  preproc_phase_info,

            -- Output interface
            valid_o                            => preproc_valid_o,
            reduced_phase_o                    => preproc_reduced_phase
        ); 

    --------------
    -- Stage 3  --
    --------------
    
    cordic_core_valid_i <= preproc_valid_o;

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
            areset_i                        => areset_i, 

            sideband_data_i                 => cordic_core_sideband_i,
            sideband_data_o                 => cordic_core_sideband_o,
            
            valid_i                         => cordic_core_valid_i, 
            
            X_i                             => cordic_core_x_i,  
            Y_i                             => cordic_core_y_i,   
            Z_i                             => cordic_core_z_i,   
            
            valid_o                         => cordic_core_valid_o,
            X_o                             => cordic_core_x_o,  
            Y_o                             => cordic_core_y_o, 
            Z_o                             => cordic_core_z_o 
        );

    -------------
    -- Stage 4 --
    -------------

    posproc_valid_i       <=  cordic_core_valid_o;
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
            
            sideband_data_i                     => posproc_sideband_i,
            sideband_data_o                     => posproc_sideband_o,

            -- Input interface
            valid_i                             => posproc_valid_i,
            sin_phase_i                         => posproc_sin_phase_i,
            cos_phase_i                         => posproc_cos_phase_i,

            -- Control Interface
            phase_info_i                        => posproc_phase_info,

            -- Output interface
            valid_o                             => posproc_valid_o,
            sin_phase_o                         => posproc_sin_phase_o,
            cos_phase_o                         => posproc_cos_phase_o
        ); 


    -------------
    -- Stage 5 --
    -------------

    ------------------------------------------------------------------
    --                     Grupo Equação 1                           
    --                                                                
    --   Goal: Calcular os termos -a1.cos(2pi)
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: win_valid_i;
    --          win_cos_phase;
    --          WIN_MINUS_A1;
    --          win_cos_2pi_phase;
    --          win_cos_4pi_phase;
    --          win_cos_6pi_phase;
    --
    --   Output: win_valid_1_reg;
    --           win_minus_a1_cos_reg;
    --
    --   Result: Os termos usados em todas as janelas são calculados com os coeficientes
    ------------------------------------------------------------------

    win_valid_i    <= posproc_valid_o;
    win_cos_phase <= posproc_cos_phase_o;
  
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

    ------------------------------------------------------------------
    --                     Grupo Equação 2                          
    --                                                                
    --   Goal: Calcular os termos a0-a1.cos(2pi)
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: win_valid_1_reg;
    --          win_minus_a1_cos_reg;
    --          WIN_A0;
    --
    --   Output: win_valid_2_reg;
    --           win_a0_minus_a1_cos_reg;
    --
    --   Result: Os termos usados em todas as janelas são calculados com os coeficientes
    ------------------------------------------------------------------
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
    valid_o             <= win_valid_2_reg;
    tk_result_o         <= win_a0_minus_a1_cos_reg ;

    end behavioral;

---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                           
-- Module Name: phase_acc_v2                                                                           
-- Author Name: Lucas Grativol Ribeiro                                                                           
--                                                                                         
-- Revision Date: 18/11/2020                                                                         
-- Tool version: Vivado 2017.4       
--                                                                    
-- Goal:          Acumulador de fase para produzir os ângulos de [0;2pi] podendo repetir 
--                esse processo por um número de repetições
--                                                                         
-- Description:  
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
--               Cada parâmetro é salvo perante um "valid_i", o sinal "valid_i" age como um 
--               sinal "go" também. 
--               O sinal "restart_acc_i" reseta o acumulador para executar com os parâmetros salvos.
--               "restart_acc_i" funciona com falling_edge (transição de alto para baixo)
--               Enquanto alto (HIGH) "restart_acc_i" age como sinal de hold para o phase_acc
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

entity phase_acc_v2 is
    generic(
        PHASE_INTEGER_PART                 : natural ; -- phase integer part
        PHASE_FRAC_PART                    : integer ; -- phase fractional part
        NB_POINTS_WIDTH                    : positive -- nb_points/nb_repetitions width
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Indica que os parâmetros da interface são válidos no ciclo atual
        phase_term_i                        : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); -- Ver acima
        initial_phase_i                     : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); -- Ver acima
        nb_points_one_period_i              : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0); -- Ver acima
        nb_repetitions_i                    : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0); -- Ver acima
        mode_time_i                         : in  std_logic;

        -- Control interface
        restart_acc_i                       : in  std_logic;  -- Em falling_edge reseta o acumulador -- Ver acima
        
        -- Debug interface
        flag_done_o                         : out std_logic; -- Indica que é o último ciclo
        flag_period_o                       : out std_logic; -- Indica o final de 1 período

        -- Output interface
        valid_o                             : out std_logic; -- Indica que a fase é válida no ciclo atual
        phase_o                             : out ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) -- fase variando de [0;2pi]
    ); 
end phase_acc_v2;

------------------
-- Architecture --
------------------

architecture behavioral of phase_acc_v2 is

    ---------------
    -- Constants --
    ---------------
 
    -------------
    -- Signals --
    -------------
    
    -- Input signals
    signal input_valid                          : std_logic; 
    signal phase_term                           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal initial_phase                        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal nb_points_one_period                 : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_repetitions                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal mode_time                            : std_logic; 
    signal restart_acc                          : std_logic; 
    
    -- Behavioral
    signal valid_new_term_reg                   : std_logic;

    signal phase_term_reg                       : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);    
    signal initial_phase_reg                    : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal nb_points_one_period_reg             : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_repetitions_reg                   : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal mode_time_reg                        : std_logic; 
    
    signal start_new_cycle                      : std_logic;
    signal restart_acc_reg                      : std_logic;
    signal neg_edge_detector_restart_acc        : std_logic;
    signal set_phase                            : std_logic;
    
    signal output_valid                         : std_logic;
    signal output_valid_reg                     : std_logic;
    signal phase_acc                            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
    signal enable_counters                      : std_logic;
    signal nb_points_one_period_counter         : unsigned((NB_POINTS_WIDTH - 1) downto 0);
    signal full_period_done                     : std_logic;
    
    signal nb_repetitions_counter               : unsigned((NB_POINTS_WIDTH - 1) downto 0);
    signal full_wave_done                       : std_logic;

    signal phase_time_counter                   : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal phase_time_counter_not_done          : std_logic;
    signal phase_time_counter_not_done_reg      : std_logic;
    
begin          
    
    -- Input
    input_valid             <=  valid_i;
    phase_term              <=  phase_term_i;
    initial_phase           <=  initial_phase_i;
    nb_points_one_period    <=  nb_points_one_period_i;
    nb_repetitions          <=  nb_repetitions_i;
    mode_time               <=  mode_time_i;
    restart_acc             <=  restart_acc_i;
    
    ------------------------------------------------------------------
    --                     Input registering                           
    --                                                                
    --   Goal: Registrar os parâmetros fornecidos
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: input_valid;
    --          phase_term;
    --          nb_repetitions;
    --          nb_points_one_period;
    --          initial_phase;
    --          mode_time
    --
    --   Output: valid_new_term_reg;
    --           nb_repetitions_reg;
    --           nb_points_one_period_reg;
    --           initial_phase_reg;
    --           mode_time_reg
    --
    --   Result: Salva os parâmetros (inputs) em registros e 
    --           indica que um novo ciclo pode começar "valid_new_term_reg"
    ------------------------------------------------------------------

    input_regs : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            valid_new_term_reg <= '0';
            mode_time_reg     <= '0';

        elsif (rising_edge(clock_i) ) then                       
            valid_new_term_reg <= input_valid;

            if (input_valid = '1') then
                phase_term_reg              <= phase_term;
                nb_repetitions_reg          <= nb_repetitions;
                nb_points_one_period_reg    <= nb_points_one_period;
                initial_phase_reg           <= initial_phase;
                mode_time_reg               <= mode_time;
            end if;

        end if;
    end process;

    ------------------------------------------------------------------
    --                     Acumulador de phase                           
    --                                                                
    --   Goal: Acumular a fase (phase_acc) ; registrar o sinal
    --         restart_acc para o falling_edge_detector
    -- 
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: output_valid;
    --          restart_acc;
    --          set_phase;
    --          mode_time_reg;
    --          initial_phase_reg;
    --          phase_term_reg
    --
    --   Output: output_valid_reg;
    --           restart_acc_reg;
    --           phase_acc;
    --
    --   Result: Acumulação da phase (phase_acc) normal 
    --           e em modo "mode_time". 
    ------------------------------------------------------------------

    phase_acc_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then

            output_valid_reg    <= '0';
            restart_acc_reg     <= '0';

        elsif ( rising_edge(clock_i) ) then

            output_valid_reg    <= output_valid;
            restart_acc_reg     <= restart_acc;

            if (output_valid = '1') then

                if (set_phase = '1') then
                    if(mode_time_reg = '1') then
                        phase_acc <= (others => '0');
                    else
                        phase_acc <= initial_phase_reg;
                    end if;
                else
                    phase_acc <= resize( (phase_acc + phase_term_reg) ,PHASE_INTEGER_PART,PHASE_FRAC_PART);
                end if;
                
            end if;
        end if;
    end process;

    neg_edge_detector_restart_acc   <=                  restart_acc_reg -- Detecta falling_edge sobre o sinal
                                                    and (not restart_acc);

    -- Reseta o bloco
    start_new_cycle                 <=                  valid_new_term_reg  -- novos parâmetros fornecidos
                                                    or  neg_edge_detector_restart_acc;  -- Restart com os últimos parâmetros
    -- Reseta a acumulação a cada período completo
    set_phase                       <=                  full_period_done    -- Full cycle (number of repetitions)
                                                    or  start_new_cycle     -- Reset cycle signal
                                                    or  phase_time_counter_not_done_reg; -- Ver abaixo 
    -- Determina que a saída é valída
    output_valid                     <=              (       (not full_wave_done)    -- Período não completo    
                                                        and output_valid_reg      )  -- and phase_acc válida
                                                    or  start_new_cycle;             -- Novos parâmetros

    ------------------------------------------------------------------
    --                     Contadores                           
    --                                                                
    --   Goal: Controle do número de pontos e número de repetições
    --         já executadas
    -- 
    --   Clock & reset domain: clock_i & areset_i
    --
    --   Input: enable_counters;
    --          full_period_done;
    --          restart_acc;
    --          nb_repetitions_counter;
    --          nb_points_one_period_counter;
    --
    --   Output: nb_repetitions_counter;
    --           nb_points_one_period_counter;
    --
    --   Result: Marca quando o acumulador de phase
    --           terminou um período e/ou terminou 
    --           a geração da onda completa
    ------------------------------------------------------------------

    enable_counters     <=          output_valid
                                and not(phase_time_counter_not_done_reg);

    counters : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then

            nb_points_one_period_counter    <= (others => '0');
            nb_repetitions_counter          <= (others => '0');

        elsif (rising_edge(clock_i)) then

            if(enable_counters = '1') then
               
                if(full_period_done = '1') then                    
                    nb_points_one_period_counter    <= (others => '0');
                    nb_repetitions_counter          <= nb_repetitions_counter + 1;
                else
                    nb_points_one_period_counter <= nb_points_one_period_counter + 1;
                end if;                
            end if;

            if((restart_acc = '1')) then
                nb_points_one_period_counter    <= (others => '0');
                nb_repetitions_counter          <= (others => '0');
            end if;

        end if;
    end process;

    full_period_done     <=             '1'     when (  nb_points_one_period_counter = ( unsigned(nb_points_one_period_reg) - 1) )
                                else    '0'; -- 1 período completo
            
    full_wave_done      <=              '1'     when (  nb_repetitions_counter  = ( unsigned(nb_repetitions_reg)) )
                                else    '0';-- Todas as repetições completas

    ------------------------------------------------------------------
    --                     Contador Mode Time                           
    --                                                                
    --   Goal: Contar os ciclos necessários para atingir
    --         initial_phase, usando phase_term
    --         no mode_time = '1'
    -- 
    --   Clock & reset domain: clock_i & areset_i
    --
    --   Input: phase_time_counter_not_done;
    --          output_valid;
    --          phase_time_counter;
    --          restart_acc;
    --
    --   Output: phase_time_counter;
    --           phase_time_counter_not_done_reg;
    --
    --   Result: Atrasa a geração da fase até  
    --           initial_phase, deixando a saída "0"
    --           o efeito é um delay no tempo, em função da fase
    ------------------------------------------------------------------

    -- Phase time
    phase_time_counter_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            phase_time_counter          <= (others => '0');
        elsif (rising_edge(clock_i)) then

            phase_time_counter_not_done_reg <=  phase_time_counter_not_done;

            if((output_valid = '1')) then

                if( phase_time_counter_not_done = '1') then
                    phase_time_counter      <= resize( (phase_time_counter + phase_term_reg) 
                                                       ,PHASE_INTEGER_PART,PHASE_FRAC_PART);
                end if;

                if((restart_acc = '1')) then
                    phase_time_counter <= (others => '0'); 
                end if;

            end if;
        end if;
    end process;

    phase_time_counter_not_done     <=          '0' when (              phase_time_counter >= (initial_phase_reg - phase_term_reg)
                                                                    or  mode_time_reg = '0'                      )
                                        else    '1';
                                
    -- Output
    valid_o             <= output_valid_reg;
    phase_o             <= phase_acc;
    flag_period_o       <= full_period_done; 
    flag_done_o         <= full_wave_done;

end behavioral;
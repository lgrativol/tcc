---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                           
-- Module Name: tukey_phase_acc                                                                           
-- Author Name: Lucas Grativol Ribeiro                                                                           
--                                                                                         
-- Revision Date: 24/11/2020                                                                         
-- Tool version: Vivado 2017.4       
--                                                                    
-- Goal:          Acumulador de fase para a fase do Tukey -> 2pi/(alfa.L)
--                                                                         
-- Description:  
--               Para o bloco é fornecido:
--               * phase_term : a variação de fase usada para pelo acumulador de fase para gerar os ângulos
--                              phase_term = 2pi/(alfa.L)
--               * nb_points_one_period_i : Número de pontos total da janela - 1 (Não é o parâmetro L)
--               * nb_repetitions: Número de períodos do seno/cosseno a serem gerados
--
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

entity tukey_phase_acc is
    generic(
        WIN_ALFA                           : real; -- Coeficiente alfa da janela Tukey
        PHASE_INTEGER_PART                 : natural; -- phase integer part
        PHASE_FRAC_PART                    : integer; -- phase fractional part
        NB_POINTS_WIDTH                    : positive  -- nb_points/nb_repetitions width
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Indica que os parâmetros da interface são válidos no ciclo atual
        phase_term_i                        : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); -- Ver acima
        nb_points_one_period_i              : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0); -- Ver acima
        nb_repetitions_i                    : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0); -- Ver acima

        -- Control interface
        restart_acc_i                       : in  std_logic;  -- Em falling_edge reseta o acumulador -- Ver acima
        
        -- Debug interface
        flag_done_o                         : out std_logic; -- Debug 
        flag_period_o                       : out std_logic; -- Debug

        -- Output interface
        valid_o                             : out std_logic; -- Indica que a fase é válida no ciclo atual
        phase_o                             : out ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) -- fase
    ); 
end tukey_phase_acc;

------------------
-- Architecture --
------------------

architecture behavioral of tukey_phase_acc is

    ---------------
    -- Constants --
    ---------------

    constant    TUKEY_ALFA                      : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := to_ufixed(WIN_ALFA , PHASE_INTEGER_PART ,PHASE_FRAC_PART);
    constant    TUKEY_ALFA_HALF                 : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := to_ufixed(WIN_ALFA / 2.0 , PHASE_INTEGER_PART ,PHASE_FRAC_PART);
 
    -------------
    -- Signals --
    -------------
    
    -- Input signals
    signal input_valid                          : std_logic; 
    signal phase_term                           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal initial_phase                        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal nb_points_one_period                 : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_repetitions                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    
    signal restart_acc                          : std_logic; 
    
    -- Behavioral
    signal valid_input_delay                    : std_logic;
    signal valid_input_delay_reg                : std_logic;
    signal valid_new_term_reg                   : std_logic;

    signal phase_term_reg                       : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);    
    signal initial_phase_reg                    : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal nb_points_one_period_reg             : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_repetitions_reg                   : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    
    signal nb_l_points_reg                      : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal ufixed_nb_l_points_reg               : ufixed((NB_POINTS_WIDTH - 1) downto 0);  
    signal nb_half_l_alfa                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_half_points                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_half_points_plus_half_l_alfa      : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);

    signal hold_phase                           : std_logic;
    signal hold_phase_reg                       : std_logic;
    signal reverse_acc                          : std_logic;
    signal reverse_acc_reg                      : std_logic;
    signal neg_edge_detector_hold_phase         : std_logic;
    signal less_half_alfa_l                     : std_logic;
    signal less_half_points_plus_half_l_alfa    : std_logic;

    signal start_new_cycle                      : std_logic;
    signal restart_acc_reg                      : std_logic;
    signal neg_edge_detector_restart_acc        : std_logic;
    signal set_phase                            : std_logic;
    
    signal output_valid                         : std_logic;
    signal output_valid_reg                     : std_logic;
    signal phase_acc                            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal output_phase                         : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
    signal enable_counters                      : std_logic;
    signal nb_points_one_period_counter         : unsigned((NB_POINTS_WIDTH - 1) downto 0);
    signal full_period_done                     : std_logic;
    
    signal nb_repetitions_counter               : unsigned((NB_POINTS_WIDTH - 1) downto 0);
    signal full_wave_done                       : std_logic;
    
begin          
    
    -- Input
    input_valid             <=  valid_i;
    phase_term              <=  phase_term_i;
    nb_points_one_period    <=  nb_points_one_period_i;
    nb_repetitions          <=  nb_repetitions_i;
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
    --
    --   Output: valid_input_delay;
    --           phase_term_reg;
    --           nb_repetitions_reg;
    --           nb_points_one_period_reg;
    --           nb_l_points_reg
    --
    --   Result: Salva os parâmetros (inputs) em registros e registra o
    --           vetor L = nb_points + 1
    ------------------------------------------------------------------
    input_regs : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            valid_input_delay <= '0';

        elsif (rising_edge(clock_i) ) then                       
            valid_input_delay <= input_valid;

            if (input_valid = '1') then
                phase_term_reg              <= phase_term;
                nb_repetitions_reg          <= nb_repetitions;
                nb_points_one_period_reg    <= nb_points_one_period;
                nb_l_points_reg             <= std_logic_vector(unsigned(nb_points_one_period) + 1);
            end if;
        end if;
    end process;
    
    ------------------------------------------------------------------
    --                     Phase conformation  (half_alfa_l)                         
    --                                                                
    --   Goal: gerar o parâmetro (alfa.L/2) e nb_points/2
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: valid_input_delay;
    --          TUKEY_ALFA_HALF;
    --          ufixed_nb_l_points_reg;
    --          nb_points_one_period_reg;
    --
    --   Output: valid_input_delay_reg;
    --           nb_half_l_alfa;
    --           nb_half_points;
    --
    --   Result: gerar o parâmetro (alfa.L/2) e nb_points/2 
    ------------------------------------------------------------------
    ufixed_nb_l_points_reg      <= to_ufixed(nb_l_points_reg,ufixed_nb_l_points_reg);

    half_alfa_l_proc : process(clock_i,areset_i)
    begin   
        if ( areset_i = '1') then
            valid_input_delay_reg   <= '0';

        elsif ( rising_edge(clock_i) ) then

            valid_input_delay_reg   <= valid_input_delay;

            if (valid_input_delay = '1' ) then
                nb_half_l_alfa      <= to_slv  (  resize ( ufixed_nb_l_points_reg * TUKEY_ALFA_HALF,  ufixed_nb_l_points_reg) );
                nb_half_points      <= '0' & nb_points_one_period_reg( (nb_points_one_period_reg'left) downto 1); -- nb_points_one_period/2
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    --                     Phase conformation  (half_alfa_L + nb_points)                         
    --                                                                
    --   Goal: gerar o parâmetro (alfa.L/2) e nb_points/2
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: valid_input_delay_reg;
    --          nb_half_points;
    --
    --   Output: valid_new_term_reg;
    --           nb_half_points_plus_half_l_alfa;
    --
    --   Result: gerar o parâmetro (alfa.L/2) e nb_points/2 e 
    --           indica que um novo ciclo pode começar "valid_new_term_reg"
    ------------------------------------------------------------------
    half_points_plus_half_l_alfa_proc : process(clock_i,areset_i)
    begin   
        if ( areset_i = '1') then
            valid_new_term_reg   <= '0';

        elsif ( rising_edge(clock_i) ) then

            valid_new_term_reg   <= valid_input_delay_reg;

            if (valid_input_delay_reg = '1' ) then
                nb_half_points_plus_half_l_alfa  <= std_logic_vector( unsigned(nb_half_points)  +  unsigned(nb_half_l_alfa) );
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    --                     Acumulador de phase                           
    --                                                                
    --   Goal: Acumular a fase (phase_acc) ; registrar o sinal
    --         restart_acc para o falling_edge_detector,
    --         o sinal hold_phase_reg e reverse_acc_reg
    -- 
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: output_valid;
    --          restart_acc;
    --          set_phase;
    --          hold_phase;
    --          reverse_acc;
    --          phase_term_reg
    --          phase_acc
    --
    --   Output: output_valid_reg;
    --           restart_acc_reg;
    --           hold_phase_reg;
    --           reverse_acc_reg;
    --           phase_acc;
    --
    --   Result: Acumulação da phase (phase_acc) normal 
    --           O modo hold impede a acumulação para criar o patamar no tukey
    --           O modo reverse decrementa phase para criar a parte decrescente
    --           da janela Tukey
    ------------------------------------------------------------------
    phase_acc_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then

            output_valid_reg     <= '0';
            restart_acc_reg     <= '0';
            hold_phase_reg      <= '0';
            reverse_acc_reg     <= '0';

        elsif ( rising_edge(clock_i) ) then

            output_valid_reg    <= output_valid;
            restart_acc_reg     <= restart_acc;
            hold_phase_reg      <= hold_phase;
            reverse_acc_reg     <= reverse_acc;

            if (output_valid = '1') then

                if (set_phase = '1') then
                    phase_acc <= (others => '0');
                else
                    if (hold_phase  = '0') then
                        if (reverse_acc = '1') then
                            phase_acc <= resize( (phase_acc - phase_term_reg) ,PHASE_INTEGER_PART,PHASE_FRAC_PART);
                        else
                            phase_acc <= resize( (phase_acc + phase_term_reg) ,PHASE_INTEGER_PART,PHASE_FRAC_PART);
                        end if;
                    end if;
                end if;
                
            end if;
        end if;
    end process;

    neg_edge_detector_restart_acc   <=                  restart_acc_reg -- Detecta falling_edge sobre o sinal
                                                    and (not restart_acc);

    -- Restart the accumulation
    start_new_cycle                 <=                  valid_new_term_reg              -- novos parâmetros fornecidos
                                                    or  neg_edge_detector_restart_acc;  -- Restart com os últimos parâmetros
    
    -- Resets phase acc to initial phase upon
    set_phase                       <=                  full_period_done    -- Full cycle (number of repetitions)
                                                    or  start_new_cycle;    -- Reset cycle signal
                                                       
    hold_phase                      <=                  less_half_points_plus_half_l_alfa
                                                    and not(less_half_alfa_l);
    
    neg_edge_detector_hold_phase    <=                  hold_phase_reg
                                                    and (not hold_phase);

    reverse_acc                     <=          (       neg_edge_detector_hold_phase
                                                            or  reverse_acc_reg      )
                                                    and (not full_wave_done          ); 

    output_valid                     <=              (       (not full_wave_done)        
                                                        and output_valid_reg      )  
                                                    or  start_new_cycle;

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
    counters : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then

            nb_points_one_period_counter    <= (others => '0');
            nb_repetitions_counter          <= (others => '0');

        elsif (rising_edge(clock_i)) then

            if(output_valid = '1') then
               
                if(full_period_done = '1') then                    
                    nb_points_one_period_counter    <= (others => '0');
                    nb_repetitions_counter <= nb_repetitions_counter + 1;
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

    full_period_done                    <=              '1'     when (  nb_points_one_period_counter = ( unsigned(nb_points_one_period_reg) - 1) )
                                                else    '0'; -- 1 período completo
                                
    less_half_alfa_l                    <=              '1'     when (  nb_points_one_period_counter <= ( unsigned(nb_half_l_alfa)) )
                                                else    '0'; -- antes do ponto (alfa.L/2)
                            
    less_half_points_plus_half_l_alfa   <=              '1'     when (  nb_points_one_period_counter <= ( unsigned(nb_half_points_plus_half_l_alfa) - 1) )
                                                else    '0'; -- entre o ponto (alfa.L/2) e N/2
                        
    full_wave_done                      <=              '1'     when (  nb_repetitions_counter  = (unsigned(nb_repetitions_reg)) )
                                                else    '0';
    
    -- Output
    valid_o             <= output_valid_reg;
    phase_o             <= phase_acc;
    flag_period_o       <= full_period_done; 
    flag_done_o         <= full_wave_done;

end behavioral;
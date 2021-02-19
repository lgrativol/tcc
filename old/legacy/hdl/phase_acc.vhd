---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                           
-- Module Name: phase_acc                                                                        
-- Module Name: Lucas Grativol Ribeiro                                                                           
--                                                                                         
-- Revision Date: 18/11/2020             (Versão inicial, usar a versão v2)                                                                 
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

entity phase_acc is
    generic(
        SAMPLING_FREQUENCY                 : positive := 100E6; -- 100 MHz
        MODE_TIME                          : boolean  := TRUE 
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Valid in
        target_frequency_i                  : in  std_logic_vector((ceil_log2(SAMPLING_FREQUENCY + 1) - 1) downto 0);
        nb_cycles_i                         : in  std_logic_vector((NB_CYCLES_WIDTH - 1) downto 0);
        phase_diff_i                        : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  -- For the first sine, max: 2PI

        -- Control interface
        restart_cycles_i                    : in  std_logic; 
        done_cycles_o                       : out std_logic;
        flag_full_cycle_o                   : out std_logic;

        -- Output interface
        valid_o                             : out std_logic;
        phase_o                             : out ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART)
    ); 
end phase_acc;

------------------
-- Architecture --
------------------

architecture behavioral of phase_acc is

    ---------------
    -- Constants --
    ---------------
    -- Frequency
    constant        FREQUENCY_WIDTH                     : positive                                          := target_frequency_i'length;

    -- Define frequency
    constant        DELTA_PHASE_FACTOR_INTEGER_PART     : integer                                           := PHASE_INTEGER_PART;
    constant        DELTA_PHASE_FACTOR_FRAC_PART        : integer                                           := PHASE_FRAC_PART;
    -- delta_phase        = delta_phase_factor * target_frequency
    -- delta_phase_factor = (2 * Pi * (1/sampling_frequency))    
    constant        DELTA_PHASE_FACTOR                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( ((2.0 * PI) * (1.0/real(SAMPLING_FREQUENCY))),PHASE_INTEGER_PART,PHASE_FRAC_PART);

    constant        TWO_PI                              : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( (2.0 * PI) ,
                                                                                                                        PHASE_INTEGER_PART,
                                                                                                                        PHASE_FRAC_PART);   
    constant        ZERO_COUNTER_CTE                    : unsigned((NB_CYCLES_WIDTH - 1) downto 0)          := (others => '0'); 
    -------------
    -- Signals --
    -------------
    
    -- Input frequency
    signal target_frequency                 : std_logic_vector((FREQUENCY_WIDTH - 1) downto 0);
    signal nb_cycles                        : std_logic_vector((NB_CYCLES_WIDTH - 1) downto 0);
    signal phase_diff                       : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal final_phase                      : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal final_phase_diff_delta           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  

    -- Behavioral
    signal delta_phase_reg                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
    signal nb_cycles_reg                    : std_logic_vector((NB_CYCLES_WIDTH - 1) downto 0);
    signal phase_diff_reg                   : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);

    signal valid_new_delta_reg                           : std_logic;
    signal valid_output                                  : std_logic;

    signal neg_edge_detector_restart_cycles             : std_logic;
    signal restart_cycles_reg                           : std_logic;

    signal start_new_cycle                              : std_logic;
    signal two_pi_phase                                 : std_logic;
    signal set_phase                                    : std_logic;

    signal nb_cycles_counter                            : unsigned((NB_CYCLES_WIDTH - 1) downto 0);
    signal cycles_done                                  : std_logic;

    --Phase time (experimental)
    signal phase_time_counter                           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal phase_time_counter_not_done                  : std_logic;
    signal phase_time_counter_not_done_reg              : std_logic;
    
    -- Output interface
    signal valid_output_reg                              : std_logic;
    signal phase_reg                                    : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
begin

    -- Input
    target_frequency <= target_frequency_i;
    nb_cycles        <= nb_cycles_i;
    phase_diff       <= phase_diff_i;

    -- Delta phase generation
    delta_phase_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            valid_new_delta_reg <= '0';

        elsif (rising_edge(clock_i) ) then                       
            valid_new_delta_reg <= valid_i;

            if (valid_i = '1') then
                delta_phase_reg <= resize( ( DELTA_PHASE_FACTOR * to_ufixed( unsigned(target_frequency) )) ,
                                             PHASE_INTEGER_PART , PHASE_FRAC_PART );

                final_phase     <= resize( (TWO_PI + phase_diff) ,
                                             PHASE_INTEGER_PART , PHASE_FRAC_PART );

                nb_cycles_reg   <= nb_cycles;
                
                phase_diff_reg  <= phase_diff;
            end if;

        end if;
    end process;

    -- Phase accumulator
    phase_acc_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            valid_output_reg            <= '0';
            restart_cycles_reg         <= '0';
        elsif ( rising_edge(clock_i) ) then

            valid_output_reg     <= valid_output;
            restart_cycles_reg  <= restart_cycles_i;

            if (valid_output = '1') then

                if (set_phase = '1') then

                    if (MODE_TIME) then
                        phase_reg <= (others => '0');
                    else
                        phase_reg <= phase_diff_reg;
                    end if;

                else
                    phase_reg <= resize( (phase_reg + delta_phase_reg) ,PHASE_INTEGER_PART,PHASE_FRAC_PART);
                end if;
                
            end if;
        end if;
    end process;

    final_phase_diff_delta  <=              resize( (TWO_PI - delta_phase_reg) ,PHASE_INTEGER_PART,PHASE_FRAC_PART)             when (MODE_TIME)
                                    else    resize( (final_phase - delta_phase_reg) ,PHASE_INTEGER_PART,PHASE_FRAC_PART);  --TODO : Pass to reg (better timing)
     
    -- TODO: check impact from phase_reg >= TWO_PI to phase_reg >= (TWO_PI - delta_phase_reg)

    two_pi_phase    <=          '1'     when (phase_reg >= final_phase_diff_delta) -- Checking full cycle
                        else    '0';
    

    neg_edge_detector_restart_cycles <=         restart_cycles_reg
                                            and (not restart_cycles_i);

    start_new_cycle <=                  valid_new_delta_reg                          -- New frequency
                                    or  neg_edge_detector_restart_cycles;           -- start new cycle
    -- resets phase to zero upon
    set_phase       <=                  two_pi_phase                   -- Full cycle, wrap back to phase = 0
                                    or  start_new_cycle                -- Reset cycle signal
                                    or  phase_time_counter_not_done_reg;   

    valid_output     <=          (       (not cycles_done)        
                                    and valid_output_reg )  
                            or  start_new_cycle;
    
    -- Phase time
    phase_time_counter_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            phase_time_counter          <= (others => '0');
        elsif (rising_edge(clock_i)) then

            phase_time_counter_not_done_reg <=  phase_time_counter_not_done;

            if((valid_output = '1')) then

                if( phase_time_counter_not_done = '1') then
                    phase_time_counter      <= resize( (phase_time_counter + delta_phase_reg) 
                                                       ,PHASE_INTEGER_PART,PHASE_FRAC_PART);
                end if;

                if((restart_cycles_i = '1')) then
                    phase_time_counter <= (others => '0'); --TODO: check synthesis (maybe generate~VHDL-2008)
                end if;

            end if;
        end if;
    end process;

    phase_time_counter_not_done     <=          '0' when (              phase_time_counter >= (phase_diff_reg)
                                                                    or  not(MODE_TIME)                          )
                                        else    '1';

    count_nb_cycles : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            nb_cycles_counter          <= (others => '0');
        elsif (rising_edge(clock_i)) then

            if((two_pi_phase = '1')) then
                nb_cycles_counter <= nb_cycles_counter + 1;
            end if;
            
            if((restart_cycles_i = '1')) then
                nb_cycles_counter <= (others => '0');
            end if;

        end if;
    end process;

    cycles_done     <=              '1' when (unsigned(nb_cycles_reg) = (nb_cycles_counter))
                            else    '0';
                                  
    -- Output
    done_cycles_o      <= cycles_done;
    flag_full_cycle_o  <= two_pi_phase; -- Full cycle indicator

    valid_o            <= valid_output_reg;
    phase_o           <= phase_reg;

end behavioral;
---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Dezembro/2020                                                                
-- Module Name: wave_generator_win
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date: 15/01/2021
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Servir de bloco para instanciar os geradores de sinal (exemplo)
--          
-- Description: Instancia um DDS CORDIC WIN e um Pulser
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
use work.defs_pkg.all;

------------
-- Entity --
------------

entity wave_generator_win is
    port(
        -- Clock interface
        clock_i                             : in  std_logic; -- Clock
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        bang_i                              : in  std_logic; -- Indica que o sinal deve começar a ser produzido
        wave_config_i                       : in  std_logic_vector(0 downto 0); -- Indica qual sinal deve ser produzido (DDS =0, Pulser =1)
        restart_wave_i                      : in  std_logic; -- Sinal para reiniciar a geração do sinal, utilizando os parâmetros 
                                                             -- fornecidos no último sinal de valid/run

        -- Pulser (Ver pulser)
        pulser_nb_repetitions_value_i       : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
        pulser_t1_value_i                   : in  std_logic_vector((TIMER_WIDTH - 1) downto 0);
        pulser_t2_value_i                   : in  std_logic_vector((TIMER_WIDTH - 1) downto 0);
        pulser_t3_value_i                   : in  std_logic_vector((TIMER_WIDTH - 1) downto 0);
        pulser_t4_value_i                   : in  std_logic_vector((TIMER_WIDTH - 1) downto 0);
        pulser_tdamp_value_i                : in  std_logic_vector((TIMER_WIDTH - 1) downto 0);
        pulser_config_invert_i              : in  std_logic;
        pulser_config_triple_i              : in  std_logic;

        -- DDS Cordic Win (Ver DDS CORDIC WIN)
        dds_win_mode_value_i                : in  std_logic_vector(2 downto 0);
        dds_win_phase_term_value_i          : in  std_logic_vector((PHASE_WIDTH - 1) downto 0); 
        dds_win_window_term_value_i         : in  std_logic_vector((PHASE_WIDTH - 1) downto 0);  
        dds_win_initial_phase_value_i       : in  std_logic_vector((PHASE_WIDTH - 1) downto 0);  
        dds_win_nb_points_value_i           : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0); 
        dds_win_nb_repetitions_value_i      : in  std_logic_vector((NB_REPT_WIDTH - 1) downto 0); 
        dds_win_mode_time_value_i           : in  std_logic;  
    
        -- Output interface
        valid_o                             : out std_logic; -- Indica a validade do sinal de saída no clico atual de clock
        wave_data_o                         : out std_logic_vector( (OUTPUT_WIDTH - 1) downto 0); -- Amostra
        wave_done_o                         : out std_logic -- Indica que a última amostra do sinal
    );
end wave_generator_win;

------------------
-- Architecture --
------------------

architecture behavioral of wave_generator_win is
    
    
    
    ---------------
    -- Constants --
    ---------------

    constant    TYPE_CORDIC                     : std_logic := '0';
    constant    TYPE_PULSER                     : std_logic := '1';
    constant    PULSER_NB_REPETITIONS_WIDTH     : positive  := pulser_nb_repetitions_value_i'length;


    -------------
    -- Signals --
    -------------

    -- Input
    signal bang                               : std_logic;
    signal bang_reg                           : std_logic;
    signal wave_config                        : std_logic_vector(0 downto 0);
    signal wave_config_reg                    : std_logic_vector(0 downto 0);
    signal restart_wave                       : std_logic;

    signal wave_type                          : std_logic_vector(0 downto 0);

    -- DDS CORDIC WINDOWS
    signal cordic_win_mode                    : std_logic_vector(dds_win_mode_value_i'range);
    signal cordic_win_valid_i                 : std_logic;
    signal cordic_win_phase_term              : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal cordic_win_window_term             : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal cordic_win_nb_points               : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal cordic_win_nb_repetitions          : std_logic_vector((NB_REPT_WIDTH - 1) downto 0);
    signal cordic_win_initial_phase           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal cordic_win_mode_time               : std_logic;
    signal cordic_win_restart_cycles          : std_logic;
    
    signal cordic_win_valid_o                 : std_logic;
    signal cordic_win_sine_phase              : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal cordic_win_done_cycles             : std_logic;
    signal cordic_win_flag_full_cycle         : std_logic;

    signal slv_cordic_win_sine_phase          : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);

    -- Pulser
    signal pulser_bang                        : std_logic; 
    signal pulser_valid_i                     : std_logic; -- Valid in for all inputs and mode interface
    signal pulser_restart                     : std_logic; -- Valid in for all inputs and mode interface
    signal pulser_nb_repetitions              : std_logic_vector((PULSER_NB_REPETITIONS_WIDTH - 1) downto 0);
    signal pulser_timer1                      : std_logic_vector((TIMER_WIDTH - 1) downto 0); 
    signal pulser_timer2                      : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal pulser_timer3                      : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal pulser_timer4                      : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal pulser_timer_damp                  : std_logic_vector((TIMER_WIDTH - 1) downto 0);

    signal pulser_invert_pulser               : std_logic;
    signal pulser_triple_pulser               : std_logic; 
    
    signal pulser_valid_o                     : std_logic;
    signal pulser_done                        : std_logic;
    signal pulser_data                        : std_logic_vector(1 downto 0);

    signal resized_pulser_data                : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);

    -- Output
    signal output_valid                       : std_logic;
    signal output_result                      : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal output_last                        : std_logic;

    signal output_valid_reg                   : std_logic;
    signal output_result_reg                  : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal output_last_reg                    : std_logic;

begin

    -- Input
    bang                <= bang_i;
    wave_config         <= wave_config_i;       
    restart_wave        <= restart_wave_i;

    --------------------
    -- WAVE TYPE valid --
    --------------------

    reg_wave_type : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            bang_reg    <= '0';
            wave_config_reg   <= (others => '0');
        elsif (rising_edge(clock_i)) then

            bang_reg <= bang;

            if (bang = '1') then
                wave_config_reg <= wave_config;
            end if;
        end if;
    end process;


    -- 0x0 -> DDS Cordic
    -- 0x1 -> Pulser
    -- TBD

    wave_type   <= wave_config_reg;


    pulser_valid_i          <=               bang_reg       when ( wave_type(0) = TYPE_PULSER)
                                    else    '0';  

    pulser_restart          <=              restart_wave   when ( wave_type(0) = TYPE_PULSER)
                                    else    '0';   

    cordic_win_valid_i           <=              bang_reg       when ( wave_type(0) = TYPE_CORDIC)
                                    else    '0';         
    
    cordic_win_restart_cycles  <=               restart_wave   when ( wave_type(0) = TYPE_CORDIC)
                                    else    '0';   
                                    

    ------------
    -- Pulser --
    ------------
    pulser_bang            <= pulser_valid_i; 
    pulser_nb_repetitions  <= pulser_nb_repetitions_value_i; 
    pulser_timer1          <= pulser_t1_value_i;
    pulser_timer2          <= pulser_t2_value_i; 
    pulser_timer3          <= pulser_t3_value_i; 
    pulser_timer4          <= pulser_t4_value_i;
    pulser_timer_damp      <= pulser_tdamp_value_i; 
    pulser_invert_pulser   <= pulser_config_invert_i;
    pulser_triple_pulser   <= pulser_config_triple_i;

    wave_pulser: entity work.pulser
    generic map(
            NB_REPETITIONS_WIDTH                => NB_REPT_WIDTH,
            TIMER_WIDTH                         => TIMER_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,
            
            -- Input interface
            valid_i                             => pulser_valid_i,
            restart_i                           => pulser_restart,
            nb_repetitions_i                    => pulser_nb_repetitions,
            t1_i                                => pulser_timer1,
            t2_i                                => pulser_timer2,
            t3_i                                => pulser_timer3,
            t4_i                                => pulser_timer4,
            tdamp_i                             => pulser_timer_damp,
            
            -- Control Interface
            bang_i                              => pulser_bang,
            
            -- Mode Interface 
            invert_pulser_i                     => pulser_invert_pulser,
            triple_pulser_i                     => pulser_triple_pulser,
            
            -- Output interface
            valid_o                             => pulser_valid_o,
            pulser_done_o                       => pulser_done,
            pulser_data_o                       => pulser_data
            );  

    -------------
    --  CORDIC --
    -------------

    cordic_win_mode           <= dds_win_mode_value_i;
    cordic_win_phase_term     <= to_ufixed( dds_win_phase_term_value_i , cordic_win_phase_term) ;
    cordic_win_window_term    <= to_ufixed( dds_win_window_term_value_i , cordic_win_window_term) ;
    cordic_win_nb_points      <= dds_win_nb_points_value_i;
    cordic_win_nb_repetitions <= dds_win_nb_repetitions_value_i;
    cordic_win_initial_phase  <= to_ufixed( dds_win_initial_phase_value_i , cordic_win_initial_phase);
    cordic_win_mode_time      <= dds_win_mode_time_value_i;

    wave_window: entity work.dds_cordic_win_v2
        generic map(
            PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                    => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS                 => N_CORDIC_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => NB_REPT_WIDTH,
            WIN_INTEGER_PART                    => WIN_INTEGER_PART,
            WIN_FRAC_PART                       => WIN_FRAC_PART,
            WIN_NB_ITERATIONS                   => WIN_NB_ITERATIONS
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            valid_i                             => cordic_win_valid_i,
            win_mode_i                          => cordic_win_mode,
            phase_term_i                        => cordic_win_phase_term,
            window_term_i                       => cordic_win_window_term,
            initial_phase_i                     => cordic_win_initial_phase,
            nb_points_i                         => cordic_win_nb_points,
            nb_repetitions_i                    => cordic_win_nb_repetitions,
            mode_time_i                         => cordic_win_mode_time,
        
            
            -- Control interface
            restart_cycles_i                    => cordic_win_restart_cycles,
            
            -- Output interface
            valid_o                             => cordic_win_valid_o,
            sine_win_phase_o                    => cordic_win_sine_phase,
            last_word_o                         => open
        );

    resized_pulser_data         <= to_slv( to_sfixed( signed(pulser_data), cordic_win_sine_phase)  ); 
    slv_cordic_win_sine_phase   <= to_slv(cordic_win_sine_phase);                                    
                     
    output_valid    <=              pulser_valid_o          
                            or      cordic_win_valid_o;
    
    output_result   <=          resized_pulser_data         when (wave_type(0) = TYPE_PULSER)
                        else    slv_cordic_win_sine_phase   when (wave_type(0) = TYPE_CORDIC)
                        else    (others => '0');                     
    
    
    output_last     <=            pulser_done            
                            or    cordic_win_done_cycles ;

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

    -- Output                           
                     
    valid_o         <=          output_valid_reg;
    
    wave_data_o     <=          output_result_reg;                     
    
    wave_done_o     <=          output_last_reg;   
            
end architecture behavioral;
---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Dezembro/2020                                                                
-- Module Name: wave_generator
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date: 15/01/2021
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Servir de bloco para instanciar os geradores de sinal (exemplo)
--          
-- Description: Instancia um DDS CORDIC e um Pulser
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
use work.defs_pkg.all;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity wave_generator is
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

        -- Cordic  (Ver DDS CORDIC)
        dds_phase_term_value_i              : in  std_logic_vector((PHASE_WIDTH - 1) downto 0);
        dds_init_phase_value_i              : in  std_logic_vector((PHASE_WIDTH - 1) downto 0);
        dds_nb_points_i                     : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
        dds_nb_repetitions_i                : in  std_logic_vector((NB_REPT_WIDTH - 1) downto 0);
        dds_mode_time_i                     : in  std_logic;
    
        -- Output interface
        valid_o                             : out std_logic; -- Indica a validade do sinal de saída no clico atual de clock
        wave_data_o                         : out std_logic_vector( (OUTPUT_WIDTH - 1) downto 0); -- Amostra
        wave_done_o                         : out std_logic -- Indica que a última amostra do sinal
    );
end wave_generator;

------------------
-- Architecture --
------------------

architecture behavioral of wave_generator is
    
    ---------------
    -- Constants --
    ---------------

    constant    TYPE_CORDIC                     : std_logic := '0';
    constant    TYPE_PULSER                     : std_logic := '1';
    constant    PULSER_NB_REPETITIONS_WIDTH     : positive  := NB_REPT_WIDTH;

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
    --signal win_type                           : std_logic_vector(3 downto 0);

    -- CORDIC
    signal cordic_valid_i                     : std_logic;
    signal cordic_phase_term                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal cordic_nb_points                   : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal cordic_nb_repetitions              : std_logic_vector((NB_REPT_WIDTH - 1) downto 0);
    signal cordic_initial_phase               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal cordic_mode_time                   : std_logic;
    signal cordic_restart_cycles              : std_logic;
    
    signal cordic_valid_o                     : std_logic;
    signal cordic_sine_phase                  : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal cordic_done_cycles                 : std_logic;
    signal cordic_flag_full_cycle             : std_logic;

    signal slv_cordic_sine_phase              : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);

    -- Pulser
    signal pulser_bang                        : std_logic; 
    signal pulser_valid_i                     : std_logic; 
    signal pulser_restart                     : std_logic; 
    signal pulser_nb_repetitions              : std_logic_vector( (PULSER_NB_REPETITIONS_WIDTH - 1) downto 0);
    signal pulser_timer1                      : std_logic_vector( (TIMER_WIDTH - 1) downto 0); 
    signal pulser_timer2                      : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal pulser_timer3                      : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal pulser_timer4                      : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal pulser_timer_damp                  : std_logic_vector( (TIMER_WIDTH - 1) downto 0);

    signal pulser_invert_pulser               : std_logic;
    signal pulser_triple_pulser               : std_logic; 
    
    signal pulser_valid_o                     : std_logic;
    signal pulser_done                        : std_logic;
    signal pulser_data                        : std_logic_vector(1 downto 0);

    signal resized_pulser_data                : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);

    -- Output
    signal output_valid                       : std_logic;
    signal output_wave_data                   : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal wave_done                          : std_logic;

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

    wave_type   <= wave_config_reg;

    pulser_valid_i          <=               bang_reg       when ( wave_type(0) = TYPE_PULSER)
                                    else    '0';  

    pulser_restart          <=              restart_wave   when ( wave_type(0) = TYPE_PULSER)
                                    else    '0';   

    cordic_valid_i           <=              bang_reg       when ( wave_type(0) = TYPE_CORDIC)
                                    else    '0';         
    
    cordic_restart_cycles  <=               restart_wave   when ( wave_type(0) = TYPE_CORDIC)
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

    cordic_phase_term     <= to_ufixed( dds_phase_term_value_i , cordic_phase_term) ;
    cordic_nb_points      <= dds_nb_points_i;
    cordic_nb_repetitions <= dds_nb_repetitions_i;
    cordic_initial_phase  <= to_ufixed( dds_init_phase_value_i , cordic_initial_phase);
    cordic_mode_time      <= dds_mode_time_i;

    wave_cordic: entity work.dds_cordic
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
            valid_i                             => cordic_valid_i,
            phase_term_i                        => cordic_phase_term,
            initial_phase_i                     => cordic_initial_phase,
            nb_points_i                         => cordic_nb_points,
            nb_repetitions_i                    => cordic_nb_repetitions,
            mode_time_i                         => cordic_mode_time,
            
            -- Control interface
            restart_cycles_i                    => cordic_restart_cycles,
            
            -- Output interface
            valid_o                             => cordic_valid_o,
            sine_phase_o                        => cordic_sine_phase,
            cos_phase_o                         => open,
            done_cycles_o                       => cordic_done_cycles,
            flag_full_cycle_o                   => cordic_flag_full_cycle
        );
            

    -- Output

    resized_pulser_data     <= to_slv( to_sfixed( signed(pulser_data), cordic_sine_phase)  ); 
    slv_cordic_sine_phase   <= to_slv(cordic_sine_phase);                                    


                                
    valid_o          <=          pulser_valid_o       when (wave_type(0) = TYPE_PULSER)
                        else    cordic_valid_o       when (wave_type(0) = TYPE_CORDIC)
                        else    '0';
    
    wave_data_o     <=          resized_pulser_data     when (wave_type(0) = TYPE_PULSER)
                        else    slv_cordic_sine_phase   when (wave_type(0) = TYPE_CORDIC)
                        else    (others => '0');                     
    
    
    wave_done_o     <=          pulser_done         when (wave_type(0) = TYPE_PULSER)
                        else    cordic_done_cycles  when (wave_type(0) = TYPE_CORDIC)
                        else    '0';                      
    
            
end architecture behavioral;
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

entity wave_generator is
    generic(
        CONFIG_DATA_WIDTH                   : positive;
        OUTPUT_WIDTH                        : positive
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        bang_i                              : in  std_logic;
        --strb_i                              : in  std_logic; -- Valid in
        wave_data_i                         : in  std_logic_vector((CONFIG_DATA_WIDTH - 1) downto 0);
        wave_config_i                       : in  std_logic_vector(7 downto 0); 
        restart_wave_i                      : in  std_logic;

        -- Output interface
        strb_o                              : out std_logic;
        wave_data_o                         : out std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
        wave_done_o                         : out std_logic
    );
end wave_generator;

------------------
-- Architecture --
------------------

architecture behavioral of wave_generator is
    
    ---------------
    -- Constants --
    ---------------    

    -- Wave type

    constant    TYPE_PULSER                     : std_logic_vector := x"1";
    constant    TYPE_CORDIC                     : std_logic_vector := x"2";


    -- CORDIC
    constant    CORDIC_PHASE_WIDTH              : positive := PHASE_INTEGER_PART + (-PHASE_FRAC_PART + 1) ; --pkg
    constant    CORDIC_PHASE_TERM_START         : natural  := 0;
    constant    CORDIC_PHASE_TERM_END           : natural  := ( CORDIC_PHASE_TERM_START + (CORDIC_PHASE_WIDTH - 1) );

    constant    CORDIC_INIT_PHASE_WIDTH         : positive := CORDIC_PHASE_WIDTH; 
    constant    CORDIC_INIT_PHASE_START         : natural  := (CORDIC_PHASE_TERM_END + 1);
    constant    CORDIC_INIT_PHASE_END           : natural  := ( CORDIC_INIT_PHASE_START + (CORDIC_INIT_PHASE_WIDTH - 1) );
    
    constant    CORDIC_NB_POINTS_WIDTH          : positive := NB_POINTS_WIDTH; -- pkg
    constant    CORDIC_NB_POINTS_START          : natural  := (CORDIC_INIT_PHASE_END + 1);
    constant    CORDIC_NB_POINTS_END            : natural  := ( CORDIC_NB_POINTS_START + (CORDIC_NB_POINTS_WIDTH - 1) );  

    constant    CORDIC_NB_REPETITIONS_WIDTH     : positive := CORDIC_NB_POINTS_WIDTH; --TODO: separate points and repetitions
    constant    CORDIC_NB_REPETITIONS_START     : natural  := (CORDIC_NB_POINTS_END + 1);
    constant    CORDIC_NB_REPETITIONS_END       : natural  := ( CORDIC_NB_REPETITIONS_START + (CORDIC_NB_REPETITIONS_WIDTH - 1) ); 

    constant    CORDIC_MODE_TIME_WIDTH          : positive := 1;
    constant    CORDIC_MODE_TIME_START          : natural  := ( CORDIC_NB_REPETITIONS_END + 1 );
    constant    CORDIC_MODE_TIME_END            : natural  := ( CORDIC_MODE_TIME_START +  (CORDIC_MODE_TIME_WIDTH - 1) );
    
    -- Pulser
    constant    PULSER_NB_REPETITIONS_WIDTH     : positive := NB_POINTS_WIDTH;
    constant    PULSER_NB_REPETITIONS_START     : natural  := 0;
    constant    PULSER_NB_REPETITIONS_END       : natural  := ( PULSER_NB_REPETITIONS_START + (PULSER_NB_REPETITIONS_WIDTH - 1) ); 

    constant    PULSER_TIMER_WIDTH              : positive := TIMER_WIDTH; --pkg
    constant    PULSER_T1_START                 : natural  := (PULSER_NB_REPETITIONS_END + 1);
    constant    PULSER_T1_END                   : natural  := ( PULSER_T1_START + (PULSER_TIMER_WIDTH - 1) );

    constant    PULSER_T2_START                 : natural  := ( PULSER_T1_END + 1 );
    constant    PULSER_T2_END                   : natural  := ( PULSER_T2_START + (PULSER_TIMER_WIDTH - 1) );

    constant    PULSER_T3_START                 : natural  := ( PULSER_T2_END + 1 );
    constant    PULSER_T3_END                   : natural  := ( PULSER_T3_START + (PULSER_TIMER_WIDTH - 1) );

    constant    PULSER_T4_START                 : natural  := ( PULSER_T3_END + 1 );
    constant    PULSER_T4_END                   : natural  := ( PULSER_T4_START  + (PULSER_TIMER_WIDTH - 1) );
    
    constant    PULSER_TDAMP_START              : natural  := ( PULSER_T4_END + 1 );
    constant    PULSER_TDAMP_END                : natural  := ( PULSER_TDAMP_START +  (PULSER_TIMER_WIDTH - 1) );

    constant    PULSER_INVERT_PULSER_WIDTH      : positive := 1;
    constant    PULSER_INVERT_PULSER_START      : natural  := ( PULSER_TDAMP_END + 1 );
    constant    PULSER_INVERT_PULSER_END        : natural  := ( PULSER_INVERT_PULSER_START +  (PULSER_INVERT_PULSER_WIDTH - 1) );
    
    constant    PULSER_TRIPLE_PULSER_WIDTH      : positive := 1;
    constant    PULSER_TRIPLE_PULSER_START      : natural  := ( PULSER_INVERT_PULSER_END + 1 );
    constant    PULSER_TRIPLE_PULSER_END        : natural  := ( PULSER_TRIPLE_PULSER_START +  (PULSER_TRIPLE_PULSER_WIDTH - 1) );

    
    -------------
    -- Signals --
    -------------

    -- Input
    signal bang                               : std_logic;
    signal bang_reg                           : std_logic;
    signal wave_config                        : std_logic_vector(7 downto 0);
    signal wave_config_reg                    : std_logic_vector(7 downto 0);
    signal input_wave_data                    : std_logic_vector((CONFIG_DATA_WIDTH - 1) downto 0); 
    signal restart_wave                       : std_logic;

    signal wave_type                          : std_logic_vector(3 downto 0);
    signal win_type                           : std_logic_vector(3 downto 0);

    -- CORDIC
    signal cordic_strb_i                      : std_logic;
    signal cordic_phase_term                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal cordic_nb_points                   : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal cordic_nb_repetitions              : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal cordic_initial_phase               : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal cordic_mode_time                   : std_logic_vector(0 downto 0);
    signal cordic_restart_cycles              : std_logic;
    
    signal cordic_strb_o                      : std_logic;
    signal cordic_sine_phase                  : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal cordic_done_cycles                 : std_logic;
    signal cordic_flag_full_cycle             : std_logic;

    signal slv_cordic_sine_phase              : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);

    -- Pulser
    signal pulser_bang                        : std_logic; 
    signal pulser_strb_i                      : std_logic; -- Valid in for all inputs and mode interface
    signal pulser_nb_repetitions              : std_logic_vector( (PULSER_NB_REPETITIONS_WIDTH - 1) downto 0);
    signal pulser_timer1                      : std_logic_vector( (TIMER_WIDTH - 1) downto 0); 
    signal pulser_timer2                      : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal pulser_timer3                      : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal pulser_timer4                      : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal pulser_timer_damp                  : std_logic_vector( (TIMER_WIDTH - 1) downto 0);

    signal pulser_invert_pulser               : std_logic_vector(0 downto 0);
    signal pulser_triple_pulser               : std_logic_vector(0 downto 0); 
    
    signal pulser_strb_o                      : std_logic;
    signal pulser_done                        : std_logic;
    signal pulser_data                        : std_logic_vector(1 downto 0);

    signal resized_pulser_data                : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);

    -- Output
    signal output_strb                        : std_logic;
    signal output_wave_data                   : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal wave_done                          : std_logic;

begin


    -- Input
    bang                <= bang_i;
    input_wave_data     <= wave_data_i; 
    wave_config         <= wave_config_i;       
    restart_wave        <= restart_wave_i;

    --------------------
    -- WAVE TYPE STRB --
    --------------------

    reg_wave_type : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            bang_reg    <= '0';
            wave_type   <= (others => '0');
        elsif (rising_edge(clock_i)) then

            bang_reg <= bang;

            if (bang = '1') then
                wave_config_reg <= wave_config;
            end if;
        end if;
    end process;


    -- 0x0 -> Nothing
    -- 0x1 -> Pulser
    -- 0x2 -> DDS Cordic
    -- TBD

    wave_type   <= wave_config_reg(3 downto 0);

    -- 0x0 -> Nothing
    -- 0x1 -> None (no window)

    win_type    <= wave_config_reg(7 downto 4); 


    pulser_strb_i          <=               bang_reg       when ( wave_type = TYPE_PULSER)
                                    else    '0';  

    cordic_strb_i           <=              bang_reg       when ( wave_type = TYPE_CORDIC)
                                    else    '0';         
    
    cordic_restart_cycles  <=               restart_wave   when ( wave_type = TYPE_CORDIC)
                                    else    '0';   
                                    
                                    
                                    
    pulser_nb_repetitions  <= input_wave_data( PULSER_NB_REPETITIONS_END  downto PULSER_NB_REPETITIONS_START ); 
    pulser_timer1          <= input_wave_data( PULSER_T1_END              downto PULSER_T1_START             );
    pulser_timer2          <= input_wave_data( PULSER_T2_END              downto PULSER_T2_START             ); 
    pulser_timer3          <= input_wave_data( PULSER_T3_END              downto PULSER_T3_START             ); 
    pulser_timer4          <= input_wave_data( PULSER_T4_END              downto PULSER_T4_START             );
    pulser_timer_damp      <= input_wave_data( PULSER_TDAMP_END           downto PULSER_TDAMP_START          ); 
    pulser_invert_pulser   <= input_wave_data( PULSER_INVERT_PULSER_END   downto PULSER_INVERT_PULSER_START  );
    pulser_triple_pulser   <= input_wave_data( PULSER_TRIPLE_PULSER_END   downto PULSER_TRIPLE_PULSER_START  );

    wave_pulser: entity work.pulser
    generic map(
            NB_REPETITIONS_WIDTH                => NB_POINTS_WIDTH,
            TIMER_WIDTH                         => TIMER_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,
            areset_i                            => areset_i,
            
            -- Input interface
            strb_i                              => pulser_strb_i,
            nb_repetitions_i                    => pulser_nb_repetitions,
            t1_i                                => pulser_timer1,
            t2_i                                => pulser_timer2,
            t3_i                                => pulser_timer3,
            t4_i                                => pulser_timer4,
            tdamp_i                             => pulser_timer_damp,
            
            -- Control Interface
            bang_i                              => pulser_bang,
            
            -- Mode Interface 
            invert_pulser_i                     => pulser_invert_pulser(0),
            triple_pulser_i                     => pulser_triple_pulser(0),
            
            -- Output interface
            strb_o                              => pulser_strb_o,
            pulser_done_o                       => pulser_done,
            pulser_data_o                       => pulser_data
            );  

    -------------
    --  CORDIC --
    -------------

    cordic_phase_term     <= to_ufixed( input_wave_data( CORDIC_PHASE_TERM_END     downto CORDIC_PHASE_TERM_START     ) , cordic_phase_term) ;
    cordic_nb_points      <=            input_wave_data( CORDIC_NB_POINTS_END      downto CORDIC_NB_POINTS_START      );
    cordic_nb_repetitions <=            input_wave_data( CORDIC_NB_REPETITIONS_END downto CORDIC_NB_REPETITIONS_START );
    cordic_initial_phase  <= to_ufixed( input_wave_data( CORDIC_INIT_PHASE_END     downto CORDIC_INIT_PHASE_START     ) , cordic_initial_phase);
    cordic_mode_time      <=            input_wave_data( CORDIC_MODE_TIME_END      downto CORDIC_MODE_TIME_START      );

    wave_cordic: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                    => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS                 => N_CORDIC_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            EN_POSPROC                          => FALSE
        )
        port map(
            -- Clock interface
            clock_i                             => clock_i,  
            areset_i                            => areset_i,
    
            -- Input interface
            strb_i                              => cordic_strb_i,
            phase_term_i                        => cordic_phase_term,
            initial_phase_i                     => cordic_initial_phase,
            nb_points_i                         => cordic_nb_points,
            nb_repetitions_i                    => cordic_nb_repetitions,
            mode_time_i                         => cordic_mode_time(0), -- Forced FALSE
            
            -- Control interface
            restart_cycles_i                    => cordic_restart_cycles,
            
            -- Output interface
            strb_o                              => cordic_strb_o,
            sine_phase_o                        => cordic_sine_phase,
            cos_phase_o                         => open,
            done_cycles_o                       => cordic_done_cycles,
            flag_full_cycle_o                   => cordic_flag_full_cycle
        );
            

    -- Output

    resized_pulser_data     <= to_slv(to_sfixed( pulser_data,cordic_sine_phase));
    slv_cordic_sine_phase   <= to_slv(cordic_sine_phase);                                    


                                
    strb_o          <=          pulser_strb_o       when (wave_type = TYPE_PULSER)
                        else    cordic_strb_o       when (wave_type = TYPE_CORDIC)
                        else    '0';
    
    wave_data_o     <=          resized_pulser_data     when (wave_type = TYPE_PULSER)
                        else    slv_cordic_sine_phase   when (wave_type = TYPE_CORDIC)
                        else    (others => '0');                     
    
    
    wave_done_o     <=          pulser_done         when (wave_type = TYPE_PULSER)
                        else    cordic_done_cycles  when (wave_type = TYPE_CORDIC) -- TODO: Add done signal
                        else    '0';                      
    
            
end architecture behavioral;
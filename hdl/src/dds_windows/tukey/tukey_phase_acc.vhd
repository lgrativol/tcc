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
        WIN_ALFA                           : REAL     :=   0.5;
        PHASE_INTEGER_PART                 : natural  :=   0;
        PHASE_FRAC_PART                    : integer  := -15;
        NB_POINTS_WIDTH                    : positive :=  10 
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        phase_term_i                        : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
        nb_points_one_period_i              : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
        nb_repetitions_i                    : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);

        -- Control interface
        restart_acc_i                       : in  std_logic; 
        
        -- Debug interface
        flag_done_o                         : out std_logic;
        flag_period_o                       : out std_logic;

        -- Output interface
        strb_o                              : out std_logic;
        phase_o                             : out ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART)
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
    signal input_strb                           : std_logic; 
    signal phase_term                           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal initial_phase                        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal nb_points_one_period                 : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_repetitions                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    
    signal restart_acc                          : std_logic; 
    
    -- Behavioral
    signal strb_input_delay                     : std_logic;
    signal strb_input_delay_reg                 : std_logic;
    signal strb_new_term_reg                    : std_logic;

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
    
    signal output_strb                          : std_logic;
    signal output_strb_reg                      : std_logic;
    signal phase_acc                            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal output_phase                         : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
    signal enable_counters                      : std_logic;
    signal nb_points_one_period_counter         : unsigned((NB_POINTS_WIDTH - 1) downto 0);
    signal full_period_done                     : std_logic;
    
    signal nb_repetitions_counter               : unsigned((NB_POINTS_WIDTH - 1) downto 0);
    signal full_wave_done                       : std_logic;
    
begin          
    
    -- Input
    input_strb              <=  strb_i;
    phase_term              <=  phase_term_i;
    nb_points_one_period    <=  nb_points_one_period_i;
    nb_repetitions          <=  nb_repetitions_i;
    restart_acc             <=  restart_acc_i;
    
    --------------------
    -- Input register --
    --------------------

    input_regs : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_input_delay <= '0';

        elsif (rising_edge(clock_i) ) then                       
            strb_input_delay <= input_strb;

            if (input_strb = '1') then
                phase_term_reg              <= phase_term;
                nb_repetitions_reg          <= nb_repetitions;
                nb_points_one_period_reg    <= nb_points_one_period;
                nb_l_points_reg             <= std_logic_vector(unsigned(nb_points_one_period) + 1);
            end if;
        end if;
    end process;
    
    
    ------------------------
    -- Phase conformation --
    ------------------------
    
    -- Register -> alfa*L/2

    ufixed_nb_l_points_reg      <= to_ufixed(nb_l_points_reg,ufixed_nb_l_points_reg);

    half_alfa_l_proc : process(clock_i,areset_i)
    begin   
        if ( areset_i = '1') then
            strb_input_delay_reg   <= '0';

        elsif ( rising_edge(clock_i) ) then

            strb_input_delay_reg   <= strb_input_delay;

            if (strb_input_delay = '1' ) then
                nb_half_l_alfa      <= to_slv  (  resize ( ufixed_nb_l_points_reg * TUKEY_ALFA_HALF,  ufixed_nb_l_points_reg) );
                nb_half_points      <= '0' & nb_points_one_period_reg( (nb_points_one_period_reg'left) downto 1); -- nb_points_one_period/2
            end if;
        end if;
    end process;

    -- Third point
    half_points_plus_half_l_alfa_proc : process(clock_i,areset_i)
    begin   
        if ( areset_i = '1') then
            strb_new_term_reg   <= '0';

        elsif ( rising_edge(clock_i) ) then

            strb_new_term_reg   <= strb_input_delay_reg;

            if (strb_input_delay_reg = '1' ) then
                nb_half_points_plus_half_l_alfa  <= std_logic_vector( unsigned(nb_half_points)  +  unsigned(nb_half_l_alfa) );
            end if;
        end if;
end process;

    -----------------------
    -- Phase accumulator --
    -----------------------
    
    phase_acc_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then

            output_strb_reg     <= '0';
            restart_acc_reg     <= '0';
            hold_phase_reg      <= '0';
            reverse_acc_reg     <= '0';

        elsif ( rising_edge(clock_i) ) then

            output_strb_reg     <= output_strb;
            restart_acc_reg     <= restart_acc;
            hold_phase_reg      <= hold_phase;
            reverse_acc_reg     <= reverse_acc;

            if (output_strb = '1') then

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

    neg_edge_detector_restart_acc   <=                  restart_acc_reg
                                                    and (not restart_acc);

    -- Restart the accumulation
    start_new_cycle                 <=                  strb_new_term_reg               -- New phase term
                                                    or  neg_edge_detector_restart_acc;  -- Restart with the same phase term
    -- Resets phase acc to initial phase upon
    set_phase                       <=                  full_period_done    -- Full cycle (number of repetitions)
                                                    or  start_new_cycle;    -- Reset cycle signal
                                                       
    hold_phase                      <=                  less_half_points_plus_half_l_alfa
                                                    and not(less_half_alfa_l);
    
    neg_edge_detector_hold_phase    <=                  hold_phase_reg
                                                    and (not hold_phase);

    reverse_acc                     <=          (       neg_edge_detector_hold_phase
                                                            or  reverse_acc_reg               )
                                                    and (not full_wave_done                   ); 

    output_strb                     <=              (       (not full_wave_done)        
                                                        and output_strb_reg      )  
                                                    or  start_new_cycle;

    --------------
    -- Counters --
    --------------
    counters : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then

            nb_points_one_period_counter    <= (others => '0');
            nb_repetitions_counter          <= (others => '0');

        elsif (rising_edge(clock_i)) then

            if(output_strb = '1') then
               
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
                                                else    '0';
                                
    less_half_alfa_l                    <=              '1'     when (  nb_points_one_period_counter <= ( unsigned(nb_half_l_alfa)) )
                                                else    '0';
                            
    less_half_points_plus_half_l_alfa   <=              '1'     when (  nb_points_one_period_counter <= ( unsigned(nb_half_points_plus_half_l_alfa) - 1) )
                                                else    '0';
                        
    full_wave_done                      <=              '1'     when (  nb_repetitions_counter  = (unsigned(nb_repetitions_reg)) )
                                                else    '0';
    
    -- Output
    strb_o              <= output_strb_reg;
    phase_o             <= phase_acc;
    flag_period_o       <= full_period_done; 
    flag_done_o         <= full_wave_done;

end behavioral;
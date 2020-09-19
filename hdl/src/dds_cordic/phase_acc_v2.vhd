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
        initial_phase_i                     : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
        nb_points_one_period_i              : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
        nb_repetitions_i                    : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
        mode_time_i                         : in  std_logic;

        -- Control interface
        restart_acc_i                       : in  std_logic; 
        
        -- Debug interface
        flag_done_o                         : out std_logic;
        flag_period_o                       : out std_logic;

        -- Output interface
        strb_o                              : out std_logic;
        phase_o                             : out ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART)
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
    signal input_strb                           : std_logic; 
    signal phase_term                           : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal initial_phase                        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal nb_points_one_period                 : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_repetitions                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal mode_time                            : std_logic; 
    
    signal restart_acc                          : std_logic; 
    
    -- Behavioral
    signal strb_new_term_reg                    : std_logic;

    signal phase_term_reg                       : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);    
    signal initial_phase_reg                    : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal nb_points_one_period_reg             : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_repetitions_reg                   : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal mode_time_reg                        : std_logic; 
    
    signal start_new_cycle                      : std_logic;
    signal restart_acc_reg                      : std_logic;
    signal neg_edge_detector_restart_acc        : std_logic;
    signal set_phase                            : std_logic;
    
    signal output_strb                          : std_logic;
    signal output_strb_reg                      : std_logic;
    signal phase_acc                            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
    signal enable_counters                      : std_logic;
    signal nb_points_one_period_counter         : unsigned((NB_POINTS_WIDTH - 1) downto 0);
    signal full_period_done                     : std_logic;
    
    signal nb_repetitions_counter               : unsigned((NB_POINTS_WIDTH - 1) downto 0);
    signal full_wave_done                       : std_logic;

    --Phase time (experimental)
    signal phase_time_counter                   : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal phase_time_counter_not_done          : std_logic;
    signal phase_time_counter_not_done_reg      : std_logic;
    
begin          
    
    -- Input
    input_strb              <=  strb_i;
    phase_term              <=  phase_term_i;
    initial_phase           <=  initial_phase_i;
    nb_points_one_period    <=  nb_points_one_period_i;
    nb_repetitions          <=  nb_repetitions_i;
    mode_time               <= mode_time_i;
    
    restart_acc             <= restart_acc_i;
    
    --------------------
    -- Input register --
    --------------------

    input_regs : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_new_term_reg <= '0';
            mode_time_reg     <= '0';

        elsif (rising_edge(clock_i) ) then                       
            strb_new_term_reg <= input_strb;

            if (input_strb = '1') then
                phase_term_reg              <= phase_term;
                nb_repetitions_reg          <= nb_repetitions;
                nb_points_one_period_reg    <= nb_points_one_period;
                initial_phase_reg           <= initial_phase;
                mode_time_reg               <= mode_time;
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

        elsif ( rising_edge(clock_i) ) then

            output_strb_reg     <= output_strb;
            restart_acc_reg     <= restart_acc;

            if (output_strb = '1') then

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

    neg_edge_detector_restart_acc   <=                  restart_acc_reg
                                                    and (not restart_acc);

    -- Restart the accumulation
    start_new_cycle                 <=                  strb_new_term_reg               -- New phase term
                                                    or  neg_edge_detector_restart_acc;  -- Restart with the same phase term
    -- Resets phase acc to initial phase upon
    set_phase                       <=                  full_period_done    -- Full cycle (number of repetitions)
                                                    or  start_new_cycle     -- Reset cycle signal
                                                    or  phase_time_counter_not_done_reg;   

    output_strb                     <=              (       (not full_wave_done)        
                                                        and output_strb_reg      )  
                                                    or  start_new_cycle;

    --------------
    -- Counters --
    --------------

    enable_counters     <=          output_strb
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

    full_period_done     <=             '1'     when (  nb_points_one_period_counter = ( unsigned(nb_points_one_period_reg) - 1) )
                                else    '0';
            
    full_wave_done      <=              '1'     when (  nb_repetitions_counter  = ( unsigned(nb_repetitions_reg)) )
                                else    '0';

    -----------------------
    -- MODE TIME COUNTER --
    -----------------------

        -- Phase time
    phase_time_counter_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            phase_time_counter          <= (others => '0');
        elsif (rising_edge(clock_i)) then

            phase_time_counter_not_done_reg <=  phase_time_counter_not_done;

            if((output_strb = '1')) then

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
    strb_o              <= output_strb_reg;
    phase_o             <= phase_acc;
    flag_period_o       <= full_period_done; 
    flag_done_o         <= full_wave_done;

end behavioral;
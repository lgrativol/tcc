--
-- Timers Figure
--
--
--                        
--                 _____
--                |     |
--           t2   | t3  |  t4       tdamp
--          ------       -------_--------
--   |  t1 | 
--   |_____|
--
-- Any timer (t1,t2,t3,t4 or tdamp) can be zero, the zone will be skipped
-- The "invert_i" signal inteverts t1, t3 and tdamp (when in triple pulser mode) 
-- 
--
--
--
---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------
-- Entity --
------------

entity pulser is
    generic(
        NB_REPETITIONS_WIDTH                : positive  := 5;
        TIMER_WIDTH                         : positive  := 10  
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in for all inputs and mode interface
        nb_repetitions_i                    : in  std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0);
        t1_i                                : in  std_logic_vector( (TIMER_WIDTH - 1) downto 0); 
        t2_i                                : in  std_logic_vector( (TIMER_WIDTH - 1) downto 0);
        t3_i                                : in  std_logic_vector( (TIMER_WIDTH - 1) downto 0);
        t4_i                                : in  std_logic_vector( (TIMER_WIDTH - 1) downto 0);
        tdamp_i                             : in  std_logic_vector( (TIMER_WIDTH - 1) downto 0);
        
        -- Control Interface
        bang_i                              : in  std_logic; 

        -- Mode Interface 
        invert_pulser_i                     : in std_logic;
        triple_pulser_i                     : in std_logic;
        
        -- Output interface
        strb_o                              : out std_logic;
        pulser_done_o                       : out std_logic;
        pulser_data_o                       : out std_logic_vector(1 downto 0)
    );
end pulser;

------------------
-- Architecture --
------------------
architecture behavioral of pulser is

    --------------
    -- Constant --
    --------------
    constant    PULSER_AMP1     : std_logic_vector ( 1 downto 0) := "11"; -- -1
    constant    PULSER_ZERO     : std_logic_vector ( 1 downto 0) := "00"; -- 0
    constant    PULSER_AMP2     : std_logic_vector ( 1 downto 0) := "01"; -- +1

    constant    TIMER_ONE_CTE   : unsigned( (TIMER_WIDTH - 1) downto 0) := to_unsigned( 1,TIMER_WIDTH);

    -----------
    -- Types --
    -----------

    type tp_pulser_state is (ST_WAIT_BANG, ST_T1 , ST_T2, ST_T3, ST_T4, ST_TDAMP); 


    -------------
    -- Signals --
    -------------
    
    -- Input 
    signal input_strb                          : std_logic; -- Valid in for all inputs and mode interface
    signal nb_repetitions                      : std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0);
    signal timer1                              : std_logic_vector( (TIMER_WIDTH - 1) downto 0); 
    signal timer2                              : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal timer3                              : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal timer4                              : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal timer_damp                          : std_logic_vector( (TIMER_WIDTH - 1) downto 0);

    signal bang                                : std_logic; 

    signal invert_pulser                       : std_logic;
    signal triple_pulser                       : std_logic;    

    signal nb_repetitions_reg                  : std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0);
    signal timer1_reg                          : std_logic_vector( (TIMER_WIDTH - 1) downto 0); 
    signal timer2_reg                          : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal timer3_reg                          : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal timer4_reg                          : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal timer_damp_reg                      : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    
    signal invert_pulser_reg                   : std_logic;
    signal triple_pulser_reg                   : std_logic;    
    
    -- FSM
    signal pulser_state                        : tp_pulser_state;
    signal next_state                          : tp_pulser_state;
    signal first_non_zero_state                : tp_pulser_state;
    
    signal pulser_neg_amplitude                : std_logic_vector ( 1 downto 0) ; 
    signal pulser_pos_amplitude                : std_logic_vector ( 1 downto 0) ; 

    signal pulser_strb                         : std_logic;
    signal pulser_done                         : std_logic;
    signal pulser_data                         : std_logic_vector(1 downto 0);
    
    signal repetitions_counter                 : unsigned( (TIMER_WIDTH - 1) downto 0);
    signal enable_repetitions_counter          : std_logic;
    signal reset_repetitions_counter           : std_logic;
    signal nb_repetitions_done                 : std_logic;
    
    signal counter_timer1                      : unsigned( (TIMER_WIDTH - 1) downto 0); 
    signal timer1_done                         : std_logic;
    signal timer1_zero                         : std_logic;

    signal counter_timer2                      : unsigned( (TIMER_WIDTH - 1) downto 0);
    signal timer2_done                         : std_logic;
    signal timer2_zero                         : std_logic;

    signal counter_timer3                      : unsigned( (TIMER_WIDTH - 1) downto 0);
    signal timer3_done                         : std_logic;
    signal timer3_zero                         : std_logic;

    signal counter_timer4                      : unsigned( (TIMER_WIDTH - 1) downto 0);
    signal timer4_done                         : std_logic;
    signal timer4_zero                         : std_logic;    

    signal counter_timer_damp                  : unsigned( (TIMER_WIDTH - 1) downto 0);
    signal timer_damp_done                     : std_logic;
    signal timer_damp_zero                     : std_logic;

    signal all_zero_lock                       : std_logic;

    -- Output
    signal output_strb                         : std_logic;
    signal done                                : std_logic;
    signal data                                : std_logic_vector(1 downto 0);

begin
    
    -- Input
    input_strb          <= strb_i;
    nb_repetitions      <= nb_repetitions_i;
    timer1              <= t1_i;
    timer2              <= t2_i;
    timer3              <= t3_i;
    timer4              <= t4_i;
    timer_damp          <= tdamp_i;
    invert_pulser       <= invert_pulser_i;
    triple_pulser       <= triple_pulser_i;

    bang                <= bang_i;

    input_reg : process (clock_i,areset_i)
    begin
        if (areset_i = '1') then
            invert_pulser_reg   <= '0';
            triple_pulser_reg   <= '0';

        elsif(rising_edge(clock_i)) then
            if (input_strb = '1') then
                nb_repetitions_reg      <= nb_repetitions;
                timer1_reg              <= timer1;
                timer2_reg              <= timer2;
                timer3_reg              <= timer3;
                timer4_reg              <= timer4;
                timer_damp_reg          <= timer_damp;
                invert_pulser_reg       <= invert_pulser;
                triple_pulser_reg       <= triple_pulser;
            end if;
        end if;
    end process;

    pulser_neg_amplitude <=             PULSER_AMP2     when invert_pulser_reg = '1'
                                else    PULSER_AMP1;

    pulser_pos_amplitude <=             PULSER_AMP1     when invert_pulser_reg = '1'
                                else    PULSER_AMP2;

    -- FSM
    time_zones_fsm : process (clock_i,areset_i)
    begin
        if (areset_i = '1') then
            pulser_state            <= ST_WAIT_BANG;
            pulser_strb             <= '0';
            pulser_done             <= '0';
            reset_repetitions_counter <= '0';
            counter_timer1          <= TIMER_ONE_CTE;
            counter_timer2          <= TIMER_ONE_CTE;
            counter_timer3          <= TIMER_ONE_CTE;
            counter_timer4          <= TIMER_ONE_CTE;
            counter_timer_damp          <= TIMER_ONE_CTE;
            
        elsif (rising_edge(clock_i)) then

            pulser_strb    <= '0';
            pulser_done    <= '0';
            reset_repetitions_counter <= '0';
            pulser_data      <= PULSER_ZERO;
                                    
            case pulser_state is
                
                when ST_WAIT_BANG =>

                    pulser_data         <= PULSER_ZERO;

                    if(bang = '1') then                        
                        pulser_state       <= next_state;
                    else
                        pulser_state       <= ST_WAIT_BANG;
                    end if;

                when ST_T1 =>
                    
                    pulser_data         <= pulser_neg_amplitude;
                    pulser_strb         <= '1';                  
                   
                    if( timer1_done = '1' ) then
                        pulser_state        <= next_state;
                        counter_timer1      <= TIMER_ONE_CTE;
                    else
                        pulser_state        <= ST_T1;
                        counter_timer1      <= counter_timer1 + 1;
                    end if;

                when ST_T2 =>
    
                    pulser_data         <= PULSER_ZERO;
                   
                    if( timer2_done = '1' ) then
                        pulser_state        <= next_state;
                        counter_timer2      <= TIMER_ONE_CTE;
                    else
                        pulser_state        <= ST_T2;
                        counter_timer2      <= counter_timer2 + 1;
                    end if;

                when ST_T3 =>
            
                    pulser_data         <= pulser_pos_amplitude;
                    pulser_strb         <= '1';       

                    if( timer3_done = '1' ) then
                        pulser_state        <= next_state;
                        counter_timer3      <= TIMER_ONE_CTE;
                    else
                        pulser_state        <= ST_T3;
                        counter_timer3      <= counter_timer3 + 1;
                    end if;
                
                when ST_T4 =>
                    
                    pulser_data         <= PULSER_ZERO;
                   
                    if( timer4_done = '1' ) then
                        pulser_state        <= next_state;
                        counter_timer4      <= TIMER_ONE_CTE;
                    else
                        pulser_state        <= ST_T4;
                        counter_timer4      <= counter_timer4 + 1;
                    end if;               

                when ST_TDAMP =>

                    if (triple_pulser_reg = '1') then
                        pulser_strb         <= '1';
                        pulser_data         <= pulser_neg_amplitude;
                    else
                        pulser_data         <= PULSER_ZERO;
                    end if;
                
                    if( timer_damp_done = '1' ) then
                        pulser_done    <= '1';
                        pulser_state                <= ST_WAIT_BANG;
                        counter_timer_damp          <= TIMER_ONE_CTE;
                        reset_repetitions_counter   <= '1';
                    else
                        pulser_state            <= ST_TDAMP;
                        counter_timer_damp      <= counter_timer_damp + 1;
                    end if;     

                when others =>
                    pulser_state   <= ST_WAIT_BANG;
            end case;
        end if;
    end process;

    timer1_done                     <=              '1'   when ( counter_timer1 = unsigned(timer1_reg) )
                                            else    '0';

    timer1_zero                     <=              '1'   when ( timer1_reg = std_logic_vector(to_unsigned( 0 ,timer1_reg'length )))
                                            else    '0';

    timer2_done                     <=              '1'   when ( counter_timer2 = unsigned(timer2_reg) )
                                            else    '0';

    timer2_zero                     <=              '1'   when ( timer2_reg = std_logic_vector(to_unsigned( 0 ,timer2_reg'length )))
                                            else    '0';

    timer3_done                     <=              '1'   when ( counter_timer3 = unsigned(timer3_reg) )
                                            else    '0';
    
    timer3_zero                     <=              '1'   when ( timer3_reg = std_logic_vector(to_unsigned( 0 ,timer3_reg'length )))
                                            else    '0';

    timer4_done                     <=              '1'   when ( counter_timer4 = unsigned(timer4_reg) )
                                            else    '0';

    timer4_zero                     <=              '1'   when ( timer4_reg = std_logic_vector(to_unsigned( 0 ,timer4_reg'length )))
                                            else    '0';

    timer_damp_done                 <=              '1'   when ( counter_timer_damp = unsigned(timer_damp_reg) )
                                            else    '0'; 

    timer_damp_zero                 <=              '1'   when ( timer_damp_reg = std_logic_vector(to_unsigned( 0 ,timer_damp_reg'length )))
                                            else    '0';                                        

    first_non_zero_state            <=              ST_T1   when timer1_zero = '0'
                                            else    ST_T2   when timer2_zero = '0'
                                            else    ST_T3   when timer3_zero = '0'
                                            else    ST_T4   when timer4_zero = '0'
                                            else    ST_TDAMP;

    all_zero_lock                   <=              '1' when   (    first_non_zero_state = ST_TDAMP
                                                                or  timer_damp_zero = '1'            )
                                            else    '0';

        -- FSM next state decision
    next_state_proc : process(pulser_state,timer1_done,timer2_done,timer3_done,timer4_done,nb_repetitions_done,
                              timer1_zero, timer2_zero, timer3_zero, timer4_zero, first_non_zero_state , all_zero_lock)
        variable temp_state : tp_pulser_state;
    begin
        temp_state  := pulser_state;

        enable_repetitions_counter <= '0';

        if( temp_state = ST_WAIT_BANG) then
            if (all_zero_lock = '1') then -- Avoid deadlock with all timers = 0 and nb_reptitions > 1
                temp_state := ST_WAIT_BANG;
            else
                temp_state := first_non_zero_state;
            end if;
        end if;

        if( temp_state = ST_T1 and ( timer1_done = '1' or timer1_zero = '1') ) then
            temp_state := ST_T2;
        end if;

        if( temp_state = ST_T2 and ( timer2_done = '1' or timer2_zero = '1')) then
            temp_state := ST_T3;
        end if;

        if( temp_state = ST_T3 and ( timer3_done = '1' or timer3_zero = '1')) then
            temp_state := ST_T4;
        end if;

        if( temp_state = ST_T4 and ( timer4_done = '1' or timer4_zero = '1')) then
            
            if (nb_repetitions_done = '1') then
                temp_state := ST_TDAMP;
            else
                temp_state := first_non_zero_state;
                enable_repetitions_counter <= '1';
            end if;
        end if;

        next_state <= temp_state;
    end process;


    -- Repetitions Counter
    repetitions_counter_proc : process(clock_i,areset_i)
    begin
        if ( areset_i = '1') then
            repetitions_counter <= (others => '0');
        elsif ( rising_edge(clock_i) ) then

            if ( reset_repetitions_counter = '1') then
                repetitions_counter <= (others => '0');
            elsif ( enable_repetitions_counter = '1') then
                repetitions_counter <= repetitions_counter + 1;
            end if;

        end if;
    end process;

    nb_repetitions_done             <=              '1'   when ( repetitions_counter = unsigned(nb_repetitions_reg) - 1 )
                                            else    '0';

    output_proc : process(clock_i,areset_i) -- Removable
    begin
        if (areset_i = '1') then
            output_strb   <= '0';
        elsif (rising_edge(clock_i)) then

            output_strb <= pulser_strb;
            done        <= pulser_done;

            if (pulser_strb = '1') then
                data         <= pulser_data;
            end if;
        end if;
    end process;

    -- Output
    strb_o            <= output_strb;
    pulser_done_o     <= done;
    pulser_data_o     <= data;

end behavioral;
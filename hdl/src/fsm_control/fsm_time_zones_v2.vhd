---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity fsm_time_zones_v2 is
    generic(
        NB_REPETITIONS_WIDTH                : positive := 6
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        nb_repetitions_i                    : in  std_logic_vector(( NB_REPETITIONS_WIDTH - 1) downto 0);
        tx_time_i                           : in  std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
        tx_off_time_i                       : in  std_logic_vector(( TX_OFF_TIME_WIDTH - 1) downto 0);
        rx_time_i                           : in  std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
        off_time_i                          : in  std_logic_vector(( OFF_TIME_WIDTH - 1) downto 0);
        output_strb_i                       : in  std_logic;

        -- Control Interface
        start_rx_o                          : out std_logic;
        restart_cycles_o                    : out std_logic;
        end_zones_cycle_o                   : out std_logic
    );
end fsm_time_zones_v2;

------------------
-- Architecture --
------------------
architecture behavioral of fsm_time_zones_v2 is

    -----------
    -- Types --
    -----------

    type tp_time_state is (ST_INPUT, ST_TX , ST_TX_OFF, ST_RX, ST_OFF); 


    -------------
    -- Signals --
    -------------
    
    -- Input
    
    signal  tx_time                             : std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
    signal  tx_off_time                         : std_logic_vector(( TX_OFF_TIME_WIDTH - 1) downto 0);
    signal  rx_time                             : std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
    signal  off_time                            : std_logic_vector(( OFF_TIME_WIDTH - 1) downto 0);
    signal  nb_repetitions                      : std_logic_vector((NB_REPETITIONS_WIDTH - 1) downto 0);

    -- FSM
    signal  time_state                          : tp_time_state;

    -- Behavioral
    signal  nb_repetitions_reg                  : std_logic_vector((NB_REPETITIONS_WIDTH - 1) downto 0);
    signal  tx_time_reg                         : std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
    signal  tx_off_time_reg                     : std_logic_vector(( TX_OFF_TIME_WIDTH - 1) downto 0);
    signal  rx_time_reg                         : std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
    signal  off_time_reg                        : std_logic_vector(( OFF_TIME_WIDTH - 1) downto 0);
    
    signal  counter_nb_repetitions              : unsigned(( NB_REPETITIONS_WIDTH - 1) downto 0);
    signal  counter_tx_time                     : unsigned(( TX_TIME_WIDTH - 1) downto 0);
    signal  counter_tx_off_time                 : unsigned(( TX_OFF_TIME_WIDTH - 1) downto 0);
    signal  counter_rx_time                     : unsigned(( RX_TIME_WIDTH - 1) downto 0);
    signal  counter_off_time                    : unsigned(( OFF_TIME_WIDTH - 1) downto 0);
    
    signal  counter_nb_repetitions_done         : std_logic;
    signal  counter_tx_time_done                : std_logic;
    signal  counter_tx_off_time_done            : std_logic;
    signal  counter_rx_time_done                : std_logic;
    signal  counter_off_time_done               : std_logic;

    -- Output
    signal  start_rx                            : std_logic;
    signal  restart_cycles                      : std_logic;
    signal  end_zones_cycle                     : std_logic;


begin
    
    -- Input
    nb_repetitions      <= nb_repetitions_i;
    tx_time             <= tx_time_i;      
    tx_off_time         <= tx_off_time_i;
    rx_time             <= rx_time_i;      
    off_time            <= off_time_i;     

    input_reg : process (clock_i)
    begin
        if(rising_edge(clock_i)) then
            if (strb_i = '1') then
                nb_repetitions_reg      <= nb_repetitions;
                tx_time_reg             <= tx_time;      
                tx_off_time_reg         <= tx_off_time;
                rx_time_reg             <= rx_time;      
                off_time_reg            <= off_time; 
            end if;
        end if;
    end process;

    -- FSM
    time_zones_fsm : process (clock_i,areset_i)
    begin
        if (areset_i = '1') then
            counter_nb_repetitions  <= (others => '0');
            time_state              <= ST_INPUT;
            start_rx                <= '0';
            restart_cycles          <= '0';
            end_zones_cycle         <= '0';
            
        elsif (rising_edge(clock_i)) then

            restart_cycles      <= '0';
            start_rx            <= '0';
            end_zones_cycle     <= '0';
            
            case time_state is
                
                when ST_INPUT =>

                    if(strb_i = '1') then                        
                        counter_tx_time  <= (others => '0');
                        time_state       <= ST_TX;
                    else
                        time_state       <= ST_INPUT;
                    end if;

                when ST_TX =>
                    
                    restart_cycles <= '0';

                    if(output_strb_i = '1') then
                        if (counter_tx_time_done = '1') then
                            time_state       <= ST_TX_OFF;
                            counter_tx_off_time <= (others => '0');
                        else
                            time_state       <= ST_TX;
                            counter_tx_time <= counter_tx_time + 1 ;
                        end if;
                    else
                        time_state       <= ST_TX;
                    end if;

                when ST_TX_OFF =>

                    restart_cycles <= '0';

                    if (counter_tx_off_time_done = '1') then
                        time_state          <= ST_RX;
                        counter_rx_time     <= (others => '0');
                    else
                        time_state          <= ST_TX_OFF;
                        counter_tx_off_time <= counter_tx_off_time + 1 ;
                    end if;

                when ST_RX =>
                    start_rx        <= '1';
                    restart_cycles  <= '0';

                    if (counter_rx_time_done = '1') then
                        time_state       <= ST_OFF;
                        counter_off_time <= (others => '0');
                    else
                        time_state       <= ST_RX;
                        counter_rx_time <= counter_rx_time + 1 ;
                    end if;

                when ST_OFF =>

                    if (counter_off_time_done = '1') then


                        if (counter_nb_repetitions_done = '1') then
                            time_state              <= ST_INPUT;
                            counter_nb_repetitions  <= (others => '0');
                            end_zones_cycle         <= '1';
                        else
                            time_state              <= ST_TX;
                            counter_tx_time         <= (others => '0');
                            counter_nb_repetitions  <= counter_nb_repetitions + 1 ;
                            restart_cycles          <= '1';
                        end if;

                    else
                        time_state       <= ST_OFF;
                        counter_off_time <= counter_off_time + 1 ;
                        restart_cycles   <= '0';
                    end if;

                when others =>
                    time_state   <= ST_INPUT;
            end case;
        end if;
    end process;

    counter_nb_repetitions_done         <=              '1'     when (counter_nb_repetitions = ( unsigned(nb_repetitions_reg) - 1))
                                                else    '0';

    counter_tx_time_done                <=              '1'     when (counter_tx_time     = ( unsigned(tx_time_reg) - 1))
                                                else    '0';

    counter_tx_off_time_done            <=              '1'     when (counter_tx_off_time = ( unsigned(tx_off_time_reg) - 1))
                                                else    '0';

    counter_rx_time_done                <=              '1'     when (counter_rx_time     = ( unsigned(rx_time_reg) - 1))
                                                else    '0';

    counter_off_time_done               <=              '1'     when (counter_off_time    = ( unsigned(off_time_reg) - 1))
                                                else    '0';  

    -- Output
    start_rx_o         <= start_rx;
    restart_cycles_o   <= restart_cycles;
    end_zones_cycle_o  <= end_zones_cycle;

end behavioral;
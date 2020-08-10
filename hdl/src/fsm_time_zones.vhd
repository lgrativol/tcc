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

entity fsm_time_zones is
    generic(
        SYSTEM_FREQUENCY                    : positive := 100E6 -- 100 MHz
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        tx_time_i                           : in  std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
        tx_off_time_i                       : in  std_logic_vector(( TX_OFF_TIME_WIDTH - 1) downto 0);
        rx_time_i                           : in  std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
        off_time_i                          : in  std_logic_vector(( OFF_TIME_WIDTH - 1) downto 0);
        output_strb_i                       : in  std_logic;
        
        -- Control Interface
        restart_cycles_o                    : out std_logic

    );
end fsm_time_zones;

------------------
-- Architecture --
------------------
architecture behavioral of fsm_time_zones is

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

    -- FSM
    signal  time_state                          : tp_time_state;

    -- Behavioral
    signal  tx_time_reg                         : std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
    signal  tx_off_time_reg                     : std_logic_vector(( TX_OFF_TIME_WIDTH - 1) downto 0);
    signal  rx_time_reg                         : std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
    signal  off_time_reg                        : std_logic_vector(( OFF_TIME_WIDTH - 1) downto 0);
    
    signal  counter_tx_time                     : unsigned(( TX_TIME_WIDTH - 1) downto 0);
    signal  counter_tx_off_time                 : unsigned(( TX_OFF_TIME_WIDTH - 1) downto 0);
    signal  counter_rx_time                     : unsigned(( RX_TIME_WIDTH - 1) downto 0);
    signal  counter_off_time                    : unsigned(( OFF_TIME_WIDTH - 1) downto 0);
    
    signal  counter_tx_time_done                : std_logic;
    signal  counter_tx_off_time_done            : std_logic;
    signal  counter_rx_time_done                : std_logic;
    signal  counter_off_time_done               : std_logic;

    -- Output
    signal  restart_cycles                      : std_logic;


begin
    
    -- Input
    tx_time      <= tx_time_i;      
    tx_off_time  <= tx_off_time_i;
    rx_time      <= rx_time_i;      
    off_time     <= off_time_i;     

    input_reg : process (clock_i)
    begin
        if(rising_edge(clock_i)) then
            if (strb_i = '1') then
                tx_time_reg      <= tx_time;      
                tx_off_time_reg  <= tx_off_time;
                rx_time_reg      <= rx_time;      
                off_time_reg     <= off_time; 
            end if;
        end if;
    end process;

    -- FSM
    time_zones_fsm : process (clock_i,areset_i)
    begin
        if (areset_i = '1') then
            time_state      <= ST_INPUT;
            restart_cycles  <= '0';
            
        elsif (rising_edge(clock_i)) then

            restart_cycles <= '0';
                                    
            case time_state is
                
                when ST_INPUT =>

                    if(strb_i = '1') then                        
                        counter_tx_time  <= (others => '0');
                        time_state       <= ST_TX;
                    else
                        time_state       <= ST_INPUT;
                    end if;

                when ST_TX =>
                    
                    --restart_cycles <= '1';

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

                    restart_cycles <= '1';

                    if (counter_tx_off_time_done = '1') then
                        time_state       <= ST_RX;
                        counter_rx_time <= (others => '0');
                    else
                        time_state       <= ST_TX_OFF;
                        counter_tx_off_time <= counter_tx_off_time + 1 ;
                    end if;

                when ST_RX =>

                    restart_cycles <= '1';

                    if (counter_rx_time_done = '1') then
                        time_state       <= ST_OFF;
                        counter_off_time <= (others => '0');
                    else
                        time_state       <= ST_RX;
                        counter_rx_time <= counter_rx_time + 1 ;
                    end if;

                when ST_OFF =>

                    if (counter_off_time_done = '1') then
                        time_state       <= ST_TX;
                        counter_tx_time  <= (others => '0');
                        restart_cycles   <= '0';
                    else
                        time_state       <= ST_OFF;
                        counter_off_time <= counter_off_time + 1 ;
                        restart_cycles   <= '1';
                    end if;

                when others =>
                    time_state   <= ST_INPUT;
            end case;
        end if;
    end process;

    counter_tx_time_done        <=          '1' when (counter_tx_time     = ( unsigned(tx_time_reg) - 1)    )
                                    else    '0';

    counter_tx_off_time_done    <=          '1' when (counter_tx_off_time = ( unsigned(tx_off_time_reg) - 1))
                                    else    '0';

    counter_rx_time_done        <=          '1' when (counter_rx_time     = ( unsigned(rx_time_reg) - 1)    )
                                    else    '0';

    counter_off_time_done       <=          '1' when (counter_off_time    = ( unsigned(off_time_reg) - 1)   )
                                    else    '0';  

    -- Output
    restart_cycles_o <= restart_cycles;

end behavioral;
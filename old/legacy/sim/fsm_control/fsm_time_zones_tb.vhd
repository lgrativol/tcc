---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee_proposed;                      
use ieee_proposed.fixed_float_types.all; 
use ieee_proposed.fixed_pkg.all;         

library work;
use work.sim_input_pkg.all;

------------
-- Entity --
------------

entity fsm_time_zones_tb is
end fsm_time_zones_tb;

------------------
-- Architecture --
------------------
architecture testbench of fsm_time_zones_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                        : time     := 10 ns; -- 100 MHz
    constant SYSTEM_FREQUENCY                  : positive := 100E6;
    constant FREQUENCY_WIDTH                   : positive := ceil_log2(SYSTEM_FREQUENCY + 1);
    
    constant FULL_CYCLE_LATENCY                : positive := 1;

    constant CORDIC_OUTPUT_WIDTH               : positive := (N_CORDIC_ITERATIONS );

    -- Time zones
    constant  DELAY_TIME_WIDTH                 : positive := 18; -- Max time = 2.62 ms
    constant  TX_TIME_WIDTH                    : positive := 18; -- Max time = 2.62 ms
    constant  DEADZONE_TIME_WIDTH              : positive := 18; -- Max time = 2.62 ms
    constant  RX_TIME_WIDTH                    : positive := 18; -- Max time = 2.62 ms
    constant  IDLE_TIME_WIDTH                  : positive := 18; -- Max time = 2.62 ms

    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';

    signal valid_i                             : std_logic := '0';
    signal tx_time                             : std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
    signal tx_off_time                         : std_logic_vector(( DEADZONE_TIME_WIDTH - 1) downto 0);
    signal rx_time                             : std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
    signal off_time                            : std_logic_vector(( IDLE_TIME_WIDTH - 1) downto 0);
    signal output_valid                        : std_logic;

    signal restart_cycles                      : std_logic;
    signal end_zones_cycle                     : std_logic;

begin

    -- clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
   end process;

   UUT: entity work.fsm_time_zones
    generic map(
        SYSTEM_FREQUENCY                    => SYSTEM_FREQUENCY
    )
    port map(
        -- Clock interface
        clock_i                             => clk,
        areset_i                            => areset,

        -- Input interface
        valid_i                             => valid_i,
        tx_time_i                           => tx_time,
        tx_off_time_i                       => tx_off_time,
        rx_time_i                           => rx_time,
        off_time_i                          => off_time,

        output_valid_i                      => output_valid,
        
        -- Control Interface
        restart_cycles_o                    => restart_cycles,
        end_zones_cycle_o                   => end_zones_cycle
    );

    stim_proc : process
    begin
        areset <= '1';
        valid_i <= '0';
        
        for I in 0 to 4 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;
        
        areset <= '0';
        valid_i <= '1';
        output_valid <= '0';
        tx_time                             <= std_logic_vector(to_unsigned( 200, tx_time'length )  ); -- Sine frequency = 1 MHz
        tx_off_time                         <= std_logic_vector(to_unsigned( 10, tx_off_time'length )  );  -- Extra time 
        rx_time                             <= std_logic_vector(to_unsigned( 300, rx_time'length )  ); -- A huge amount of time
        off_time                            <= std_logic_vector(to_unsigned( 10, off_time'length )  ); -- Extra time 
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        
        output_valid <= '0';
        valid_i <= '0';
    
        for I in 0 to 9 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;

        output_valid <= '1';
        
        wait;
        
    end process;

end testbench;
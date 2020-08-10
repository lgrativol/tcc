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
use work.utils_pkg.all;
use work.sim_input_pkg.all;

------------
-- Entity --
------------

entity top_dds_cordic_tb is
end top_dds_cordic_tb;

------------------
-- Architecture --
------------------
architecture testbench of top_dds_cordic_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                        : time     := 10 ns; -- 100 MHz
    
    -- Input target frequency
    constant SYSTEM_FREQUENCY                  : positive := 100E6;
    constant FREQUENCY_WIDTH                   : positive := ceil_log2(SYSTEM_FREQUENCY + 1);

    -- Input TX time (nb 100 MHz cycles)
    constant TX_TIME_CONSTANT                  : positive := ( (SYSTEM_FREQUENCY / SIM_INPUT_TARGETFREQ) * SIM_INPUT_NBCYCLES );
    
    -- Write txt
    constant CORDIC_OUTPUT_WIDTH               : positive := (N_CORDIC_ITERATIONS );

    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';

    signal strb_i                              : std_logic := '0';
    signal target_freq                         : std_logic_vector((FREQUENCY_WIDTH - 1) downto 0):= std_logic_vector(to_unsigned(20e3,FREQUENCY_WIDTH ));
    signal nb_cycles                           : std_logic_vector((NB_CYCLES_WIDTH - 1) downto 0);
    signal phase_diff                          : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  

    signal tx_time                             : std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
    signal tx_off_time                         : std_logic_vector(( TX_OFF_TIME_WIDTH - 1) downto 0);
    signal rx_time                             : std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
    signal off_time                            : std_logic_vector(( OFF_TIME_WIDTH - 1) downto 0);

    signal done_cycles                         : std_logic;

    signal strb_o                              : std_logic := '0';
    signal sine_phase                          : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal flag_full_cycle                     : std_logic;

    -- Simulation
    signal write_data_in                       : std_logic_vector((CORDIC_OUTPUT_WIDTH - 1) downto 0);
    
begin

    -- clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
   end process;

    UUT : entity work.top_dds_cordic
        generic map (
            SYSTEM_FREQUENCY                    => SYSTEM_FREQUENCY
        )
        port map(
            clock_i                             => clk,  
            areset_i                            => areset,

            strb_i                              => strb_i,
            target_frequency_i                  => target_freq,
            nb_cycles_i                         => nb_cycles,
            phase_diff_i                        => phase_diff,
            
            tx_time_i                           => tx_time,    
            tx_off_time_i                       => tx_off_time,
            rx_time_i                           => rx_time,    
            off_time_i                          => off_time,   

            done_cycles_o                       => done_cycles,

            strb_o                              => strb_o,
            sine_phase_o                        => sine_phase,
            flag_full_cycle_o                   => flag_full_cycle
            
        );

    stim_proc : process
    begin
        areset <= '1';
        strb_i <= '0';
        
        for I in 0 to 3 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;
        
        areset <= '0';
        strb_i <= '1';

        -- Inputs --
        target_freq     <=  std_logic_vector(to_unsigned( SIM_INPUT_TARGETFREQ, FREQUENCY_WIDTH )); -- TODO: check behavior with 0
        nb_cycles       <=  std_logic_vector(to_unsigned( SIM_INPUT_NBCYCLES, NB_CYCLES_WIDTH ));  -- TODO: check behavior with 0
        phase_diff      <=  (others => '0');
        
        tx_time         <=  std_logic_vector(to_unsigned( TX_TIME_CONSTANT , tx_time'length));
        tx_off_time     <=  std_logic_vector(to_unsigned( 80 , tx_off_time'length ));  -- Extra time 
        rx_time         <=  std_logic_vector(to_unsigned( 10000 , rx_time'length )); -- A huge amount of time
        off_time        <=  std_logic_vector(to_unsigned( 100 , off_time'length )); -- Extra time 
        -- Inputs --
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));

        wait;
        
    end process;

    -- Simulation 
    
    write_data_in <= to_slv(sine_phase);

    write2file : entity work.sim_write2file
        generic map (
            FILE_NAME    => "./output.txt", 
            INPUT_WIDTH  => CORDIC_OUTPUT_WIDTH
        )
        port map (
            clock           => clk,
            hold            => '1',
            data_valid      => strb_o,
            data_in         => write_data_in
        ); 

end testbench;
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

use std.env.finish;

------------
-- Entity --
------------

entity double_driver_tb is
end double_driver_tb;

------------------
-- Architecture --
------------------
architecture testbench of double_driver_tb is
    
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

    signal end_zones_cycle                     : std_logic;

    signal tx_time                             : std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
    signal tx_off_time                         : std_logic_vector(( TX_OFF_TIME_WIDTH - 1) downto 0);
    signal rx_time                             : std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
    signal off_time                            : std_logic_vector(( OFF_TIME_WIDTH - 1) downto 0);

    signal driver_a_strb_o                     : std_logic := '0';
    signal driver_a_sine_phase                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal driver_a_done_cycles                : std_logic;
    signal driver_a_flag_full_cycle            : std_logic;

    signal driver_b_strb_o                     : std_logic := '0';
    signal driver_b_sine_phase                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal driver_b_done_cycles                : std_logic;
    signal driver_b_flag_full_cycle            : std_logic;

    -- Simulation
    signal write_driver_a_strb_o               : std_logic;
    signal write_driver_a_strb_o_reg           : std_logic;
    signal write_data_in_driver_a              : std_logic_vector((CORDIC_OUTPUT_WIDTH - 1) downto 0);
    
    signal write_driver_b_strb_o               :  std_logic;
    signal write_driver_b_strb_o_reg           :  std_logic;
    signal write_data_in_driver_b              : std_logic_vector((CORDIC_OUTPUT_WIDTH - 1) downto 0);

    signal stop_clock                          : std_logic;
    
begin

    stop_clock <= end_zones_cycle;

    -- clock process definitions
   clk_process :process
   begin

        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
   end process;

   UUT: entity work.double_driver
    generic map (
        SYSTEM_FREQUENCY                    => SYSTEM_FREQUENCY
    )
    port map(
        -- Clock interface
        clock_i                             => clk,
        areset_i                            => areset,

        -- Input interface
        strb_i                              => strb_i,
        target_frequency_i                  => target_freq,
        nb_cycles_i                         => nb_cycles,
        phase_diff_i                        => phase_diff,

        -- Control Interface
        tx_time_i                           => tx_time ,    
        tx_off_time_i                       => tx_off_time,  
        rx_time_i                           => rx_time,     
        off_time_i                          => off_time,    
        
        -- Output driver A interface
        A_strb_o                            => driver_a_strb_o,         
        A_sine_phase_o                      => driver_a_sine_phase,     
        A_done_cycles_o                     => driver_a_done_cycles,    
        A_flag_full_cycle_o                 => driver_a_flag_full_cycle,
        
        -- Output driver B interface
        B_strb_o                            => driver_b_strb_o,         
        B_sine_phase_o                      => driver_b_sine_phase,     
        B_done_cycles_o                     => driver_b_done_cycles,    
        B_flag_full_cycle_o                 => driver_b_flag_full_cycle,

        end_zones_cycle_o                   => end_zones_cycle
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
        phase_diff      <=  resize(PI / 2.0 ,PHASE_INTEGER_PART, PHASE_FRAC_PART);
        
        tx_time         <=  std_logic_vector(to_unsigned( SIM_INPUT_TX_TIME , tx_time'length));
        tx_off_time     <=  std_logic_vector(to_unsigned( SIM_INPUT_TX_OFF_TIME , tx_off_time'length ));  -- Extra time 
        rx_time         <=  std_logic_vector(to_unsigned( SIM_INPUT_RX_TIME , rx_time'length )); -- A huge amount of time
        off_time        <=  std_logic_vector(to_unsigned( SIM_INPUT_OFF_TIME , off_time'length )); -- Extra time 

        -- Inputs --
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));

        wait;
        
    end process;

    -- Simulation 

    write_start : process(clk,areset)
    begin
        if(areset = '1') then
            write_driver_a_strb_o_reg <= '0';
            write_driver_b_strb_o_reg <= '0';
        elsif(rising_edge(clk)) then
            write_driver_a_strb_o_reg <= write_driver_a_strb_o;
            write_driver_b_strb_o_reg <= write_driver_b_strb_o;    
        end if;        
    end process;


    write_driver_a_strb_o   <=              driver_a_strb_o
                                        or  write_driver_a_strb_o_reg;
    
    write_driver_b_strb_o   <=              driver_b_strb_o
                                        or  write_driver_b_strb_o_reg;
    
    
    write_data_in_driver_a <= to_slv(driver_a_sine_phase);

    write2fileA : entity work.sim_write2file
        generic map (
            FILE_NAME    => "./outputA.txt", 
            INPUT_WIDTH  => CORDIC_OUTPUT_WIDTH
        )
        port map (
            clock           => clk,
            hold            => '0',
            data_valid      => write_driver_a_strb_o_reg,
            data_in         => write_data_in_driver_a
        ); 
    
    write_data_in_driver_b <= to_slv(driver_b_sine_phase);

    write2fileB : entity work.sim_write2file
        generic map (
            FILE_NAME    => "./outputB.txt", 
            INPUT_WIDTH  => CORDIC_OUTPUT_WIDTH
        )
        port map (
            clock           => clk,
            hold            => '0',
            data_valid      => write_driver_b_strb_o_reg,
            data_in         => write_data_in_driver_b
        ); 

    finish_sim : process    
    begin
    
        wait until end_zones_cycle = '1';
        finish;    
    end process;

end testbench;
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
    constant SYSTEM_FREQUENCY                  : positive := 100E6;
    constant FREQUENCY_WIDTH                   : positive := ceil_log2(SYSTEM_FREQUENCY + 1);
    
    constant FULL_CYCLE_LATENCY                : positive := 1;

    constant CORDIC_OUTPUT_WIDTH               : positive := (N_CORDIC_ITERATIONS );

    ----------
    -- Type --
    ----------
    type tp_shift_latency   is array ( 0 to(FULL_CYCLE_LATENCY - 1)) of std_logic; 


    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';

    signal strb_i                              : std_logic := '0';
    signal target_freq                         : std_logic_vector((FREQUENCY_WIDTH - 1) downto 0):= std_logic_vector(to_unsigned(20e3,FREQUENCY_WIDTH ));
    signal nb_cycles                           : std_logic_vector((NB_CYCLES_WIDTH - 1) downto 0);
    signal phase_diff                          : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  

    signal restart_cycles                      : std_logic;
    signal done_cycles                         : std_logic;

    signal strb_o                              : std_logic := '0';
    signal sine_phase                          : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal flag_full_cycle                     : std_logic;

    -- Simulation
    signal shift_latency                       : tp_shift_latency;
    signal full_cycle                          : std_logic;
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

            restart_cycles_i                    => restart_cycles,
            done_cycles_o                       => done_cycles,

            strb_o                              => strb_o,
            sine_phase_o                        => sine_phase,
            flag_full_cycle_o                   => flag_full_cycle
            
        );

    stim_proc : process
    begin
        areset <= '1';
        strb_i <= '0';
        
        wait for 4*CLK_PERIOD;
        wait until (rising_edge(clk));
        
        areset <= '0';
        restart_cycles <= '0';
        strb_i <= '1';
        target_freq <=  std_logic_vector(to_unsigned( 200e3, FREQUENCY_WIDTH )); -- TODO: check behavior with 0
        nb_cycles   <=  std_logic_vector(to_unsigned(   1, NB_CYCLES_WIDTH ));  -- TODO: check behavior with 0
        phase_diff  <=  (others => '0');
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';

        wait until done_cycles = '1';
        restart_cycles <= '0';
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        restart_cycles <= '0';

        wait;
        
    end process;

    -- Simulation 
    
    shift_latency_proc : process(clk,areset)
    begin
        if( areset = '1') then
            shift_latency <= (others => '0');
        elsif ( rising_edge(clk)) then
            shift_latency(0) <= flag_full_cycle;
            
            for i in 1 to (FULL_CYCLE_LATENCY - 1) loop
                shift_latency(i)    <= shift_latency(i-1) ;
            end loop;
        end if;
    end process;
    
    full_cycle <= shift_latency(FULL_CYCLE_LATENCY - 1);


    write_data_in <= to_slv(sine_phase);

    write2file : entity work.sim_write2file
        generic map (
            FILE_NAME    => "./output.txt", 
            INPUT_WIDTH  => CORDIC_OUTPUT_WIDTH
        )
        port map (
            clock           => clk,
            data_valid      => strb_o,
            data_in         => write_data_in
        ); 

end testbench;
---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.fixed_float_types.all; -- only synthesis
--use ieee.fixed_pkg.all;         -- only synthesis

library ieee_proposed;                      -- only simulation
use ieee_proposed.fixed_float_types.all;    -- only simulation
use ieee_proposed.fixed_pkg.all;            -- only simulation

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
    
    constant FULL_CYCLE_LATENCE                : positive := 1;

    ----------
    -- Type --
    ----------
    type tp_shift_latence   is array ( 0 to(FULL_CYCLE_LATENCE - 1)) of std_logic; 


    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';

    signal freq_valid                          : std_logic := '0';
    signal target_freq                         : std_logic_vector((FREQUENCY_WIDTH - 1) downto 0):= std_logic_vector(to_unsigned(20e3,FREQUENCY_WIDTH ));
    
    -- Simulation
    signal shift_latence                       : tp_shift_latence;
    signal flag_full_cycle_o                   : std_logic;
    signal full_cycle                          : std_logic;
    
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
            strb_frequency_i                    => freq_valid,
            target_frequency_i                  => target_freq,
            flag_full_cycle_o                   => flag_full_cycle_o
        );

    stim_proc : process
    begin
        areset <= '1';
        freq_valid <= '0';
        
        wait for 4*CLK_PERIOD;
        wait until (rising_edge(clk));
        
        areset <= '0';

        freq_valid <= '1';
        target_freq <=  std_logic_vector(to_unsigned(20e3,FREQUENCY_WIDTH ));
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        freq_valid <= '0';

        for k in 0 to 47 loop
            wait until (full_cycle = '1');
            freq_valid <= '1';
            target_freq <=  std_logic_vector(to_unsigned(to_integer(unsigned(target_freq)) + 20e3,FREQUENCY_WIDTH ));
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
            freq_valid <= '0';
        end loop;
        wait;
        
    end process;
    
    shift_latence_proc : process(clk,areset)
    begin
        if( areset = '1') then
            shift_latence <= (others => '0');
        elsif ( rising_edge(clk)) then
            shift_latence(0) <= flag_full_cycle_o;
            
            for i in 1 to (FULL_CYCLE_LATENCE - 1) loop
                shift_latence(i)    <= shift_latence(i-1) ;
            end loop;
        end if;
    end process;
    
    full_cycle <= shift_latence(FULL_CYCLE_LATENCE - 1);


end testbench;
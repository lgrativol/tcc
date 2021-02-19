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

entity lookup_wave_tb is
end lookup_wave_tb;

------------------
-- Architecture --
------------------
architecture testbench of lookup_wave_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                         : time      := 10 ns; -- 100 MHz
    
    constant WORD_WIDTH                         : positive  := 8;
    constant MAX_NB_POINTS                      : positive  := 64;
    constant ADDR_WIDTH                         : positive  := ceil_log2(MAX_NB_POINTS + 1);
    
    constant NB_POINTS_WIDTH                    : positive  := 6;

    -------------
    -- Signals --
    -------------

    signal clk                                  : std_logic :='0';
    signal areset                               : std_logic :='0';

    signal new_wave                             : std_logic;
    signal nb_points                            : std_logic_vector((ADDR_WIDTH - 1) downto 0);
    signal nb_repetitions                       : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    
    signal bang                                 : std_logic;
    signal restart                              : std_logic;
    
    signal valid                                : std_logic;
    signal data                                 : std_logic_vector((WORD_WIDTH - 1) downto 0); 
    signal last_word                            : std_logic;

    -- Memory Interface
    signal mem_write_addr                       : std_logic_vector((ADDR_WIDTH - 1) downto 0);  
    signal mem_write_enable                     : std_logic := '0';                       			            
    signal mem_write_data                       : std_logic_vector((WORD_WIDTH - 1) downto 0);           

begin

    -- clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    UUT: entity work.lookup_wave
        generic map(
            INIT_FILE                   => "",
            WORD_WIDTH                  => WORD_WIDTH,
            RAM_DEPTH                   => MAX_NB_POINTS,
            NB_REPT_WIDTH               => NB_POINTS_WIDTH
        )
        port map(
            clock_i                     => clk,
            areset_i                    => areset,

            -- Memory Write Interface
            mem_write_addr_i            => mem_write_addr,
            mem_write_enable_i          => mem_write_enable,
            mem_write_data_i            => mem_write_data,

            -- Control Interface
            bang_i                      => bang,
            nb_points_i                 => nb_points,
            nb_repetitions_i            => nb_repetitions,
            restart_i                   => restart,

            -- Wave Interface
            valid_o                     => valid,
            data_o                      => data,
            last_word_o                 => last_word
    );

    stim_proc : process
    begin
        areset              <= '1';
        mem_write_enable    <= '0';
        restart             <= '0';
        bang                <= '0';

        
        for I in 0 to 3 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;

        areset <= '0';

        for I in 0 to (MAX_NB_POINTS - 1) loop
            mem_write_enable    <= '1';

            mem_write_addr      <=  std_logic_vector(to_unsigned(I,mem_write_addr'length));
            mem_write_data      <=  std_logic_vector(to_unsigned(I,mem_write_data'length));

            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;
        
        mem_write_enable    <= '0';

        bang                    <= '1';
        nb_points               <= std_logic_vector( to_unsigned(  32  ,nb_points'length)); 
        nb_repetitions          <= std_logic_vector( to_unsigned(  3 ,nb_repetitions'length)); 
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));

        bang                    <= '0';
        nb_points               <= (others => '-');
        nb_repetitions          <= (others => '-');

        wait;
        
    end process;

end testbench;
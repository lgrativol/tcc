---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------
-- Entity --
------------

entity pulser_tb is
end pulser_tb;

------------------
-- Architecture --
------------------
architecture testbench of pulser_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                        : time      := 10 ns; -- 100 MHz
    constant NB_REPETITIONS_WIDTH              : positive  := 5;
    constant TIMER_WIDTH                       : positive  := 10;  
    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';

    signal strb_i                              : std_logic := '0';
    signal nb_repetitions                      : std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0);
    signal timer1                              : std_logic_vector( (TIMER_WIDTH - 1) downto 0); 
    signal timer2                              : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal timer3                              : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal timer4                              : std_logic_vector( (TIMER_WIDTH - 1) downto 0);
    signal timer_damp                          : std_logic_vector( (TIMER_WIDTH - 1) downto 0);

    signal bang                                : std_logic; 

    signal invert_pulser                       : std_logic;
    signal triple_pulser                       : std_logic;    

    signal strb_o                              : std_logic;
    signal pulser_done                         : std_logic;
    signal pulser_data                         : std_logic_vector(1 downto 0);

begin

    -- clock process definitions
   clk_process :process
   begin

        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
   end process;

   UUT: entity work.pulser
    generic map(
        NB_REPETITIONS_WIDTH                => NB_REPETITIONS_WIDTH,
        TIMER_WIDTH                         => TIMER_WIDTH
    )
    port map(
        -- Clock interface
        clock_i                             => clk,
        areset_i                            => areset,

        -- Input interface
        strb_i                              => strb_i,
        nb_repetitions_i                    => nb_repetitions,
        t1_i                                => timer1,
        t2_i                                => timer2,
        t3_i                                => timer3,
        t4_i                                => timer4,
        tdamp_i                             => timer_damp,
        
        -- Control Interface
        bang_i                              => bang,

        -- Mode Interface 
        invert_pulser_i                     => invert_pulser,
        triple_pulser_i                     => triple_pulser,
        
        -- Output interface
        strb_o                              => strb_o,
        pulser_done_o                       => pulser_done,
        pulser_data_o                       => pulser_data
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
        
        
        report ("Teste simples");
        -- Inputs --

        strb_i <= '1';
        nb_repetitions  <= std_logic_vector( to_unsigned(   1   ,nb_repetitions'length));
        timer1          <= std_logic_vector( to_unsigned(   2   ,timer1'length));
        timer2          <= std_logic_vector( to_unsigned(   2   ,timer2'length));
        timer3          <= std_logic_vector( to_unsigned(   2   ,timer3'length));
        timer4          <= std_logic_vector( to_unsigned(   2   ,timer4'length));
        timer_damp      <= std_logic_vector( to_unsigned(   2   ,timer_damp'length));

        invert_pulser <= '0';
        triple_pulser <= '0';
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';
        bang   <= '1';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        bang   <= '0';

        wait until pulser_done = '1';        
        for I in 0 to 4 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;

        -- Inputs --

        report ("Triple pulser");
        -- Inputs --

        strb_i <= '1';
        nb_repetitions  <= std_logic_vector( to_unsigned(   1   ,nb_repetitions'length));
        timer1          <= std_logic_vector( to_unsigned(   2   ,timer1'length));
        timer2          <= std_logic_vector( to_unsigned(   4   ,timer2'length));
        timer3          <= std_logic_vector( to_unsigned(   8   ,timer3'length));
        timer4          <= std_logic_vector( to_unsigned(   16   ,timer4'length));
        timer_damp      <= std_logic_vector( to_unsigned(   32   ,timer_damp'length));

        invert_pulser <= '0';
        triple_pulser <= '1';
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';
        bang   <= '1';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        bang   <= '0';

        -- Inputs --        
        wait until pulser_done = '1';        
        for I in 0 to 4 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;

        report ("Inverted pulser");
        -- Inputs --

        strb_i <= '1';
        nb_repetitions  <= std_logic_vector( to_unsigned(   1   ,nb_repetitions'length));
        timer1          <= std_logic_vector( to_unsigned(   2   ,timer1'length));
        timer2          <= std_logic_vector( to_unsigned(   4   ,timer2'length));
        timer3          <= std_logic_vector( to_unsigned(   8   ,timer3'length));
        timer4          <= std_logic_vector( to_unsigned(   16   ,timer4'length));
        timer_damp      <= std_logic_vector( to_unsigned(   32   ,timer_damp'length));

        invert_pulser <= '1';
        triple_pulser <= '1';
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';
        bang   <= '1';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        bang   <= '0';

        -- Inputs --  

        wait until pulser_done = '1';        
        for I in 0 to 4 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;

        report ("Zeros test 1");
        -- Inputs --

        strb_i <= '1';
        nb_repetitions  <= std_logic_vector( to_unsigned(   4   ,nb_repetitions'length));
        timer1          <= std_logic_vector( to_unsigned(   2   ,timer1'length));
        timer2          <= std_logic_vector( to_unsigned(   0   ,timer2'length));
        timer3          <= std_logic_vector( to_unsigned(   2   ,timer3'length));
        timer4          <= std_logic_vector( to_unsigned(   0   ,timer4'length));
        timer_damp      <= std_logic_vector( to_unsigned(   4   ,timer_damp'length));

        invert_pulser <= '0';
        triple_pulser <= '1';
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';
        bang   <= '1';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        bang   <= '0';

        wait until pulser_done = '1';        
        for I in 0 to 4 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;

        report ("Zeros test 2");
        -- Inputs --

        strb_i <= '1';
        nb_repetitions  <= std_logic_vector( to_unsigned(   3   ,nb_repetitions'length));
        timer1          <= std_logic_vector( to_unsigned(   0   ,timer1'length));
        timer2          <= std_logic_vector( to_unsigned(   0   ,timer2'length));
        timer3          <= std_logic_vector( to_unsigned(   2   ,timer3'length));
        timer4          <= std_logic_vector( to_unsigned(   0   ,timer4'length));
        timer_damp      <= std_logic_vector( to_unsigned(   4   ,timer_damp'length));

        invert_pulser <= '1';
        triple_pulser <= '0';
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        strb_i <= '0';
        bang   <= '1';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        bang   <= '0';

        wait until pulser_done = '1';        
        for I in 0 to 4 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;

        -- Inputs --           

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));

        wait;
        
    end process;

end testbench;
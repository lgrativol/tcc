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
use work.random_pkg;

------------
-- Entity --
------------

entity averager_v2_tb is
end averager_v2_tb;

------------------
-- Architecture --
------------------
architecture testbench of averager_v2_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                         : time      := 10 ns; -- 100 MHz
    
    constant DATA_WIDTH                         : positive  := 8;
    constant SIDEBAND_WIDTH                     : positive  := 1;
    constant MAX_NB_POINTS                      : positive  := 64;
    constant ADDR_WIDTH                         : positive  := ceil_log2(MAX_NB_POINTS + 1);
    
    constant NB_REPETITIONS_WIDTH               : positive  := 6;
    constant WORD_FRAC_PART                     : integer   := -6;    

    constant SIM_NB_REPETITIONS                 : positive  := 4;


    -------------
    -- Signals --
    -------------

    signal clk                                  : std_logic :='0';
    signal areset                               : std_logic :='0';

    signal config_valid_i                       : std_logic := '0';
    signal config_max_addr                      : std_logic_vector( (ADDR_WIDTH  - 1 ) downto 0 ) := std_logic_vector( to_unsigned (MAX_NB_POINTS - 1 ,ADDR_WIDTH ) );
    signal config_nb_repetitions                : std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0 );

    -- Input interface 
    signal input_valid_i                        : std_logic := '0';
    signal input_data                           : sfixed( 1 downto WORD_FRAC_PART );
    signal random_signal                        : sfixed( 1 downto WORD_FRAC_PART );
    signal input_last_word                      : std_logic := '0';

    -- AXI-ST output interface
    signal s_axis_st_tready_i                   : std_logic;
    signal s_axis_st_tvalid_o                   : std_logic;
    signal s_axis_st_tdata                      : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal s_axis_st_tlast                      : std_logic;

    -- Empty Cycle
    signal empty_ready_o                        : std_logic;
    signal empty_data_valid_i                   : std_logic;    
    signal empty_data_i                         : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal empty_sideband_i                     : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal empty_ready_i                        : std_logic;
    signal empty_data_valid_o                   : std_logic;    
    signal empty_data_o                         : std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal empty_sideband_o                     : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

begin

    -- clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    UUT: entity work.averager_v2 
        generic map(
            -- Behavioral
            NB_REPETITIONS_WIDTH        => NB_REPETITIONS_WIDTH,
            WORD_FRAC_PART              => WORD_FRAC_PART,    
            MAX_NB_POINTS               => MAX_NB_POINTS
        )
        port map (
            clock_i                     => clk,
            areset_i                    => areset,
    
            -- Config  interface
            config_valid_i              => config_valid_i,
            config_max_addr_i           => config_max_addr, 
            config_nb_repetitions_i     => config_nb_repetitions, -- Only powers of 2 ( 2^0, 2^1, 2^2, 2^3 ....)
    
            -- Input interface 
            input_valid_i               => input_valid_i,
            input_data_i                => input_data,
            input_last_word_i           => input_last_word,
    
            -- Output interface
            s_axis_st_tready_i          => s_axis_st_tready_i,
            s_axis_st_tvalid_o          => s_axis_st_tvalid_o,
            s_axis_st_tdata_o           => s_axis_st_tdata,
            s_axis_st_tlast_o           => s_axis_st_tlast
        );

    stim_proc : process

        procedure write_memory  (   constant pattern            : in std_logic_vector; 
                                    constant nb_rep             : in positive;
                                    constant nb_empty_cycles    : in natural
                                ) is

            constant WORD_WIDTH     : positive := ( pattern'length);
            constant NB_WORDS       : positive := ( ( WORD_WIDTH + DATA_WIDTH) / DATA_WIDTH );

            variable random_pattern : sfixed( 1 downto WORD_FRAC_PART);
            variable random_part    : sfixed( 1 downto WORD_FRAC_PART);

        begin

            input_valid_i <= '0';
            input_last_word <= '0';

            for idx_rep in 1 to nb_rep loop

                input_last_word <= '0';

                for idx in 0 to (NB_WORDS - 2) loop

                    input_valid_i <= '1';
                    random_pattern := to_sfixed( pattern ( ( (idx * DATA_WIDTH ) )  to ( ( (idx + 1) * DATA_WIDTH ) - 1)  ) , input_data) ;
                    random_part := to_sfixed(random_pkg.randn(0.0,0.0),input_data);
                    random_signal <= random_part;
                    input_data   <= resize(random_pattern + random_part,input_data);

                    if (  idx = (NB_WORDS - 2) ) then
                        input_last_word <= '1';
                    end if;                    

                    wait for CLK_PERIOD;
                    wait until (rising_edge(clk));

                end loop;

                input_valid_i <= '0';
                input_last_word <= '0';

                if (nb_empty_cycles > 0) then
                    wait for nb_empty_cycles * CLK_PERIOD;
                    wait until (rising_edge(clk));
                end if;
            end loop;
            
            input_valid_i <= '0';
            input_last_word <= '0';

            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
            
        end procedure write_memory;
    begin
        areset <= '1';
        
        for I in 0 to 3 loop
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;
        
        areset <= '0';
        config_valid_i           <= '1';
        config_max_addr         <= std_logic_vector( to_unsigned(  4   ,config_max_addr'length)); 
        config_nb_repetitions   <= std_logic_vector( to_unsigned(  SIM_NB_REPETITIONS ,config_nb_repetitions'length)); 
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        
        config_valid_i <= '0';
        
        write_memory(x"11223340BE",SIM_NB_REPETITIONS,8);

        wait for 10*CLK_PERIOD;
        wait until (rising_edge(clk));
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        write_memory(x"BE40332211",SIM_NB_REPETITIONS,8);
        write_memory(x"1122334455",SIM_NB_REPETITIONS,4);
        
        wait;
        
    end process;

    empty_ready_i       <= '1';
    empty_data_valid_i  <= s_axis_st_tvalid_o;
    empty_data_i        <= s_axis_st_tdata;
    empty_sideband_i(0) <= s_axis_st_tlast;

    empty_cycle_inserter : entity work.sim_empty_cycle
        generic map(
            MEAN            => 3.0,
            WORD_WIDTH      => DATA_WIDTH,
            SIDEBAND_WIDTH  => SIDEBAND_WIDTH
        )
        port map(
            clock           => clk,
            areset          => areset,
            -- Input --
            ready_o         => empty_ready_o,
            data_valid_i    => empty_data_valid_i,
            data_i          => empty_data_i,
            sideband_i      => empty_sideband_i,

            -- Output --
            ready_i         => empty_ready_i,
            data_valid_o    => empty_data_valid_o,
            data_o          => empty_data_o,
            sideband_o      => empty_sideband_o
    ); 

    s_axis_st_tready_i <= empty_ready_o;
    --s_axis_st_tready_i <= '1';

end testbench;
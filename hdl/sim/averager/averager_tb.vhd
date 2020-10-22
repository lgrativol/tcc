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

entity averager_tb is
end averager_tb;

------------------
-- Architecture --
------------------
architecture testbench of averager_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                         : time      := 10 ns; -- 100 MHz
    
    constant DATA_WIDTH                         : positive  := 8;
    constant MAX_NB_POINTS                      : positive  := 64;
    constant ADDR_WIDTH                         : positive  := ceil_log2(MAX_NB_POINTS + 1);
    
    constant NB_REPETITIONS_WIDTH               : positive  := 5;
    constant WORD_FRAC_PART                     : integer   := -6;    

    constant SIM_NB_REPETITIONS                 : positive  := 4;


    -------------
    -- Signals --
    -------------

    signal clk                                  : std_logic :='0';
    signal areset                               : std_logic :='0';

    signal config_strb_i                        : std_logic := '0';
    signal config_max_addr                      : std_logic_vector( (ADDR_WIDTH  - 1 ) downto 0 ) := std_logic_vector( to_unsigned (MAX_NB_POINTS - 1 ,ADDR_WIDTH ) );
    signal config_reset_pointers                : std_logic := '0';
    signal config_nb_repetitions                : std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0 );

    -- Input interface 
    signal input_strb_i                         : std_logic := '0';
    signal input_data                           : sfixed( 1 downto WORD_FRAC_PART );
    signal input_last_word                      : std_logic := '0';

    -- Output interface
    signal output_strb                          : std_logic;
    signal output_data                          : sfixed( 1 downto WORD_FRAC_PART );
    signal output_last_word                     : std_logic;

begin

    -- clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    UUT: entity work.averager 
        generic map(
            -- Behavioral
            NB_REPETITIONS_WIDTH        => NB_REPETITIONS_WIDTH,
            WORD_FRAC_PART              => WORD_FRAC_PART,     -- WORD_INT_PART is fixed at 2 bits [-1;+1]
            MAX_NB_POINTS               => MAX_NB_POINTS    -- MAX_NB_POINTS power of 2, needed for BRAM inferece
        )
        port map (
            clock_i                     => clk,
            areset_i                    => areset,
    
            -- Config  interface
            config_strb_i               => config_strb_i,
            config_max_addr_i           => config_max_addr, -- (NB_POINTS - 1)
            config_nb_repetitions_i     => config_nb_repetitions, -- Only powers of 2 ( 2^0, 2^1, 2^2, 2^3 ....)
            config_reset_pointers_i     => config_reset_pointers,
    
            -- Input interface 
            input_strb_i                => input_strb_i,
            input_data_i                => input_data,
            input_last_word_i           => input_last_word,
    
            -- Output interface
            output_strb_o               => output_strb,
            output_data_o               => output_data,
            output_last_word_o          => output_last_word
        );

    stim_proc : process

        procedure write_memory  (   constant pattern            : in std_logic_vector; 
                                    constant nb_rep             : in positive;
                                    constant nb_empty_cycles    : in natural
                                ) is

            constant WORD_WIDTH     : positive := ( pattern'length);
            constant NB_WORDS       : positive := ( ( WORD_WIDTH + DATA_WIDTH) / DATA_WIDTH );

        begin

            input_strb_i <= '0';
            input_last_word <= '0';

            for idx_rep in 1 to nb_rep loop

                input_last_word <= '0';

                for idx in 0 to (NB_WORDS - 2) loop

                    input_strb_i <= '1';
                    input_data   <= to_sfixed( pattern ( ( (idx * DATA_WIDTH ) )  to ( ( (idx + 1) * DATA_WIDTH ) - 1)  ) , input_data) ;

                    if (  idx = (NB_WORDS - 2) ) then
                        input_last_word <= '1';
                    end if;                    

                    wait for CLK_PERIOD;
                    wait until (rising_edge(clk));

                end loop;

                input_strb_i <= '0';
                input_last_word <= '0';

                if (nb_empty_cycles > 0) then
                    wait for nb_empty_cycles * CLK_PERIOD;
                    wait until (rising_edge(clk));
                end if;
            end loop;
            
            input_strb_i <= '0';
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
        
        config_strb_i           <= '1';
        config_max_addr         <= std_logic_vector( to_unsigned(  4   ,config_max_addr'length)); 
        config_nb_repetitions   <= std_logic_vector( to_unsigned(  SIM_NB_REPETITIONS ,config_nb_repetitions'length)); 

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        
        config_strb_i <= '0';
        
        write_memory(x"1122334455",SIM_NB_REPETITIONS,8);
        
        config_reset_pointers <= '1';

        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        
        config_reset_pointers <= '0';

        write_memory(x"5544332211",SIM_NB_REPETITIONS,0);
        write_memory(x"1122334455",SIM_NB_REPETITIONS,4);

        wait;
        
    end process;

end testbench;
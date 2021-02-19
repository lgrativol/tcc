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

entity ring_fifo_tb is
end ring_fifo_tb;

------------------
-- Architecture --
------------------
architecture testbench of ring_fifo_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                         : time      := 10 ns; -- 100 MHz
    
    constant DATA_WIDTH                         : positive  := 8;
    constant RAM_DEPTH                          : positive  := 16;
    constant ADDR_WIDTH                         : positive  := ceil_log2(RAM_DEPTH + 1);


    -------------
    -- Signals --
    -------------

    signal clk                                  : std_logic :='0';
    signal areset                               : std_logic :='0';

    signal config_valid_i                       : std_logic := '0';
    signal config_max_addr                      : std_logic_vector( (ADDR_WIDTH  - 1 ) downto 0 ) := std_logic_vector( to_unsigned (RAM_DEPTH - 1 ,ADDR_WIDTH ) );
    signal config_reset_pointers                : std_logic := '0';
    signal wr_valid_i                           : std_logic := '0';
    signal wr_data                              : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal rd_en                                : std_logic := '0';
    signal rd_valid_o                           : std_logic;
    signal rd_data                              : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal empty                                : std_logic;
    signal full                                 : std_logic;

begin

    -- clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    UUT: entity work.ring_fifo
    generic map (
        DATA_WIDTH      => DATA_WIDTH,
        RAM_DEPTH       => RAM_DEPTH
    )
    port map (
        clock_i                     => clk,
        areset_i                    => areset,

        -- Config  port
        config_valid_i              => config_valid_i,
        config_max_addr_i           => config_max_addr,
        config_reset_pointers_i     => config_reset_pointers,

        -- Write port
        wr_valid_i                  => wr_valid_i,
        wr_data_i                   => wr_data,

        -- Read port
        rd_en_i                     => rd_en,
        rd_valid_o                  => rd_valid_o, 
        rd_data_o                   => rd_data, 

        -- Flags
        empty                       => empty,
        full                        => full
    );

    stim_proc : process

        procedure write_memory ( constant data : in std_logic_vector) is

            constant WORD_WIDTH     : positive := data'length;
            constant NB_WORDS       : positive := ( ( WORD_WIDTH + DATA_WIDTH) / DATA_WIDTH );

        begin

            wr_valid_i <= '0';

            for idx in 0 to (NB_WORDS - 2) loop

                wr_valid_i <= '1';
                wr_data   <= data ( ( (idx * DATA_WIDTH ) )  to ( ( (idx + 1) * DATA_WIDTH ) - 1)  );
                
                if (full = '1') then
                    rd_en <= '1';
                end if;
                
                wait for CLK_PERIOD;
                wait until (rising_edge(clk));

            end loop;
            
            wr_valid_i <= '0';
            
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
        
        config_valid_i       <= '1';
        config_max_addr     <= std_logic_vector( to_unsigned(  4   ,config_max_addr'length)); 
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        
        config_valid_i <= '0';
        
        write_memory(x"0102030405060708090A0B0C0D0E0F");

        wait;
        
    end process;

end testbench;
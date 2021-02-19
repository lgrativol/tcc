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

entity upsampler_tb is
end upsampler_tb;

------------------
-- Architecture --
------------------
architecture testbench of upsampler_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                         : time      := 10 ns; -- 100 MHz
    
    constant DATA_WIDTH                         : positive  := 8;
    constant RAM_DEPTH                          : positive  := 64;
    constant MAX_FACTOR                         : positive  := 4;
    constant MAX_FACTOR_WIDTH                   : positive  := ceil_log2(MAX_FACTOR + 1);

    constant WEIGHT_INT_PART                    : natural   := 0;
    constant WEIGHT_FRAC_PART                   : integer   := -15;
    constant WEIGHT_WIDTH                       : positive  := WEIGHT_INT_PART + 1 - WEIGHT_FRAC_PART;
    constant NB_TAPS                            : natural   := 10;
    constant FIR_WORD_INT_PART                  : natural   := 1;
    constant FIR_WORD_FRAC_PART                 : integer   := -6;
    constant FIR_WORD_WIDTH                     : natural   := FIR_WORD_INT_PART + 1 - FIR_WORD_FRAC_PART;
    constant FIR_TYPE                           : string    := "DIREC";

    type weights_tp                         is array (natural range <>) of std_logic_vector( (WEIGHT_WIDTH - 1) downto 0 );

    constant WEIGHTS_DATA                       : std_logic_vector := x"00EE" & x"042D" & x"0A71" & x"1218" &  x"177D" &  x"177D" & x"1218" & x"0A71" & x"042D" & x"00EE";
                                                            
    -------------
    -- Signals --
    -------------

    signal clk                                  : std_logic :='0';
    signal areset                               : std_logic :='0';

    -- Fifo
    signal      fifo_in_wave_valid              : std_logic :='0';
    signal      fifo_in_wave_data               : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal      fifo_in_wave_last               : std_logic;
    
    signal      fifo_rd_enable                  : std_logic;

    signal      fifo_out_wave_valid             : std_logic;
    signal      fifo_out_wave_data              : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal      fifo_out_wave_last              : std_logic;
    
    signal      fifo_empty                      : std_logic;
    signal      fifo_full                       : std_logic;

    -- Upsampler
    signal      upsampler_in_wave_valid         : std_logic;
    signal      upsampler_in_wave_data          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal      upsampler_in_wave_last          : std_logic;

    signal      upsampler_weights_valid         : std_logic_vector((NB_TAPS - 1) downto 0);
    signal      upsampler_weights_data          : std_logic_vector( ((NB_TAPS * WEIGHT_WIDTH) - 1) downto 0);

    signal      upsampler_factor_valid          : std_logic;
    signal      upsampler_factor                : std_logic_vector(MAX_FACTOR_WIDTH - 1 downto 0);
    
    signal      upsampler_out_wave_valid        : std_logic;
    signal      upsampler_out_wave_data         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal      upsampler_out_wave_last         : std_logic;

begin
    
    -- clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    UUT_FIFO : entity work.wave_fifo
    generic map(
        DATA_WIDTH              => DATA_WIDTH,
        RAM_DEPTH               => RAM_DEPTH
    )
    port map(
        clock_i                 => clk,
        areset_i                => areset,

        -- Write port
        wave_valid_i            => fifo_in_wave_valid,
        wave_data_i             => fifo_in_wave_data,
        wave_last_i             => fifo_in_wave_last,

        -- Read port
        wave_rd_enable_i        => fifo_rd_enable,
        wave_valid_o            => fifo_out_wave_valid,
        wave_data_o             => fifo_out_wave_data,
        wave_last_o             => fifo_out_wave_last,

        -- Flags
        empty_o                 => fifo_empty,
        full_o                  => fifo_full
    );

    upsampler_in_wave_valid <= fifo_out_wave_valid;
    upsampler_in_wave_data  <= fifo_out_wave_data;
    upsampler_in_wave_last  <= fifo_out_wave_last;

    UTT_UPSAMPLER: entity work.upsampler
    generic map(
        FIR_TYPE                => FIR_TYPE,
        WEIGHT_WIDTH            => WEIGHT_WIDTH,
        NB_TAPS                 => NB_TAPS,
        FIR_WIDTH               => FIR_WORD_WIDTH,
        MAX_FACTOR              => MAX_FACTOR,
        DATA_WIDTH              => DATA_WIDTH
    )
    port map(
        clock_i                 => clk,
        areset_i                => areset,

        -- Insertion config
        upsample_factor_valid_i => upsampler_factor_valid,
        upsample_factor_i       => upsampler_factor,

        -- Weights
        weights_valid_i         => upsampler_weights_valid,
        weights_data_i          => upsampler_weights_data,

        -- Wave in
        wave_enable_o           => fifo_rd_enable,
        wave_valid_i            => upsampler_in_wave_valid,
        wave_data_i             => upsampler_in_wave_data,
        wave_last_i             => upsampler_in_wave_last,

        -- Wave Out
        wave_valid_o            => upsampler_out_wave_valid,
        wave_data_o             => upsampler_out_wave_data ,
        wave_last_o             => upsampler_out_wave_last 
    );


    stim_proc : process

        procedure write_memory ( constant data : in std_logic_vector) is

            constant WORD_WIDTH     : positive := data'length;
            constant NB_WORDS       : positive := ( ( WORD_WIDTH + DATA_WIDTH) / DATA_WIDTH );

        begin

            fifo_in_wave_valid <= '0';
            fifo_in_wave_last  <= '0';

            for idx in 0 to (NB_WORDS - 2) loop

                fifo_in_wave_last   <= '0';
                fifo_in_wave_valid  <= '1';
                fifo_in_wave_data   <= data ( ( (idx * DATA_WIDTH ) )  to ( ( (idx + 1) * DATA_WIDTH ) - 1)  );
                
                if (idx = (NB_WORDS - 2)) then
                    fifo_in_wave_last <= '1';
                end if;
                
                wait for CLK_PERIOD;
                wait until (rising_edge(clk));

            end loop;
            
            fifo_in_wave_valid <= '0';
            fifo_in_wave_last  <= '0';
            
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
        
        upsampler_factor_valid          <= '1';
        upsampler_weights_valid         <= (others => '1');
        --upsampler_weights_data          <= WEIGHTS_DATA;
        upsampler_weights_data          <= (others =>'0');
        upsampler_factor                <= std_logic_vector( to_unsigned(  8  ,upsampler_factor'length)); 
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        
        upsampler_factor_valid      <= '0';
        
        write_memory(x"0102030405060708090A0B0C0D0E0F");

        wait until upsampler_out_wave_last = '1';
        wait until (rising_edge(clk));
        --write_memory(x"0102030405060708090A0B0C0D0E0F");

        wait;
        
    end process;

end testbench;
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

entity downsampler_tb is
end downsampler_tb;

------------------
-- Architecture --
------------------
architecture testbench of downsampler_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                         : time      := 10 ns; -- 100 MHz
    
    constant DATA_WIDTH                         : positive  := 8;
    constant RAM_DEPTH                          : positive  := 64;
    constant MAX_FACTOR                         : positive  := 4;
    constant MAX_FACTOR_WIDTH                   : positive  := ceil_log2(MAX_FACTOR + 1);

    constant WEIGHT_INT_PART                    : natural   := 1;
    constant WEIGHT_FRAC_PART                   : integer   := -6;
    constant WEIGHT_WIDTH                       : positive  := WEIGHT_INT_PART + 1 - WEIGHT_FRAC_PART;
    constant NB_TAPS                            : natural   := 2;
    constant FIR_WORD_INT_PART                  : natural   := 1;
    constant FIR_WORD_FRAC_PART                 : integer   := -6;
    constant FIR_WORD_WIDTH                     : natural   := FIR_WORD_INT_PART + 1 - FIR_WORD_FRAC_PART;
    constant FIR_TYPE                           : string    := "TRANS"; -- DIREC

    -------------
    -- Signals --
    -------------

    signal clk                                    : std_logic :='0';
    signal areset                                 : std_logic :='0';


    -- Upsampler
    signal      downsampler_in_wave_valid         : std_logic :='0';
    signal      downsampler_in_wave_data          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal      downsampler_in_wave_last          : std_logic;

    signal      downsampler_weights_valid         : std_logic_vector((NB_TAPS - 1) downto 0);
    signal      downsampler_weights_data          : std_logic_vector( ((NB_TAPS * WEIGHT_WIDTH) - 1) downto 0);

    signal      downsampler_factor_valid          : std_logic;
    signal      downsampler_factor                : std_logic_vector(MAX_FACTOR_WIDTH - 1 downto 0);
    
    signal      downsampler_out_wave_valid        : std_logic;
    signal      downsampler_out_wave_data         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal      downsampler_out_wave_last         : std_logic;

begin
    
    -- clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    UTT_DOWNSAMPLER: entity work.downsampler
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
        downsample_factor_valid_i => downsampler_factor_valid,
        downsample_factor_i       => downsampler_factor,

        -- Weights
        weights_valid_i         => downsampler_weights_valid,
        weights_data_i          => downsampler_weights_data,

        -- Wave in
        wave_valid_i            => downsampler_in_wave_valid,
        wave_data_i             => downsampler_in_wave_data,
        wave_last_i             => downsampler_in_wave_last,

        -- Wave Out
        wave_valid_o            => downsampler_out_wave_valid,
        wave_data_o             => downsampler_out_wave_data ,
        wave_last_o             => downsampler_out_wave_last 
    );


    stim_proc : process

        procedure write_memory ( constant data : in std_logic_vector) is

            constant WORD_WIDTH     : positive := data'length;
            constant NB_WORDS       : positive := ( ( WORD_WIDTH + DATA_WIDTH) / DATA_WIDTH );

        begin

            downsampler_in_wave_valid <= '0';
            downsampler_in_wave_last  <= '0';

            for idx in 0 to (NB_WORDS - 2) loop

                downsampler_in_wave_last   <= '0';
                downsampler_in_wave_valid  <= '1';
                downsampler_in_wave_data   <= data ( ( (idx * DATA_WIDTH ) )  to ( ( (idx + 1) * DATA_WIDTH ) - 1)  );
                
                if (idx = (NB_WORDS - 2)) then
                    downsampler_in_wave_last <= '1';
                end if;
                
                wait for CLK_PERIOD;
                wait until (rising_edge(clk));

            end loop;
            
            downsampler_in_wave_valid <= '0';
            downsampler_in_wave_last  <= '0';
            
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
        
        downsampler_factor_valid          <= '1';
        downsampler_weights_valid         <= (others => '1');
        downsampler_weights_data          <= (others => '0');
        downsampler_factor                <= std_logic_vector( to_unsigned(  4 ,downsampler_factor'length)); 
        
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        wait for CLK_PERIOD;
        wait until (rising_edge(clk));
        
        downsampler_factor_valid      <= '0';
        downsampler_weights_valid     <= (others => '0');
        
        write_memory(x"0102030405060708090A0B0C0D0E0F");

      --  write_memory(x"0102030405060708090A0B0C0D0E0F");

        wait;
        
    end process;

end testbench;
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

entity top_rx is
    generic(
        OUTPUT_WIDTH                        : positive                      := 10
    );
    port(

        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Wave
        wave_valid_i                        : in  std_logic;
        wave_data_i                         : in  std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
        wave_done_i                         : in  std_logic;

        -- Control
        control_sample_frequency_valid_i    : in  std_logic;
        control_sample_frequency_i          : in  std_logic_vector(26 downto 0); --TBD

        control_enable_rx_i                 : in  std_logic;
        control_reset_averager_i            : in  std_logic;
        control_config_valid_i              : in  std_logic;
        control_nb_points_wave_i            : in  std_logic_vector(31 downto 0); -- TBD
        control_nb_repetitions_wave_i       : in  std_logic_vector(5 downto 0);  -- TBD

        ----------------------------------
        -- Output  AXI Stream Interface --
        ----------------------------------
        sending_o                           : out std_logic;
        s_axis_st_tready_i                  : in  std_logic;
        s_axis_st_tvalid_o                  : out std_logic;
        s_axis_st_tdata_o                   : out std_logic_vector ((OUTPUT_WIDTH - 1) downto 0);
        s_axis_st_tlast_o                   : out std_logic
    );
end top_rx;

------------------
-- Architecture --
------------------
architecture behavioral of top_rx is


    ---------------
    -- Constants --
    ---------------

    constant AVG_NB_REPETITIONS_WIDTH       : positive := 6; -- TBD
    constant AVG_WORD_FRAC_PART             : integer  := CORDIC_FRAC_PART;
    constant AVG_MAX_NB_POINTS              : positive := 1024;
    constant ADDR_WIDTH                     : positive := ceil_log2(AVG_MAX_NB_POINTS + 1);

    -------------
    -- Signals --
    -------------

    -- Avg
    signal avg_output_ready                 : std_logic;
    signal avg_config_valid_i               : std_logic;
    signal avg_config_max_addr              : std_logic_vector( (ADDR_WIDTH  - 1 ) downto 0 );
    signal avg_config_reset_pointers        : std_logic;
    signal avg_config_nb_repetitions        : std_logic_vector( (AVG_NB_REPETITIONS_WIDTH - 1) downto 0 ); --TBD

    signal avg_input_valid                  : std_logic;
    signal avg_input_data                   : sfixed( 1 downto AVG_WORD_FRAC_PART );

    signal avg_input_last_word              : std_logic;
    signal avg_output_sending               : std_logic;
    signal avg_output_valid                 : std_logic;
    signal avg_output_data                  : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal avg_output_last_word             : std_logic;

begin

    --------------
    -- Averager --
    --------------

    avg_output_ready            <= s_axis_st_tready_i;

    avg_config_valid_i          <= control_config_valid_i;
    avg_config_max_addr         <= std_logic_vector(   resize( unsigned(control_nb_points_wave_i) - 1, ADDR_WIDTH) )  ;
    avg_config_reset_pointers   <= control_reset_averager_i;
    avg_config_nb_repetitions   <= control_nb_repetitions_wave_i;

    avg_input_valid             <=          wave_valid_i
                                        and control_enable_rx_i;

    avg_input_data              <= to_sfixed (wave_data_i,avg_input_data);
    avg_input_last_word         <= wave_done_i;

    averager: entity work.averager_v2 
        generic map(
            -- Behavioral
            NB_REPETITIONS_WIDTH        => AVG_NB_REPETITIONS_WIDTH,
            WORD_FRAC_PART              => AVG_WORD_FRAC_PART,     -- WORD_INT_PART is fixed at 2 bits [-1;+1]
            MAX_NB_POINTS               => AVG_MAX_NB_POINTS    -- MAX_NB_POINTS power of 2, needed for BRAM inferece
        )
        port map (
            clock_i                     => clock_i,
            areset_i                    => areset_i,
    
            -- Config  interface
            config_valid_i              => avg_config_valid_i,
            config_max_addr_i           => avg_config_max_addr, -- (NB_POINTS - 1)
            config_nb_repetitions_i     => avg_config_nb_repetitions, -- Only powers of 2 ( 2^0, 2^1, 2^2, 2^3 ....)
            config_reset_pointers_i     => avg_config_reset_pointers,
    
            -- Input interface 
            input_valid_i               => avg_input_valid,
            input_data_i                => avg_input_data,
            input_last_word_i           => avg_input_last_word,

            ----------------------------------
            -- Output  AXI Stream Interface --
            ----------------------------------
            sending_o                   => avg_output_sending,           
            s_axis_st_tready_i          => avg_output_ready,
            s_axis_st_tvalid_o          => avg_output_valid,
            s_axis_st_tdata_o           => avg_output_data,
            s_axis_st_tlast_o           => avg_output_last_word
        );

    -- Output
    sending_o                   <= avg_output_sending;
    s_axis_st_tvalid_o          <= avg_output_valid;
    s_axis_st_tdata_o           <= avg_output_data;
    s_axis_st_tlast_o           <= avg_output_last_word;

end behavioral;
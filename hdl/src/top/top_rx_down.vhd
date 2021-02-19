---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Dezembro/2020                                                                
-- Module Name: top_rx_down
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date: 15/01/2021
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Implementar a estrutura top de recepçao (exemplo de implementação)
--          
-- Description: Instancia o averager_v2 e downsampler.
---------------------------------------------------------------------------------------------

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
use work.defs_pkg.all;

------------
-- Entity --
------------

entity top_rx_down is
    port(

        -- Clock interface
        clock_i                             : in  std_logic; -- Clock
        areset_i                            : in  std_logic; -- Positive async reset

        -- Wave
        wave_valid_i                        : in  std_logic; -- Indica que os outros sinais da interface são válidos nesse ciclo de clock
        wave_data_i                         : in  std_logic_vector( (OUTPUT_WIDTH - 1) downto 0); -- Amostra do sinal
        wave_done_i                         : in  std_logic; -- Indica que é a última amostra do sinal

        -- Control
        control_enable_rx_i                 : in  std_logic; -- Indica que a recepção é válida
        control_config_valid_i              : in  std_logic; -- India que as informações de configuração são válida nesse ciclo de clock
        control_nb_points_wave_i            : in  std_logic_vector((WAVE_NB_POINTS_WIDTH - 1) downto 0); -- Número de pontos totais do sinal
        control_nb_repetitions_wave_i       : in  std_logic_vector((NB_SHOTS_WIDTH - 1) downto 0);  -- Número de shots do sinal (para cálculo da média)
        
        -- Downsampler
        downsampler_factor_valid_i          : in  std_logic; -- Indica que o fator de downsampling é válido nesse ciclo de clock
        downsampler_factor_i                : in  std_logic_vector((DOWN_MAX_FACTOR_WIDTH - 1) downto 0);  -- Fator de downsampling 
        downsampler_weights_valid_i         : in  std_logic_vector((NB_TAPS - 1) downto 0); -- Indica que os pesos são válidos nesse ciclo de clock
        downsampler_weights_data_i          : in  std_logic_vector(((NB_TAPS * WEIGHT_WIDTH) - 1) downto 0);  -- Vetor com todos os pesos

        ----------------------------------
        -- Output  AXI Stream Interface --
        ----------------------------------
        sending_o                           : out std_logic; -- Indica que a operação de envio para o host está acontecendo 
        s_axis_st_tready_i                  : in  std_logic;
        s_axis_st_tvalid_o                  : out std_logic;
        s_axis_st_tdata_o                   : out std_logic_vector ((OUTPUT_WIDTH - 1) downto 0);
        s_axis_st_tlast_o                   : out std_logic
    );
end top_rx_down;

------------------
-- Architecture --
------------------
architecture rtl of top_rx_down is


    ---------------
    -- Constants --
    ---------------
    
    -- Downsampler
    constant MAX_FACTOR_WIDTH               : positive  := downsampler_factor_i'length;
    constant WEIGHT_INT_PART                : natural   := 1;
    constant WEIGHT_FRAC_PART               : integer   := -(OUTPUT_WIDTH - WEIGHT_INT_PART - 1);
    constant FIR_WORD_INT_PART              : natural   := 1;
    constant FIR_WORD_FRAC_PART             : integer   := -(OUTPUT_WIDTH - FIR_WORD_INT_PART - 1);
    constant FIR_WIDTH                      : integer   := OUTPUT_WIDTH;
    constant FIR_TYPE                       : string    := DOWN_FIR_TYPE; 
    
    -- Avg
    constant AVG_NB_REPETITIONS_WIDTH       : positive := NB_SHOTS_WIDTH;
    constant AVG_WORD_FRAC_PART             : integer  := FIR_WORD_FRAC_PART;
    constant ADDR_WIDTH                     : positive := ceil_log2(AVG_MAX_NB_POINTS + 1);

    -------------
    -- Signals --
    -------------

    -- Downsampler
    signal downsampler_in_wave_valid        : std_logic;
    signal downsampler_in_wave_data         : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal downsampler_in_wave_last         : std_logic;

    signal downsampler_weights_valid        : std_logic_vector((NB_TAPS - 1) downto 0);
    signal downsampler_weights_data         : std_logic_vector( ((NB_TAPS * WEIGHT_WIDTH) - 1) downto 0);

    signal downsampler_factor_valid         : std_logic;
    signal downsampler_factor               : std_logic_vector(MAX_FACTOR_WIDTH - 1 downto 0);
    
    signal downsampler_out_wave_valid       : std_logic;
    signal downsampler_out_wave_data        : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal downsampler_out_wave_last        : std_logic;

    -- Avg
    signal avg_output_ready                 : std_logic;
    signal avg_config_valid_i               : std_logic;
    signal avg_config_max_addr              : std_logic_vector( (ADDR_WIDTH  - 1 ) downto 0 );
    signal avg_config_nb_repetitions        : std_logic_vector( (AVG_NB_REPETITIONS_WIDTH - 1) downto 0 );

    signal avg_input_valid                  : std_logic;
    signal avg_input_data                   : sfixed( 1 downto AVG_WORD_FRAC_PART );

    signal avg_input_last_word              : std_logic;
    signal avg_output_sending               : std_logic;
    signal avg_output_valid                 : std_logic;
    signal avg_output_data                  : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal avg_output_last_word             : std_logic;

begin

    -----------------
    -- Downsampler --
    -----------------

    downsampler_factor_valid       <= downsampler_factor_valid_i;
    downsampler_factor             <= downsampler_factor_i;

    downsampler_weights_valid      <= downsampler_weights_valid_i;
    downsampler_weights_data       <= downsampler_weights_data_i;
    
    downsampler_in_wave_valid      <=           wave_valid_i
                                        and control_enable_rx_i;    
    
    downsampler_in_wave_data       <= wave_data_i;
    downsampler_in_wave_last       <= wave_done_i;

    downsampler_inst : entity work.downsampler
        generic map(
            FIR_TYPE                => FIR_TYPE,
            WEIGHT_WIDTH            => WEIGHT_WIDTH,
            NB_TAPS                 => NB_TAPS,
            FIR_WIDTH               => FIR_WIDTH,
            MAX_FACTOR              => DOWN_MAX_FACTOR,
            DATA_WIDTH              => OUTPUT_WIDTH
        )
        port map(
            clock_i                 => clock_i,
            areset_i                => areset_i,

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
            wave_data_o             => downsampler_out_wave_data,
            wave_last_o             => downsampler_out_wave_last
        );   


    --------------
    -- Averager --
    --------------

    avg_output_ready            <= s_axis_st_tready_i;

    avg_config_valid_i          <= control_config_valid_i;
    avg_config_max_addr         <= control_nb_points_wave_i;
    avg_config_nb_repetitions   <= control_nb_repetitions_wave_i;

    avg_input_valid             <= downsampler_out_wave_valid;

    avg_input_data              <= to_sfixed (downsampler_out_wave_data,avg_input_data);
    avg_input_last_word         <= downsampler_out_wave_last;

    averager: entity work.averager_v2 
        generic map(
            -- Behavioral
            NB_REPETITIONS_WIDTH        => AVG_NB_REPETITIONS_WIDTH,
            WORD_FRAC_PART              => AVG_WORD_FRAC_PART,     
            MAX_NB_POINTS               => AVG_MAX_NB_POINTS    
        )
        port map (
            clock_i                     => clock_i,
            areset_i                    => areset_i,
    
            -- Config  interface
            config_valid_i              => avg_config_valid_i,
            config_max_addr_i           => avg_config_max_addr, 
            config_nb_repetitions_i     => avg_config_nb_repetitions, 
    
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

end rtl;
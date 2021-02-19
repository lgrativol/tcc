---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Dezembro/2020                                                                
-- Module Name: top_rx
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date: 15/01/2021
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Implementar a estrutura top de recepçao (exemplo de implementação)
--          
-- Description: Instancia o averager_v2 
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

entity top_rx is
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
        control_nb_points_wave_i            : in  std_logic_vector((WAVE_NB_POINTS_WIDTH - 1) downto 0); -- Número de pontos em um período do sinal gerado
        control_nb_repetitions_wave_i       : in  std_logic_vector((NB_SHOTS_WIDTH - 1) downto 0);  -- Número de shots do sinal (para cálculo da média)

        ----------------------------------
        -- Output  AXI Stream Interface --
        ----------------------------------
        sending_o                           : out std_logic; -- Indica que a operação de envio para o host está acontecendo 
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

    constant AVG_NB_REPETITIONS_WIDTH       : positive := control_nb_repetitions_wave_i'length; 
    constant AVG_WORD_FRAC_PART             : integer  := -(OUTPUT_WIDTH - 2);
    constant ADDR_WIDTH                     : positive := ceil_log2(AVG_MAX_NB_POINTS + 1);

    -------------
    -- Signals --
    -------------

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

    --------------
    -- Averager --
    --------------

    avg_output_ready            <= s_axis_st_tready_i;

    avg_config_valid_i          <= control_config_valid_i;
    avg_config_max_addr         <= std_logic_vector(   resize( unsigned(control_nb_points_wave_i) - 1, ADDR_WIDTH) )  ;
    avg_config_nb_repetitions   <= control_nb_repetitions_wave_i;

    avg_input_valid             <=          wave_valid_i
                                        and control_enable_rx_i;

    avg_input_data              <= to_sfixed (wave_data_i,avg_input_data);
    avg_input_last_word         <= wave_done_i;

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

end behavioral;
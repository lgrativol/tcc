---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Dezembro/2020                                                                         
-- Module Name: fifo_upsampler                                                                           
-- Author Name: Lucas Grativol Ribeiro                          
--                                                                                         
-- Revision Date: 09/01/2021                                                                         
-- Tool version: Vivado 2017.4                                                                           
--                                                                      
-- Goal: Instanciar uma FIFO e um upsampler juntos para completar a utilização do 
--       bloco de upsampling     
--
-- Description: Como o bloco de upsampling insere amostras no sinal, é 
--              necessário interromper a informação entrando no upsampler,
--              como na atual versão do projeto, o pipeline não possui
--              mecanismos de interrupeção da produção de amostras
--              é necessária a utilização de uma FIFO para evitar
--              perda de amostras.
--              Os pesos do FIR podem ser modificado livremente, 
--              usando a interface "weights_..."
--
--              Obs.: O filtro foi projeto para pesos entre [-1;+1]
--              Obs.2: Existem duas arquiteturas de FIR, direct (DIREC) e transpose 
--              (TRANS). Cada uma com as suas vantagens.  
--              Obs.3: Na versão 2017.4, até onde eu entendo, para a inferência de BRAMs
--                     a profundidade da RAM deve ser potência de 2.
--                     Em versões mais recentes do vivado, é possível que essa condição seja 
--                     mais flexível.
--
---------------------------------------------------------------------------------------------

-------------
-- Library --
-------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee_proposed;                    
use ieee_proposed.fixed_float_types.all;  
use ieee_proposed.fixed_pkg.all;     
 
library work;
use work.utils_pkg;

------------
-- Entity --
------------

entity fifo_upsampler is
    generic (
        FIR_TYPE                : string;  -- Arquitetura dos filtros "DIREC" ou "TRANS"
        WEIGHT_WIDTH            : natural; -- Tamanho da palavra em bits que representa os pesos do FIR
                                           -- como os pesos são definidos entre [-1;+1], a parte fracionária
                                           -- é definida como WEIGHT_WIDTH - 2
        NB_TAPS                 : positive; -- Número de TAPS do filtro
        FIR_WIDTH               : natural; -- Tamanho da palavra em bits que representa a palavra entrando no
                                           -- FIR. É considerado aqui que a entrada sempre está entre [-1;+1]
        MAX_FACTOR              : natural; -- Fator máximo de upsampling
        DATA_WIDTH              : natural; -- Tamanho da palavra de saída.
        RAM_DEPTH               : natural  -- Profundidade da RAM, potência de 2
    );
    port (
        clock_i                 : in std_logic; -- Clock
        areset_i                : in std_logic; -- Positive async reset

        -- Insertion config
        upsample_factor_valid_i : in std_logic; -- Indica que o fator de upsampling é válido nesse ciclo de clock
        upsample_factor_i       : in std_logic_vector((utils_pkg.ceil_log2(MAX_FACTOR + 1) - 1) downto 0); -- Fator de upsampling

        -- Weights
        weights_valid_i         : in std_logic_vector((NB_TAPS - 1) downto 0); -- Indica que os pesos são válidos nesse ciclo de clock
        weights_data_i          : in std_logic_vector(((NB_TAPS * WEIGHT_WIDTH) - 1) downto  0); -- Vetor com todos os pesos

        -- Wave in
        wave_valid_i            : in  std_logic; -- Indica que os outros sinais da interface são válidos nesse ciclo de clock
        wave_data_i             : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Amostra do sinal
        wave_last_i             : in  std_logic; -- Indica que é a última amostra do sinal

        -- Wave Out
        wave_valid_o            : out std_logic; -- Indica que os outros sinais da interface são válidos nesse ciclo de clock
        wave_data_o             : out std_logic_vector(DATA_WIDTH - 1 downto 0); -- Amostra resultante
        wave_last_o             : out std_logic; -- Indica que é a última amostra do sinal

        -- FIFO
        fifo_empty_o            : out std_logic;  -- Indica FIFO vazia no ciclo de clock atual         
        fifo_full_o             : out std_logic   -- Indica FIFO cheia no ciclo de clock atual           
    );
end fifo_upsampler;

------------------
-- Architecture --
------------------

architecture behavioral of fifo_upsampler is


    --------------
    -- Constant --
    --------------

    -- FIR
    constant    WEIGHT_INT_PART             : natural := 1; -- Fixed
    constant    WEIGHT_FRAC_PART            : integer := -(WEIGHT_WIDTH - (WEIGHT_INT_PART + 1));  

    constant    FIR_WORD_INT_PART           : natural := 1; -- Fixed
    constant    FIR_WORD_FRAC_PART          : integer := -(FIR_WIDTH - (FIR_WORD_INT_PART + 1));
    constant    MAX_FACTOR_WIDTH            : positive := utils_pkg.ceil_log2(MAX_FACTOR + 1);

   
    ------------
    -- Signal --
    ------------

    -- Fifo
    signal      fifo_in_wave_valid              : std_logic;
    signal      fifo_in_wave_data               : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal      fifo_in_wave_last               : std_logic;
    
    signal      fifo_rd_enable                  : std_logic;

    signal      fifo_out_wave_valid             : std_logic;
    signal      fifo_out_wave_data              : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal      fifo_out_wave_last              : std_logic;
    
    signal      fifo_empty                      : std_logic;
    signal      fifo_full                       : std_logic;

    -- Upsampler
    signal      upsampler_in_wave_enable        : std_logic;
    
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

    ----------
    -- FIFO --
    ----------

    fifo_in_wave_valid      <= wave_valid_i;
    fifo_in_wave_data       <= wave_data_i;
    fifo_in_wave_last       <= wave_last_i;

    fifo_rd_enable          <= upsampler_in_wave_enable;

    fifo_inst : entity work.wave_fifo
    generic map(
        DATA_WIDTH              => DATA_WIDTH,
        RAM_DEPTH               => RAM_DEPTH
    )
    port map(
        clock_i                 => clock_i,
        areset_i                => areset_i,

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

    ---------------
    -- Upsampler --
    ---------------

    upsampler_factor_valid      <= upsample_factor_valid_i;
    upsampler_factor            <= upsample_factor_i;

    upsampler_weights_valid     <= weights_valid_i;
    upsampler_weights_data      <= weights_data_i;

    upsampler_in_wave_valid     <= fifo_out_wave_valid;
    upsampler_in_wave_data      <= fifo_out_wave_data;
    upsampler_in_wave_last      <= fifo_out_wave_last;

    upsampler_inst: entity work.upsampler
        generic map(
            FIR_TYPE                => FIR_TYPE,
            WEIGHT_WIDTH            => WEIGHT_WIDTH,
            NB_TAPS                 => NB_TAPS,
            FIR_WIDTH               => FIR_WIDTH,
            MAX_FACTOR              => MAX_FACTOR,
            DATA_WIDTH              => DATA_WIDTH
        )
        port map(
            clock_i                 => clock_i,
            areset_i                => areset_i,

            -- Insertion config
            upsample_factor_valid_i => upsampler_factor_valid,
            upsample_factor_i       => upsampler_factor,

            -- Weights
            weights_valid_i         => upsampler_weights_valid,
            weights_data_i          => upsampler_weights_data,

            -- Wave in
            wave_enable_o           => upsampler_in_wave_enable,
            wave_valid_i            => upsampler_in_wave_valid,
            wave_data_i             => upsampler_in_wave_data,
            wave_last_i             => upsampler_in_wave_last,

            -- Wave Out
            wave_valid_o            => upsampler_out_wave_valid,
            wave_data_o             => upsampler_out_wave_data,
            wave_last_o             => upsampler_out_wave_last 
        );

    ------------
    -- Output --
    ------------

    -- Wave Out
    wave_valid_o            <= upsampler_out_wave_valid;
    wave_data_o             <= upsampler_out_wave_data;
    wave_last_o             <= upsampler_out_wave_last;

    -- FIFO
    fifo_empty_o            <= fifo_empty;
    fifo_full_o             <= fifo_full;

end architecture;
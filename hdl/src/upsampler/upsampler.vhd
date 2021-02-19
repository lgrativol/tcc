---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Dezembro/2020                                                                         
-- Module Name: upsampler                                                                           
-- Author Name: Lucas Grativol Ribeiro                          
--                                                                                         
-- Revision Date: 09/01/2021                                                                         
-- Tool version: Vivado 2017.4                                                                           
--                                                                      
-- Goal: Apesar do nome, o bloco implementa a operação conhecida como interpolação(upsampling) 
--       (https://en.wikipedia.org/wiki/Upsampling)     
--
-- Description: O bloco implementa o filtro de interpolação. Implementando primeiro
--              uma operação de padding, completando o sinal com upsample_factor_i-1 zeros,
--              em seguida, um FIR é aplicado.
--              Por exemplo, ao aumentar a frequência de amostragem de N vezes
--              Só N-1 amostras serão inseridas, padded.
--              Os pesos do FIR podem ser modificado livremente, 
--              usando a interface "weights_..."
--
--              Obs.: O filtro foi projeto para pesos entre [-1;+1]
--              Obs.2: Existem duas arquiteturas de FIR, direct (DIREC) e transpose 
--              (TRANS). Cada uma com as suas vantagens.  
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

entity upsampler is
    generic (
        FIR_TYPE                : string;  -- Arquitetura dos filtros "DIREC" ou "TRANS"
        WEIGHT_WIDTH            : natural; -- Tamanho da palavra em bits que representa os pesos do FIR
                                           -- como os pesos são definidos entre [-1;+1], a parte fracionária
                                           -- é definida como WEIGHT_WIDTH - 2
        NB_TAPS                 : positive; -- Número de TAPS do filtro
        FIR_WIDTH               : natural; -- Tamanho da palavra em bits que representa a palavra entrando no
                                           -- FIR. É considerado aqui que a entrada sempre está entre [-1;+1]
        MAX_FACTOR              : natural; -- Fator máximo de upsampling
        DATA_WIDTH              : natural -- Tamanho da palavra de saída.
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
        wave_enable_o           : out std_logic; -- Indica que o bloco pode aceitar amostras no ciclo de clock seguinte
        wave_valid_i            : in  std_logic; -- Indica que os outros sinais da interface são válidos nesse ciclo de clock
        wave_data_i             : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Amostra do sinal
        wave_last_i             : in  std_logic; -- Indica que é a última amostra do sinal

        -- Wave Out
        wave_valid_o            : out std_logic; -- Indica que os outros sinais da interface são válidos nesse ciclo de clock
        wave_data_o             : out std_logic_vector(DATA_WIDTH - 1 downto 0); -- Amostra resultante
        wave_last_o             : out std_logic -- Indica que é a última amostra do sinal
    );
end upsampler;

------------------
-- Architecture --
------------------

architecture behavioral of upsampler is


    --------------
    -- Constant --
    --------------
    
    -- FIR
    constant    WEIGHT_INT_PART             : natural := 1; -- Fixed
    constant    WEIGHT_FRAC_PART            : integer:= -(WEIGHT_WIDTH - (WEIGHT_INT_PART + 1));  

    constant    FIR_WORD_INT_PART           : natural:= 1; -- Fixed
    constant    FIR_WORD_FRAC_PART          : integer:= -(FIR_WIDTH - (FIR_WORD_INT_PART + 1));

    -- Upsampler
    constant    UPSAMPLE_FACTOR_WIDTH       : positive                                       := upsample_factor_i'length;
    constant    COUNTER_ZERO                : unsigned((UPSAMPLE_FACTOR_WIDTH - 1) downto 0) := (others => '0');
    constant    FIR_SIDEBAND_WIDTH          : natural                                        := 1;
    
   
    ------------
    -- Signal --
    ------------

    -- Upsampler Factor
    signal      upsample_factor         : unsigned((UPSAMPLE_FACTOR_WIDTH - 1) downto 0);


    -- Wave register
    signal      wave_valid_reg          : std_logic;
    signal      wave_data_reg           : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal      wave_last               : std_logic;
    signal      wave_last_reg           : std_logic;

    signal      valid_sample            : std_logic;
    signal      sfixed_wave_data        : sfixed(FIR_WORD_INT_PART downto FIR_WORD_FRAC_PART);

    -- Counter

    signal      counter_samples         : unsigned((UPSAMPLE_FACTOR_WIDTH - 1) downto 0);
    signal      counter_samples_zero    : std_logic;
    signal      reset_counter           : std_logic;
    signal      counter_samples_done    : std_logic;
    signal      wave_enable             : std_logic;

    --FIR

    signal      fir_weights_valid       : std_logic_vector((NB_TAPS - 1) downto 0);
    signal      fir_weights_data        : std_logic_vector( ((NB_TAPS *(WEIGHT_INT_PART + 1 - WEIGHT_FRAC_PART)) - 1) downto  0); 

    signal      fir_in_valid            : std_logic;
    signal      fir_in_data             : sfixed(FIR_WORD_INT_PART downto FIR_WORD_FRAC_PART);
    signal      fir_in_sideband         : std_logic_vector((FIR_SIDEBAND_WIDTH - 1) downto 0);
    
    signal      fir_out_valid           : std_logic;
    signal      fir_out_data            : sfixed(FIR_WORD_INT_PART downto FIR_WORD_FRAC_PART);
    signal      fir_out_sideband        : std_logic_vector((FIR_SIDEBAND_WIDTH - 1) downto 0);
    

begin

    ------------------------------------------------------------------
    --                    Upsample factor register                           
    --                                                                
    --   Goal: Registrar o valor do fator de upsampling
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: upsample_factor_valid_i;
    --          upsample_factor_i;
    --
    --   Output: upsample_factor;
    --
    --   Result: unsigned(upsample_factor_valid_i) registrado
    ------------------------------------------------------------------
    factor_register_proc : process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            upsample_factor <= to_unsigned(1,upsample_factor'length);
        elsif(rising_edge(clock_i)) then
            if(upsample_factor_valid_i = '1') then
                upsample_factor <= unsigned(upsample_factor_i);
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    --                    Insert Sample                           
    --                                                                
    --   Goal: Acrescentar N-1 amostras 
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: valid_sample;
    --          counter_samples_zero;
    --          wave_data_i;
    --          wave_last_i;
    --          counter_samples_done;
    --          wave_last;
    --
    --   Output: wave_valid_reg;
    --           wave_last_reg;
    --           wave_data_reg;
    --
    --   Result: Acrescentar zeros (padding) no sinal
    --           obs.: perceba que isso interrompe o sinal
    --                 para tanto existe o sinal "wave_enable"
    --                 para garantir que nenhuma amostras é perdida
    ------------------------------------------------------------------
    insert_sample : process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            wave_valid_reg  <= '0';
            wave_last_reg   <= '0';
            wave_last       <= '0';
        elsif(rising_edge(clock_i)) then
            wave_valid_reg      <= valid_sample;

            if(valid_sample = '1') then

                if (counter_samples_zero =  '1') then
                    wave_data_reg   <= wave_data_i;
                    wave_last       <= wave_last_i;
                else
                    wave_data_reg   <= (others => '0');
                    wave_last_reg   <= wave_last and counter_samples_done;
                end if;
                
            end if;
        end if;
    end process;

    -- As amostras devem ser inseridas se existe uma amostra válida 
    -- na interface de entrada (input), ou se ainda é preciso
    -- inserir zeros (fim do sinal)
    valid_sample            <=                  wave_valid_i
                                            or  (       wave_valid_reg
                                                    and not(wave_last_reg) );

    ------------------------------------------------------------------
    --                    Contador de amostras                           
    --                                                                
    --   Goal: Contar as amostras inseridas
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: valid_sample;
    --          counter_samples_done;
    --          counter_samples;
    --          reset_counter;
    --
    --   Output: counter_samples;
    --
    --   Result: counter_samples + 1
    ------------------------------------------------------------------
    counter_samples_proc : process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            counter_samples <= (others => '0');
        elsif(rising_edge(clock_i)) then
            if(valid_sample = '1') then
                if(counter_samples_done = '1')then
                    counter_samples <= (others => '0');
                else
                    counter_samples <= counter_samples + 1;
                end if;
            end if;

            if(reset_counter = '1') then
                counter_samples <= (others => '0');
            end if;
        end if;
    end process;


    counter_samples_zero    <=              '1'         when(counter_samples = COUNTER_ZERO)
                                    else    '0';

    counter_samples_done    <=              '1'         when(counter_samples = (upsample_factor - 1))
                                    else    '0';

    reset_counter           <=              wave_last_reg;

    -- O sinal wave_enable foi idealizado para ser usado junto com uma FIFO,
    -- onde o sinal de "read_enable", da FIFO, só produz uma amostra na saída
    -- da FIFO um ciclo de clock depois (por causa da RAM instanciada dentro da
    -- FIFO). Esse sinal é diferente de um "ready" clássico que tem seu efeito
    -- no ciclo de clock atual.
    wave_enable             <=          counter_samples_zero;


    fir_weights_valid       <= weights_valid_i;
    fir_weights_data        <= weights_data_i;

    fir_in_valid            <= wave_valid_reg;
    fir_in_data             <= to_sfixed(wave_data_reg,fir_in_data);
    fir_in_sideband(0)      <= wave_last_reg;


     FIR_TRANS_SELECT_GEN: 
        if  (FIR_TYPE = "TRANS") generate
            --fir_inst : entity work.fir_direct_core
            fir_inst : entity work.fir_transpose_core
                generic map(
                    WEIGHT_INT_PART                 => WEIGHT_INT_PART,
                    WEIGHT_FRAC_PART                => WEIGHT_FRAC_PART,
                    NB_TAPS                         => NB_TAPS,
                    WORD_INT_PART                   => FIR_WORD_INT_PART,
                    WORD_FRAC_PART                  => FIR_WORD_FRAC_PART,
                    SIDEBAND_WIDTH                  => FIR_SIDEBAND_WIDTH
                )
                port map(
                    -- Clock interface
                    clock_i                         => clock_i,
                    areset_i                        => areset_i,
                    
                    -- Weights
                    weights_valid_i                 => fir_weights_valid,
                    weights_data_i                  => fir_weights_data,
                    
                    --Input
                    valid_i                         => fir_in_valid,
                    data_i                          => fir_in_data,
                    sideband_data_i                 => fir_in_sideband,
                
                    -- Ouput 
                    valid_o                         => fir_out_valid,
                    data_o                          => fir_out_data,
                    sideband_data_o                 => fir_out_sideband
                );
        end generate FIR_TRANS_SELECT_GEN;

    FIR_DIREC_SELECT_GEN: 
        if  (FIR_TYPE = "DIREC") generate
            fir_inst : entity work.fir_direct_core
                generic map(
                    WEIGHT_INT_PART                 => WEIGHT_INT_PART,
                    WEIGHT_FRAC_PART                => WEIGHT_FRAC_PART,
                    NB_TAPS                         => NB_TAPS,
                    WORD_INT_PART                   => FIR_WORD_INT_PART,
                    WORD_FRAC_PART                  => FIR_WORD_FRAC_PART,
                    SIDEBAND_WIDTH                  => FIR_SIDEBAND_WIDTH
                )
                port map(
                    -- Clock interface
                    clock_i                         => clock_i,
                    areset_i                        => areset_i,
                    
                    -- Weights
                    weights_valid_i                 => fir_weights_valid,
                    weights_data_i                  => fir_weights_data,
                    
                    --Input
                    valid_i                         => fir_in_valid,
                    data_i                          => fir_in_data,
                    sideband_data_i                 => fir_in_sideband,
                
                    -- Ouput 
                    valid_o                         => fir_out_valid,
                    data_o                          => fir_out_data,
                    sideband_data_o                 => fir_out_sideband
                );
        end generate FIR_DIREC_SELECT_GEN;

    -- Output      
    wave_enable_o           <= wave_enable;
    wave_valid_o            <= fir_out_valid;
    wave_data_o             <= to_slv(fir_out_data);
    wave_last_o             <= fir_out_sideband(0);

end architecture;
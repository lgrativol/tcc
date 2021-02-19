---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Novembro/2020                                                                
-- Module Name: averager_v2                                                                
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date: 10/01/2021                                                               
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Calcular a média de MAX_NB_POINTS pontos diferentes em NB_REPETITIONS_WIDTH
--       repetições e servir de interface AXI-STREAM                                
-- Description:  O bloco foi idealizado para calcular a médias de várias repetições
--               de um sinal. Os pontos são salvos em uma FIFO circular. Os pontos
--               são considerados [-1;+1], com o tamanho da parte fracionária configurável
--               WORD_FRAC_PART. O tamanho da FIFO é estabelecido por MAX_NB_POINTS
--               e o número de repetições deve ser uma potência de 2 (ex: 00001 ou 01000).
--               Por fim, o bloco utiliza um handshake ready/valid para ser compatível com
--               uma interface AXI-STREAM.
--
--               obs.: Na versão 2017.4, até onde eu entendo, para a inferência de BRAMs
--                     o número de pontos da instância da RAM deve ser potência de 2.
--                     Em versões mais recentes do vivado, é possível que essa condição seja 
--                     mais flexível.
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
use work.utils_pkg.all;

------------
-- Entity --
------------

entity averager_v2 is
    generic (
        -- Behavioral
        NB_REPETITIONS_WIDTH        : positive; -- Tamanho do número de repetições log2(num_repetições + 1)
        WORD_FRAC_PART              : integer;  -- Tamanho da parte fracionária de uma amostra   
        MAX_NB_POINTS               : natural   -- MAX_NB_POINTS power of 2, needed for BRAM inferece
    );
    port (
        clock_i                     : in  std_logic; -- Clock
        areset_i                    : in  std_logic; -- Positive async reset

        -- Config  interface
        config_valid_i              : in  std_logic; -- Indica que os dados de config_* são válidos no ciclo atual de clock
        config_max_addr_i           : in  std_logic_vector( ( ceil_log2(MAX_NB_POINTS + 1) - 1 ) downto 0 ); -- Endereço máximo para configurar a FIFO.
                                                                                                             -- Ex: Se o sinal possui 64 amostras, para configurar o bloco 
                                                                                                             -- a aceitar esse número de amostras, deve se usar 
                                                                                                             -- config_max_addr_i = 63 (número de pontos - 1)
        config_nb_repetitions_i     : in  std_logic_vector(5 downto 0); -- Número de repetições do sinal, sobre o qual se faz a média (só potência de 2 até 32)

        -- Input interface 
        input_valid_i               : in  std_logic; -- Indica que os outros sinais da interface são válidos nesse ciclo de clock
        input_data_i                : in  sfixed( 1 downto WORD_FRAC_PART ); -- Uma amostra
        input_last_word_i           : in  std_logic; -- Sinal indicando que a amostra é a última do ciclo

        ----------------------------------
        -- Output  AXI Stream Interface --
        ----------------------------------
        sending_o                   : out std_logic; -- Indica que o bloco está enviando dados na interface de saída
        s_axis_st_tready_i          : in  std_logic; -- Handshake ready (AXI)
        s_axis_st_tvalid_o          : out std_logic; -- Handshake valid (AXI) 
        s_axis_st_tdata_o           : out std_logic_vector ((1  + (- WORD_FRAC_PART)) downto 0); -- Data
        s_axis_st_tlast_o           : out std_logic -- Handshake last (AXI)
        
    );
end averager_v2;

------------------
-- Architecture --
------------------

architecture behavioral of averager_v2 is


    --------------
    -- Constant --
    --------------
    
    -- Memory
    constant    WORD_INT_PART               : positive := 1;
    constant    MAX_ADDR_WIDTH              : positive := config_max_addr_i'length;
    constant    RAM_DEPTH                   : positive := MAX_NB_POINTS;
    constant    MAX_NB_REPETITIONS          : positive := 2**(NB_REPETITIONS_WIDTH - 1);
    --constant    INPUT_WIDTH                 : positive := ( ( WORD_INT_PART + 1) + (- WORD_FRAC_PART) );
    
    -- A conta em seguida funciona, pois estamos considerando sinais entre [-1;+1]
    -- então estamos adicionando [-1;+1] MAX_NB_REPETITIONS vezes
    -- O tamanho calculado é usado para descobrir o espaço necessário em RAM para acumular todos os pontos
    -- durante o número de repetições máximo (MAX_NB_REPETITIONS)
    constant    ACC_WORD_INT_PART           : positive := ceil_log2 (MAX_NB_REPETITIONS + 1); -- sfixed já leva um bit de sinal em conta
    constant    RAM_DATA_WIDTH              : positive := (ACC_WORD_INT_PART + 1) + (-WORD_FRAC_PART);
  
    ------------
    -- Signal --
    ------------
    
    -- Input
    signal config_input_valid                   : std_logic;
    signal config_max_addr                      : std_logic_vector( ( MAX_ADDR_WIDTH - 1 ) downto 0 ); 
    signal config_nb_repetitions                : std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0); 
    signal config_nb_repetitions_reg            : std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0); 
    signal config_reset_pointers                : std_logic; 
    
    signal input_valid                          : std_logic;
    signal input_valid_reg                      : std_logic;
    signal input_data                           : sfixed( WORD_INT_PART downto WORD_FRAC_PART );
    signal input_data_reg                       : sfixed( WORD_INT_PART downto WORD_FRAC_PART );
    signal input_last_word                      : std_logic;
    signal input_last_word_reg                  : std_logic;

    -- Accumulator
    signal acc_en                               : std_logic;
    signal acc_en_reg                           : std_logic;

    signal resized_input_data                   : sfixed ( ACC_WORD_INT_PART downto WORD_FRAC_PART );
    signal slv_resized_input_data               : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);  

    signal acc_point                            : sfixed ( ACC_WORD_INT_PART downto WORD_FRAC_PART );      
    signal slv_acc_point                        : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);      

    -- Ring FiFo
    signal fifo_config_input_valid              : std_logic;
    signal fifo_config_max_addr                 : std_logic_vector( ( MAX_ADDR_WIDTH - 1 ) downto 0 );
    signal fifo_config_reset_pointers           : std_logic;
    
    signal fifo_wr_input_valid                  : std_logic;
    signal fifo_wr_data                         : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    
    signal fifo_rd_enable_from_input            : std_logic;
    signal fifo_rd_enable_from_output           : std_logic;
    
    signal enable_read                          : std_logic;
    signal enable_read_reg                      : std_logic;
    
    signal fifo_rd_en                           : std_logic;
    signal fifo_output_valid                    : std_logic;
    signal fifo_rd_data                         : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    signal sfixed_fifo_rd_data                  : sfixed( ACC_WORD_INT_PART downto WORD_FRAC_PART );     

    signal fifo_empty                           : std_logic;
    signal fifo_full                            : std_logic;

    signal enable_counter                       : std_logic;
    signal last_word                            : std_logic;
    signal last_word_reg                        : std_logic;
    signal reset_counter_repetitions            : std_logic;
    signal counter_repetitions                  : unsigned( (NB_REPETITIONS_WIDTH - 1) downto 0);
    signal counter_repetitions_done             : std_logic;

    -- Midway fifo
    signal enable_read_from_fifo                : std_logic;
    
    signal enable_one_fifo                      : std_logic;

    signal one_fifo_valid                       : std_logic;
    signal one_fifo_valid_reg                   : std_logic;
    signal one_fifo_data                        : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    signal one_fifo_last                        : std_logic;

    signal fifo_last_word                       : std_logic;

    signal mux_valid                            : std_logic;
    signal mux_data                             : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    signal mux_last                             : std_logic;

    -- Division
    signal nb_shifts                            : unsigned( ( ceil_log2( NB_REPETITIONS_WIDTH + 1) - 1) downto 0  );
    
    signal enable_output                        : std_logic;
    signal output_valid                         : std_logic;
    signal output_valid_reg                     : std_logic;
    signal shifted_data                         : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    signal output_data                          : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);

    signal output_last_word                     : std_logic;

    -- AXI-ST output interface
    signal s_axis_st_tready                     : std_logic;
    signal s_axis_st_tdata                      : std_logic_vector((s_axis_st_tdata_o'length - 1) downto 0);

begin
    
    -- Input
    config_input_valid      <= config_valid_i ;
    config_max_addr         <= config_max_addr_i;
    config_nb_repetitions   <= config_nb_repetitions_i;
   
    -- Usado para resetar os ponteiros internos da FIFO
    -- durante uma transição negativa 
    config_reset_pointers   <=          enable_read_reg 
                                    and not(enable_read);
    
    input_valid             <= input_valid_i;
    input_data              <= input_data_i;
    input_last_word         <= input_last_word_i;

    ------------------------------------------------------------------
    --                     Registro da entrada                           
    --                                                                
    --   Goal: Registrar a entrada (configuração e dados) e forçar
    --         que o sinal de "last_word" só seja '1' qnd valid = '1'
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: input_valid;
    --          config_input_valid;
    --          input_data;
    --          input_last_word;
    --          config_nb_repetitions;
    --
    --   Output: input_valid_reg;
    --           input_data_reg;
    --           input_last_word_reg;
    --           config_nb_repetitions_reg;
    --
    --   Result: A entrada é salva em registros e é garantido
    --           que "last_word" só aconteça qnd "valid" é '1'
    ------------------------------------------------------------------
    proc_input_reg : process (clock_i , areset_i)
    begin
        if (areset_i = '1') then
            config_nb_repetitions_reg   <= (others => '0'); 
            input_last_word_reg         <= '0';
        elsif ( rising_edge (clock_i) ) then
            input_valid_reg  <= input_valid;
            
            if(input_valid = '1' ) then
                input_data_reg              <= input_data;
                input_last_word_reg         <= input_last_word;
            else
                input_last_word_reg         <= '0';
            end if;
            
            if (config_input_valid = '1') then
                config_nb_repetitions_reg   <= config_nb_repetitions;
            end if;
        end if;
    end process;

    -- Usado para converter a entrada (sfixed) para slv para salvar na FIFO
    resized_input_data              <= resize(input_data_reg, ACC_WORD_INT_PART, WORD_FRAC_PART); 
    slv_resized_input_data          <= to_slv(resized_input_data);

    ---------------
    -- Ring FIFO --
    ---------------

    fifo_config_input_valid         <=              config_input_valid;
    fifo_config_max_addr            <=              config_max_addr;
    fifo_config_reset_pointers      <=              config_reset_pointers;

    fifo_wr_input_valid              <=              input_valid_reg;

    fifo_wr_data                    <=              slv_acc_point  when ( acc_en_reg = '1' )
                                            else    slv_resized_input_data;

    fifo_rd_en                      <=              fifo_rd_enable_from_output    when enable_read = '1'
                                            else    fifo_rd_enable_from_input;

    fifo_rd_enable_from_output      <=         enable_read_from_fifo;

    ring_fifo_ent: entity work.ring_fifo
        generic map (
            DATA_WIDTH                  => RAM_DATA_WIDTH,
            RAM_DEPTH                   => RAM_DEPTH
        )
        port map (
            clock_i                     => clock_i,
            areset_i                    => areset_i,

            -- Config  port
            config_valid_i               => fifo_config_input_valid,
            config_max_addr_i           => fifo_config_max_addr,
            config_reset_pointers_i     => fifo_config_reset_pointers,

            -- Write port
            wr_valid_i                   => fifo_wr_input_valid,
            wr_data_i                   => fifo_wr_data,

            -- Read port
            rd_en_i                     => fifo_rd_en,
            rd_valid_o                   => fifo_output_valid, 
            rd_data_o                   => fifo_rd_data, 

            -- Flags
            empty                       => fifo_empty,
            full                        => fifo_full
        );

    -- Habilita o contador de repetições
    enable_counter  <=          input_valid_reg
                            and input_last_word_reg ;   

    -- Reseta o contador de repetições
    reset_counter_repetitions       <=          last_word
                                            or  config_reset_pointers;

    ------------------------------------------------------------------
    --                     Contador de repetições                           
    --                                                                
    --   Goal: Servir de contador de repetições, resetando o contador 
    --         em uma operação completa (fim das repetições)
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: reset_counter_repetitions;
    --          enable_counter;
    --          counter_repetitions_done;
    --          counter_repetitions;
    --
    --   Output: counter_repetitions;
    --
    --   Result: Counter_repetitions + 1
    --
    ------------------------------------------------------------------
    proc_counter_rep : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then

            counter_repetitions                 <= to_unsigned( 1 , counter_repetitions'length );

        elsif (rising_edge(clock_i)) then

            if ( reset_counter_repetitions = '1' ) then
                counter_repetitions <= to_unsigned( 1 , counter_repetitions'length );

            elsif (enable_counter = '1') then
                if ( counter_repetitions_done = '0') then
                    counter_repetitions <= counter_repetitions + 1;
                end if;

            end if;
        end if;
    end process;
    
    -- Indica que todas as repetições esperadas foram completadas
    counter_repetitions_done                <=              '1'     when ( counter_repetitions = ( unsigned(config_nb_repetitions_reg)) )
                                                    else    '0';

    ------------------------------------------------------------------
    --                     Registro de flag                      
    --                                                                
    --   Goal: Servir de sincronia de flags (delay de um ciclo no sinal)
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: config_reset_pointers;
    --          acc_en;
    --          enable_read;
    --          last_word;
    --
    --   Output: acc_en_reg;
    --           enable_read_reg;
    --           last_word_reg;
    --
    --   Result: Atraso de um sinal dos sinais (acc_en, enable_read
    --           e last_word).
    --
    ------------------------------------------------------------------
    flag_register : process (clock_i , areset_i)
    begin
        if (areset_i = '1') then
            acc_en_reg          <= '0';
            enable_read_reg     <= '0';
            last_word_reg       <= '0';
        elsif ( rising_edge(clock_i) ) then

            if (config_reset_pointers = '1') then
                acc_en_reg      <= '0';
            else
                acc_en_reg      <= acc_en;
            end if;

            enable_read_reg <= enable_read;
            last_word_reg   <= last_word;
        end if;
    end process;

    -- Marca que é a última palavra do processo de média
    -- Serve para retornar o bloco ao estado inicial (ver acc_en)
    last_word           <=                 counter_repetitions_done
                                        and input_last_word_reg     ;

    -- Sinal de enable para o acumulador (acc). Depois que a primeira
    -- repetição (shot) do sinal foi colocado na FIFO, as outras amostras
    -- antes de serem postas na FIFO são acumuladas com os valores já
    -- salvos na FIFO. (Ref: references/tcc_1321111_23_12_20.pdf)
    acc_en              <=          (   fifo_full
                                    or  acc_en_reg )
                                and not(last_word);

    -- Indica que a FIFO está sendo lida para a saída e não
    -- para o acumulador/entrada
    enable_read         <=          (    last_word_reg
                                    or  enable_read_reg)
                                and not (output_last_word);

    -- Sinal de enable para leitura para entrada da FIFO
    fifo_rd_enable_from_input       <=          input_valid_reg
                                            and acc_en;

    -- Conversação do valor na FIFO, em slv, para sfixed
    sfixed_fifo_rd_data     <= to_sfixed(fifo_rd_data, ACC_WORD_INT_PART, WORD_FRAC_PART);

    -- Soma entre entrada e valor salvo em FIFO para o acumulador (ver acc_en)
    acc_point               <= resize ( resized_input_data + sfixed_fifo_rd_data , acc_point );

    slv_acc_point           <= to_slv(acc_point);

    -- Indica que o valor da FIFO de saída é válido. 
    -- Para estar de acordo com o handshake de saída
    -- foi construída uma FIFO unitária (1 posição) para
    -- se adequar ao handshake e evitar perda de dados
    -- caso ready se torne '0' no ciclo atual
    one_fifo_valid           <=          fifo_output_valid
                                    and enable_read;

    -- Enable para a FIFO de saída (ver one_fifo_valid)
    enable_one_fifo <=          (       not(enable_output)
                                    and one_fifo_valid      )
                            or  (       enable_output
                                    and one_fifo_valid_reg     );

    -- Indica que a palavra na FIFO de saída é a última (ver one_fifo_valid)
    fifo_last_word  <=          fifo_empty 
                            and enable_read;

    ------------------------------------------------------------------
    --                     FIFO de saída (one_fifo)                     
    --                                                                
    --   Goal: Servir de tampão entre a FIFO principal (ring) e
    --         a interface AXI-STREAM definida na saída, cuidando
    --         do handshake ready/valid
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: enable_one_fifo;
    --          one_fifo_valid;
    --          fifo_rd_data;
    --          fifo_empty;
    --
    --   Output: one_fifo_valid_reg;
    --           one_fifo_data;
    --           one_fifo_last;
    --
    --   Result: Cuida de casos em que o sinal "ready" na saída
    --           passa para zero no mesmo ciclo, evitando perda
    --           de pacotes na saída do averager_v2
    ------------------------------------------------------------------
    one_fifo_element : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            one_fifo_valid_reg <= '0';
        elsif(rising_edge(clock_i)) then
            if(enable_one_fifo = '1') then
                one_fifo_valid_reg  <= one_fifo_valid;
                if (one_fifo_valid = '1') then
                    one_fifo_data <= fifo_rd_data;
                    one_fifo_last <= fifo_empty;
                end if;
            end if;
        end if;
    end process;

    -- Conjunto de MUX's que selecionam entre a saída da FIFO principal (ring)
    -- e da FIFO de saída (one_fifo). Como exemplo de utilização, caso
    -- o sinal "ready" da saída seja sempre '1' esses MUXs tem como saída
    -- sempre os valores da FIFO principal, caso "ready" passa para '0' 
    -- durante o ciclo atual, para não perder o pacote já requisitado da FIFO
    -- ele é posto na FIFO de saída e depois os MUXs são usados para 
    -- recuperar o valor da FIFO de sáida, invés da FIFO principal
    mux_valid            <=              one_fifo_valid_reg    when  (one_fifo_valid_reg = '1')
                                else    one_fifo_valid;
                                    
    mux_data            <=              one_fifo_data    when    (one_fifo_valid_reg = '1')
                                else    fifo_rd_data;

    mux_last            <=              one_fifo_last    when    (one_fifo_valid_reg = '1')
                                else    fifo_empty;
                                
    -- Habilita a leitura da FIFO principal para a saída de dados
    -- pela interface AXI-STREAM                            
    enable_read_from_fifo       <=          enable_output
                                        or  (       one_fifo_valid_reg 
                                                nor fifo_output_valid);

    output_valid                     <=         mux_valid -- garante que o sinal de saída só seja
                                            and enable_read; -- válido durante o output
    
    -- Habilita o processo de output quando "ready" = '1' ou quando não existem
    -- dados no registro de saída. Estrutura ready or not(valid) padrão de um pipeline
    enable_output                   <=          (    s_axis_st_tready
                                                or  not(output_valid_reg))
                                            and enable_read;
                                            
    -- Realiza a divisão do valor acumulado pelo número de repetições
    shifted_data    <=          std_logic_vector(resize(signed ( mux_data( (mux_data'high) downto 1)),output_data'length)) when  (config_nb_repetitions_reg = "000010")
                        else    std_logic_vector(resize(signed ( mux_data( (mux_data'high) downto 2)),output_data'length)) when  (config_nb_repetitions_reg = "000100")
                        else    std_logic_vector(resize(signed ( mux_data( (mux_data'high) downto 3)),output_data'length)) when  (config_nb_repetitions_reg = "001000")
                        else    std_logic_vector(resize(signed ( mux_data( (mux_data'high) downto 4)),output_data'length)) when  (config_nb_repetitions_reg = "010000")
                        else    std_logic_vector(resize(signed ( mux_data( (mux_data'high) downto 5)),output_data'length)) when  (config_nb_repetitions_reg = "100000")
                        else    mux_data;

    ------------------------------------------------------------------
    --                     Processo de saída                    
    --                                                                
    --   Goal: Servir de registro para a interface AXI-Stream
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: output_valid;
    --          output_valid;
    --          shifted_data;
    --          mux_last;
    --          config_reset_pointers;
    --
    --   Output: output_valid_reg;
    --           output_data;
    --           output_last_word;
    --
    --   Result: Registro dos componentes da interface de saída
    --           antes da interface AXI-STREAM
    ------------------------------------------------------------------
    proc_output_word : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            output_valid_reg   <= '0';
            output_last_word  <= '0';
        elsif (rising_edge(clock_i)) then

                output_valid_reg <= output_valid;

                if (enable_output = '1') then
                    if(output_valid = '1') then
                        output_data <=  shifted_data;
                        output_last_word <=  mux_last;
                    end if;
                end if;

                if(config_reset_pointers = '1') then -- Limpeza do registro
                    output_last_word <=  '0';
                end if;
        end if;
    end process;


    s_axis_st_tdata         <= output_data((s_axis_st_tdata'length - 1) downto 0); 

    -- Output
    sending_o               <= enable_read;
    s_axis_st_tready        <= s_axis_st_tready_i;
    s_axis_st_tvalid_o      <= output_valid_reg;
    s_axis_st_tdata_o       <= s_axis_st_tdata;
    s_axis_st_tlast_o       <= output_last_word;

end architecture;
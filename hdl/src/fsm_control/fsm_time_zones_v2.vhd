---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                         
-- Module Name: fsm_time_zones_v2                                                                           
-- Author Name: Lucas Grativol Ribeiro                                                                           
--                                                                                         
-- Revision Date: 24/11/2020                                                                         
-- Tool version: Vivado 2017.4                                                                           
--                                                                      
-- Goal: Máquina de estados que controla o proceso de transmissão                                                
--               e recepção do sinal.        
--
-- Description:  O cotrole do processo do sinal se faz com simples contadores                                        
--               para o tempo de cada uma das zonas permitidas para o sinal           
--               Zonas de tempo:                                                                          
--               -- Delay timer : Tempo que nada acontece antes do envio;                                                                          
--               -- Tx timer : Momento que é permitido o envio do sinal,                                                                         
--               -- Deadzone timer : Tempo entre a transmissão e a recepção,                   
--               --                  em que nada acontece; 
--               -- Rx timer : Tempo reservado a recepção do sinal;                    
--               -- Idle timer : Tempo em que nada acontece;                   
--                                  
--               O controle não interfere na síntese do sinal TX;                    
--               Ao invés disso, o controle decide quando o sinal TX começa
--               o tempo entre o inicio da RX e o fim de TX, habilitando a RX;
--               O tempo idle final marca o tempo para recomeçar a o envio de um sinal,
--               controlando múltiplos disparos.
--
--               Obs.: Não existe proteção de tempos nulos, caso um sinal seja zero b"[0..0]
--                     a lógica transformar o contador em b"[1..1], número máximo                    
---------------------------------------------------------------------------------------------

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

entity fsm_time_zones_v2 is
    generic(
        NB_SHOTS_WIDTH                      : positive := 6 -- Tamanho do contador de disparos
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        bang_i                              : in  std_logic; -- Indica que todos parâmetros são válidos no ciclo atual e inicia a FSM
        nb_shots_i                          : in  std_logic_vector(( NB_SHOTS_WIDTH - 1) downto 0); -- Número de disparos (repetições) do sinal

        -- Timers values
        delay_time_i                        : in  std_logic_vector(( DELAY_TIME_WIDTH - 1) downto 0); -- Número de ciclos
        tx_time_i                           : in  std_logic_vector(( TX_TIME_WIDTH - 1) downto 0); -- Número de ciclos
        deadzone_time_i                     : in  std_logic_vector(( DEADZONE_TIME_WIDTH - 1) downto 0); -- Número de ciclos
        rx_time_i                           : in  std_logic_vector(( RX_TIME_WIDTH - 1) downto 0); -- Número de ciclos
        idle_time_i                         : in  std_logic_vector(( IDLE_TIME_WIDTH - 1) downto 0); -- Número de ciclos
        
        --Feedback Interface
        output_valid_i                      : in  std_logic; -- Sinal de entrada para sincronizar a FSM com a saída do módulo TX
        system_busy_i                       : in  std_logic; -- Indica que a RX ainda não acabou de enviar os dados para o host (bloqueia o sinal "bang")
        bang_o                              : out std_logic; -- Sinal fornecido ao sistema para começar o ciclo

        -- Control Interface
        enable_rx_o                         : out std_logic; -- Enable o sinal de recepção
        restart_cycles_o                    : out std_logic; -- Reinicia o sinal TX uma vez, esse sinal é acionado "nb_shots" vezes
        end_zones_cycle_o                   : out std_logic -- Indica o fim das operações
    );
end fsm_time_zones_v2;

------------------
-- Architecture --
------------------
architecture behavioral of fsm_time_zones_v2 is

    -----------
    -- Types --
    -----------

    type tp_time_state is (ST_INPUT, ST_DELAY_START , ST_TX , ST_DEADZONE , ST_RX, ST_IDLE); 
 
    -------------
    -- Signals --
    -------------
    
    -- Input
    
    signal  delay_time                          : std_logic_vector(( DELAY_TIME_WIDTH - 1) downto 0);
    signal  tx_time                             : std_logic_vector(( TX_TIME_WIDTH - 1) downto 0);
    signal  deadzone_time                       : std_logic_vector(( DEADZONE_TIME_WIDTH - 1) downto 0);
    signal  rx_time                             : std_logic_vector(( RX_TIME_WIDTH - 1) downto 0);
    signal  idle_time                           : std_logic_vector(( IDLE_TIME_WIDTH - 1) downto 0);
    signal  nb_shots                            : std_logic_vector((NB_SHOTS_WIDTH - 1) downto 0);

    -- FSM
    signal  time_state                          : tp_time_state;

    -- Behavioral
    signal enable_system                        : std_logic;

    signal  nb_shots_reg                        : unsigned((NB_SHOTS_WIDTH - 1) downto 0);
    signal  delay_time_reg                      : unsigned(( DELAY_TIME_WIDTH - 1) downto 0);
    signal  tx_time_reg                         : unsigned(( TX_TIME_WIDTH - 1) downto 0);
    signal  deadzone_time_reg                   : unsigned(( DEADZONE_TIME_WIDTH - 1) downto 0);
    signal  rx_time_reg                         : unsigned(( RX_TIME_WIDTH - 1) downto 0);
    signal  idle_time_reg                       : unsigned(( IDLE_TIME_WIDTH - 1) downto 0);

    signal enable_bang                          : std_logic;
    
    signal  counter_nb_shots                    : unsigned(( NB_SHOTS_WIDTH - 1) downto 0);
    signal  counter_delay_time                  : unsigned(( TX_TIME_WIDTH - 1) downto 0);
    signal  counter_tx_time                     : unsigned(( TX_TIME_WIDTH - 1) downto 0);
    signal  counter_deadzone_time               : unsigned(( DEADZONE_TIME_WIDTH - 1) downto 0);
    signal  counter_rx_time                     : unsigned(( RX_TIME_WIDTH - 1) downto 0);
    signal  counter_idle_time                   : unsigned(( IDLE_TIME_WIDTH - 1) downto 0);
    
    signal  counter_nb_shots_done               : std_logic;
    signal  counter_delay_time_done             : std_logic;
    signal  counter_tx_time_done                : std_logic;
    signal  counter_deadzone_time_done          : std_logic;
    signal  counter_rx_time_done                : std_logic;
    signal  counter_idle_time_done              : std_logic;

    -- Output
    signal  enable_rx                           : std_logic;
    signal  restart_cycles                      : std_logic;
    signal  end_zones_cycle                     : std_logic;


begin
    
    -- Input
    nb_shots            <= nb_shots_i;
    tx_time             <= tx_time_i;      
    deadzone_time       <= deadzone_time_i;
    rx_time             <= rx_time_i;      
    idle_time           <= idle_time_i;     

    ------------------------------------------------------------------
    --                     Input registering                           
    --                                                                
    --   Goal: Registrar os parâmetros fornecidos
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: bang_i;
    --          nb_shots;
    --          tx_time;
    --          deadzone_time;
    --          rx_time;
    --          idle_time;
    --
    --   Output: nb_shots_reg;
    --           tx_time_reg;
    --           deadzone_time_reg;
    --           rx_time_reg;
    --           idle_time_reg;
    --
    --   Result: Salva os parâmetros (inputs) em registros
    ------------------------------------------------------------------
    input_reg : process (clock_i)
    begin
        if(rising_edge(clock_i)) then
            if (bang_i = '1') then
                nb_shots_reg        <= unsigned(nb_shots);
                tx_time_reg         <= unsigned(tx_time);      
                deadzone_time_reg   <= unsigned(deadzone_time);
                rx_time_reg         <= unsigned(rx_time);      
                idle_time_reg       <= unsigned(idle_time); 
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    --                     FSM                           
    --                                                                
    --   Goal: Máquina de estados para marcar o tempo de cada zona
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: enable_system;
    --          counter_delay_time_done;
    --          output_valid_i;
    --          counter_tx_time;
    --          counter_tx_time_done;
    --          counter_deadzone_time_done;
    --          counter_rx_time_done;
    --          counter_idle_time_done;
    --          counter_nb_shots_done;
    --
    --   Output: counter_nb_shots;
    --           time_state;
    --           enable_rx;
    --           restart_cycles;
    --           end_zones_cycle;
    --           enable_bang;
    --           counter_delay_time;
    --           counter_tx_time;
    --           counter_deadzone_time;
    --           counter_rx_time;
    --           counter_idle_time;
    --
    --   Result: Controla o processo de TX e RX, além
    --           dos múltiplos disparos do sinal TX
    ------------------------------------------------------------------    
    time_zones_fsm : process (clock_i,areset_i)
    begin
        if (areset_i = '1') then
            counter_nb_shots  <= (others => '0');
            time_state              <= ST_INPUT;
            enable_rx               <= '0';
            restart_cycles          <= '0';
            end_zones_cycle         <= '0';
            enable_bang             <= '0';
            
        elsif (rising_edge(clock_i)) then

            restart_cycles      <= '0';
            enable_rx           <= '0';
            enable_bang         <= '0';
            end_zones_cycle     <= '0';
            
            case time_state is
                
                when ST_INPUT =>

                    if(enable_system = '1') then                        
                        counter_delay_time  <= (others => '0');
                        time_state          <= ST_TX;
                    else
                        time_state          <= ST_DELAY_START;
                    end if;

                when ST_DELAY_START =>

                    if (counter_delay_time_done = '1') then 
                        time_state          <= ST_TX;
                        counter_tx_time     <= (others => '0');
                    else
                        time_state          <= ST_DELAY_START;
                        counter_delay_time  <= counter_delay_time + 1 ;
                    end if;

                when ST_TX =>

                    if(counter_tx_time = to_unsigned(0,counter_tx_time'length))then
                        enable_bang  <= '1';
                    end if;
                    
                    if(output_valid_i = '1') then
                        if (counter_tx_time_done = '1') then
                            time_state              <= ST_DEADZONE;
                            counter_deadzone_time   <= (others => '0');
                        else
                            time_state          <= ST_TX;
                            counter_tx_time     <= counter_tx_time + 1 ;
                        end if;
                    else
                        time_state       <= ST_TX;
                    end if;

                when ST_DEADZONE =>

                    if (counter_deadzone_time_done = '1') then
                        time_state          <= ST_RX;
                        counter_rx_time     <= (others => '0');
                    else
                        time_state              <= ST_DEADZONE;
                        counter_deadzone_time   <= counter_deadzone_time + 1 ;
                    end if;

                when ST_RX =>

                    enable_rx        <= '1';

                    if (counter_rx_time_done = '1') then
                        time_state          <= ST_IDLE;
                        counter_idle_time   <= (others => '0');
                    else
                        time_state          <= ST_RX;
                        counter_rx_time     <= counter_rx_time + 1 ;
                    end if;

                when ST_IDLE =>

                    if (counter_idle_time_done = '1') then

                        if (counter_nb_shots_done = '1') then
                            time_state          <= ST_INPUT;
                            counter_nb_shots    <= (others => '0');
                            end_zones_cycle     <= '1';
                        else
                            time_state          <= ST_TX;
                            counter_tx_time     <= (others => '0');
                            counter_nb_shots    <= counter_nb_shots + 1 ;
                            restart_cycles      <= '1';
                        end if;

                    else
                        time_state          <= ST_IDLE;
                        counter_idle_time   <= counter_idle_time + 1 ;
                        restart_cycles      <= '0';
                    end if;

                when others =>
                    time_state   <= ST_INPUT;
            end case;
        end if;
    end process;
    
    -- 0 protection
    counter_nb_shots_done         <=                    '1'     when (counter_nb_shots = (nb_shots_reg - 1))
                                                else    '0';

    counter_delay_time_done             <=              '1'     when (counter_delay_time     = (delay_time_reg - 1))
                                                else    '0';

    counter_tx_time_done                <=              '1'     when (counter_tx_time     = (tx_time_reg - 1))
                                                else    '0';

    counter_deadzone_time_done            <=            '1'     when (counter_deadzone_time = (deadzone_time_reg - 1))
                                                else    '0';

    counter_rx_time_done                <=              '1'     when (counter_rx_time     = (rx_time_reg - 1))
                                                else    '0';

    counter_idle_time_done               <=             '1'     when (counter_idle_time    = (idle_time_reg - 1))
                                                else    '0';  

    enable_system       <=          bang_i
                                and not(system_busy_i);

    ------------
    -- Output --
    ------------
    
    enable_rx_o        <= enable_rx;
    restart_cycles_o   <= restart_cycles;
    end_zones_cycle_o  <= end_zones_cycle;

end behavioral;
---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                           
-- Module Name: phase_adjust                                                                           
-- Author Name: Lucas Grativol Ribeiro                                                                           
--                                                                                         
-- Revision Date: 24/11/2020                                                                         
-- Tool version: Vivado 2017.4       
--                                                                    
-- Goal:         Ajustar a phase e o número de pontos para as janelas usarem várioas fatores 
--               cos(4pi), cos(6pi)...
--                                                                         
-- Description:   A partir de um FACTOR fixo é ajustado as fases e número de pontos
--
--          Obs.(1): SIDEBAND serve para passar um sinal de SIDEBAND_WIDTH bits (sideband_data)
--                 por todo o pipeline da entidade, o sinal não influencia no design
--                 e pode ser usado para sincronizar sinais.  
--
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

------------
-- Entity --
------------

entity phase_adjust is
    generic (
        PHASE_INTEGER_PART                  : natural; -- phase integer part
        PHASE_FRAC_PART                     : integer; -- phase fractional part
        NB_POINTS_WIDTH                     : positive; -- Número de bits de nb_points
        FACTOR                              : positive; -- Fator para ajustar a fase
        SIDEBAND_WIDTH                      : natural
    );
    port (
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        valid_i                             : in  std_logic; -- Indica que todos os parâmetros abaixo são válidos no ciclo atual
        phase_in_i                          : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); -- A variação de fase usada para pelo acumulador de fase 
                                                                                                     -- para gerar os ângulos
        nb_cycles_in_i                      : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0); -- Número de pontos
        
        -- Sideband interface
        sideband_data_i                     : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0); -- Ver acima
        sideband_data_o                     : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0); -- Ver acima
        
        -- Output interface
        valid_o                             : out std_logic; -- Indica que as saída abaixo são válidas no ciclo atual
        phase_out_o                         : out ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART); -- Fase ajustada
        nb_cycles_out_o                     : out std_logic_vector((NB_POINTS_WIDTH - 1) downto 0); -- Número de pontos ajustado
        nb_rept_out_o                       : out std_logic_vector((NB_POINTS_WIDTH - 1) downto 0) -- Número de repetições ajustado
    );
end phase_adjust;

------------------
-- Architecture --
------------------
architecture behavioral of phase_adjust is

    ---------------
    -- Constants --
    ---------------
    constant    FACTOR_INTEGER_PART                 : natural :=   0;
    constant    FACTOR_FRAC_PART                    : integer := -10;
    constant    UFX_FACTOR                          : ufixed((NB_POINTS_WIDTH - 1) downto 0)                := to_ufixed(real(FACTOR),NB_POINTS_WIDTH - 1,0);
    constant    ONE_FACTOR                          : ufixed(FACTOR_INTEGER_PART downto FACTOR_FRAC_PART)   := to_ufixed( (1.0 / real(FACTOR) ) ,FACTOR_INTEGER_PART,FACTOR_FRAC_PART);

    -------------
    -- Signals --
    -------------
    
    -- Input
    signal      input_valid                         : std_logic;
    signal      phase_in                            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal      nb_cycles_in                        : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      sideband_data_in                    : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 1
    signal      input_valid_reg                     : std_logic; 
    signal      phase_in_reg                        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal      nb_cycles_in_reg                    : ufixed((NB_POINTS_WIDTH - 1) downto 0);                     
    signal      sideband_data_in_reg                : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);


    -- Stage 2
    signal      output_valid                        : std_logic; 
    signal      phase_factor                        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal      nb_cycles_factor                    : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      nb_rept_factor                      : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      sideband_data_out                   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);


begin

    -----------
    -- Input --
    -----------

    input_valid         <= valid_i;        
    phase_in            <= phase_in_i;    
    nb_cycles_in        <= nb_cycles_in_i;
    sideband_data_in    <= sideband_data_i;

    -------------
    -- Stage 1 --
    -------------

    ------------------------------------------------------------------
    --                     Input registering                           
    --                                                                
    --   Goal: Registrar os parâmetros fornecidos
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: input_valid;
    --          nb_cycles_in;
    --          sideband_data_in;
    --
    --   Output: input_valid_reg;
    --           nb_cycles_in_reg;
    --           sideband_data_in_reg;
    --
    --   Result: Salva os parâmetros (inputs) em registros
    ------------------------------------------------------------------
    input_registers : process (clock_i, areset_i)
    begin
        if (areset_i = '1') then
            
            input_valid_reg <= '0';
        elsif ( rising_edge(clock_i) ) then

            input_valid_reg <= input_valid;

            if (input_valid = '1') then
                phase_in_reg            <= phase_in;    
                nb_cycles_in_reg        <= to_ufixed(nb_cycles_in, nb_cycles_in_reg);
                sideband_data_in_reg    <= sideband_data_in;
            end if;
        end if;
    end process;

    --------------
    -- Stage 2  --
    --------------
    ------------------------------------------------------------------
    --                     Adjustments                          
    --                                                                
    --   Goal: Ajustar a phase e o número de pontos
    --         para um determinado fator
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: input_valid_reg;
    --          nb_cycles_in_reg;
    --          UFX_FACTOR;
    --          nb_cycles_in_reg;
    --          ONE_FACTOR;
    --          sideband_data_in_reg;
    --          FACTOR
    --
    --   Output: output_valid;
    --           phase_factor;
    --           nb_cycles_factor;
    --           nb_rept_factor;
    --           sideband_data_out
    --
    --   Result: As entradas são ajustadas de um fator fixo e podem ser
    --           usadas para gerar cos(2pi * FACTOR)
    ------------------------------------------------------------------
    phase_adjustment : process (clock_i, areset_i)
    begin
        if (areset_i = '1') then
            
            output_valid <= '0';
        elsif ( rising_edge(clock_i) ) then

            output_valid <= input_valid_reg;

            if (input_valid_reg = '1') then

                phase_factor        <= resize(phase_in_reg * UFX_FACTOR , phase_factor);
                nb_cycles_factor    <= to_slv  (  resize ( nb_cycles_in_reg * ONE_FACTOR, UFX_FACTOR) );
                nb_rept_factor      <= std_logic_vector(to_unsigned(FACTOR,nb_rept_factor'length));
                sideband_data_out   <= sideband_data_in_reg;
            end if;
        end if;
    end process;

    ------------
    -- Output --
    ------------
    valid_o             <= output_valid;
    phase_out_o         <= phase_factor;
    nb_cycles_out_o     <= nb_cycles_factor;
    nb_rept_out_o       <= nb_rept_factor;
    sideband_data_o     <= sideband_data_out;

end behavioral;

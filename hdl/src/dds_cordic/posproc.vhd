---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                           
-- Module Name: posproc                                                                           
-- Author Name: Lucas Grativol Ribeiro                                                                           
--                                                                                         
-- Revision Date: 18/11/2020                                                                         
-- Tool version: Vivado 2017.4       
--                                                                    
-- Goal:          Corrigir o sinal do seno/cosseno , intrudizido pelo remapeamento do
--                preprocessador 
--                                                                         
-- Description:   Para cada "phase_info" (quadrante de origem do ângulo) corrige
--                o sinal do seno e do cosseno
--                                                                                         
--        Obs.(1): SIDEBAND serve para passar um sinal de SIDEBAND_WIDTH bits (sideband_data)
--                 por todo o pipeline da entidade, o sinal não influencia no design
--                 e pode ser usado para sincronizar sinais.  
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

entity posproc is
    generic (
        SIDEBAND_WIDTH                      : integer;
        WORD_INTEGER_PART                   : natural; -- sfixed integer part 
        WORD_FRAC_PART                      : integer  -- sfixed fractional part
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset
       
        -- Sideband
        sideband_data_i                     : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        sideband_data_o                     : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

        -- Input interface
        valid_i                             : in  std_logic; -- Indica que os sinais são válidos no ciclo atual
        sin_phase_i                         : in  sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
        cos_phase_i                         : in  sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);

        -- Control Interface
        phase_info_i                        : in  std_logic_vector(1 downto 0); -- Informação de fase

        -- Output interface
        valid_o                             : out std_logic; -- Indica que os sinais são válidos no ciclo atual
        sin_phase_o                         : out sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
        cos_phase_o                         : out sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART)
    ); 
end posproc;

------------------
-- Architecture --
------------------

architecture behavioral of posproc is

  
    -------------
    -- Signals --
    -------------
    
    -- Input interface
    signal valid_i_reg                       : std_logic;
    signal sin_phase_reg                    : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
    signal cos_phase_reg                    : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);

    -- Sideband
    signal sideband_data_reg1               : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    signal sideband_data_reg2               : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    -- Control interface
    signal phase_info_reg                   : std_logic_vector(1 downto 0);

    -- Output interface
    signal valid_reg                         : std_logic;
    signal sin_phase                        : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);
    signal cos_phase                        : sfixed(WORD_INTEGER_PART downto WORD_FRAC_PART);   

begin

    ------------------------------------------------------------------
    --                     Input registering                           
    --                                                                
    --   Goal: Registrar os parâmetros fornecidos
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: valid_i;
    --          sideband_data_i;
    --          phase_info_i;
    --          sin_phase_i;
    --          cos_phase_i;
    --
    --   Output: valid_i_reg;
    --           sideband_data_reg1;
    --           sin_phase_reg;
    --           cos_phase_reg;
    --
    --   Result: Salva os parâmetros (inputs) em registros
    ------------------------------------------------------------------
    input_registering : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            valid_i_reg <= '0';
        elsif (rising_edge(clock_i)) then
            valid_i_reg <= valid_i;

            if (valid_i = '1') then

                sideband_data_reg1 <= sideband_data_i;

                phase_info_reg  <= phase_info_i;
                sin_phase_reg   <= sin_phase_i;
                cos_phase_reg   <= cos_phase_i;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    --                     Corretor de phase                           
    --                                                                
    --   Goal: Corrigir a phase 
    --
    --   Clock & reset domain: clock_i & areset_i
    --
    --
    --   Input: valid_i_reg;
    --          sideband_data_reg1;
    --          sin_phase_reg;
    --          cos_phase_reg;
    --          phase_info_reg;
    --
    --   Output: valid_reg;
    --           sideband_data_reg2;
    --           sin_phase;
    --           cos_phase;
    --
    --   Result: Os sinais do cosseno são corrigidos 
    ------------------------------------------------------------------

    phase_correction_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            valid_reg <= '0';
        elsif ( rising_edge(clock_i) ) then
            
            valid_reg <= valid_i_reg;

            if ( valid_i_reg = '1' ) then

                sideband_data_reg2 <= sideband_data_reg1;

                sin_phase   <= sin_phase_reg;
                
                if ( phase_info_reg = "00" or phase_info_reg = "10") then-- phase no primeiro quadrante
                    cos_phase   <= cos_phase_reg;
                else                                 -- phase no quarto quadrante
                    cos_phase   <=  resize(-cos_phase_reg, cos_phase);
                end if;
                
            end if;
        end if;
    end process;

                                
    -- Output

    sideband_data_o         <= sideband_data_reg2;

    valid_o                  <= valid_reg;
    sin_phase_o             <= sin_phase;
    cos_phase_o             <= cos_phase;

end behavioral;
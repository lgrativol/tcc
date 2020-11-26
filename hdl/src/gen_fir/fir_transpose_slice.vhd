---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: 21/11/2020                                                                
-- Module Name: fir_transpose_slice                                                                
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date:                                                      
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: 
--          
-- Description: 
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

------------
-- Entity --
------------

entity fir_transpose_slice is
    generic(
        WEIGHT_INT_PART                 : natural;
        WEIGHT_FRAC_PART                : integer;
        WORD_INT_PART                   : natural;
        WORD_FRAC_PART                  : integer;
        SIDEBAND_WIDTH                  : natural
    );
    port(
        -- Clock interface
        clock_i                         : in  std_logic;
        areset_i                        : in  std_logic; 

        -- Sideband
        sideband_data_i                 : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        sideband_data_o                 : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        
        -- Weight
        weight_valid_i                  : in  std_logic;
        weight_data_i                   : in  sfixed(WEIGHT_INT_PART downto WEIGHT_FRAC_PART);
        
        --Input
        fir_valid_i                     : in  std_logic; 
        sample_data_i                   : in  sfixed(WORD_INT_PART downto WORD_FRAC_PART);
        pipeline_data_i                 : in  sfixed(WORD_INT_PART downto WORD_FRAC_PART);
    
        -- Ouput 
        pipeline_data_o                 : out sfixed(WORD_INT_PART downto WORD_FRAC_PART)
        
    );
end fir_transpose_slice;

------------------
-- Architecture --
------------------

architecture behavioral of fir_transpose_slice is


    ---------------
    -- Constants --
    ---------------

    -------------
    -- Signals --
    -------------

    -- Weight logic
    signal weight                           : sfixed(WEIGHT_INT_PART downto WEIGHT_FRAC_PART);

    -- Downside Logic
    signal pipeline_mult                    : sfixed(WEIGHT_INT_PART downto WEIGHT_FRAC_PART);
    signal pipeline_add_mult                : sfixed(WORD_INT_PART downto WORD_FRAC_PART);
    signal pipeline_out_data                : sfixed(WORD_INT_PART downto WORD_FRAC_PART);

    signal sideband_data_reg                : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        
begin

    weight_reg : process(clock_i)
    begin
        if (rising_edge(clock_i)) then
            if (weight_valid_i = '1') then
                weight   <= weight_data_i;
            end if; 
        end if;
    end process;

    pipeline_mult       <= resize(sample_data_i * weight , pipeline_mult);
    pipeline_add_mult   <= resize(pipeline_mult + pipeline_data_i , pipeline_add_mult);

    pipeline_logic : process(clock_i)
    begin
        if (rising_edge(clock_i)) then
            if (fir_valid_i = '1') then
                pipeline_out_data   <= pipeline_add_mult;
            end if; 
        end if;
    end process;

    ------------------------------------------------------------------
    --                    Sinal Sideband                            
    --                                                                
    --   Goal: Aplicar sobre o sinal sideband o mesmo delay que os sinais de
    --         de entrada sofrem. 
    --
    --   Clock & reset domain: clock_i & sem reset
    --
    --
    --   Input: fir_valid_i;
    --          sideband_data_i
    --
    --   Output: sideband_data_reg
    --
    --   Result: O sinal é atrasado igual as entradas, podendo ser usado
    --           para sincroninzar qualquer sinal com o pipeline do CORDIC
    --           sem precisar de lógica externa.  
    ------------------------------------------------------------------
    sideband_proc : process(clock_i)
    begin
        if ( rising_edge(clock_i) )then
            sideband_data_reg <= sideband_data_i;
        end if;
    end process;
    
    ------------
    -- Output --
    ------------
    
    pipeline_data_o     <= pipeline_out_data;
    sideband_data_o     <= sideband_data_reg;
    
end behavioral;

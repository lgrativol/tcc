---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: 21/11/2020                                                                
-- Module Name: fir_direct_slice                                                                
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

entity fir_direct_slice is
    generic(
        WEIGHT                          : std_logic_vector;
        WEIGTH_INT_PART                 : natural;
        WEIGTH_FRAC_PART                : integer;
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
        
        --Input
        upside_valid_i                  : in  std_logic; 
        upside_data_i                   : in  sfixed(WORD_INT_PART downto WORD_FRAC_PART);
        downside_valid_i                : in  std_logic; 
        downside_data_i                 : in  sfixed(WORD_INT_PART downto WORD_FRAC_PART);
    
        -- Ouput 
        upside_valid_o                  : out std_logic; 
        upside_data_o                   : out sfixed(WORD_INT_PART downto WORD_FRAC_PART);   
        downside_valid_o                : out std_logic; 
        downside_data_o                 : out sfixed(WORD_INT_PART downto WORD_FRAC_PART)
        
    );
end fir_direct_slice;

------------------
-- Architecture --
------------------

architecture behavioral of fir_direct_slice is


    ---------------
    -- Constants --
    ---------------

    -- Weight
    constant SFIXED_WEIGHT                  : sfixed(WEIGTH_INT_PART downto WEIGTH_FRAC_PART) := to_sfixed(WEIGHT,WEIGTH_INT_PART,WEIGTH_FRAC_PART);

    -------------
    -- Signals --
    -------------

    -- Upside Logic
    signal upside_inter_valid               : std_logic;
    signal upside_inter_data                : sfixed(WORD_INT_PART downto WORD_FRAC_PART);
    signal upside_out_valid                 : std_logic;
    signal upside_out_data                  : sfixed(WORD_INT_PART downto WORD_FRAC_PART);
    
    -- Downside Logic
    signal downside_mult                    : sfixed(WEIGTH_INT_PART downto WEIGTH_FRAC_PART);
    signal downside_add_mult                : sfixed(WORD_INT_PART downto WORD_FRAC_PART);
    signal downside_out_valid               : std_logic;
    signal downside_out_data                : sfixed(WORD_INT_PART downto WORD_FRAC_PART);

    signal sideband_data_reg                : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        
begin


    upside_logic1 : process(clock_i, areset_i)
    begin
        if (areset_i = '1') then
            upside_inter_valid <= '0';
        elsif (rising_edge(clock_i)) then
            upside_inter_valid  <=  upside_valid_i;

            if (upside_valid_i = '1') then
                upside_inter_data   <= upside_data_i;
            end if; 
        end if;
    end process;

    upside_logic2 : process(clock_i, areset_i)
    begin
        if (areset_i = '1') then
            upside_out_valid <= '0';
        elsif (rising_edge(clock_i)) then
            upside_out_valid  <=  upside_inter_valid;

            if (upside_inter_valid = '1') then
                upside_out_data   <= upside_inter_data;
            end if; 
        end if;
    end process;

    downside_mult       <= resize(upside_data_i * SFIXED_WEIGHT , downside_mult);
    downside_add_mult   <= resize(downside_mult + downside_data_i , downside_add_mult);

    downside_logic : process(clock_i, areset_i)
    begin
        if (areset_i = '1') then
            downside_out_valid <= '0';
        elsif (rising_edge(clock_i)) then
            downside_out_valid  <=  downside_valid_i;

            if (downside_valid_i = '1') then
                downside_out_data   <= downside_add_mult;
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
    --   Input: downside_valid_i;
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
            if (downside_valid_i = '1') then 
                sideband_data_reg <= sideband_data_i;
            end if;
        end if;
    end process;
    
    ------------
    -- Output --
    ------------
    
    upside_valid_o      <= upside_out_valid;
    upside_data_o       <= upside_out_data;
    downside_valid_o    <= downside_out_valid;
    downside_data_o     <= downside_out_data;
    sideband_data_o     <= sideband_data_reg;
    
end behavioral;

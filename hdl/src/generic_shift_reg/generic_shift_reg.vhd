---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Agosto/2020                                                                
-- Module Name: generic_shift_reg                                                                
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date: 24/11/2020                                                     
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Instanciar um shift-register genérico
--          
-- Description: Serve de entidade para construção de shift-registers genéricos
--              usado para sincronizar pipelines
---------------------------------------------------------------------------------------------

---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------
-- Entity --
------------

entity generic_shift_reg is
    generic (
        WORD_WIDTH                          : positive; -- Tamanho em bits da palavra de entrada
        SHIFT_SIZE                          : integer; -- Tamanho do shift, quantos registros no shift-register
        SIDEBAND_WIDTH                      : natural  -- Tamanho em bits do sideband
    );
    port (
        -- Clock interface
        clock_i                             : in  std_logic; -- Clock
        areset_i                            : in  std_logic; -- Positive async reset
        -- Input interface
        valid_i                             : in  std_logic; -- Valid in
        input_data_i                        : in  std_logic_vector((WORD_WIDTH - 1) downto 0); -- Data
        sideband_data_i                     : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0); -- Sideband data
        
        -- Output interface
        valid_o                             : out std_logic; -- Valid out
        output_data_o                       : out std_logic_vector((WORD_WIDTH - 1) downto 0); -- Data
        sideband_data_o                     : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0) -- Sideband data
    );
end generic_shift_reg;

------------------
-- Architecture --
------------------
architecture behavioral of generic_shift_reg is

    -----------
    -- Types --
    -----------

    type t_shift_reg_valid      is array (integer range <>) of std_logic;
    type t_shift_reg_data       is array (integer range <>) of std_logic_vector((WORD_WIDTH - 1) downto 0);
    type t_shift_reg_sideband   is array (integer range <>) of std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    -------------
    -- Signals --
    -------------
    
    -- Stage 0
    signal      valid_in                        : std_logic;
    signal      input_data                      : std_logic_vector((WORD_WIDTH - 1) downto 0);
    signal      sideband_data_in                : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    signal      enable_shift                    : std_logic;

    -- Stage 1

    signal      shift_reg_valid                 : t_shift_reg_valid     (0 to (SHIFT_SIZE - 1));
    signal      shift_reg_data                  : t_shift_reg_data      (0 to (SHIFT_SIZE - 1));
    signal      shift_reg_sideband              : t_shift_reg_sideband  (0 to (SHIFT_SIZE - 1));

begin


    -------------
    -- Stage 0 --
    -------------
    
    valid_in          <=valid_i;
    input_data        <=input_data_i;
    sideband_data_in  <=sideband_data_i;

    NO_SHIFT_GEN: 
        if (SHIFT_SIZE <= 0) generate

            ------------
            -- Output --
            ------------

            valid_o         <= valid_in;
            output_data_o   <= input_data;
            sideband_data_o <= sideband_data_in;

        end generate NO_SHIFT_GEN;

    SHIFT_GEN: 
        if (SHIFT_SIZE > 0) generate    

            --------------
            -- Stage 1  --
            --------------
            enable_shift    <=          valid_in
                                    or  shift_reg_valid     (SHIFT_SIZE - 1);

            shift_reg_proc : process(clock_i,areset_i)
            begin
                if(areset_i ='1') then
                    shift_reg_valid    <= (others=>'0');

                elsif(rising_edge(clock_i)) then

                    shift_reg_valid(0)    <= valid_in;

                    for index in 1 to  (SHIFT_SIZE - 1) loop

                        shift_reg_valid(index)    <= shift_reg_valid(index - 1) ;
                    end loop;

                    --if (enable_shift = '1') then

                        shift_reg_data(0)       <= input_data;    
                        shift_reg_sideband(0)   <= sideband_data_in;    

                        for index in 1 to  (SHIFT_SIZE - 1) loop

                            shift_reg_data(index)       <= shift_reg_data(index - 1) ;
                            shift_reg_sideband(index)   <= shift_reg_sideband(index - 1) ;
                        end loop;    
                    --end if;
                end if;
            end process;
            

            ------------
            -- Output --
            ------------
            valid_o             <= shift_reg_valid     (SHIFT_SIZE - 1);
            output_data_o       <= shift_reg_data     (SHIFT_SIZE - 1);
            sideband_data_o     <= shift_reg_sideband (SHIFT_SIZE - 1);

        end generate SHIFT_GEN;

    end behavioral;

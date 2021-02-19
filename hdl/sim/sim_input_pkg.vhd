---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Novembro/2020                                                                                                                      
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                                                                                  
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Pacote usado como "interface" entre o python e o simulador VHDL. 
-- Description: Parâmetros são ajustados no script em python e esse arquivo
--              é reescrito com os valores para o simulador.
---------------------------------------------------------------------------------------------


---------------
-- Libraries --
---------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.utils_pkg.all;
use work.defs_pkg.all;

package sim_input_pkg is
   -- DDS
   constant SIM_INPUT_PHASE_TERM     : std_logic_vector((PHASE_WIDTH - 1) downto 0) := x"004056fe";
   constant SIM_INPUT_WIN_TERM       : std_logic_vector((PHASE_WIDTH - 1) downto 0) := x"00066f19";
   constant SIM_INPUT_INIT_PHASE     : std_logic_vector((PHASE_WIDTH - 1) downto 0) := x"00000000";
   constant SIM_INPUT_WIN_MODE       : string    := "NONE";
   constant SIM_INPUT_NBPOINTS       : natural   := 200;
   constant SIM_INPUT_NBREPET        : natural   := 1;
   constant SIM_INPUT_MODE_TIME      : std_logic := '0';
   
   -- Double Driver
   constant SIM_INPUT_TX_TIME        : positive  := 2000;
   constant SIM_INPUT_TX_OFF_TIME    : positive  := 300;
   constant SIM_INPUT_RX_TIME        : positive  := 300;
   constant SIM_INPUT_OFF_TIME       : positive  := 100;
end sim_input_pkg;

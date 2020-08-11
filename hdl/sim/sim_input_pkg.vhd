library ieee;
use ieee.std_logic_1164.all;

library work;
use work.utils_pkg.all;

package sim_input_pkg is
   constant SIM_INPUT_TARGETFREQ     : positive  := 500000;
   constant SIM_INPUT_NBCYCLES       : natural   := 10;
   constant SIM_INPUT_PHASE_DIFF     : std_logic_vector((PHASE_WIDTH - 1) downto 0) := x"0c90fdaa22";
   constant SIM_INPUT_TX_TIME        : positive  := 2000;
   constant SIM_INPUT_TX_OFF_TIME    : positive  := 300;
   constant SIM_INPUT_RX_TIME        : positive  := 10000;
   constant SIM_INPUT_OFF_TIME       : positive  := 100;
end sim_input_pkg;

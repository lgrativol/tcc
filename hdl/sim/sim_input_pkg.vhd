library ieee;
use ieee.std_logic_1164.all;

package sim_input_pkg is
   constant SIM_INPUT_TARGETFREQ     : positive  := 500000;
   constant SIM_INPUT_NBCYCLES       : natural   := 10;
   constant SIM_INPUT_TX_TIME        : positive  := 2000;
   constant SIM_INPUT_TX__OFF_TIME   : positive  := 30;
   constant SIM_INPUT_RX_TIME        : positive  := 2000;
   constant SIM_INPUT_OFF_TIME       : positive  := 20;
end sim_input_pkg;

---------------
-- Libraries --
---------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fir_weights_pkg is

    ---------------
    -- Constants --
    ---------------
    
    -- Definitions
    constant WEIGHT_WIDTH     : positive  := 12;
    constant WEIGHT_INT_PART  : positive  := 1;
    constant WEIGHT_FRAC_PART : integer   := (WEIGHT_INT_PART + 1) - WEIGHT_WIDTH;   -- int. negative
    
    constant NB_TAPS           : positive  := 10; 

    -- Weights
    type fir_weights_tp    is array (natural range <>) of std_logic_vector( (WEIGHT_WIDTH - 1) downto 0 );
    
    constant FIR_WEIGHTS                   : fir_weights_tp(0 to (NB_TAPS - 1)) := (    x"002",
                                                                                        x"100",
                                                                                        x"320",
                                                                                        x"AFE",
                                                                                        x"AFE",
                                                                                        x"AFE",
                                                                                        x"AFE",
                                                                                        x"AFE",
                                                                                        x"004",
                                                                                        x"320" 
                                                                                    );    
    
end fir_weights_pkg;
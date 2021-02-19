---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Novembro/2020                                                                                                                      
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                                                                                  
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Pacotes com todas as definições usadas no projeto (TCC)
--
--
---------------------------------------------------------------------------------------------


---------------
-- Libraries --
---------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ieee_proposed;                      
use ieee_proposed.fixed_float_types.all; 
use ieee_proposed.fixed_pkg.all;    

library work;
use work.utils_pkg.all;

package defs_pkg is

    ---------------
    -- Constants --
    ---------------
    
    -- Phase accumulator phase 
    constant PHASE_INTEGER_PART     : natural  := 4; 
    constant PHASE_FRAC_PART        : integer  := -27; 
    constant PHASE_WIDTH            : positive := PHASE_INTEGER_PART + (-PHASE_FRAC_PART) + 1;

    constant PI_INTEGER_PART        : integer  := 4; 
    constant PI_FRAC_PART           : integer  := -27;

    constant PI                     : ufixed(PI_INTEGER_PART downto PI_FRAC_PART) := to_ufixed(MATH_PI, PI_INTEGER_PART,PI_FRAC_PART);

    constant NB_POINTS_WIDTH        : positive := 10;
    constant NB_REPT_WIDTH          : positive := 10;
    constant NB_SHOTS_WIDTH         : positive := 6; -- FIX (see averager_v2.vhd)
    constant NB_PERIODS_WIDTH       : positive := 10;

    -- Cordic
    constant CORDIC_INTEGER_PART    : natural  := 1;
    constant N_CORDIC_ITERATIONS    : natural  := 10;
    constant CORDIC_FRAC_PART       : integer  := -(N_CORDIC_ITERATIONS - (CORDIC_INTEGER_PART + 1));

    -- Time zones
    constant  DELAY_TIME_WIDTH      : positive := 18; -- Max time = 2.62 ms
    constant  TX_TIME_WIDTH         : positive := 18; -- Max time = 2.62 ms
    constant  DEADZONE_TIME_WIDTH   : positive := 18; -- Max time = 2.62 ms
    constant  RX_TIME_WIDTH         : positive := 18; -- Max time = 2.62 ms
    constant  IDLE_TIME_WIDTH       : positive := 18; -- Max time = 2.62 ms

    -- Pulser
    constant  TIMER_WIDTH           : positive := 10;

    --Averager
    constant  AVG_MAX_NB_POINTS     : natural := 65536;
    constant  WAVE_NB_POINTS_WIDTH  : natural := ceil_log2(AVG_MAX_NB_POINTS + 1);

    --DDS CORDIC WIN
    constant  WIN_INTEGER_PART      : natural   := CORDIC_INTEGER_PART;
    constant  WIN_NB_ITERATIONS     : positive  := N_CORDIC_ITERATIONS;
    constant  WIN_FRAC_PART         : integer   := CORDIC_FRAC_PART;

    -- Upsampler/Downsampler
    constant  NB_TAPS               : positive := 10;
    constant  WEIGHT_WIDTH          : positive := 10;
    constant  DOWN_MAX_FACTOR       : positive := 10;
    constant  DOWN_MAX_FACTOR_WIDTH : positive := ceil_log2(DOWN_MAX_FACTOR + 1);
    constant  UP_MAX_FACTOR         : positive := 10;
    constant  UP_MAX_FACTOR_WIDTH   : positive := ceil_log2(UP_MAX_FACTOR + 1);
    constant  DOWN_FIR_TYPE         : string := "DIREC";
    constant  UP_FIR_TYPE           : string := "DIREC";

    --Wave Generator
    constant  OUTPUT_WIDTH          : positive := N_CORDIC_ITERATIONS;

    --AXI-STREAM
    constant AXI_ADDR_WIDTH         : positive                      := 32;  
    constant BASEADDR               : std_logic_vector(31 downto 0) := x"00000000";

end defs_pkg;

---------------
-- Libraries --
---------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
--use ieee.fixed_float_types.all; -- only synthesis
--use ieee.fixed_pkg.all;         -- only synthesis

library ieee_proposed;                      -- only simulation
use ieee_proposed.fixed_float_types.all;    -- only simulation
use ieee_proposed.fixed_pkg.all;            -- only simulation


package utils_pkg is

    ---------------
    -- Functions --
    ---------------

    --------------------------------------------------------------------------------------
    -- Combine the ceil and log2 functions.  ceil_log2(x) then gives the minimum number --
    -- of bits required to represent 'x'.  ceil_log2(4) = 2, ceil_log2(5) = 3, etc.     --
    --------------------------------------------------------------------------------------
    function ceil_log2 (arg : positive) return natural;

    ---------------
    -- Constants --
    ---------------

    -- Obs.: Using the fixed_pkg
    constant PI_INTEGER_PART        : integer := 2;
    constant PI_FRAC_PART           : integer := -30;
    constant PI                     : ufixed(PI_INTEGER_PART downto PI_FRAC_PART) := to_ufixed(MATH_PI, PI_INTEGER_PART,PI_FRAC_PART);
                             
end utils_pkg;

package body utils_pkg is
    ---------------
    -- Functions --
    ---------------
    --------------------------------------------------------------------------------------
    -- Combine the ceil and log2 functions.  ceil_log2(x) then gives the minimum number --
    -- of bits required to represent 'x'.  ceil_log2(4) = 2, ceil_log2(5) = 3, etc.     --
    --------------------------------------------------------------------------------------
    function ceil_log2 (
                arg : positive
            ) 
    return natural is
        -- Internal variables
        variable temp               : natural;
        variable return_value, log  : natural;
    begin
        temp             := arg;
        return_value     := 0; 

        while (temp /= 0) loop
            temp          := temp / 2;
            return_value  := return_value + 1;
        end loop;

        if (arg > (2**return_value)) then
            return(return_value + 1); -- return_value is too small, so bump it up by 1 and return
        else
            return(return_value); -- Just right
        end if;
    end function ceil_log2;
end utils_pkg;

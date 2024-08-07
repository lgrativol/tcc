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

package utils_pkg is

    ---------------
    -- Functions --
    ---------------

    function ceil_log2 (arg : positive)  return natural;    

    function to_hexchar(usgd : unsigned) return character;

    function to_hexstring(slv : std_logic_vector) return string;

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


    --------------------------------------------------------------
    -- Convert an unsigned value (4 bit) to                     --
    -- a HEX digit (0-F)                                        --
    --------------------------------------------------------------
    function to_hexchar(
            usgd : unsigned
        ) 
    return character is

        constant    HEX             : string    := "0123456789ABCDEF";

    begin
        if (usgd < 16) then
            return HEX(to_integer(usgd) + 1);
        else
            return 'X'; 
        end if;
    end function;

    -------------------------------------------------------------
    -- Convert an std_logic_vector to   HEX digit (0-F)        --
    -------------------------------------------------------------
    function to_hexstring(
            slv : std_logic_vector
        ) 
    return string is
        
        constant    VECTOR_WIDTH        : positive  := slv'length;
        constant    WORD_SIZE           : positive  := ( (VECTOR_WIDTH / 4) + 1);
        constant    WORD_WIDTH          : positive  := ( 4 * WORD_SIZE ); 
        constant    VALUE               : unsigned( (WORD_WIDTH - 1) downto 0) := resize(unsigned(slv), WORD_WIDTH);
        
        variable    digit               : unsigned(3 downto 0);
        variable    result              : string(1 to WORD_SIZE);
        variable    j                   : natural;

    begin
        j             := 0;
        for i in result'reverse_range loop
            digit       := VALUE( ( j * 4)  + 3 downto ( j * 4 ) );
            result(i)   := to_hexchar(digit);
            j           := j + 1;
        end loop;

        return result;
    end function;
      
end utils_pkg;

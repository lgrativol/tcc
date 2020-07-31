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

------------
-- Entity --
------------

entity cordic_slice is
    generic(
        CORDIC_INTEGER_PART             : integer; -- sfixed integer part;    ex: sfixed(0 downto -19) --> 0.1111111111111111111 ~ +1.000 
        CORDIC_FRAC_PART                : integer; -- sfixed fractional part; ex: sfixed(0 downto -19) --> 1.1010000000000000000 = -0.750
        N_CORDIC_ITERATIONS             : natural  -- number of cordic iterations
    );
    port(
        -- Clock interface
        clock_i                         : in  std_logic;
        areset_i                        : in  std_logic; -- high async reset
        
        -- Control interface
        enable_i                        : in  std_logic; -- Hold signal
        strb_i                          : in  std_logic; -- Data valid in
        strb_o                          : out std_logic; -- Data valid out
        
        -- Rotational angle values
        shift_value_i                   : in  integer range 0 to N_CORDIC_ITERATIONS; -- TODO: move to generic
        current_rotation_angle          : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); --TODO: move to internal room
        
        --Input vector + angle
        X_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Y_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Z_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

        -- Ouput vector + angle
        X_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Y_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Z_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART)
    );
end cordic_slice;

------------------
-- Architecture --
------------------

architecture Behavioral of cordic_slice is

    -------------
    -- Signals --
    -------------
    signal X                                : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); 
    signal Y                                : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal Z                                : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); 
    signal strb_r                           : std_logic;
        
begin
    --TODO: Improve comment
    ------------------------------------------------------------------
    --       Cordic algorithm to generate sine(Y) and cos(X)        --
    --                                                              --
    --   Objective: Rotate angle(Z_0) to zero                       --
    --              Using vector = (1/A_N ; 0)                      --
    --                                                              --
    --   Result        : X_N -> (1)*cossine(Z_0)                    --
    --                   Y_N -> (1)*sine(Z_0)                       --
    --                                                              --
    --   A_N : Cordic factor                                        --
    --                                                              --
    ------------------------------------------------------------------
    cordic_register : process(clock_i, areset_i)
    begin
        if (areset_i = '1') then
            strb_r <= '0';
        elsif (rising_edge(clock_i)) then
            strb_r  <=  strb_i;

            if (strb_i = '1' and enable_i = '1') then 
                -- Testing Angle sign
                if (Z_i > 0) then -- Z>0, needs to rotatate clockwise (Z - current_rotation_angle)
                    X <= resize(X_i - (Y_i sra shift_value_i), CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                    Y <= resize(Y_i + (X_i sra shift_value_i), CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                    Z <= resize(Z_i - current_rotation_angle,  CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                elsif (Z_i < 0) then -- Z>0, needs to rotatate anticlockwise (Z + current_rotation_angle)
                    X <= resize(X_i + (Y_i sra shift_value_i), CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                    Y <= resize(Y_i - (X_i sra shift_value_i), CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                    Z <= resize(Z_i + current_rotation_angle,  CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                else -- When Z= 0, nothing needs to be done
                    X <= X_i;
                    Y <= Y_i;
                    Z <= Z_i;
                end if;
            end if;
        end if;        
    end process;
    
    ------------
    -- Output --
    ------------
    X_o <= X;
    Y_o <= Y;
    Z_o <= Z;
    strb_o <= strb_r;

end Behavioral;

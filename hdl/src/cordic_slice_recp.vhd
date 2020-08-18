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

entity cordic_slice_recp is
    generic(
        SIDEBAND_WIDTH                  : integer;
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

        sideband_data_i                 : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        sideband_data_o                 : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        
        -- Rotational angle values
        shift_value_i                   : in  integer range 0 to N_CORDIC_ITERATIONS; -- TODO: move to generic
        
        --Input vector + angle
        X_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Y_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Z_i                             : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

        -- Ouput vector + angle
        X_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Y_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Z_o                             : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART)
    );
end cordic_slice_recp;

------------------
-- Architecture --
------------------

architecture Behavioral of cordic_slice_recp is

    ---------------
    -- Constants --
    ---------------

    constant ONE_CTE                        : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART) := to_sfixed(real(1),CORDIC_INTEGER_PART,CORDIC_FRAC_PART);

    -------------
    -- Signals --
    -------------
    signal X                                : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); 
    signal Y                                : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal Z                                : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART); 
    signal strb_r                           : std_logic;

    signal sideband_data_reg                : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        
begin
    

    --TODO: Improve comment
    ------------------------------------------------------------------
    --       Cordic algorithm to generate  z= x/y                   --
    --                                                              --
    --   Objective:                                                 --
    --                                                              --
    --                                                              --
    --   Result                                                     --
    --                                                              --
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
                if (X_i > 0) then -- Z>0, needs to rotatate clockwise (Z - current_rotation_angle)
                    X <= resize(X_i - (Y_i sra shift_value_i), CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                    Y <=Y_i;
                    Z <= resize(Z_i + (ONE_CTE sra shift_value_i),  CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                elsif (X_i < 0) then -- Z>0, needs to rotatate anticlockwise (Z + current_rotation_angle)
                    X <= resize(X_i + (Y_i sra shift_value_i), CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                    Y <=Y_i;
                    Z <= resize(Z_i - (ONE_CTE sra shift_value_i),  CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
                else -- When Z= 0, nothing needs to be done
                    X <= X_i;
                    Y <= Y_i;
                    Z <= Z_i;
                end if;
            end if;
        end if;        
    end process;

    sideband_proc : process(clock_i)
    begin
        if ( rising_edge(clock_i) )then
            if (strb_i = '1' and enable_i = '1') then 
                sideband_data_reg <= sideband_data_i;
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
    sideband_data_o <= sideband_data_reg;
    
end Behavioral;

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

entity cordic_core is
    generic(
        CORDIC_INTEGER_PART                 : natural :=   0;
        CORDIC_FRAC_PART                    : integer := -19;
        N_CORDIC_ITERATIONS                 : natural :=  20 
    );
    port(
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset
        
        strb_i                              : in  std_logic; -- Valid in
        strb_o                              : out std_logic; -- Valid out
        
        X_i                                 : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Y_i                                 : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Z_i                                 : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

        X_o                                 : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Y_o                                 : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        Z_o                                 : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART)
    );
end cordic_core;

------------------
-- Architecture --
------------------
architecture behavioral of cordic_core is
    
    ---------------
    -- Component --
    ---------------
    component cordic_slice
        generic(
            CORDIC_INTEGER_PART             : integer; -- sfixed integer part 
            CORDIC_FRAC_PART                : integer; -- sfixed fractional part
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
    end component;
  
    -----------
    -- Types --
    -----------
    type sfixed_connecting_array is array (0 to N_CORDIC_ITERATIONS) of sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    type rotation_angles_type is array (0 to N_CORDIC_ITERATIONS-1) of sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    
    ---------------
    -- Functions --
    ---------------

    function GenerateRotationAngles(N_ITERATIONS : natural)
                                    return rotation_angles_type is
        variable RotationVector : rotation_angles_type;
    begin
        for I in 0 to N_ITERATIONS-1 loop
            RotationVector(I) := to_sfixed(arctan(2.0 ** real(-I)), CORDIC_INTEGER_PART, CORDIC_FRAC_PART); --Internal rotation angles( 2^(-I), I -> Cordic stage index)
        end loop;
        return RotationVector;
    end function;
    
    ---------------
    -- Constants --
    ---------------
    constant all_rotation_angles            : rotation_angles_type := GenerateRotationAngles(N_CORDIC_ITERATIONS);
    
    -------------
    -- Signals --
    -------------
    -- Cordic-slices vectors
    signal X_vector                         : sfixed_connecting_array; -- X coordinate
    signal Y_vector                         : sfixed_connecting_array; -- Y coordinate
    signal Z_vector                         : sfixed_connecting_array; -- Z angle
    signal strb                             : std_logic_vector(0 to N_CORDIC_ITERATIONS) := (others => '0'); -- Data_valid vector, used in "for generate" to connect
    
    
begin
    -----------
    -- Input --
    -----------
    X_vector(0) <= X_i; 
    Y_vector(0) <= Y_i;
    Z_vector(0) <= Z_i;
    strb(0)     <= strb_i;

    -----------------------------
    -- Cordic slices instances --
    -----------------------------

    cordic_array : for cordic_index in 0 to (N_CORDIC_ITERATIONS - 1) generate
        cordic_element : cordic_slice
            generic map(
                CORDIC_INTEGER_PART    => CORDIC_INTEGER_PART,
                CORDIC_FRAC_PART       => CORDIC_FRAC_PART,
                N_CORDIC_ITERATIONS    => N_CORDIC_ITERATIONS
            )
            port map(
                -- Clock interface
                clock_i                => clock_i,
                areset_i               => areset_i,

                -- Control interface
                enable_i               => '1',
                strb_i                 => strb(cordic_index),
                strb_o                 => strb(cordic_index+1),

                -- Rotational angle values
                shift_value_i          => cordic_index,
                current_rotation_angle => all_rotation_angles(cordic_index),
                
                --Input vector + angle
                X_i                    => X_vector(cordic_index),
                Y_i                    => Y_vector(cordic_index),
                Z_i                    => Z_vector(cordic_index),
                
                --Output vector + angle                
                X_o                    => X_vector(cordic_index+1),
                Y_o                    => Y_vector(cordic_index+1),
                Z_o                    => Z_vector(cordic_index+1)
            );    
    end generate;

    ------------
    -- Output --
    ------------
    X_o         <= X_vector(N_CORDIC_ITERATIONS);
    Y_o         <= Y_vector(N_CORDIC_ITERATIONS);
    Z_o         <= Z_vector(N_CORDIC_ITERATIONS);
    strb_o      <= strb(N_CORDIC_ITERATIONS);
    
end behavioral;

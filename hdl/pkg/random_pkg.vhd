-----------------------------  =  ----------------------------------
-- random_pkg.vhd - Random number generation (VHDL-93 version)
-- Adapted from :Freely available from VHDL-extras (http://github.com/kevinpt/vhdl-extras)
--
-- DESCRIPTION:
--  This package provides a general set of pseudo-random number functions.
--  It is implemented as a wrapper around the ieee.math_real.uniform
--  procedure and is only suitable for simulation not synthesis. See the
--  LCAR and LFSR packages for synthesizable random generators.
--
--  This package makes use of shared variables to keep track of the PRNG
--  state more conveniently than calling uniform directly. 
--  ATTETION :VHDL-2002 broke forward compatability of shared variables.
--
-- EXAMPLE USAGE:
--   seed(12345);    -- Initialize PRNG with a seed value
--   seed(123, 456); -- Alternate seed procedure
--
--   variable : r : real    := random; -- Generate a random real
--   variable : n : natural := random; -- Generate a random natural
--   variable : b : boolean := random; -- Generate a random boolean
--   -- Generate a random std_logic_vector of any size
--   variable : bv : std_logic_vector(99 downto 0) := random(100);
--
--   -- Generate a random integer within a specified range
--   -- Number between 2 and 10 inclusive
--   variable : i : natural := randint(2, 10);
--------------------------------------------------------------------

---------------
-- Libraries --
---------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-------------
-- Package --
-------------

package random_pkg is

    procedure seed(s : in positive);
    --## seed the prng with a number.
    --# args:
    --#  s:  seed value

    procedure seed(s1, s2 : in positive);
    --## seed the prng with s1 and s2. this offers more
    --#  random initialization than the one argument version
    --#  of seed.
    --# args:
    --#  s1:  seed value 1
    --#  s2:  seed value 2

    impure function random return real;
    --## generate a random real.
    --# returns:
    --#  random value.

    impure function random return natural;
    --## generate a random natural.
    --# returns:
    --#  random value.

    impure function random return boolean;
    --## generate a random boolean.
    --# returns:
    --#  random value.

    impure function random return character;
    --## generate a random character.
    --# returns:
    --#  random value.

    impure function random(size : positive) return std_logic_vector;
    --## generate a random std_logic_vector of size bits.
    --# args:
    --#  size: length of the random result
    --# returns:
    --#  random value.

    impure function randint(min, max : integer) return integer;
    --## generate a random integer between min and max inclusive.
    --#  note that the span max - min must be less than integer'high.
    --# args:
    --#  min: minimum value
    --#  max: maximum value
    --# returns:
    --#  random value between min and max.

    impure function random_exp(mean : real) return real;
    --## generate a random exponential real.
    --# args:
    --#  mean : 1/lambda (exp. parameter)
    --# returns:
    --#  random value.

    impure function random(min,max : real) return real;
    --## generate a random real number between [min;max].
    --# args:
    --#  min : lower value
    --#  max : upper value
    --# returns:
    --#  random value.

    impure function randn return real;
    --## generate a normal distribution using Box Müller transform (0;1)
    --# args: 
    --# returns:
    --#  random value.

    impure function randn(mean,sigma : real) return real;
    --## generate a normal distribution using Box Müller transform (mean;sigma)
    --# args: 
    --# mean : gaussian mean
    --# sigma : gaussian standard deviation
    --# returns:
    --#  random value.

end package;

------------------
-- Package Body --
------------------

package body random_pkg is

    shared variable seed1 : positive;
    shared variable seed2 : positive;

    procedure seed(s : in positive) is
    begin
        seed1 := s;
        if (s > 1) then
            seed2 := s - 1;
        else
            seed2 := s + 42; -- random number, easter-egg reasons
        end if;
    end procedure;

    procedure seed(s1, s2 : in positive) is
    begin
        seed1 := s1;
        seed2 := s2;
    end procedure;

    impure function random 
    return real is
        variable result : real;
    begin
        uniform(seed1, seed2, result);
        return result;
    end function;

    impure function randint(min, max : integer) 
    return integer is
    begin
        return integer(trunc(real(max - min + 1) * random)) + min;
    end function;

    impure function random 
    return natural is
    begin
        return natural(trunc(real(natural'high) * random));
    end function;

    impure function random 
    return boolean is
    begin
        return randint(0, 1) = 1;
    end function;

    impure function random 
    return character is
    begin
        return character'val(randint(0, 255));
    end function;

    impure function random(size : positive) 
    return std_logic_vector is
        -- Populate vector in 30-bit chunks to avoid exceeding the
        -- range of integer
        constant SEG_SIZE  : natural := 30;
        constant SEGMENTS  : natural := size / SEG_SIZE;
        constant REMAINDER : natural := size - SEGMENTS * SEG_SIZE;

        variable result : std_logic_vector( (size - 1) downto 0);
    begin
        if (SEGMENTS > 0) then
            for s in 0 to (SEGMENTS - 1) loop
                result( (((s + 1) * SEG_SIZE) - 1) downto (s * SEG_SIZE)) := std_logic_vector(to_unsigned(randint(0, (2**(SEG_SIZE - 1))), SEG_SIZE));
            end loop;
        end if;

        if (REMAINDER > 0) then
            result( (size - 1) downto (size - REMAINDER)) := std_logic_vector(to_unsigned(randint(0, (2**(REMAINDER - 1))), REMAINDER));
        end if;

        return result;
    end function;

    impure function random_exp(mean : real) 
    return real is
        variable random_real    : real;
    begin
        random_real := random;
        return - ( log( random_real ) * mean);
    end function;

    impure function random(min,max : real) 
    return real is
        variable result : real;
    begin
        uniform(seed1, seed2, result);
        return (result*(max - min) + min);
    end function;

    impure function randn 
    return real is
        variable u1 : real;
        variable u2 : real;
    begin
        u1 := random;
        u2 := random;
        -- sqrt(-2*ln(u1)) * cos(2pi*u2)
        return ( sqrt((-2.0*log( u1 ))) * cos(MATH_2_PI * u2));
    end function;

    --## generate a normal distribution using Box Müller transform (0;1)
    --# args: 
    --# returns:
    --#  random value.

    impure function randn(mean,sigma : real)
    return real is
    begin
        return ((randn*sigma) + mean);
    end function;


end package body;
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

library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity frequency_definer is
    generic(
        SAMPLING_FREQUENCY                 : positive := 100E6; -- 100 MHz
        FREQUENCY_WIDTH                    : positive := 27; --  log2(100 MHz)
        --NB_STEPS_CYCLE_WIDTH               : positive :=  13; -- For the worst case (100 MHz / 20 KHz) = 5000
        PHASE_INTEGER_PART                 : natural  :=   2;
        PHASE_FRAC_PART                    : integer  := -30 -- PI precision
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset
        
        strb_frequency_i                    : in  std_logic; -- Valid in
        target_frequency_i                  : in  std_logic_vector((FREQUENCY_WIDTH - 1) downto 0);

        -- Output interface
        strb_delta_o                        : out std_logic;
        delta_phase_o                       : out ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART)
        --nb_steps_to_full_cycle_o            : out std_logic_vector((NB_STEPS_CYCLE_WIDTH - 1) downto 0)
    );
end frequency_definer;

------------------
-- Architecture --
------------------

architecture behavioral of frequency_definer is

    ---------------
    -- Constants --
    ---------------
    constant        DELTA_PHASE_FACTOR_INTEGER_PART     : integer                                           := PHASE_INTEGER_PART;
    constant        DELTA_PHASE_FACTOR_FRAC_PART        : integer                                           := PHASE_FRAC_PART;
    
    -- delta_phase        = delta_phase_factor * target_frequency
    -- delta_phase_factor = (2 * Pi * (1/sampling_frequency))    
    constant        DELTA_PHASE_FACTOR                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( ((2.0 * PI) * (1.0/real(SAMPLING_FREQUENCY))),PHASE_INTEGER_PART,PHASE_FRAC_PART);

    -------------
    -- Signals --
    -------------
    
    -- Input interface
    signal target_frequency                 : std_logic_vector((FREQUENCY_WIDTH - 1) downto 0);

    -- Output interface
    signal strb_reg                         : std_logic;
    signal delta_phase_reg                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    --signal nb_steps_to_full_cycle_reg       : std_logic_vector((NB_STEPS_CYCLE_WIDTH - 1) downto 0)
    

begin

    -- Input
    target_frequency <= target_frequency_i;


    delta_phase_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_reg <= '0';

        elsif (rising_edge(clock_i) ) then                       
            strb_reg <= strb_frequency_i;

            if (strb_frequency_i = '1') then
                delta_phase_reg <= resize(DELTA_PHASE_FACTOR * to_ufixed(unsigned(target_frequency)) ,PHASE_INTEGER_PART,PHASE_FRAC_PART);
            end if;
        end if;
    end process;

    -- Output
    strb_delta_o  <= strb_reg;
    delta_phase_o <= delta_phase_reg;
end behavioral;
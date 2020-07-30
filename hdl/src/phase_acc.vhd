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

------------
-- Entity --
------------

entity phase_acc is
    generic(
        SAMPLING_FREQUENCY                 : positive := 100E6 -- 100 MHz
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        target_frequency_i                  : in  std_logic_vector((ceil_log2(SAMPLING_FREQUENCY + 1) - 1) downto 0);

        -- Output interface
        strb_o                              : out std_logic;
        flag_full_cycle_o                   : out std_logic;
        phase_o                             : out ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART)
    ); 
end phase_acc;

------------------
-- Architecture --
------------------

architecture behavioral of phase_acc is

    ---------------
    -- Constants --
    ---------------
    -- Frequency
    constant        FREQUENCY_WIDTH                     : positive                                          := target_frequency_i'length;

    -- Define frequency
    constant        DELTA_PHASE_FACTOR_INTEGER_PART     : integer                                           := PHASE_INTEGER_PART;
    constant        DELTA_PHASE_FACTOR_FRAC_PART        : integer                                           := PHASE_FRAC_PART;
    -- delta_phase        = delta_phase_factor * target_frequency
    -- delta_phase_factor = (2 * Pi * (1/sampling_frequency))    
    constant        DELTA_PHASE_FACTOR                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( ((2.0 * PI) * (1.0/real(SAMPLING_FREQUENCY))),PHASE_INTEGER_PART,PHASE_FRAC_PART);

    constant        TWO_PI                              : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( (2.0 * PI) ,
                                                                                                                        PHASE_INTEGER_PART,
                                                                                                                        PHASE_FRAC_PART);
   
    -------------
    -- Signals --
    -------------
    
    -- Input frequency
    signal target_frequency                 : std_logic_vector((FREQUENCY_WIDTH - 1) downto 0);


    -- Behavioral
    signal delta_phase_reg                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);

    signal strb_new_delta_reg               : std_logic;
    signal strb_output                      : std_logic;

    signal two_pi_phase                     : std_logic;
    signal set_zero_phase                   : std_logic;

    -- Output interface
    signal strb_output_reg                  : std_logic;
    signal flag_full_cycle                  : std_logic;
    signal phase_reg                        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
begin

    target_frequency <= target_frequency_i;

    -- Delta phase generation
    delta_phase_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_new_delta_reg <= '0';

        elsif (rising_edge(clock_i) ) then                       
            strb_new_delta_reg <= strb_i;

            if (strb_i = '1') then
                delta_phase_reg <= resize( ( DELTA_PHASE_FACTOR * to_ufixed( unsigned(target_frequency) )) ,
                                             PHASE_INTEGER_PART , PHASE_FRAC_PART );
            end if;

        end if;
    end process;

    -- Phase accumulator
    phase_acc_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_output_reg            <= '0';
        elsif ( rising_edge(clock_i) ) then

            strb_output_reg <= strb_output;

            if(set_zero_phase = '1') then
                phase_reg <= (others => '0');
            else
                phase_reg <= resize( (phase_reg + delta_phase_reg) ,PHASE_INTEGER_PART,PHASE_FRAC_PART);
            end if;
        end if;
    end process;

    two_pi_phase    <=          '1'     when (phase_reg >= TWO_PI) -- Checking full cycle
                        else    '0';
    
    flag_full_cycle <=          two_pi_phase;                      -- Full cycle indicator

    -- resets phase to zero upon
    set_zero_phase  <=          two_pi_phase       -- Full cycle, wrap back to phase = 0
                            or  strb_new_delta_reg; -- New frequency

    strb_output     <=          strb_new_delta_reg -- Once started 
                            or  strb_output_reg;   -- it keeps running

    
    -- Output
    
    strb_o            <= strb_output_reg;
    flag_full_cycle_o <= flag_full_cycle;
    phase_o           <= phase_reg;

end behavioral;
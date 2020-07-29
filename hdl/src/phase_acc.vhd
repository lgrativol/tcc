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

entity phase_acc is
    generic(
        PHASE_INTEGER_PART                 : natural  :=   2;
        PHASE_FRAC_PART                    : integer  := -30
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_phase_i                        : in  std_logic; -- Valid in
        delta_phase_i                       : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);

        -- Output interface
        strb_phase_o                        : out std_logic;
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
    constant        TWO_PI                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( (2.0 * PI) ,
                                                                                                           PHASE_INTEGER_PART,
                                                                                                           PHASE_FRAC_PART);
   
    -------------
    -- Signals --
    -------------
    
    -- Input interface
    signal delta_phase                      : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal start_over                       : std_logic;

    -- Behavioral
    signal strb_output                      : std_logic;
    signal delta_phase_reg                  : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal strb_new_frequency               : std_logic;
    signal two_pi_phase                     : std_logic;
    signal set_zero_phase                   : std_logic;

    -- Output interface
    signal strb_output_reg                  : std_logic;
    signal flag_full_cycle                  : std_logic;
    signal phase_reg                        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
begin

    -- Input
    delta_phase <= delta_phase_i;

    new_frequency_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_new_frequency <= '0';
        elsif ( rising_edge(clock_i) ) then
            
            strb_new_frequency <= strb_phase_i;

            if ( strb_phase_i = '1' ) then
                delta_phase_reg <= delta_phase;
            end if;
        end if;
    end process;

    strb_output <=      strb_new_frequency
                    or  strb_output_reg;

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

    two_pi_phase    <=          '1'     when (phase_reg >= TWO_PI)
                        else    '0';
    
    flag_full_cycle <= two_pi_phase;

    -- resets phase to zero upon
    set_zero_phase  <=          two_pi_phase       -- Full cycle, wrap back to phase = 0
                            or  strb_new_frequency; -- New frequency

    -- Output
    strb_phase_o      <= strb_output_reg;
    flag_full_cycle_o <= flag_full_cycle;
    phase_o           <= phase_reg;

end behavioral;
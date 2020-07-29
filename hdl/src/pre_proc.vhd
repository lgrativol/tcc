---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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

entity pre_proc is
    generic(
        CORDIC_INTEGER_PART                : natural  :=   0;
        CORDIC_FRAC_PART                   : integer  := -19;
        PHASE_INTEGER_PART                 : natural  :=   2;
        PHASE_FRAC_PART                    : integer  := -30
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_phase_i                        : in  std_logic; -- Valid in
        phase_i                             : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);

        -- Output interface
        strb_reduc_phase_o                  : out std_logic;
        reduc_phase_o                       : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART)
    ); 
end pre_proc;

------------------
-- Architecture --
------------------

architecture behavioral of pre_proc is

    ---------------
    -- Constants --
    ---------------
    constant        S_PI                    : sfixed((PHASE_INTEGER_PART) downto PHASE_FRAC_PART) := to_sfixed(PI);
    
    constant        PI_2                    : sfixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( (S_PI / 2.0) ,
                                                                                                           PHASE_INTEGER_PART,
                                                                                                           PHASE_FRAC_PART);

    constant        PI3_2                   : sfixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( ((3.0 * S_PI) / 2.0) ,
                                                                                                           PHASE_INTEGER_PART,
                                                                                                           PHASE_FRAC_PART);
    constant        PI2                     : sfixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( (2.0 * S_PI) ,
                                                                                                           PHASE_INTEGER_PART,
                                                                                                           PHASE_FRAC_PART);
   
    -------------
    -- Signals --
    -------------
    
    -- Input interface
    signal phase                            : sfixed((PHASE_INTEGER_PART + 1) downto PHASE_FRAC_PART);

    -- Behavioral
    signal phase_less_pi_2                  : std_logic;
    signal phase_less_3pi_2                 : std_logic;
    -- Output interface
    signal strb_reg                         : std_logic;
    signal reduc_phase_reg                  : sfixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
begin

    -- Input
    phase <= to_sfixed(phase_i);

    phase_reducer_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_reg <= '0';
        elsif ( rising_edge(clock_i) ) then
            
            strb_reg <= strb_phase_i;

            if ( strb_phase_i = '1' ) then

                if ( phase_less_pi_2 = '1') then
                    reduc_phase_reg <= resize(phase,PHASE_INTEGER_PART,PHASE_FRAC_PART);
                elsif ( phase_less_3pi_2 = '1') then
                    reduc_phase_reg <= resize((S_PI - phase),PHASE_INTEGER_PART,PHASE_FRAC_PART);
                else
                    reduc_phase_reg <= resize((phase - PI2),PHASE_INTEGER_PART,PHASE_FRAC_PART);
                end if;
                
            end if;
        end if;
    end process;

    phase_less_pi_2     <=          '1' when(phase <= PI_2)
                            else    '0';

    phase_less_3pi_2     <=         '1' when(phase <= PI3_2)
                            else    '0';
                                  
                            
    -- Output
    strb_reduc_phase_o  <= strb_reg;
    reduc_phase_o       <= resize(reduc_phase_reg, CORDIC_INTEGER_PART,CORDIC_FRAC_PART);

end behavioral;
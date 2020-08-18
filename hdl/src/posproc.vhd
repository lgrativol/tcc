---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee_proposed;                      
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity posproc is
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        sin_phase_i                         : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        cos_phase_i                         : in  sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

        -- Control Interface
        phase_info_i                        : in  std_logic_vector(1 downto 0);

        -- Output interface
        strb_o                              : out std_logic;
        sin_phase_o                         : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
        cos_phase_o                         : out sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART)
    ); 
end posproc;

------------------
-- Architecture --
------------------

architecture behavioral of posproc is

  
    -------------
    -- Signals --
    -------------
    
    -- Input interface
    signal strb_i_reg                       : std_logic;
    signal sin_phase_reg                    : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal cos_phase_reg                    : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    -- Control interface
    signal phase_info_reg                   : std_logic_vector(1 downto 0);

    -- Output interface
    signal strb_reg                         : std_logic;
    signal sin_phase                        : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal cos_phase                        : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);   
begin

    -- Input
    input_registering : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_i_reg <= '0';
        elsif (rising_edge(clock_i)) then
            strb_i_reg <= strb_i;

            if (strb_i = '1') then
                phase_info_reg  <= phase_info_i;
                sin_phase_reg   <= sin_phase_i;
                cos_phase_reg   <= cos_phase_i;
            end if;
        end if;
    end process;

    phase_correction_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_reg <= '0';
        elsif ( rising_edge(clock_i) ) then
            
            strb_reg <= strb_i_reg;

            if ( strb_i_reg = '1' ) then

                sin_phase   <= sin_phase_reg;
                
                if ( phase_info_reg = "00" or phase_info_reg = "10") then     -- phase in first quad
                    cos_phase   <= cos_phase_reg;
                else                                 -- phase in forth quad
                    cos_phase   <=  resize(-cos_phase_reg, cos_phase);
                end if;
                
            end if;
        end if;
    end process;

                                
    -- Output
    strb_o                  <= strb_reg;
    sin_phase_o             <= sin_phase;
    cos_phase_o             <= cos_phase;

end behavioral;
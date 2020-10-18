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

entity preproc is
    generic(
        SIDEBAND_WIDTH                      : integer;
        PHASE_INTEGER_PART                  : natural;
        PHASE_FRAC_PART                     : integer;
        OUTPUT_INTEGER_PART                 : natural; -- sfixed integer part 
        OUTPUT_FRAC_PART                    : integer  -- sfixed fractional part
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset
        
        -- Sideband
        sideband_data_i                     : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        sideband_data_o                     : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        phase_i                             : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);

        -- Control Interface
        phase_info_o                        : out std_logic_vector(1 downto 0);

        -- Output interface
        strb_o                              : out std_logic;
        reduced_phase_o                     : out sfixed(OUTPUT_INTEGER_PART downto OUTPUT_FRAC_PART)
    ); 
end preproc;

------------------
-- Architecture --
------------------

architecture behavioral of preproc is

    ---------------
    -- Constants --
    ---------------
    constant        S_PI                    : sfixed((PHASE_INTEGER_PART) downto PHASE_FRAC_PART) := resize(to_sfixed(PI),
                                                                                                                PHASE_INTEGER_PART,
                                                                                                                PHASE_FRAC_PART); -- signed PI
    
    constant        PI_2                    : sfixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( (S_PI / 2.0) , -- signed PI/2
                                                                                                           PHASE_INTEGER_PART,
                                                                                                           PHASE_FRAC_PART);

    constant        PI3_2                   : sfixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( ((3.0 * S_PI) / 2.0), -- signed 3PI/2
                                                                                                           PHASE_INTEGER_PART,
                                                                                                           PHASE_FRAC_PART);

    constant        PI2                     : sfixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART) := resize( (2.0 * S_PI) ,      -- signed 2PI
                                                                                                           PHASE_INTEGER_PART,
                                                                                                           PHASE_FRAC_PART);
   
    -------------
    -- Signals --
    -------------
    
    -- Input interface
    signal strb_i_reg                       : std_logic;
    signal sphase_reg                       : sfixed((PHASE_INTEGER_PART + 1) downto PHASE_FRAC_PART);

    -- Sideband
    signal sideband_data_reg1               : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    signal sideband_data_reg2               : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    
    -- Behavioral
    signal phase_less_pi_2                  : std_logic;
    signal phase_less_3pi_2                 : std_logic;

    -- Control interface
    signal phase_info                       : std_logic_vector(1 downto 0);

    -- Output interface
    signal strb_reg                         : std_logic;
    signal reduced_phase_reg                : sfixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    
begin

    -- Input
    input_registering : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_i_reg <= '0';
        elsif (rising_edge(clock_i)) then
            strb_i_reg <= strb_i;

            if (strb_i = '1') then
                sideband_data_reg1  <= sideband_data_i;
                sphase_reg <= to_sfixed(phase_i);
            end if;
        end if;
    end process;

    phase_reducer_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_reg <= '0';
        elsif ( rising_edge(clock_i) ) then
            
            strb_reg <= strb_i_reg;

            if ( strb_i_reg = '1' ) then

                sideband_data_reg2  <= sideband_data_reg1;

                if ( phase_less_pi_2 = '1') then     -- phase in first quad
                    phase_info        <= "00";
                    reduced_phase_reg <= resize(sphase_reg,PHASE_INTEGER_PART,PHASE_FRAC_PART); -- phase
                elsif ( phase_less_3pi_2 = '1') then -- phase in second or thrid
                    phase_info        <= "01";
                    reduced_phase_reg <= resize((S_PI - sphase_reg),PHASE_INTEGER_PART,PHASE_FRAC_PART); -- PI - phase
                else                                 -- phase in forth quad
                    phase_info        <= "10";
                    reduced_phase_reg <= resize((sphase_reg - PI2),PHASE_INTEGER_PART,PHASE_FRAC_PART); -- phase - 2PI
                end if;
                
            end if;
        end if;
    end process;

    phase_less_pi_2     <=          '1' when(sphase_reg <= PI_2) -- phase <= PI/2
                            else    '0';

    phase_less_3pi_2     <=         '1' when(sphase_reg <= PI3_2) -- phase <= 3PI/2
                            else    '0';

    -- Output
    strb_o                  <= strb_reg;
    sideband_data_o         <= sideband_data_reg2;
    phase_info_o            <= phase_info;
    reduced_phase_o         <= resize(reduced_phase_reg, OUTPUT_INTEGER_PART,OUTPUT_FRAC_PART);

end behavioral;
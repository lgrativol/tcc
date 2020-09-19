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

entity phase_adjust is
    generic (
        PHASE_INTEGER_PART                  : positive := 4;
        PHASE_FRAC_PART                     : integer  := 4;
        NB_POINTS_WIDTH                     : positive := 13;
        FACTOR                              : positive := 1;
        SIDEBAND_WIDTH                      : natural  := 0
    );
    port (
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        phase_in_i                          : in  ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
        nb_cycles_in_i                      : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
        
        -- Sideband interface
        sideband_data_i                     : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        sideband_data_o                     : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
        
        -- Output interface
        strb_o                              : out std_logic; -- Valid in
        phase_out_o                         : out ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
        nb_cycles_out_o                     : out std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
        nb_rept_out_o                       : out std_logic_vector((NB_POINTS_WIDTH - 1) downto 0)
    );
end phase_adjust;

------------------
-- Architecture --
------------------
architecture behavioral of phase_adjust is

    ---------------
    -- Constants --
    ---------------
    constant    FACTOR_INTEGER_PART                 : natural :=   0;
    constant    FACTOR_FRAC_PART                    : integer := -10;
    constant    UFX_FACTOR                          : ufixed((NB_POINTS_WIDTH - 1) downto 0)                      := to_ufixed(real(FACTOR),NB_POINTS_WIDTH - 1,0);
    constant    ONE_FACTOR                          : ufixed(FACTOR_INTEGER_PART downto FACTOR_FRAC_PART)   := to_ufixed( (1.0 / real(FACTOR) ) ,FACTOR_INTEGER_PART,FACTOR_FRAC_PART);

    -------------
    -- Signals --
    -------------
    
    -- Input
    signal      input_strb                          : std_logic; -- Valid in
    signal      phase_in                            : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal      nb_cycles_in                        : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      sideband_data_in                    : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    -- Stage 1
    signal      input_strb_reg                      : std_logic; -- Valid in
    signal      phase_in_reg                        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal      nb_cycles_in_reg                    : ufixed((NB_POINTS_WIDTH - 1) downto 0);                     
    signal      sideband_data_in_reg                : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);


    -- Stage 2
    signal      output_strb                         : std_logic; -- Valid in
    signal      phase_factor                        : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);
    signal      nb_cycles_factor                    : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      nb_rept_factor                      : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      sideband_data_out                   : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);


begin

    -----------
    -- Input --
    -----------

    input_strb          <= strb_i;        
    phase_in            <= phase_in_i;    
    nb_cycles_in        <= nb_cycles_in_i;
    sideband_data_in    <= sideband_data_i;

    -------------
    -- Stage 1 --
    -------------

    -- Input registering

    input_registers : process (clock_i, areset_i)
    begin
        if (areset_i = '1') then
            
            input_strb_reg <= '0';
        elsif ( rising_edge(clock_i) ) then

            input_strb_reg <= input_strb;

            if (input_strb = '1') then
                phase_in_reg        <= phase_in;    
                nb_cycles_in_reg    <= to_ufixed(nb_cycles_in, nb_cycles_in_reg);
            end if;
        end if;
    end process;

    input_sideband : process (clock_i)
    begin
        if ( rising_edge(clock_i) ) then
            if (input_strb = '1') then

                sideband_data_in_reg    <= sideband_data_in;
            end if;
        end if;
    end process;


    --------------
    -- Stage 2  --
    --------------

    -- Adjustments
    phase_adjustment : process (clock_i, areset_i)
    begin
        if (areset_i = '1') then
            
            output_strb <= '0';
        elsif ( rising_edge(clock_i) ) then

            output_strb <= input_strb_reg;

            if (input_strb_reg = '1') then

                phase_factor        <= resize(phase_in_reg * UFX_FACTOR , phase_factor);
                nb_cycles_factor    <= to_slv  (  resize ( nb_cycles_in_reg * ONE_FACTOR, UFX_FACTOR) );
                nb_rept_factor      <= std_logic_vector(to_unsigned(FACTOR,nb_rept_factor'length));
            end if;
        end if;
    end process;

    output_sideband : process (clock_i)
    begin
        if ( rising_edge(clock_i) ) then
            if (input_strb_reg = '1') then
                
                sideband_data_out    <= sideband_data_in_reg;
            end if;
        end if;
    end process;

    ------------
    -- Output --
    ------------
    strb_o              <= output_strb;
    phase_out_o         <= phase_factor;
    nb_cycles_out_o     <= nb_cycles_factor;
    nb_rept_out_o       <= nb_rept_factor;
    sideband_data_o     <= sideband_data_out;

end behavioral;

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


------------
-- Entity --
------------

entity reciprocal_xy is
    generic (
        INPUT_WIDTH                         : positive := 4;
        RECIPROCAL_INTEGER_PART             : natural  := 0;
        RECIPROCAL_FRAC_PART                : integer  := -19;
        RECIPROCAL_NB_ITERATIONS            : positive := 21
    );
    port (
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        x_i                                 : in  std_logic_vector((INPUT_WIDTH - 1) downto 0);
        y_i                                 : in  std_logic_vector((INPUT_WIDTH - 1) downto 0);
         
        -- Output interface
        strb_o                              : out std_logic;
        reciprocal_xy_o                     : out sfixed(RECIPROCAL_INTEGER_PART downto RECIPROCAL_FRAC_PART)
    );
end reciprocal_xy;

------------------
-- Architecture --
------------------
architecture behavioral of reciprocal_xy is

    ---------------
    -- Constants --
    ---------------

    constant    SIDEBAND_WIDTH                   : natural := 0;

    -------------
    -- Signals --
    -------------
    
    -- Stage Input reg
    signal      input_strb                       : std_logic;
    signal      x_reg                            : sfixed((RECIPROCAL_INTEGER_PART + INPUT_WIDTH) downto RECIPROCAL_FRAC_PART);
    signal      y_reg                            : sfixed((RECIPROCAL_INTEGER_PART + INPUT_WIDTH) downto RECIPROCAL_FRAC_PART);
    signal      resized_x_i                      : std_logic_vector((x_reg'length - 1) downto 0);
    signal      resized_y_i                      : std_logic_vector((y_reg'length - 1) downto 0);

    -- Stage 2 Cordic Core
    signal      cordic_core_recp_strb_i          : std_logic;
    signal      cordic_core_recp_x_i             : sfixed((RECIPROCAL_INTEGER_PART + INPUT_WIDTH) downto RECIPROCAL_FRAC_PART);
    signal      cordic_core_recp_y_i             : sfixed((RECIPROCAL_INTEGER_PART + INPUT_WIDTH) downto RECIPROCAL_FRAC_PART);
    signal      cordic_core_recp_z_i             : sfixed((RECIPROCAL_INTEGER_PART + INPUT_WIDTH) downto RECIPROCAL_FRAC_PART);
    
    signal      cordic_core_recp_strb_o          : std_logic;
    signal      cordic_core_recp_x_o             : sfixed((RECIPROCAL_INTEGER_PART + INPUT_WIDTH) downto RECIPROCAL_FRAC_PART);
    signal      cordic_core_recp_y_o             : sfixed((RECIPROCAL_INTEGER_PART + INPUT_WIDTH) downto RECIPROCAL_FRAC_PART);
    signal      cordic_core_recp_z_o             : sfixed((RECIPROCAL_INTEGER_PART + INPUT_WIDTH) downto RECIPROCAL_FRAC_PART);

    signal      cordic_core_recp_sideband_i      : std_logic_vector((SIDEBAND_WIDTH -1) downto 0);

begin


    -------------
    -- Stage 1 --
    -------------

    resized_x_i <= std_logic_vector(resize(unsigned(x_i),x_reg'length));
    resized_y_i <= std_logic_vector(resize(unsigned(y_i),y_reg'length));

    input_reg_proc: process (clock_i, areset_i)
    begin
        if (areset_i = '1') then
            input_strb  <= '0';
        elsif ( rising_edge(clock_i)) then
            input_strb <= strb_i;

            if (strb_i = '1') then
                x_reg <= to_sfixed( to_integer( unsigned(resized_x_i)), x_reg);
                y_reg <= to_sfixed( to_integer( unsigned(resized_y_i)), y_reg);
            end if;
        end if;
    end process;

    --------------
    -- Stage 2  --
    --------------
    
    cordic_core_recp_strb_i <= input_strb;

    cordic_core_recp_x_i <= x_reg;
    cordic_core_recp_y_i <= y_reg;
    cordic_core_recp_z_i <= (others => '0') ;

    stage_2_cordic_core_recp : entity work.cordic_core_recp
        generic map(
            SIDEBAND_WIDTH                  => 0,
            CORDIC_INTEGER_PART             => (RECIPROCAL_INTEGER_PART + INPUT_WIDTH),
            CORDIC_FRAC_PART                => RECIPROCAL_FRAC_PART,
            N_CORDIC_ITERATIONS             => RECIPROCAL_NB_ITERATIONS
        )
        port map (
            clock_i                         => clock_i, 
            areset_i                        => areset_i, -- Positive async reset

            sideband_data_i                 => cordic_core_recp_sideband_i,
            sideband_data_o                 => open,
            
            strb_i                          => cordic_core_recp_strb_i, -- Valid in
            
            X_i                             => cordic_core_recp_x_i,   -- X initial coordinate
            Y_i                             => cordic_core_recp_y_i,   -- Y initial coordinate
            Z_i                             => cordic_core_recp_z_i,   -- angle to rotate
            
            strb_o                          => cordic_core_recp_strb_o,
            X_o                             => cordic_core_recp_x_o, -- Ignore 
            Y_o                             => cordic_core_recp_y_o, -- Ignore
            Z_o                             => cordic_core_recp_z_o  -- Reciprocal x/y
        );

    ------------
    -- Output --
    ------------
    strb_o               <= cordic_core_recp_strb_o; 
    reciprocal_xy_o      <= resize(cordic_core_recp_z_o,RECIPROCAL_INTEGER_PART,RECIPROCAL_FRAC_PART); -- TODO: Check timing

    end behavioral;

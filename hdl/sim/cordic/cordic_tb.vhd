----------------------------------------------------------------------------------
-- Create Date: 26.07.2020 09:48:08
-- Design Name: 
-- Module Name: cordic_tb - Behavioral
----------------------------------------------------------------------------------

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

entity cordic_tb is
--  Port ( );
end cordic_tb;

architecture Behavioral of cordic_tb is
    
    ---------------
    -- Constants --
    ---------------

    -- Clock
    constant CLK_PERIOD                        : time := 10 ns; -- 100 MHz

    -- Architecture
    constant Z_ANGLE                           : integer := 30;

    constant ANGLE_INTEGER_PART                : natural := 3;
    constant ANGLE_FRAC_PART                   : integer := -19;

    -- constant MATH_PI                             : ufixed(ANGLE_INTEGER_PART downto ANGLE_FRAC_PART) := to_ufixed(MATH_PI,ANGLE_INTEGER_PART,ANGLE_FRAC_PART);

    --Behavioral
    constant F_OUT                             : positive := 20E3;                   
    constant F_S                               : positive := 100E6;
    constant NB_POINTS                         : positive := (F_S/F_OUT);
    constant DELTA_ANGLE                       : sfixed(ANGLE_INTEGER_PART downto ANGLE_FRAC_PART) := to_sfixed(((2.0 * MATH_PI) / 5000.0),ANGLE_INTEGER_PART,ANGLE_FRAC_PART);
    constant SATURATION_CTE                    : sfixed(ANGLE_INTEGER_PART  downto ANGLE_FRAC_PART) := (others => '1') ;
    constant SIDEBAND_WIDTH                    : natural  := 0;


    -------------
    -- Signals --
    -------------

    signal clk                                 : std_logic :='0';
    signal areset                              : std_logic :='0';

    signal strb_i                              : std_logic; -- valid
    signal strb_o                              : std_logic; -- valid

    signal sideband_data                       : std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);

    signal x_i                                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal y_i                                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal z_i                                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal x_o                                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal y_o                                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal z_o                                 : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    -- Simulation
    signal phase_accumulator                   : sfixed(ANGLE_INTEGER_PART  downto ANGLE_FRAC_PART) := (others => '0');
    signal deg_angle                           : integer;
 
    ---------------
    -- Functions --
    ---------------
    function angle_reducer (angle : sfixed)
                            return sfixed is
        constant PI_2             : sfixed(ANGLE_INTEGER_PART  downto ANGLE_FRAC_PART) := to_sfixed( MATH_PI / 2.0         ,ANGLE_INTEGER_PART,ANGLE_FRAC_PART);
        constant PI               : sfixed(ANGLE_INTEGER_PART  downto ANGLE_FRAC_PART) := to_sfixed( MATH_PI              ,ANGLE_INTEGER_PART,ANGLE_FRAC_PART);
        constant PI3_2            : sfixed(ANGLE_INTEGER_PART  downto ANGLE_FRAC_PART) := to_sfixed( (3.0 * MATH_PI) / 2.0 ,ANGLE_INTEGER_PART,ANGLE_FRAC_PART);
        variable tmp_angle        : sfixed(CORDIC_INTEGER_PART  downto CORDIC_FRAC_PART);
        variable conv_angle       : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);

    begin
        if( angle <= PI_2 ) then
            tmp_angle := resize(angle,CORDIC_INTEGER_PART,CORDIC_FRAC_PART);
        elsif ( angle <= PI3_2 ) then
            tmp_angle := resize(PI - angle,CORDIC_INTEGER_PART,CORDIC_FRAC_PART);
        else
            tmp_angle := resize(angle - (2.0 * PI),CORDIC_INTEGER_PART,CORDIC_FRAC_PART);
        end if;
        conv_angle := tmp_angle;
        return conv_angle;
    end angle_reducer;


    function rad2deg (angle : sfixed)
                            return integer is
    begin
        return to_integer( (angle/MATH_PI) * 180);
    end rad2deg;


begin

   -- clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
   end process;
 
    UUT: entity work.cordic_core
        generic map(
            SIDEBAND_WIDTH         => SIDEBAND_WIDTH,
            CORDIC_INTEGER_PART    => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART       => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS    => N_CORDIC_ITERATIONS
        )
        port map(
            clock_i                             => clk,
            areset_i                            => areset,

            sideband_data_i                     => sideband_data,
            sideband_data_o                     => open,
            
            strb_i                              => strb_i,
            X_i                                 => x_i, -- Component X (vector)
            Y_i                                 => y_i, -- Component Y (vector)
            Z_i                                 => z_i, -- Angle
            
            strb_o                              => strb_o,
            X_o                                 => x_o,
            Y_o                                 => y_o,
            Z_o                                 => z_o       
        );

    stim_proc : process
    begin
        areset <= '1';
        strb_i <= '0';
        wait for 4*CLK_PERIOD;
        wait until (rising_edge(clk));
        areset <= '0';


        x_i    <= to_sfixed( (0.607253) , CORDIC_INTEGER_PART, CORDIC_FRAC_PART);
        y_i    <= to_sfixed( 0.0   , CORDIC_INTEGER_PART, CORDIC_FRAC_PART);

        for i in 0 to 10 loop
            for k in 0 to 4999 loop
                phase_accumulator <= resize(phase_accumulator + DELTA_ANGLE ,ANGLE_INTEGER_PART, ANGLE_FRAC_PART);
                z_i    <= angle_reducer(phase_accumulator);              
                strb_i <= '1';
                wait for CLK_PERIOD;
                wait until (rising_edge(clk));
            end loop;
            phase_accumulator <= (others =>'0');
            wait for CLK_PERIOD;
            wait until (rising_edge(clk));
        end loop;
        strb_i <= '0';
        wait;
        
    end process;

end Behavioral;

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

entity win_phase_acc is
    generic(
        MULT_FACTOR                         : positive := 1;
        WIN_PHASE_INTEGER_PART              : natural  := 0;
        WIN_PHASE_FRAC_PART                 : integer  := -1
    );
    port(
        -- Clock interface
        clock_i                             : in  std_logic; 
        areset_i                            : in  std_logic; -- Positive async reset

        -- Input interface
        strb_i                              : in  std_logic; -- Valid in
        phase_term_i                        : in  ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);

        -- Control interface
        restart_cycles_i                    : in  std_logic; 
        flag_full_cycle_o                   : out std_logic;

        -- Output interface
        strb_o                              : out std_logic;
        phase_o                             : out ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART)
    ); 
end win_phase_acc;

------------------
-- Architecture --
------------------

architecture behavioral of win_phase_acc is

    ---------------
    -- Constants --
    ---------------
    constant        FINAL_PHASE_CTE                     : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART) := resize( (real(MULT_FACTOR)*2.0 * PI) ,
                                                                                                                        WIN_PHASE_INTEGER_PART,
                                                                                                                        WIN_PHASE_FRAC_PART);   
    -------------
    -- Signals --
    -------------
    
    -- Input phase term
    signal phase_term                                   : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);

    -- Behavioral
    signal phase_term_reg                               : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
    signal final_phase_delta                            : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
    
    signal strb_new_delta_reg                           : std_logic;
    signal strb_output                                  : std_logic;

    signal neg_edge_detector_restart_cycles             : std_logic;
    signal restart_cycles_reg                           : std_logic;

    signal start_new_cycle                              : std_logic;
    signal two_pi_phase                                 : std_logic;
    signal set_phase                                    : std_logic;
   
    -- Output interface
    signal strb_output_reg                              : std_logic;
    signal phase_reg                                    : ufixed(WIN_PHASE_INTEGER_PART downto WIN_PHASE_FRAC_PART);
    
begin

    -- Input
    phase_term      <= phase_term_i;

    -- Input reg
    delta_phase_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_new_delta_reg <= '0';

        elsif (rising_edge(clock_i) ) then                       
            strb_new_delta_reg <= strb_i;

            if (strb_i = '1') then
                phase_term_reg <= phase_term;
            end if;

        end if;
    end process;

    -- Phase accumulator
    phase_acc_proc : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            strb_output_reg            <= '0';
            restart_cycles_reg         <= '0';
        elsif ( rising_edge(clock_i) ) then

            strb_output_reg     <= strb_output;
            restart_cycles_reg  <= restart_cycles_i;

            if (strb_output = '1') then

                if (set_phase = '1') then
                    phase_reg <= (others => '0');
                else
                    phase_reg <= resize( (phase_reg + phase_term_reg) ,WIN_PHASE_INTEGER_PART,WIN_PHASE_FRAC_PART);
                end if;
                
            end if;
        end if;
    end process;

    final_phase_delta   <=      resize( (FINAL_PHASE_CTE - phase_term_reg) ,WIN_PHASE_INTEGER_PART,WIN_PHASE_FRAC_PART);  --TODO : Pass to reg (better timing)
     
    two_pi_phase    <=          '1'     when (phase_reg >= final_phase_delta) -- Checking full cycle
                        else    '0';
    

    neg_edge_detector_restart_cycles <=         restart_cycles_reg
                                            and (not restart_cycles_i);

    start_new_cycle <=                          strb_new_delta_reg                          -- New frequency
                                            or  neg_edge_detector_restart_cycles;           -- start new cycle
    -- resets phase to zero upon
    set_phase       <=                          start_new_cycle;               -- Reset cycle signal

    strb_output     <=                          (       (not two_pi_phase)        
                                                    and strb_output_reg )  
                                            or  start_new_cycle;                                
    -- Output
    flag_full_cycle_o  <= two_pi_phase; -- Full cycle indicator

    strb_o            <= strb_output_reg;
    phase_o           <= phase_reg;

end behavioral;
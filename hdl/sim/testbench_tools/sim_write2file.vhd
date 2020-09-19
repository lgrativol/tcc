---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all; -- Base I/O package

library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity sim_write2file is
    generic(
        FILE_NAME   : string   := "input.txt"; 
        INPUT_WIDTH : positive := 8
    );
    port(
        clock           : in std_logic;
        hold            : in std_logic;
        data_valid      : in std_logic;
        data_in         : in std_logic_vector((INPUT_WIDTH - 1) downto 0)
); 
end sim_write2file;


architecture simulation_entity of sim_write2file is

    ----------
    -- File --
    ----------

    file        F                   : TEXT open WRITE_MODE is FILE_NAME;


    ---------------
    -- Constants --
    ---------------
        
    -- Behavioral 
    constant    WORD_SIZE           : positive  := ( ( INPUT_WIDTH / 4 ) + 1 ); -- Number of 4-bit words in <data_in>


    --------------
    -- Signals  --
    --------------

    signal      data_string         : string (1 to WORD_SIZE);

begin

    data_string <= to_hexstring(data_in);
    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    write2file: process(clock)
        variable line_out     : line;
    begin
        if ( rising_edge(clock) ) then

            if (data_valid = '1' and hold = '0') then

                write(line_out, data_string);
                writeline(F,line_out);
            end if;
        end if;              
    end process;

end architecture simulation_entity;
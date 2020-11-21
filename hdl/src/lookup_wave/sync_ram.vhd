
--  Xilinx Simple Dual Port Single Clock RAM with Byte-write
--  This code implements a parameterizable SDP single clock memory.
--  If a reset or enable is not necessary, it may be tied off or removed from the code.

---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils_pkg.all;
use std.textio.all;

------------
-- Entity --
------------

entity sync_ram is
    generic (
        INIT_FILE       : string    := "";  -- Specify name/location of RAM initialization file if using one (leave blank if not)
        WORD_WIDTH      : positive  := 10;         -- Specify word width 
        RAM_DEPTH       : positive  := 1024        -- Specify RAM depth (number of entries)
    );
    port (
            clock_i               : in  std_logic;                       			           -- Clock

            -- Write Interface
            mem_write_addr_i      : in  std_logic_vector((ceil_log2(RAM_DEPTH)-1) downto 0);  -- Write address bus, width determined from RAM_DEPTH
            mem_write_enable_i    : in  std_logic;                                            -- Write enable
            mem_write_data_i      : in  std_logic_vector((WORD_WIDTH - 1) downto 0);	      -- RAM input data

            -- Read Interface
            mem_read_addr_i       : in  std_logic_vector((ceil_log2(RAM_DEPTH)-1) downto 0);  -- Read address bus, width determined from RAM_DEPTH
            mem_read_enable_i     : in  std_logic;                       			          -- RAM Enable, for additional power savings, disable port when not in use
            mem_read_data_o       : out std_logic_vector((WORD_WIDTH - 1) downto 0)           -- RAM output data
    );
end sync_ram;

------------------
-- Architecture --
------------------

architecture rtl of sync_ram is

    -----------
    -- Types --
    -----------
    type    ram_type is array (0 to (RAM_DEPTH - 1)) of std_logic_vector((WORD_WIDTH - 1) downto 0);

    ---------------
    -- Functions --
    ---------------

    function initramfromfile (ramfilename : in string) 
    return ram_type is
        file     ramfile	 : text is in ramfilename;
        variable ramfileline : line;
        variable ram_name	 : ram_type;
        variable bitvec      : bit_vector((WORD_WIDTH - 1) downto 0); --keeping bit_vector, dont know if works with slv
    begin
        for i in ram_type'range loop
            readline (ramfile, ramfileline);
            read (ramfileline, bitvec);
            ram_name(i) := to_stdlogicvector(bitvec);
        end loop;
        
        return ram_name;
    end function;

    function init_from_file_or_zeroes(ramfile : string) 
    return ram_type is
    begin
        if(ramfile = "RAM_INIT.dat") then
            return InitRamFromFile("RAM_INIT.dat");
        else
            return (others => (others => '0'));
        end if;
    end;


    -------------
    -- Signals --
    -------------

    shared variable ram_name     : ram_type := init_from_file_or_zeroes(INIT_FILE);
    signal          ram_data     : std_logic_vector((WORD_WIDTH - 1) downto 0);

begin
    
    -- Read process
    read_proc : process(clock_i)
    begin
        if(rising_edge(clock_i)) then
            if(mem_read_enable_i= '1') then
                ram_data                                    <= ram_name(to_integer(unsigned(mem_read_addr_i)));
            end if;
        end if;
    end process;

    -- Write process
    write_proc : process(clock_i)
    begin
        if(rising_edge(clock_i)) then
            if (mem_write_enable_i = '1') then
                ram_name(to_integer(unsigned(mem_write_addr_i))) := mem_write_data_i;
            end if;
        end if;
    end process;

    -- Output
    mem_read_data_o <= ram_data;

end rtl;

-------------
-- Library --
-------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity wave_fifo is
    generic (
        DATA_WIDTH              : natural := 10;
        RAM_DEPTH               : natural := 512-- RAM_DEPTH = 2^N
    );
    port (
        clock_i                 : in std_logic;
        areset_i                : in std_logic;

        -- Write port
        wave_valid_i            : in std_logic;
        wave_data_i             : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        wave_last_i             : in std_logic;

        -- Read port
        wave_rd_enable_i        : in  std_logic;
        wave_valid_o            : out std_logic;
        wave_data_o             : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        wave_last_o             : out std_logic;

        -- Flags
        empty_o                 : out std_logic;
        full_o                  : out std_logic
    );
end wave_fifo;

------------------
-- Architecture --
------------------

architecture behavioral of wave_fifo is


    --------------
    -- Constant --
    --------------

    constant    MAX_ADDR_WIDTH  : natural                                     := ceil_log2(RAM_DEPTH);
    constant    MAX_ADDR        : unsigned( ( MAX_ADDR_WIDTH - 1 ) downto 0 ) := to_unsigned( RAM_DEPTH - 1 , MAX_ADDR_WIDTH)  ;
    constant    FIFO_DATA_WIDTH : positive                                    := DATA_WIDTH + 1; 
    
    ----------
    -- Type --
    ----------
    type    ram_type is array (0 to RAM_DEPTH - 1) of std_logic_vector((FIFO_DATA_WIDTH - 1) downto 0);
    
    ------------
    -- Signal --
    ------------

    -- Input
    signal wr_input_valid           : std_logic;
    signal wr_data                  : std_logic_vector((FIFO_DATA_WIDTH - 1) downto 0);
    signal rd_en                    : std_logic;
    
    -- Memory
    shared variable ram             : ram_type ;
    signal rd_data                  : std_logic_vector((FIFO_DATA_WIDTH - 1) downto 0);
    
    -- FIFO
    signal pointer_write            : unsigned( ( MAX_ADDR_WIDTH - 1 ) downto 0 );
    signal max_wr_reached           : std_logic;
    
    signal pointer_read             : unsigned( ( MAX_ADDR_WIDTH - 1 ) downto 0 );
    signal enable_read              : std_logic;
    signal max_rd_reached           : std_logic;
    signal rd_valid                 : std_logic;
    
    signal flag_empty               : std_logic;
    signal flag_full                : std_logic;
    signal fill_count               : unsigned( ( MAX_ADDR_WIDTH - 1 ) downto 0 );

begin
    -- Input
    wr_input_valid          <= wave_valid_i;       
    wr_data                 <= wave_last_i & wave_data_i;    

    rd_en                   <= wave_rd_enable_i;
    
    -- Write process
    write_proc : process(clock_i)
    begin
        if ( rising_edge (clock_i) ) then
            if(wave_valid_i = '1') then
                ram( to_integer(pointer_write) ) := wr_data;
            end if;
        end if;
    end process;

    update_pointer_writer_proc: process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            pointer_write <= (others => '0');
        elsif (rising_edge(clock_i)) then
        
            if(wave_valid_i = '1') then
            
                if(max_wr_reached = '1') then
                    pointer_write   <= (others => '0'); --non-blocking write, user decision
                else
                    pointer_write   <= pointer_write + 1;
                end if;
            end if;
        end if;
    end process;


    max_wr_reached     <=           '1'       when( pointer_write = MAX_ADDR )
                            else    '0';

    -- Update the tail pointer on read and pulse valid
    read_proc : process(clock_i , areset_i)
    begin
        if (areset_i = '1' ) then
            rd_valid        <= '0';
        elsif ( rising_edge(clock_i) ) then
            
            rd_valid <= '0';

            if ( enable_read = '1' ) then
                rd_data <= ram( to_integer(pointer_read) );               
                rd_valid <= '1';
            end if;
        end if;
    end process;

    
    flag_empty          <=          '1'       when( pointer_read = pointer_write )
                            else    '0'; 
    
    enable_read         <=          rd_en
                            and not(flag_empty);     
        
    update_pointer_read_proc: process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            pointer_read <= (others => '0');
        elsif (rising_edge(clock_i)) then
        
            if(enable_read = '1') then
            
                if(max_rd_reached = '1') then
                    pointer_read   <= (others => '0');
                else
                    pointer_read   <= pointer_read + 1;
                end if;
            end if;
        end if;
    end process;

    max_rd_reached     <=           '1'       when( pointer_read = MAX_ADDR )
                            else    '0';

    -- Update the fill count
    proc : process(pointer_write, pointer_read)
    begin
        if ( pointer_write < pointer_read ) then
            fill_count <= pointer_read - pointer_write ;
        else
            fill_count <= pointer_write - pointer_read;
        end if;
    end process;

    -- Set the flags
                           
    flag_full       <=              '1'     when ( fill_count = MAX_ADDR )
                            else    '0';

    -- Output

    wave_valid_o            <= rd_valid;
    wave_data_o             <= rd_data((DATA_WIDTH - 1) downto 0);
    wave_last_o             <= rd_data(DATA_WIDTH);

    empty_o                 <= flag_empty;
    full_o                  <= flag_full;
 
end architecture;
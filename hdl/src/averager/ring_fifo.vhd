
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

entity ring_fifo is
    generic (
        DATA_WIDTH      : natural;
        RAM_DEPTH       : natural -- RAM_DEPTH = 2^N
    );
    port (
        clock_i                 : in std_logic;
        areset_i                : in std_logic;

        -- Config  port
        config_strb_i           : in std_logic;
        config_max_addr_i       : in std_logic_vector( ( ceil_log2(RAM_DEPTH + 1) - 1 ) downto 0 );
        config_reset_pointers_i : in std_logic;

        -- Write port
        wr_strb_i               : in std_logic;
        wr_data_i               : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        -- Read port
        rd_en_i                 : in std_logic;
        rd_strb_o               : out std_logic;
        rd_data_o               : out std_logic_vector(DATA_WIDTH - 1 downto 0);

        -- Flags
        empty                   : out std_logic;
        full                    : out std_logic
    );
end ring_fifo;

------------------
-- Architecture --
------------------

architecture behavioral of ring_fifo is


    --------------
    -- Constant --
    --------------

    constant    MAX_ADDR_WIDTH  : positive                                    := config_max_addr_i'length;
    constant    MAX_ADDR        : unsigned( ( MAX_ADDR_WIDTH - 1 ) downto 0 ) := to_unsigned( RAM_DEPTH - 1 , MAX_ADDR_WIDTH)  ;


    ----------
    -- Type --
    ----------
    type    ram_type is array (0 to RAM_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    ------------
    -- Signal --
    ------------

    -- Input
    signal config_input_strb        : std_logic;
    signal config_max_addr          : std_logic_vector( ( MAX_ADDR_WIDTH - 1 ) downto 0 );
    signal config_reset_pointers    : std_logic;
    signal wr_input_strb            : std_logic;
    signal wr_data                  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal rd_en                    : std_logic;
    
    -- Memory
    shared variable ram             : ram_type ;
    signal rd_data                  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    -- FIFO
    signal pointer_head             : unsigned( ( MAX_ADDR_WIDTH - 1 ) downto 0 );
    signal max_wr_reached           : std_logic;
    
    signal pointer_tail             : unsigned( ( MAX_ADDR_WIDTH - 1 ) downto 0 );
    signal max_rd_reached           : std_logic;
    signal rd_valid                 : std_logic;

    signal config_max_addr_reg      : unsigned( ( MAX_ADDR_WIDTH - 1 ) downto 0 );
    
    signal flag_empty               : std_logic;
    signal flag_full                : std_logic;
    signal fill_count               : unsigned( ( MAX_ADDR_WIDTH - 1 ) downto 0 );

begin
    -- Input
    config_input_strb       <= config_strb_i;
    config_max_addr         <= config_max_addr_i;
    config_reset_pointers   <= config_reset_pointers_i;

    wr_input_strb           <= wr_strb_i;       
    wr_data                 <= wr_data_i;    

    rd_en                   <= rd_en_i;
    
    -- Set Max ADDR to ringer
    proc_max_addr_ringer : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            config_max_addr_reg <= MAX_ADDR;
        elsif( rising_edge(clock_i)) then

            if (config_input_strb = '1') then
                config_max_addr_reg <= unsigned(config_max_addr);
            end if;
        end if;
    end process;

    -- Update the head pointer in write
    proc_head : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            pointer_head        <= (others => '0');
        elsif ( rising_edge (clock_i) ) then

            if (config_reset_pointers = '1') then

                pointer_head <= (others => '0');
            elsif ( wr_input_strb = '1' ) then

                ram( to_integer(pointer_head) ) := wr_data;

                if ( max_wr_reached = '1') then

                    pointer_head        <= (others => '0');
                else
                    pointer_head        <= pointer_head + 1;
                end if;
            end if;
        end if;
    end process;

    max_wr_reached     <=           '1'       when( pointer_head = config_max_addr_reg )
                            else    '0';

    -- Update the tail pointer on read and pulse valid
    proc_tail : process(clock_i , areset_i)
    begin
        if (areset_i = '1' ) then

            pointer_tail    <= (others => '0') ;
            rd_valid        <= '0';
        elsif ( rising_edge(clock_i) ) then
            
            rd_valid <= '0';
            
            if (config_reset_pointers = '1') then
                
                pointer_tail <= (others => '0');

            elsif ( rd_en = '1' ) then
                
                rd_data <= ram( to_integer(pointer_tail) );

               -- if ( flag_empty = '0') then
                if ( max_rd_reached = '1' ) then
                    pointer_tail <= (others => '0') ;
                else
                    pointer_tail <= pointer_tail + 1;
                end if;
               -- end if;
                
                rd_valid <= '1';
            end if;
        end if;
    end process;

    max_rd_reached     <=           '1'       when( pointer_tail = config_max_addr_reg )
                            else    '0';


    -- Update the fill count
    proc : process(pointer_head, pointer_tail)
    begin
        if ( pointer_head < pointer_tail ) then
            fill_count <= pointer_tail - pointer_head ;
        else
            fill_count <= pointer_head - pointer_tail;
        end if;
    end process;

    -- Set the flags
    flag_empty      <=              '1'     when ( fill_count = to_unsigned (0 ,  fill_count'length) )
                            else    '0';
                            
    flag_full       <=              '1'     when ( fill_count >= ( config_max_addr_reg ) )
                            else    '0';

    -- Output

    rd_strb_o       <= rd_valid;
    rd_data_o       <= rd_data;

    empty           <= flag_empty;
    full            <= flag_full;
 
end architecture;
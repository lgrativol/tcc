
---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils_pkg.all;

------------
-- Entity --
------------

entity lookup_wave is
    generic (
        INIT_FILE                   : string;    -- Specify name/location of RAM initialization file if using one (leave blank if not)
        WORD_WIDTH                  : positive;    -- Specify word width 
        RAM_DEPTH                   : positive;   -- Specify RAM depth (number of entries)
        NB_POINTS_WIDTH             : positive  
    );
    port (
            clock_i                 : in  std_logic;                       			           -- Clock
            areset_i                : in  std_logic;

            -- Memory Write Interface
            mem_write_addr_i        : in  std_logic_vector((ceil_log2(RAM_DEPTH)-1) downto 0);  -- Write address bus, width determined from RAM_DEPTH
            mem_write_enable_i      : in  std_logic;                                            -- Write enable
            mem_write_data_i        : in  std_logic_vector((WORD_WIDTH - 1) downto 0);	      -- RAM input data

            -- Control Interface
            bang_i                  : in  std_logic;
            nb_points_i             : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
            nb_repetitions_i        : in  std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
            restart_i               : in  std_logic;

            -- Wave Interface
            valid_o                 : out std_logic;                       			          
            data_o                  : out std_logic_vector((WORD_WIDTH - 1) downto 0); 
            last_word_o             : out std_logic
    );
end lookup_wave;

------------------
-- Architecture --
------------------

architecture rtl of lookup_wave is

    -------------
    -- Signals --
    -------------
    
    -- Input
    signal new_wave                     : std_logic;
    signal nb_points_reg                : unsigned((NB_POINTS_WIDTH - 1) downto 0);
    signal nb_repetitions_reg           : unsigned((NB_POINTS_WIDTH - 1) downto 0);
    
    signal restart_reg                  : std_logic;
    signal falling_restart              : std_logic;

    -- Memory Interface
    signal mem_write_addr               : std_logic_vector((ceil_log2(RAM_DEPTH) - 1) downto 0);  
    signal mem_write_enable             : std_logic;                       			            
    signal mem_write_data               : std_logic_vector((WORD_WIDTH - 1) downto 0);           

    signal mem_read_addr                : std_logic_vector((ceil_log2(RAM_DEPTH) - 1) downto 0);  
    signal mem_read_enable              : std_logic;                       			            
    signal mem_read_data                : std_logic_vector((WORD_WIDTH - 1) downto 0);           

    signal enable_wave                  : std_logic;
    signal enable_wave_reg              : std_logic;
    signal start_new_cycle_trigger      : std_logic;
    
    signal valid_output                 : std_logic;
    signal valid_output_reg             : std_logic;
    
    signal read_last_word               : std_logic;
    signal read_last_word_reg           : std_logic;

    -- Counters
    signal enable_counters              : std_logic;    
    signal restart_counters             : std_logic;    

    signal counter_nb_points            : unsigned((NB_POINTS_WIDTH - 1) downto 0);    
    signal counter_nb_repetitions       : unsigned((NB_POINTS_WIDTH - 1) downto 0);    
    
    signal counter_nb_points_done       : std_logic;    
    signal counter_nb_repetitions_done  : std_logic;   

begin
    
    -- Write
    mem_write_addr      <= mem_write_addr_i;
    mem_write_enable    <= mem_write_enable_i;
    mem_write_data      <= mem_write_data_i;

    -- Read
    mem_read_addr       <= std_logic_vector(resize(counter_nb_points,mem_read_addr'length));
    mem_read_enable     <= enable_wave;
    
    --Memory
    memory_ent : entity work.sync_ram
        generic map(
            INIT_FILE                 => INIT_FILE,
            WORD_WIDTH                => WORD_WIDTH,
            RAM_DEPTH                 => RAM_DEPTH
        )
        port map(
                clock_i               => clock_i,

                -- Write Interface
                mem_write_addr_i      => mem_write_addr,
                mem_write_enable_i    => mem_write_enable,
                mem_write_data_i      => mem_write_data,

                -- Read Interface
                mem_read_addr_i       => mem_read_addr,
                mem_read_enable_i     => mem_read_enable,
                mem_read_data_o       => mem_read_data
        );


    --Input Registering
    input_registering : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            new_wave  <= '0';
        elsif(rising_edge(clock_i)) then
            new_wave  <= bang_i;

            if (bang_i = '1') then
                nb_points_reg       <= unsigned(nb_points_i);
                nb_repetitions_reg  <= unsigned(nb_repetitions_i);
            end if;
        end if;
    end process;

    -- Signal registering
    signal_reg : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            restart_reg         <= '0';
            enable_wave_reg     <= '0';
            valid_output_reg    <= '0';
            read_last_word_reg  <= '0';
        elsif(rising_edge(clock_i)) then
            restart_reg         <= restart_i;
            enable_wave_reg     <= enable_wave;
            read_last_word_reg  <= read_last_word;
        end if;
    end process;

    falling_restart             <=          not(restart_i)
                                        and restart_reg;


    start_new_cycle_trigger     <=          falling_restart
                                        or  new_wave;  

    enable_wave                 <=          (       start_new_cycle_trigger   
                                                or  enable_wave_reg )
                                            and not(read_last_word_reg);

    valid_output                <=      enable_wave_reg;

    -- Counters

    restart_counters    <=      restart_i
                            or  read_last_word;   

    enable_counters     <=  enable_wave;

    counters_proc : process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            counter_nb_points       <= (others => '0');
            counter_nb_repetitions  <= (others => '0');
        elsif (rising_edge(clock_i)) then

            if(enable_counters = '1') then
               
                if(counter_nb_points_done = '1') then                    
                    counter_nb_points           <= (others => '0');
                    counter_nb_repetitions      <= counter_nb_repetitions + 1;
                else
                    counter_nb_points           <= counter_nb_points + 1;
                end if;                
            end if;

            if((restart_counters = '1')) then
                counter_nb_points           <= (others => '0');
                counter_nb_repetitions      <= (others => '0');
            end if;

        end if;
    end process;

    counter_nb_points_done          <=              '1'     when(counter_nb_points = (nb_points_reg - 1))
                                            else    '0';

    counter_nb_repetitions_done     <=              '1'     when(counter_nb_repetitions = (nb_repetitions_reg - 1))
                                            else    '0';
                                            
    read_last_word                  <=          counter_nb_points_done
                                            and counter_nb_repetitions_done;

    -- Output
    valid_o     <= valid_output;
    data_o      <= mem_read_data;
    last_word_o <= read_last_word_reg;

end rtl;
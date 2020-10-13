
-------------
-- Library --
-------------

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

entity averager is
    generic (
        -- Behavioral
        NB_REPETITIONS_WIDTH        : positive;
        WORD_FRAC_PART              : integer;     
        MAX_NB_POINTS               : natural       -- MAX_NB_POINTS power of 2, needed for BRAM inferece
    );
    port (
        clock_i                     : in  std_logic;
        areset_i                    : in  std_logic;

        -- Config  interface
        config_strb_i               : in  std_logic;
        config_max_addr_i           : in  std_logic_vector( ( ceil_log2(MAX_NB_POINTS + 1) - 1 ) downto 0 ); -- (NB_POINTS - 1)
        config_nb_repetitions_i     : in  std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0);        -- Only powers of 2 ( 2^0, 2^1, 2^2, 2^3 ....)
        config_reset_pointers_i     : in  std_logic;

        -- Input interface 
        input_strb_i                : in  std_logic;
        input_data_i                : in  sfixed( 1 downto WORD_FRAC_PART );
        input_last_word_i           : in  std_logic;

        -- Output interface
        output_strb_o               : out std_logic;
        output_data_o               : out sfixed( 1 downto WORD_FRAC_PART );
        output_last_word_o          : out std_logic
        
    );
end averager;

------------------
-- Architecture --
------------------

architecture behavioral of averager is


    --------------
    -- Constant --
    --------------
    
    -- Memory
    constant    WORD_INT_PART               : positive := 1;
    constant    MAX_ADDR_WIDTH              : positive := config_max_addr_i'length;
    constant    RAM_DEPTH                   : positive := MAX_NB_POINTS;
    constant    MAX_NB_REPETITIONS          : positive := 2**(NB_REPETITIONS_WIDTH - 1);
    --constant    INPUT_WIDTH                 : positive := ( ( WORD_INT_PART + 1) + (- WORD_FRAC_PART) );
    -- The following eqs works because we're considering that the inputs 
    --  will be [ -1 ; +1 ], so we're adding [-1;+1] MAX_NB_REPETITIONS times 

    constant    ACC_WORD_INT_PART           : positive := ceil_log2 (MAX_NB_REPETITIONS + 2) - 1; -- sfixed already take into account the  sign bit
    constant    RAM_DATA_WIDTH              : positive := (ACC_WORD_INT_PART + 1) + (-WORD_FRAC_PART);

    -- "+2" to taking into account the sign bit and the extra representation bit for signed vectors
  
    ------------
    -- Signal --
    ------------
    
    -- Input
    signal config_input_strb                    : std_logic;
    signal config_max_addr                      : std_logic_vector( ( MAX_ADDR_WIDTH - 1 ) downto 0 ); 
    signal config_nb_repetitions                : std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0); -- Only powers of 2 ( 2^0, 2^1, 2^2, 2^3 ....)
    signal config_nb_repetitions_reg            : std_logic_vector( (NB_REPETITIONS_WIDTH - 1) downto 0); 
    signal config_reset_pointers                : std_logic; 
    
    signal input_strb                           : std_logic;
    signal input_strb_reg                       : std_logic;
    signal input_data                           : sfixed( WORD_INT_PART downto WORD_FRAC_PART );
    signal input_data_reg                       : sfixed( WORD_INT_PART downto WORD_FRAC_PART );
    signal input_last_word                      : std_logic;
    signal input_last_word_reg                  : std_logic;

    -- Accumulator
    signal acc_en                               : std_logic;
    signal acc_en_reg                           : std_logic;

    signal resized_input_data                   : sfixed ( ACC_WORD_INT_PART downto WORD_FRAC_PART );
    signal slv_input_data                       : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);  

    signal acc_point                            : sfixed ( ACC_WORD_INT_PART downto WORD_FRAC_PART );      
    signal slv_acc_point                        : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);      

    -- Ring FiFo
    signal fifo_config_input_strb               : std_logic;
    signal fifo_config_max_addr                 : std_logic_vector( ( MAX_ADDR_WIDTH - 1 ) downto 0 );
    signal fifo_config_reset_pointers           : std_logic;
    
    signal fifo_wr_input_strb                   : std_logic;
    signal fifo_wr_data                         : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    
    signal fifo_rd_en                           : std_logic;
    signal fifo_output_strb                     : std_logic;
    signal fifo_rd_data                         : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    signal sfixed_fifo_rd_data                  : sfixed( ACC_WORD_INT_PART downto WORD_FRAC_PART );     

    signal fifo_empty                           : std_logic;
    signal fifo_full                            : std_logic;
    signal fifo_full_reg                        : std_logic;

    signal enable_counter                       : std_logic;
    signal last_word                            : std_logic;
    signal reset_counter_repetitions            : std_logic;
    signal counter_repetitions                  : unsigned( (NB_REPETITIONS_WIDTH - 1) downto 0);
    signal counter_repetitions_done             : std_logic;

    -- Division
    signal nb_shifts                            : unsigned( ( ceil_log2( NB_REPETITIONS_WIDTH + 1) - 1) downto 0  );
    
    signal output_strb                          : std_logic;
    signal output_strb_reg                      : std_logic;
    signal output_data                          : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);

    signal sfixed_output_data                   : sfixed( ACC_WORD_INT_PART downto WORD_FRAC_PART );
    signal cropped_sfx_output_data              : sfixed( WORD_INT_PART downto WORD_FRAC_PART );
    signal output_last_word                     : std_logic;

begin
    
    -- Input
    config_input_strb       <= config_strb_i ;
    config_max_addr         <= config_max_addr_i;
    config_nb_repetitions   <= config_nb_repetitions_i;
    config_reset_pointers   <= config_reset_pointers_i;
    input_strb              <= input_strb_i;
    input_data              <= input_data_i;
    input_last_word         <= input_last_word_i;

    proc_input_reg : process (clock_i , areset_i)
    begin
        if (areset_i = '1') then
            config_nb_repetitions_reg   <= std_logic_vector( to_unsigned(1, config_nb_repetitions_reg'length)  ); -- b"0...0001"
            input_last_word_reg         <= '0';
        elsif ( rising_edge (clock_i) ) then
            input_strb_reg  <= input_strb;

            if(input_strb = '1' ) then
                input_data_reg              <= input_data;
                input_last_word_reg         <= input_last_word;
            end if;
            
            if (config_input_strb = '1') then
                config_nb_repetitions_reg   <= config_nb_repetitions;
            end if;
        end if;
    end process;


    slv_input_data          <= std_logic_vector( resize( unsigned( to_slv(input_data_reg) ), RAM_DATA_WIDTH)); 

    ---------------
    -- Ring FIFO --
    ---------------

    fifo_config_input_strb          <=              config_input_strb;
    fifo_config_max_addr            <=              config_max_addr;
    fifo_config_reset_pointers      <=              config_reset_pointers;

    fifo_wr_input_strb              <=              input_strb_reg; -- Only runs with incomming data

    fifo_wr_data                    <=              slv_acc_point  when ( acc_en_reg = '1' )
                                            else    slv_input_data;

    fifo_rd_en                      <=              input_strb_reg
                                                and acc_en;

    ring_fifo_ent: entity work.ring_fifo
        generic map (
            DATA_WIDTH                  => RAM_DATA_WIDTH,
            RAM_DEPTH                   => RAM_DEPTH
        )
        port map (
            clock_i                     => clock_i,
            areset_i                    => areset_i,

            -- Config  port
            config_strb_i               => fifo_config_input_strb,
            config_max_addr_i           => fifo_config_max_addr,
            config_reset_pointers_i     => fifo_config_reset_pointers,

            -- Write port
            wr_strb_i                   => fifo_wr_input_strb,
            wr_data_i                   => fifo_wr_data,

            -- Read port
            rd_en_i                     => fifo_rd_en,
            rd_strb_o                   => fifo_output_strb, 
            rd_data_o                   => fifo_rd_data, 

            -- Flags
            empty                       => fifo_empty,
            full                        => fifo_full
        );

    enable_counter  <=          input_strb_reg
                            and input_last_word_reg ;   


    reset_counter_repetitions       <=          last_word
                                            or  config_reset_pointers;

    proc_counter_rep : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then

            counter_repetitions <= to_unsigned( 1 , counter_repetitions'length );

        elsif (rising_edge(clock_i)) then

            if ( reset_counter_repetitions = '1' ) then
                counter_repetitions <= to_unsigned( 1 , counter_repetitions'length );

            elsif (enable_counter = '1') then
                if ( counter_repetitions_done = '0') then
                    counter_repetitions <= counter_repetitions + 1;
                end if;

            end if;
        end if;
    end process;

    counter_repetitions_done                <=              '1'     when ( counter_repetitions = ( unsigned(config_nb_repetitions_reg)) )
                                                    else    '0';

    flag_register : process (clock_i , areset_i)
    begin
        if (areset_i = '1') then
            acc_en_reg <= '0';

        elsif ( rising_edge(clock_i) ) then
            fifo_full_reg   <= fifo_full;
            acc_en_reg      <= acc_en;
        end if;
    end process;

    last_word   <=          counter_repetitions_done
                        and input_last_word_reg;

    acc_en      <=      (       fifo_full
                            or  acc_en_reg )
                        and not(last_word);

    resized_input_data      <= resize(input_data_reg, ACC_WORD_INT_PART, WORD_FRAC_PART); 
    sfixed_fifo_rd_data     <= to_sfixed(fifo_rd_data, ACC_WORD_INT_PART, WORD_FRAC_PART);

    acc_point               <= resize ( resized_input_data + sfixed_fifo_rd_data , acc_point );

    slv_acc_point           <= to_slv(acc_point);

    proc_nb_shifts : process(config_nb_repetitions_reg)
    begin
        for i in config_nb_repetitions_reg'range loop
            if( config_nb_repetitions_reg(i) = '1') then
                nb_shifts <= to_unsigned (i, nb_shifts'length );
                exit;
            end if;
        end loop;
    end process;

    output_strb     <=      counter_repetitions_done
                        and fifo_output_strb;

    proc_output_word : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            output_strb_reg   <= '0';
        elsif (rising_edge(clock_i)) then
        
            output_strb_reg <= output_strb;

            if(output_strb = '1') then
                output_data         <= std_logic_vector(   
                                                            resize( 
                                                                        signed ( slv_acc_point( (slv_acc_point'length - 1) downto 
                                                                                 ( to_integer(nb_shifts)) ) 
                                                                                ) 
                                                                    ,output_data'length) 
                                                        ) ; -- fifo_rd_data sra nb_shifts
                output_last_word    <= input_last_word_reg;
            end if;
        end if;
    end process;

    sfixed_output_data  <=  to_sfixed( output_data , ACC_WORD_INT_PART , WORD_FRAC_PART );

    cropped_sfx_output_data <= resize( sfixed_output_data, cropped_sfx_output_data );

    -- Output
    output_strb_o       <= output_strb_reg;
    output_data_o       <= cropped_sfx_output_data;
    output_last_word_o  <= output_last_word;
 
end architecture;
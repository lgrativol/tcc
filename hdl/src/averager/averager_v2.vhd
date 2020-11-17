
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

entity averager_v2 is
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

        ----------------------------------
        -- Output  AXI Stream Interface --
        ----------------------------------
        --busy_o                      : out std_logic;
        s_axis_st_tready_i          : in  std_logic;
        s_axis_st_tvalid_o          : out std_logic;
        s_axis_st_tdata_o           : out std_logic_vector ((2  + (- WORD_FRAC_PART)) downto 0);
        s_axis_st_tkeep_o           : out std_logic_vector (3 downto 0);
        s_axis_st_tlast_o           : out std_logic
        
    );
end averager_v2;

------------------
-- Architecture --
------------------

architecture behavioral of averager_v2 is


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
    signal slv_resized_input_data               : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);  

    signal acc_point                            : sfixed ( ACC_WORD_INT_PART downto WORD_FRAC_PART );      
    signal slv_acc_point                        : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);      

    -- Ring FiFo
    signal fifo_config_input_strb               : std_logic;
    signal fifo_config_max_addr                 : std_logic_vector( ( MAX_ADDR_WIDTH - 1 ) downto 0 );
    signal fifo_config_reset_pointers           : std_logic;
    
    signal fifo_wr_input_strb                   : std_logic;
    signal fifo_wr_data                         : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    
    signal fifo_rd_enable_from_input            : std_logic;
    signal fifo_rd_enable_from_output           : std_logic;
    
    signal enable_read                          : std_logic;
    signal enable_read_reg                      : std_logic;
    
    signal fifo_rd_en                           : std_logic;
    signal fifo_output_strb                     : std_logic;
    signal fifo_rd_data                         : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    signal sfixed_fifo_rd_data                  : sfixed( ACC_WORD_INT_PART downto WORD_FRAC_PART );     

    signal fifo_empty                           : std_logic;
    signal fifo_full                            : std_logic;

    signal enable_counter                       : std_logic;
    signal last_word                            : std_logic;
    signal last_word_reg                        : std_logic;
    signal reset_counter_repetitions            : std_logic;
    signal counter_repetitions                  : unsigned( (NB_REPETITIONS_WIDTH - 1) downto 0);
    signal counter_repetitions_done             : std_logic;

    -- Midway fifo
    signal enable_read_from_fifo                : std_logic;
    
    signal enable_one_fifo                      : std_logic;

    signal one_fifo_strb                        : std_logic;
    signal one_fifo_strb_reg                    : std_logic;
    signal one_fifo_data                        : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    signal one_fifo_last                        : std_logic;

    signal mux_strb                             : std_logic;
    signal mux_data                             : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);
    signal mux_last                             : std_logic;

    -- Division
    signal nb_shifts                            : unsigned( ( ceil_log2( NB_REPETITIONS_WIDTH + 1) - 1) downto 0  );
    
    signal enable_output                        : std_logic;
    signal output_strb                          : std_logic;
    signal output_strb_reg                      : std_logic;
    signal output_data                          : std_logic_vector( (RAM_DATA_WIDTH - 1) downto 0);

    signal output_last_word                     : std_logic;

    -- AXI-ST output interface
    signal s_axis_st_tready                     : std_logic;
    signal s_axis_st_tdata                      : std_logic_vector((s_axis_st_tdata_o'length - 1) downto 0);

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
            config_nb_repetitions_reg   <= (others => '0'); 
            input_last_word_reg         <= '0';
        elsif ( rising_edge (clock_i) ) then
            input_strb_reg  <= input_strb;
            
            if(input_strb = '1' ) then
                input_data_reg              <= input_data;
                input_last_word_reg         <= input_last_word;
            else
                input_last_word_reg         <= '0';
            end if;
            
            if (config_input_strb = '1') then
                config_nb_repetitions_reg   <= config_nb_repetitions;
            end if;
        end if;
    end process;

    resized_input_data              <= resize(input_data_reg, ACC_WORD_INT_PART, WORD_FRAC_PART); 
    slv_resized_input_data          <= to_slv(resized_input_data);

    ---------------
    -- Ring FIFO --
    ---------------

    fifo_config_input_strb          <=              config_input_strb;
    fifo_config_max_addr            <=              config_max_addr;
    fifo_config_reset_pointers      <=              config_reset_pointers;

    fifo_wr_input_strb              <=              input_strb_reg; -- Only runs with incomming data

    fifo_wr_data                    <=              slv_acc_point  when ( acc_en_reg = '1' )
                                            else    slv_resized_input_data;

    fifo_rd_en                      <=              fifo_rd_enable_from_output    when enable_read = '1'
                                            else    fifo_rd_enable_from_input;

    fifo_rd_enable_from_output      <=         enable_read_from_fifo;

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

            counter_repetitions                 <= to_unsigned( 1 , counter_repetitions'length );

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
            acc_en_reg          <= '0';
            enable_read_reg     <= '0';
            last_word_reg       <= '0';
        elsif ( rising_edge(clock_i) ) then
            acc_en_reg      <= acc_en;
            enable_read_reg <= enable_read;
            last_word_reg   <= last_word;
        end if;
    end process;

    last_word           <=          counter_repetitions_done
                                and input_last_word_reg;

    acc_en              <=          (   fifo_full
                                    or  acc_en_reg )
                                and not(last_word);

    enable_read         <=          (    last_word_reg
                                    or  enable_read_reg)
                                and not (output_last_word);

    fifo_rd_enable_from_input       <=          input_strb_reg
                                            and acc_en;

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

    one_fifo_strb           <=          fifo_output_strb
                                    and enable_read;

    enable_one_fifo <=          (       not(s_axis_st_tready)
                                    and one_fifo_strb      )
                            or  (       s_axis_st_tready
                                    and one_fifo_strb_reg     );

    one_fifo_element : process (clock_i,areset_i) 
    begin
        if (areset_i = '1') then
            one_fifo_strb_reg <= '0';
        elsif(rising_edge(clock_i)) then
            if(enable_one_fifo = '1') then
                one_fifo_strb_reg  <= one_fifo_strb;
                if (one_fifo_strb = '1') then
                    one_fifo_data <= fifo_rd_data;
                    one_fifo_last <= fifo_empty;
                end if;
            end if;
        end if;
    end process;

    mux_strb            <=              one_fifo_strb_reg    when    (one_fifo_strb_reg = '1')
                                else    one_fifo_strb;
                                    
    mux_data            <=              one_fifo_data    when    (one_fifo_strb_reg = '1')
                                else    fifo_rd_data;

    mux_last            <=              one_fifo_last    when    (one_fifo_strb_reg = '1')
                                else    fifo_empty;
                                
    enable_read_from_fifo       <=          enable_output
                                        or  (       one_fifo_strb_reg 
                                                nor fifo_output_strb);

    output_strb                     <=   mux_strb;
                                                                                                                                                
    enable_output                   <=      (    s_axis_st_tready
                                            or  not(output_strb_reg))
                                            and enable_read;

    proc_output_word : process(clock_i,areset_i)
    begin
        if (areset_i = '1') then
            output_strb_reg   <= '0';
            output_last_word  <= '0';
        elsif (rising_edge(clock_i)) then

                output_strb_reg <= output_strb;

                if (enable_output = '1') then
                    
                    if(output_strb = '1') then
                        output_data         <= std_logic_vector(   
                                                                    resize( 
                                                                                signed ( mux_data( (mux_data'length - 1) downto 
                                                                                        ( to_integer(nb_shifts)) ) 
                                                                                        ) 
                                                                            ,output_data'length) 
                                                                ) ; -- fifo_rd_data sra nb_shifts
                        output_last_word    <= mux_last; -- check ?!?
                end if;
            end if;
        end if;
    end process;

    s_axis_st_tdata         <= output_data( (s_axis_st_tdata'length - 1) downto 0);

    -- Output
    s_axis_st_tready        <= s_axis_st_tready_i;
    s_axis_st_tvalid_o      <= output_strb_reg;
    s_axis_st_tdata_o       <= s_axis_st_tdata;
    s_axis_st_tkeep_o       <= (others => '1');
    s_axis_st_tlast_o       <= output_last_word;

end architecture;

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
use work.utils_pkg;

------------
-- Entity --
------------

entity upsampler is
    generic (
        WEIGHT_INT_PART         : natural;
        WEIGHT_FRAC_PART        : integer;  
        NB_TAPS                 : positive;
        FIR_WORD_INT_PART       : natural;
        FIR_WORD_FRAC_PART      : integer;
        MAX_FACTOR              : natural;
        DATA_WIDTH              : natural
    );
    port (
        clock_i                 : in std_logic;
        areset_i                : in std_logic;

        -- Insertion config
        upsample_factor_valid_i : in std_logic;
        upsample_factor_i       : in std_logic_vector((utils_pkg.ceil_log2(MAX_FACTOR + 1) - 1) downto 0);

        -- Weights
        weights_valid_i         : in std_logic_vector((NB_TAPS - 1) downto 0);
        weights_data_i          : in std_logic_vector( ((NB_TAPS *(WEIGHT_INT_PART + 1 - WEIGHT_FRAC_PART)) - 1) downto  0);

        -- Wave in
        wave_enable_o           : out std_logic;
        wave_valid_i            : in  std_logic;
        wave_data_i             : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        wave_last_i             : in  std_logic;

        -- Wave Out
        wave_valid_o            : out std_logic;
        wave_data_o             : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        wave_last_o             : out std_logic
    );
end upsampler;

------------------
-- Architecture --
------------------

architecture behavioral of upsampler is


    --------------
    -- Constant --
    --------------
    
    -- Sfixed parts
    --constant    FIR_WORD_INT_PART           : natural := utils_pkg.CORDIC_INTEGER_PART;
    --constant    FIR_WORD_FRAC_PART          : integer := utils_pkg.CORDIC_FRAC_PART;

    
    -- Upsampler
    constant    UPSAMPLE_FACTOR_WIDTH       : positive                                       := upsample_factor_i'length;
    constant    COUNTER_ZERO                : unsigned((UPSAMPLE_FACTOR_WIDTH - 1) downto 0) := (others => '0');
    constant    FIR_SIDEBAND_WIDTH          : natural                                        := 1;
    
   
    ------------
    -- Signal --
    ------------

    -- Upsampler Factor
    signal      upsample_factor         : unsigned((UPSAMPLE_FACTOR_WIDTH - 1) downto 0);


    -- Wave register
    signal      wave_valid_reg          : std_logic;
    signal      wave_data_reg           : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal      wave_last_reg           : std_logic;

    signal      valid_sample            : std_logic;
    signal      sfixed_wave_data        : sfixed(FIR_WORD_INT_PART downto FIR_WORD_FRAC_PART);

    -- Counter

    signal      counter_samples         : unsigned((UPSAMPLE_FACTOR_WIDTH - 1) downto 0);
    signal      counter_samples_zero    : std_logic;
    signal      reset_counter           : std_logic;
    signal      counter_samples_done    : std_logic;
    signal      wave_enable             : std_logic;

    --FIR

    signal      fir_weights_valid       : std_logic_vector((NB_TAPS - 1) downto 0);
    signal      fir_weights_data        : std_logic_vector( ((NB_TAPS *(WEIGHT_INT_PART + 1 - WEIGHT_FRAC_PART)) - 1) downto  0); 

    signal      fir_in_valid            : std_logic;
    signal      fir_in_data             : sfixed(FIR_WORD_INT_PART downto FIR_WORD_FRAC_PART);
    signal      fir_in_sideband         : std_logic_vector((FIR_SIDEBAND_WIDTH - 1) downto 0);
    
    signal      fir_out_valid           : std_logic;
    signal      fir_out_data            : sfixed(FIR_WORD_INT_PART downto FIR_WORD_FRAC_PART);
    signal      fir_out_sideband        : std_logic_vector((FIR_SIDEBAND_WIDTH - 1) downto 0);
    

begin

    -- Upsample factor register
    factor_register_proc : process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            upsample_factor <= to_unsigned(1,upsample_factor'length);
        elsif(rising_edge(clock_i)) then
            if(upsample_factor_valid_i = '1') then
                upsample_factor <= unsigned(upsample_factor_i);
            end if;
        end if;
    end process;

    insert_sample : process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            wave_valid_reg <= '0';
            wave_last_reg   <= '0';
        elsif(rising_edge(clock_i)) then
            wave_valid_reg      <= valid_sample;

            if(valid_sample = '1') then

                if (counter_samples_zero =  '1') then
                    wave_data_reg   <= wave_data_i;
                    wave_last_reg   <= wave_last_i;
                else
                    wave_data_reg   <= (others => '0');
                    wave_last_reg   <= '0';
                end if;
                
            end if;
        end if;
    end process;

    valid_sample            <=                  wave_valid_i
                                            or  (       wave_valid_reg
                                                    and not(wave_last_reg) );

    counter_samples_proc : process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            counter_samples <= (others => '0');
        elsif(rising_edge(clock_i)) then
            if(valid_sample = '1') then
                if(counter_samples_done = '1')then
                    counter_samples <= (others => '0');
                else
                    counter_samples <= counter_samples + 1;
                end if;
            end if;

            if(reset_counter = '1') then
                counter_samples <= (others => '0');
            end if;
        end if;
    end process;


    counter_samples_zero    <=              '1'         when(counter_samples = COUNTER_ZERO)
                                    else    '0';

    counter_samples_done    <=              '1'         when(counter_samples = (upsample_factor - 1))
                                    else    '0';

    reset_counter           <=              wave_last_reg;

    wave_enable             <=          counter_samples_zero;


    fir_weights_valid       <= weights_valid_i;
    fir_weights_data        <= weights_data_i;

    fir_in_valid            <= wave_valid_reg;
    fir_in_data             <= to_sfixed(wave_data_reg,fir_in_data);
    fir_in_sideband(0)      <= wave_last_reg;

    --fir_inst : entity work.fir_direct_core
    fir_inst : entity work.fir_transpose_core
        generic map(
            WEIGHT_INT_PART                 => WEIGHT_INT_PART,
            WEIGHT_FRAC_PART                => WEIGHT_FRAC_PART,
            NB_TAPS                         => NB_TAPS,
            WORD_INT_PART                   => FIR_WORD_INT_PART,
            WORD_FRAC_PART                  => FIR_WORD_FRAC_PART,
            SIDEBAND_WIDTH                  => FIR_SIDEBAND_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                         => clock_i,
            areset_i                        => areset_i,
            
            -- Weights
            weights_valid_i                 => fir_weights_valid,
            weights_data_i                  => fir_weights_data,
            
            --Input
            valid_i                         => fir_in_valid,
            data_i                          => fir_in_data,
            sideband_data_i                 => fir_in_sideband,
        
            -- Ouput 
            valid_o                         => fir_out_valid,
            data_o                          => fir_out_data,
            sideband_data_o                 => fir_out_sideband
        );

    -- Output      
    wave_enable_o           <= wave_enable;
    wave_valid_o            <= fir_out_valid;
    wave_data_o             <= to_slv(fir_out_data);
    wave_last_o             <= fir_out_sideband(0);

end architecture;
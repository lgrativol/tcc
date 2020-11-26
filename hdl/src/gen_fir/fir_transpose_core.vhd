
---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: 21/11/2020                                                                
-- Module Name: fir_transpose_core                                                                
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date:                                                      
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: 
--          
-- Description: 
---------------------------------------------------------------------------------------------

---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee_proposed;                    
use ieee_proposed.fixed_float_types.all;  
use ieee_proposed.fixed_pkg.all;      

library work;
use work.fir_weights_pkg;

------------
-- Entity --
------------

entity fir_transpose_core is
    generic(
        WEIGHT_INT_PART                 : natural;
        WEIGHT_FRAC_PART                : integer;  
        NB_TAPS                         : positive;
        WORD_INT_PART                   : natural;
        WORD_FRAC_PART                  : integer;
        SIDEBAND_WIDTH                  : natural
    );
    port(
        -- Clock interface
        clock_i                         : in  std_logic;
        areset_i                        : in  std_logic; 
        
        -- Weights
        weights_valid_i                 : in std_logic_vector((NB_TAPS - 1) downto 0);
        weights_data_i                  : in std_logic_vector( ((NB_TAPS *(WEIGHT_INT_PART + 1 - WEIGHT_FRAC_PART)) - 1) downto  0);

        --Input
        valid_i                         : in  std_logic; 
        data_i                          : in  sfixed(WORD_INT_PART downto WORD_FRAC_PART);
        sideband_data_i                 : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    
        -- Ouput 
        valid_o                         : out std_logic; 
        data_o                          : out sfixed(WORD_INT_PART downto WORD_FRAC_PART);   
        sideband_data_o                 : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0)
    );
end fir_transpose_core;

------------------
-- Architecture --
------------------

architecture behavioral of fir_transpose_core is

    -----------
    -- Types --
    -----------
    type data_vector_tp       is array (natural range <>) of sfixed(WORD_INT_PART downto WORD_FRAC_PART);
    type sideband_vector_type is array (natural range <>) of std_logic_vector(((SIDEBAND_WIDTH + 1) - 1) downto 0); 
    type weight_vector_tp     is array (natural range <>) of sfixed(WEIGHT_INT_PART downto WEIGHT_FRAC_PART);

    ---------------
    -- Constants --
    ---------------

    constant FIR_NB_TAPS                    : positive := NB_TAPS;
    constant WEIGHT_WIDTH                   : positive := WEIGHT_INT_PART + 1 - WEIGHT_FRAC_PART;

    -------------
    -- Signals --
    -------------

    --Weights
    signal  weights_valid                   : std_logic_vector((FIR_NB_TAPS - 1) downto 0);
    signal  weights_data_vector             : weight_vector_tp(0 to (FIR_NB_TAPS - 1));

    -- Slices vectors
    signal fir_valid                        : std_logic;
    signal fir_valid_reg                    : std_logic;
    signal slv_valid                        : std_logic_vector(0 downto 0);
    signal sample_data                      : sfixed(WORD_INT_PART downto WORD_FRAC_PART);
    signal pipeline_data_vector             : data_vector_tp(0 to FIR_NB_TAPS);

    -- Sideband vector
    signal sideband_data_vector             : sideband_vector_type(0 to FIR_NB_TAPS);

        
begin

    -----------
    -- Input --
    -----------

    -- Fir valid extender
    fir_valid_proc : process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            fir_valid_reg <= '0';
        elsif(rising_edge(clock_i)) then
            fir_valid_reg   <= valid_i;
        end if;
    end process;

    fir_valid                       <=      valid_i
                                        or  fir_valid_reg; 

    sample_data                     <= data_i;
    --pipeline_data_vector(0)         <= data_i; 
    pipeline_data_vector(0)         <= (others => '0'); 
    slv_valid(0)                    <= valid_i;
    sideband_data_vector(0)         <= sideband_data_i & slv_valid;

    weights_reg : process(clock_i,areset_i)
    begin
        if(areset_i = '1') then
            weights_valid   <= (others => '0');
        elsif (rising_edge(clock_i)) then
            weights_valid <= weights_valid_i;
            for weight_index in 0 to (FIR_NB_TAPS - 1) loop
                if (weights_valid_i(weight_index) = '1') then
                    weights_data_vector(weight_index)   <= to_sfixed(weights_data_i( (((weight_index + 1) * WEIGHT_WIDTH) - 1) 
                                                                              downto (       weight_index * WEIGHT_WIDTH)    ),
                                                                    WEIGHT_INT_PART,WEIGHT_FRAC_PART);
                end if; 
            end loop;           
        end if;
    end process;

    ------------------------------------
    -- FIR Transpose slices instances --
    ------------------------------------

    fir_transpose_vector : for fir_index in 0 to (FIR_NB_TAPS - 1) generate
        fir_transpose_slice_inst : entity work.fir_transpose_slice
        generic map (
            WEIGHT_INT_PART     => WEIGHT_INT_PART,
            WEIGHT_FRAC_PART    => WEIGHT_FRAC_PART,
            WORD_INT_PART       => WORD_INT_PART,
            WORD_FRAC_PART      => WORD_FRAC_PART,
            SIDEBAND_WIDTH      => SIDEBAND_WIDTH + 1 -- +1 for valid
        )
        port map (
            clock_i             => clock_i,
            areset_i            => areset_i,

            sideband_data_i     => sideband_data_vector(fir_index),
            sideband_data_o     => sideband_data_vector(fir_index + 1),

            weight_valid_i      => weights_valid((FIR_NB_TAPS - 1) - fir_index),
            weight_data_i       => weights_data_vector((FIR_NB_TAPS - 1) - fir_index),
            
            fir_valid_i         => fir_valid,
            sample_data_i       => sample_data,
            pipeline_data_i     => pipeline_data_vector(fir_index),
            
            pipeline_data_o     => pipeline_data_vector(fir_index + 1)
        );
    end generate;

    ------------
    -- Output --
    ------------
    valid_o             <= sideband_data_vector(FIR_NB_TAPS)(0);
    data_o              <= pipeline_data_vector(FIR_NB_TAPS);
    sideband_data_o     <= sideband_data_vector(FIR_NB_TAPS)(SIDEBAND_WIDTH downto 1);

    
end behavioral;

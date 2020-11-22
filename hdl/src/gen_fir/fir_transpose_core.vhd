
---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: 21/11/2020                                                                
-- Module Name: fir_direct_core                                                                
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

entity fir_direct_core is
    generic(
        WORD_INT_PART                   : natural;
        WORD_FRAC_PART                  : integer;
        SIDEBAND_WIDTH                  : natural
    );
    port(
        -- Clock interface
        clock_i                         : in  std_logic;
        areset_i                        : in  std_logic; 
        
        -- Sideband
        
        --Input
        valid_i                         : in  std_logic; 
        data_i                          : in  sfixed(WORD_INT_PART downto WORD_FRAC_PART);
        sideband_data_i                 : in  std_logic_vector((SIDEBAND_WIDTH - 1) downto 0);
    
        -- Ouput 
        valid_o                         : out std_logic; 
        data_o                          : out sfixed(WORD_INT_PART downto WORD_FRAC_PART);   
        sideband_data_o                 : out std_logic_vector((SIDEBAND_WIDTH - 1) downto 0)
    );
end fir_direct_core;

------------------
-- Architecture --
------------------

architecture behavioral of fir_direct_core is

    -----------
    -- Types --
    -----------
    type data_vector_tp       is array (natural range <>) of sfixed(WORD_INT_PART downto WORD_FRAC_PART);
    type sideband_vector_type is array (natural range <>) of std_logic_vector(((SIDEBAND_WIDTH + 1) - 1) downto 0); 

    ---------------
    -- Constants --
    ---------------

    constant FIR_NB_TAPS                    : positive := fir_weights_pkg.NB_TAPS;

    -------------
    -- Signals --
    -------------

    -- Slices vectors
    signal fir_valid                        : std_logic;
    signal slv_valid                        : std_logic_vector(0 downto 0);
    signal sample_data                      : sfixed(WORD_INT_PART downto WORD_FRAC_PART);
    signal pipeline_data_vector             : data_vector_tp(0 to FIR_NB_TAPS);

    -- Sideband vector
    signal sideband_data_vector             : sideband_vector_type(0 to FIR_NB_TAPS);

        
begin

    -----------
    -- Input --
    -----------
    fir_valid                       <= valid_i; 
    sample_data                     <= data_i;
    pipeline_data_vector(0)         <= (others => '0'); 
    slv_valid(0)                    <= valid_i;
    sideband_data_vector(0)         <= sideband_data_i & slv_valid;

    ------------------------------------
    -- FIR Transpose slices instances --
    ------------------------------------

    fir_transpose_vector : for fir_index in 0 to (FIR_NB_TAPS - 1) generate
        fir_transpose_slice_inst : entity work.fir_transpose_slice
        generic map (
            WEIGHT              => fir_weights_pkg.FIR_WEIGHTS((FIR_NB_TAPS - 1) - fir_index),
            WEIGHT_INT_PART     => fir_weights_pkg.WEIGHT_INT_PART,
            WEIGHT_FRAC_PART    => fir_weights_pkg.WEIGHT_FRAC_PART,
            WORD_INT_PART       => WORD_INT_PART,
            WORD_FRAC_PART      => WORD_FRAC_PART,
            SIDEBAND_WIDTH      => SIDEBAND_WIDTH + 1 -- +1 for valid
        )
        port map (
            clock_i             => clock_i,
            areset_i            => areset_i,

            sideband_data_i     => sideband_data_vector(fir_index),
            sideband_data_o     => sideband_data_vector(fir_index + 1),
            
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

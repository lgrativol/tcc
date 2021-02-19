---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Dezembro/2020                                                                
-- Module Name: top
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date: 16/01/2021
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Implementar a estrutura top (exemplo de implementação)
--          
-- Description: Instancia TOP RX E TOP TX
---------------------------------------------------------------------------------------------

---------------
-- Libraries --
---------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils_pkg.all;
use work.defs_pkg.all;

------------
-- Entity --
------------

entity top is
    port(
        -- Clock and Reset
        axi_aclk                            : in  std_logic;
        axi_aresetn                         : in  std_logic;

        -----------------------------
        -- TX - AXI Lite Interface --
        -----------------------------

        -- AXI Write Address Channel
        s_axi_awaddr                        : in  std_logic_vector((AXI_ADDR_WIDTH - 1) downto 0);
        s_axi_awprot                        : in  std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        s_axi_awvalid                       : in  std_logic;
        s_axi_awready                       : out std_logic;
        -- AXI Write Data Channel
        s_axi_wdata                         : in  std_logic_vector(31 downto 0);
        s_axi_wstrb                         : in  std_logic_vector(3 downto 0);
        s_axi_wvalid                        : in  std_logic;
        s_axi_wready                        : out std_logic;
        -- AXI Read Address Channel
        s_axi_araddr                        : in  std_logic_vector((AXI_ADDR_WIDTH - 1) downto 0);
        s_axi_arprot                        : in  std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        s_axi_arvalid                       : in  std_logic;
        s_axi_arready                       : out std_logic;
        -- AXI Read Data Channel
        s_axi_rdata                         : out std_logic_vector(31 downto 0);
        s_axi_rready                        : in  std_logic;
        s_axi_rresp                         : out std_logic_vector(1 downto 0);
        s_axi_rvalid                        : out std_logic;
        -- AXI Write Response Channel
        s_axi_bresp                         : out std_logic_vector(1 downto 0);
        s_axi_bvalid                        : out std_logic;
        s_axi_bready                        : in  std_logic;
        
        ----------------------
        -- TX - Wave Output --
        ----------------------
        tx_wave_valid_o                     : out std_logic; -- Indica a validade do sinal de saída no clico atual de clock
        tx_wave_data_o                      : out std_logic_vector( (OUTPUT_WIDTH - 1) downto 0); -- Amostra
        tx_wave_done_o                      : out std_logic; -- Indica que a última amostra do sinal

        ---------------------
        -- RX - Wave Input --
        ---------------------
        rx_wave_valid_i                     : in  std_logic; -- Indica a validade do sinal de saída no clico atual de clock
        rx_wave_data_i                      : in  std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);  -- Amostra
        --rx_wave_done_i                      : in  std_logic; -- Indica que a última amostra do sinal

        -------------------------------
        -- RX - AXI Stream Interface --
        -------------------------------
        s_axis_s2mm_0_tready                : in  std_logic;
        s_axis_s2mm_0_tvalid                : out std_logic;
        s_axis_s2mm_0_tdata                 : out std_logic_vector ( 31 downto 0 );
        s_axis_s2mm_0_tkeep                 : out std_logic_vector ( 3 downto 0 );
        s_axis_s2mm_0_tlast                 : out std_logic
    );

end top;

architecture rtl of top is

    ---------------
    -- Constants --
    ---------------

    constant C_S_AXI_ADDR_WIDTH                : positive := AXI_ADDR_WIDTH;

    ------------
    -- Signal --
    ------------

    signal areset                              : std_logic;

    -- TOP TX
    signal tx_control_rx_last_word             : std_logic;
    signal tx_control_enable_rx                : std_logic;
    signal tx_control_system_sending           : std_logic;
    signal tx_control_config_valid_o           : std_logic;
    signal tx_control_nb_points_wave           : std_logic_vector((WAVE_NB_POINTS_WIDTH - 1) downto 0); 
    signal tx_control_nb_repetitions_wave      : std_logic_vector((NB_SHOTS_WIDTH - 1) downto 0); 

    signal tx_output_wave_valid                : std_logic;
    signal tx_output_wave_data                 : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal tx_output_wave_done                 : std_logic;

    -- TOP RX
    signal rx_input_wave_valid                 : std_logic;
    signal rx_input_wave_data                  : std_logic_vector((OUTPUT_WIDTH - 1) downto 0);
    signal rx_input_wave_done                  : std_logic;
   
    signal rx_control_enable_rx                : std_logic;
    signal rx_control_config_valid_i           : std_logic;
    signal rx_control_nb_points_wave           : std_logic_vector((WAVE_NB_POINTS_WIDTH - 1) downto 0);
    signal rx_control_nb_repetitions_wave      : std_logic_vector((NB_SHOTS_WIDTH - 1) downto 0);

    signal rx_input_wave_ready_i               : std_logic;
    signal rx_output_wave_sending              : std_logic;
    signal rx_output_wave_valid                : std_logic;
    signal rx_output_wave_data                 : std_logic_vector((OUTPUT_WIDTH - 1) downto 0);
    signal rx_output_wave_done                 : std_logic;
    
begin
    
    areset                              <= not axi_aresetn;

    --------
    -- TX --
    --------
    tx_control_system_sending  <= rx_output_wave_sending;
    
    TX : entity work.top_tx
        port map(
            -- Clock and Reset
            axi_aclk                            => axi_aclk,
            axi_aresetn                         => axi_aresetn,
            areset_i                            => areset,

            -------------------
            -- AXI Interface --
            -------------------

            -- AXI Write Address Channel
            s_axi_awaddr                        => s_axi_awaddr,
            s_axi_awprot                        => s_axi_awprot,
            s_axi_awvalid                       => s_axi_awvalid,
            s_axi_awready                       => s_axi_awready,
            -- AXI Write Data Channel
            s_axi_wdata                         => s_axi_wdata,
            s_axi_wstrb                         => s_axi_wstrb,
            s_axi_wvalid                        => s_axi_wvalid,
            s_axi_wready                        => s_axi_wready,
            -- AXI Read Address Channel
            s_axi_araddr                        => s_axi_araddr,
            s_axi_arprot                        => s_axi_arprot,
            s_axi_arvalid                       => s_axi_arvalid,
            s_axi_arready                       => s_axi_arready,
            -- AXI Read Data Channel
            s_axi_rdata                         => s_axi_rdata,
            s_axi_rready                        => s_axi_rready,
            s_axi_rresp                         => s_axi_rresp,
            s_axi_rvalid                        => s_axi_rvalid,
            -- AXI Write Response Channel
            s_axi_bresp                         => s_axi_bresp,
            s_axi_bvalid                        => s_axi_bvalid,
            s_axi_bready                        => s_axi_bready,

            ----------------------
            -- Output Interface --
            ----------------------
            -- Wave
            wave_valid_o                        => tx_output_wave_valid,
            wave_data_o                         => tx_output_wave_data, 
            wave_done_o                         => tx_output_wave_done, 

            -- Control
            control_rx_last_word_o              => tx_control_rx_last_word,
            control_enable_rx_o                 => tx_control_enable_rx,
            control_system_sending_i            => tx_control_system_sending,
            control_config_valid_o              => tx_control_config_valid_o,
            control_nb_points_wave_o            => tx_control_nb_points_wave,
            control_nb_repetitions_wave_o       => tx_control_nb_repetitions_wave
        );

    --------
    -- RX --
    --------

    rx_input_wave_valid                 <= rx_wave_valid_i;
    rx_input_wave_data                  <= rx_wave_data_i;
    --rx_input_wave_done                  <= rx_wave_done_i;
    rx_input_wave_done                  <= tx_control_rx_last_word;
    
    rx_input_wave_ready_i               <= s_axis_s2mm_0_tready;
      

    rx_control_enable_rx                <= tx_control_enable_rx;
    rx_control_config_valid_i           <= tx_control_config_valid_o;
    rx_control_nb_points_wave           <= tx_control_nb_points_wave;
    rx_control_nb_repetitions_wave      <= tx_control_nb_repetitions_wave;

   RX : entity work.top_rx
        port map(

            clock_i                             => axi_aclk,
            areset_i                            => areset,
    
            -- Wave
            wave_valid_i                        => rx_input_wave_valid,
            wave_data_i                         => rx_input_wave_data,
            wave_done_i                         => rx_input_wave_done,
    
            -- Control  
            control_enable_rx_i                 => rx_control_enable_rx,
            control_config_valid_i              => rx_control_config_valid_i,
            control_nb_points_wave_i            => rx_control_nb_points_wave,
            control_nb_repetitions_wave_i       => rx_control_nb_repetitions_wave,

            sending_o                           => rx_output_wave_sending,
            s_axis_st_tready_i                  => rx_input_wave_ready_i,
            s_axis_st_tvalid_o                  => rx_output_wave_valid,
            s_axis_st_tdata_o                   => rx_output_wave_data,
            s_axis_st_tlast_o                   => rx_output_wave_done
        );

    ------------
    -- Output --
    ------------

    tx_wave_valid_o         <= tx_output_wave_valid;
    tx_wave_data_o          <= tx_output_wave_data ;
    tx_wave_done_o          <= tx_output_wave_done ;

    s_axis_s2mm_0_tvalid    <= rx_output_wave_valid;
    s_axis_s2mm_0_tdata     <= std_logic_vector( resize (unsigned(rx_output_wave_data) ,  s_axis_s2mm_0_tdata'length));   
    s_axis_s2mm_0_tkeep     <= (others => '1'); --x"F..F"
    s_axis_s2mm_0_tlast     <= rx_output_wave_done;
    
end rtl;
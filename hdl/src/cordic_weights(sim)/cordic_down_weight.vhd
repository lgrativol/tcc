---------------------------------------------------------------------------------------------
--                                                                                         
-- Create Date: Dezembro/2020                                                                
-- Module Name: cordic_down_weight                                                                
-- Author Name: Lucas Grativol Ribeiro            
--                                                                                         
-- Revision Date: 08/01/2021                                                               
-- Tool version: Vivado 2017.4                                                             
--                                                                                         
-- Goal: Entidade para instanciar e servir de teste da entidade downsampler
--                            
-- Description:  Com objetivo de servir de exemplo de instanciação, o bloco conecta um dds_cordic
--               e um downsampler.
--
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
use work.utils_pkg;
--use work.defs_pkg;
use work.register_bank_cordic_weights_regs_pkg.all;

------------
-- Entity --
------------

entity cordic_down_weights is
    generic(
        OUTPUT_WIDTH                        : positive; -- Tamanho da palavra de saída
        WEIGHT_WIDTH                        : positive; -- Tamanho da palavra que representa os pesos do filtros
                                                        -- os pesos são pensados entre [-1;+1]. Assim a parte fracionária
                                                        -- será (WEIGHT_WIDTH - 2)
        AXI_ADDR_WIDTH                      : positive;  -- Tamanho do endereço na interface AXI-MM
        BASEADDR                            : std_logic_vector(31 downto 0) -- Endereço de base do banco de registros (AXI-MM)
    );
    port(
        -- Clock and Reset
        axi_aclk                            : in  std_logic;
        axi_aresetn                         : in  std_logic;

        ------------------------
        -- AXI Lite Interface --
        ------------------------

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
        
        ------------------------
        -- Down - Wave Output --
        ------------------------
        down_wave_valid_o                   : out std_logic; -- Indica a validade dos sinais no ciclo de clock atual
        down_wave_data_o                    : out std_logic_vector( (OUTPUT_WIDTH - 1) downto 0); -- Dados
        down_wave_done_o                    : out std_logic -- Indica a última palavra no streamming
    );

end cordic_down_weights;

architecture rtl of cordic_down_weights is

    ---------------
    -- Constants --
    ---------------
    
    -- AXI
    constant C_S_AXI_ADDR_WIDTH                 : positive  := AXI_ADDR_WIDTH;

    -- Cordic 
    constant PHASE_INTEGER_PART                 : natural  := 4;   -- for unsigned phase
    constant PHASE_FRAC_PART                    : integer  := -27; 
    constant PHASE_WIDTH                        : positive := PHASE_INTEGER_PART + (-PHASE_FRAC_PART) +1;
    constant NB_POINTS_WIDTH                    : positive := 10;
    constant NB_REPT_WIDTH                      : positive := 10;
    constant CORDIC_INTEGER_PART                : natural  := 1;
    constant N_CORDIC_ITERATIONS                : natural  := 10;
    constant CORDIC_FRAC_PART                   : integer  := -(N_CORDIC_ITERATIONS - (CORDIC_INTEGER_PART + 1));
    
    -- Downsampler
    constant MAX_FACTOR                         : positive  := 8;
    constant MAX_FACTOR_WIDTH                   : positive  := utils_pkg.ceil_log2(MAX_FACTOR + 1);
    constant WEIGHT_INT_PART                    : natural   := 0;
    constant WEIGHT_FRAC_PART                   : integer   := -(WEIGHT_WIDTH - WEIGHT_INT_PART - 1);
    constant NB_TAPS                            : natural   := 10;
    constant FIR_WORD_INT_PART                  : natural   := 1;
    constant FIR_WORD_FRAC_PART                 : integer   := -(OUTPUT_WIDTH - FIR_WORD_INT_PART - 1);
    constant FIR_WORD_WIDTH                     : integer   := OUTPUT_WIDTH;
    constant FIR_TYPE                           : string    := "DIREC"; -- ou TRANS


    ------------
    -- Signal --
    ------------

    signal areset                               : std_logic;

    -- Registers

    signal bang                                 : std_logic;
    signal bang_strobe                          : std_logic;
    signal bang_field                           : std_logic_vector(0 downto 0);

    signal sample_frequency_value               : std_logic_vector(26 downto 0);

    signal wave_nb_periods_value                : std_logic_vector(7 downto 0);
    signal wave_nb_points_value                 : std_logic_vector(31 downto 0);

    signal conv_rate_value                      : std_logic_vector(6 downto 0);

    signal weights_strobe                       : std_logic_vector(0 to 9);
    signal weights_value                        : slv16_array_t(0 to 9);

    signal dds_phase_term_value                 : std_logic_vector(31 downto 0);
    signal dds_nb_points_value                  : std_logic_vector(17 downto 0);
    signal dds_nb_periods_value                 : std_logic_vector(31 downto 0);

    -- CORDIC
    signal cordic_valid_i                       : std_logic;
    signal cordic_phase_term                    : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal cordic_nb_points                     : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal cordic_nb_repetitions                : std_logic_vector((NB_REPT_WIDTH - 1) downto 0);
    signal cordic_initial_phase                 : ufixed(PHASE_INTEGER_PART downto PHASE_FRAC_PART);  
    signal cordic_mode_time                     : std_logic;
    signal cordic_restart_cycles                : std_logic;
    
    signal cordic_valid_o                       : std_logic;
    signal cordic_sine_phase                    : sfixed(CORDIC_INTEGER_PART downto CORDIC_FRAC_PART);
    signal cordic_done_cycles                   : std_logic;

    -- Downsampler
    signal downsampler_in_wave_valid              : std_logic;
    signal downsampler_in_wave_data               : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal downsampler_in_wave_last               : std_logic;

    signal downsampler_weights_valid              : std_logic_vector((NB_TAPS - 1) downto 0);
    signal downsampler_weights_data               : std_logic_vector( ((NB_TAPS * WEIGHT_WIDTH) - 1) downto 0);

    signal downsampler_factor_valid               : std_logic;
    signal downsampler_factor                     : std_logic_vector(MAX_FACTOR_WIDTH - 1 downto 0);
    
    signal downsampler_out_wave_valid             : std_logic;
    signal downsampler_out_wave_data              : std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
    signal downsampler_out_wave_last              : std_logic;


begin
    -- A interface AXI-MM usa um reset negativo, pequena conversão,
    -- o resto do design utiliza reset positivo. Ambos assíncronos
    areset                              <= not axi_aresetn;

    -------------------
    -- Register Bank --
    -------------------
    reg_bank_inst : entity work.register_bank_cordic_weights_regs
    generic map (
        AXI_ADDR_WIDTH  => AXI_ADDR_WIDTH,
        BASEADDR        => BASEADDR
    )
    port map(
        -- Clock and Reset
        axi_aclk    => axi_aclk,   
        axi_aresetn => axi_aresetn,
        -- AXI Write Address Channel
        s_axi_awaddr  => s_axi_awaddr, 
        s_axi_awprot  => s_axi_awprot, 
        s_axi_awvalid => s_axi_awvalid,
        s_axi_awready => s_axi_awready,
        -- AXI Write Data Channel
        s_axi_wdata   => s_axi_wdata, 
        s_axi_wstrb   => s_axi_wstrb, 
        s_axi_wvalid  => s_axi_wvalid,
        s_axi_wready  => s_axi_wready,
        -- AXI Read Address Channel
        s_axi_araddr  => s_axi_araddr, 
        s_axi_arprot  => s_axi_arprot,         
        s_axi_arvalid => s_axi_arvalid,
        s_axi_arready => s_axi_arready,
        -- AXI Read Data Channel
        s_axi_rdata   => s_axi_rdata, 
        s_axi_rresp   => s_axi_rresp, 
        s_axi_rvalid  => s_axi_rvalid,
        s_axi_rready  => s_axi_rready,
        -- AXI Write Response Channel
        s_axi_bresp   => s_axi_bresp,
        s_axi_bvalid  => s_axi_bvalid, 
        s_axi_bready  => s_axi_bready,
        -- User Ports  
        version_strobe => open,
        version_field => (others => '1'),
        bang_strobe => bang_strobe,
        bang_field => bang_field,
        sample_frequency_strobe => open,
        sample_frequency_value => sample_frequency_value,
        wave_nb_periods_strobe => open,
        wave_nb_periods_value => wave_nb_periods_value,
        wave_nb_points_strobe => open,
        wave_nb_points_value => wave_nb_points_value,
        conv_rate_strobe => open,
        conv_rate_value => conv_rate_value,
        weights_strobe => open,
        weights_value => weights_value,
        dds_phase_term_strobe => open,
        dds_phase_term_value => dds_phase_term_value,
        dds_nb_points_strobe => open,
        dds_nb_points_value => dds_nb_points_value,
        dds_nb_periods_strobe => open,
        dds_nb_periods_value => open          
    );

    bang    <=          bang_strobe
                    and bang_field(0);

    ------------
    -- Cordic --
    ------------

    cordic_valid_i        <= bang;
    cordic_phase_term     <= to_ufixed(  dds_phase_term_value, cordic_phase_term) ;
    cordic_nb_points      <= dds_nb_points_value(cordic_nb_points'range);
    cordic_nb_repetitions <= "00" & wave_nb_periods_value;
    cordic_initial_phase  <= (others => '0');
    cordic_mode_time      <= '0';

    wave_cordic: entity work.dds_cordic
        generic map(
            PHASE_INTEGER_PART                  => PHASE_INTEGER_PART,
            PHASE_FRAC_PART                     => PHASE_FRAC_PART,
            CORDIC_INTEGER_PART                 => CORDIC_INTEGER_PART,
            CORDIC_FRAC_PART                    => CORDIC_FRAC_PART,
            N_CORDIC_ITERATIONS                 => N_CORDIC_ITERATIONS,
            NB_POINTS_WIDTH                     => NB_POINTS_WIDTH,
            NB_REPT_WIDTH                       => NB_REPT_WIDTH,
            EN_POSPROC                          => FALSE
        )
        port map(
            -- Clock interface
            clock_i                             => axi_aclk,  
            areset_i                            => areset,
    
            -- Input interface
            valid_i                              => cordic_valid_i,
            phase_term_i                        => cordic_phase_term,
            initial_phase_i                     => cordic_initial_phase,
            nb_points_i                         => cordic_nb_points,
            nb_repetitions_i                    => cordic_nb_repetitions,
            mode_time_i                         => cordic_mode_time, 
            
            -- Control interface
            restart_cycles_i                    => '0',
            
            -- Output interface
            valid_o                             => cordic_valid_o,
            sine_phase_o                        => cordic_sine_phase,
            cos_phase_o                         => open,
            done_cycles_o                       => cordic_done_cycles,
            flag_full_cycle_o                   => open
        );

    -----------------
    -- Downsampler --
    -----------------
    process(bang,weights_value)
    begin
        for j in 0 to (NB_TAPS - 1) loop
            downsampler_weights_valid(j)                                                                <= bang;
            downsampler_weights_data( (((j + 1) * WEIGHT_WIDTH ) - 1) downto ((j * WEIGHT_WIDTH )))   <= weights_value(j);
        end loop;
    end process;

    downsampler_factor_valid      <= bang;
    downsampler_factor            <= conv_rate_value(downsampler_factor'range);

    downsampler_in_wave_valid     <= cordic_valid_o;
    downsampler_in_wave_data      <= to_slv(cordic_sine_phase);
    downsampler_in_wave_last      <= cordic_done_cycles;

    downsampler_inst : entity work.downsampler
        generic map(
            FIR_TYPE                => FIR_TYPE,
            WEIGHT_WIDTH            => WEIGHT_WIDTH,
            NB_TAPS                 => NB_TAPS,
            FIR_WIDTH               => FIR_WORD_WIDTH,
            MAX_FACTOR              => MAX_FACTOR,
            DATA_WIDTH              => OUTPUT_WIDTH
        )
        port map(
            clock_i                 => axi_aclk,
            areset_i                => areset,

            -- Insertion config
            downsample_factor_valid_i => downsampler_factor_valid,
            downsample_factor_i       => downsampler_factor,

            -- Weights
            weights_valid_i         => downsampler_weights_valid,
            weights_data_i          => downsampler_weights_data,

            -- Wave in
            wave_valid_i            => downsampler_in_wave_valid,
            wave_data_i             => downsampler_in_wave_data,
            wave_last_i             => downsampler_in_wave_last,

            -- Wave Out
            wave_valid_o            => downsampler_out_wave_valid,
            wave_data_o             => downsampler_out_wave_data,
            wave_last_o             => downsampler_out_wave_last
        );        

    ------------
    -- Output --
    ------------

    down_wave_valid_o         <= downsampler_out_wave_valid;
    down_wave_data_o          <= downsampler_out_wave_data ;
    down_wave_done_o          <= downsampler_out_wave_last ;
    
end rtl;
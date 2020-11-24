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

entity top_tx is
    generic(
        OUTPUT_WIDTH                        : positive                      := 10;
        AXI_ADDR_WIDTH                      : positive                      := 32;  -- width of the AXI address bus
        BASEADDR                            : std_logic_vector(31 downto 0) := x"00000000" -- the register file's system base address		
    );
    port(
        -- Clock and Reset
        axi_aclk                            : in  std_logic;
        axi_aresetn                         : in  std_logic;
        areset_i                            : in  std_logic;

        -------------------
        -- AXI Interface --
        -------------------

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
        -- Output Interface --
        ----------------------
        
        -- Wave
        wave_valid_o                        : out std_logic;
        wave_data_o                         : out std_logic_vector( (OUTPUT_WIDTH - 1) downto 0);
        wave_done_o                         : out std_logic;

        -- Control
        control_bang_o                      : out std_logic;
        
        control_sample_frequency_valid_o    : out std_logic;
        control_sample_frequency_o          : out std_logic_vector(26 downto 0); --TBD

        control_enable_rx_o                 : out std_logic;
        control_system_sending_i            : in  std_logic;
        control_reset_averager_o            : out std_logic;
        control_config_valid_o              : out std_logic;
        control_nb_points_wave_o            : out std_logic_vector(31 downto 0); -- TBD
        control_nb_repetitions_wave_o       : out std_logic_vector(5 downto 0)  -- TBD
    );

end top_tx;

------------------
-- Architecture --
------------------
architecture behavioral of top_tx is

    ---------------
    -- Constants --
    ---------------

    constant    VERSION                             : std_logic_vector(7 downto 0)  :=x"01" ;

    constant    WAVE_GEN_OUTPUT_DATA_WIDTH          : positive  := 10;
    constant    NB_SHOTS_WIDTH            : positive  := 6;

    constant    CONFIG_NB_POINTS_WIDTH              : positive  := control_nb_points_wave_o'length;


    -------------
    -- Signals --
    -------------
    
    -- User signals

    signal      bang                                    : std_logic;
    signal      bang_strobe                             : std_logic;
    signal      bang_field                              : std_logic_vector(0 downto 0);

    signal      wave_config_wave_type                   : std_logic_vector(3 downto 0); -- TBD
    signal      wave_config_win_type                    : std_logic_vector(3 downto 0); -- TBD

    signal      sample_frequency_strobe                 : std_logic;
    signal      sample_frequency_value                  : std_logic_vector(26 downto 0); --TBD

    signal      wave_nb_points_strobe                   : std_logic;
    signal      wave_nb_points_value                    : std_logic_vector(31 downto 0);
    
    signal      fsm_nb_shots_strobe               : std_logic;
    signal      fsm_nb_shots_value                : std_logic_vector((NB_SHOTS_WIDTH - 1) downto 0); -- TBD
    signal      delay_timer_value                       : std_logic_vector((TX_TIME_WIDTH - 1) downto 0);
    signal      tx_timer_value                          : std_logic_vector((TX_TIME_WIDTH - 1) downto 0);
    signal      deadzone_timer_value                    : std_logic_vector((DEADZONE_TIME_WIDTH - 1) downto 0);
    signal      rx_timer_value                          : std_logic_vector((RX_TIME_WIDTH - 1) downto 0);
    signal      idle_timer_value                        : std_logic_vector((IDLE_TIME_WIDTH - 1) downto 0);
    
    signal      pulser_nb_repetitions_value             : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      pulser_t1_value                         : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal      pulser_t2_value                         : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal      pulser_t3_value                         : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal      pulser_t4_value                         : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal      pulser_tdamp_value                      : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal      pulser_config_invert                    : std_logic_vector(0 downto 0);
    signal      pulser_config_triple                    : std_logic_vector(0 downto 0);

    signal      dds_phase_term_value                    : std_logic_vector((PHASE_WIDTH - 1) downto 0);
    signal      dds_init_phase_value                    : std_logic_vector((PHASE_WIDTH - 1) downto 0);
    signal      dds_nb_points                           : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_nb_repetitions                      : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      dds_mode_time                           : std_logic_vector(0 downto 0);

    -- Wave Generator
    signal      wave_gen_bang                           : std_logic;
    signal      wave_gen_restart_wave                   : std_logic;

    signal      wave_gen_wave_config                    : std_logic_vector(7 downto 0);

    signal      wave_gen_pulser_nb_repetitions_value    : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      wave_gen_pulser_t1_value                : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal      wave_gen_pulser_t2_value                : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal      wave_gen_pulser_t3_value                : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal      wave_gen_pulser_t4_value                : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal      wave_gen_pulser_tdamp_value             : std_logic_vector((TIMER_WIDTH - 1) downto 0);
    signal      wave_gen_pulser_config_invert           : std_logic;
    signal      wave_gen_pulser_config_triple           : std_logic;

    signal      wave_gen_dds_phase_term_value           : std_logic_vector((PHASE_WIDTH - 1) downto 0);
    signal      wave_gen_dds_init_phase_value           : std_logic_vector((PHASE_WIDTH - 1) downto 0);
    signal      wave_gen_dds_nb_points                  : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      wave_gen_dds_nb_repetitions             : std_logic_vector((NB_POINTS_WIDTH - 1) downto 0);
    signal      wave_gen_dds_mode_time                  : std_logic;

    signal      wave_gen_valid_o                        : std_logic;
    signal      wave_gen_wave_data_o                    : std_logic_vector((OUTPUT_WIDTH - 1) downto 0);
    signal      wave_gen_wave_done                      : std_logic;

    --FSM         
    signal      fsm_bang_i                              : std_logic;
    signal      fsm_bang_o                              : std_logic;
    signal      fsm_nb_shots                      : std_logic_vector((NB_SHOTS_WIDTH - 1) downto 0); -- TBD
    signal      fsm_delay_time                          : std_logic_vector((DELAY_TIME_WIDTH - 1) downto 0);
    signal      fsm_tx_time                             : std_logic_vector((TX_TIME_WIDTH - 1) downto 0);
    signal      fsm_deadzone_time                         : std_logic_vector((DEADZONE_TIME_WIDTH - 1) downto 0);
    signal      fsm_rx_time                             : std_logic_vector((RX_TIME_WIDTH - 1) downto 0);
    signal      fsm_idle_time                            : std_logic_vector((IDLE_TIME_WIDTH - 1) downto 0);
    
    signal      fsm_output_valid                        : std_logic;
    signal      fsm_system_busy                         : std_logic;
   
    signal      fsm_enable_rx                           : std_logic;
    signal      fsm_restart_cycles                      : std_logic;
    signal      fsm_end_zons_cycles                     : std_logic;

    -- Output
    signal      control_config_output_valid             : std_logic;

begin

    -------------------
    -- Register Bank --
    -------------------

    register_bank_inst : entity work.register_bank_regs
    generic map (
            AXI_ADDR_WIDTH      => AXI_ADDR_WIDTH,
            BASEADDR            => BASEADDR
        )
        port map(
            -- Clock and Reset
            axi_aclk                            => axi_aclk,   
            axi_aresetn                         => axi_aresetn,

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
            s_axi_arready                       => s_axi_arready,
            s_axi_arvalid                       => s_axi_arvalid,
            -- AXI Read Data Channel
            s_axi_rdata                         => s_axi_rdata, 
            s_axi_rresp                         => s_axi_rresp, 
            s_axi_rvalid                        => s_axi_rvalid,
            s_axi_rready                        => s_axi_rready,
            -- AXI Write Response Channel
            s_axi_bresp                         => s_axi_bresp,
            s_axi_bvalid                        => s_axi_bvalid, 
            s_axi_bready                        => s_axi_bready,
            
            ----------------
            -- User Ports --
            ----------------
            version_strobe => open,
            version_field => VERSION,
            bang_strobe => bang_strobe,
            bang_field => bang_field,
            wave_config_strobe => open,
            wave_config_wave_type => wave_config_wave_type,
            wave_config_win_type => wave_config_win_type,
            sample_frequency_strobe => sample_frequency_strobe,
            sample_frequency_value => sample_frequency_value,
            wave_nb_points_strobe => wave_nb_points_strobe,
            wave_nb_points_value => wave_nb_points_value,
            fsm_nb_repetitions_strobe => fsm_nb_shots_strobe,
            fsm_nb_repetitions_value => fsm_nb_shots_value,
            tx_timer_strobe => open,
            tx_timer_value => tx_timer_value,
            deadzone_timer_strobe => open,
            deadzone_timer_value => deadzone_timer_value,
            rx_timer_strobe => open,
            rx_timer_value => rx_timer_value,
            idle_timer_strobe => open,
            idle_timer_value => idle_timer_value,
            pulser_nb_repetitions_strobe => open,
            pulser_nb_repetitions_value => pulser_nb_repetitions_value,
            pulser_t1_strobe => open,
            pulser_t1_value => pulser_t1_value,
            pulser_t2_strobe => open,
            pulser_t2_value => pulser_t2_value,
            pulser_t3_strobe => open,
            pulser_t3_value => pulser_t3_value,
            pulser_t4_strobe => open,
            pulser_t4_value => pulser_t4_value,
            pulser_tdamp_strobe => open,
            pulser_tdamp_value => pulser_tdamp_value,
            pulser_config_strobe => open,
            pulser_config_invert => pulser_config_invert,
            pulser_config_triple => pulser_config_triple,
            dds_phase_term_strobe => open,
            dds_phase_term_value => dds_phase_term_value,
            dds_init_phase_strobe => open,
            dds_init_phase_value => dds_init_phase_value,
            dds_nb_strobe => open,
            dds_nb_points => dds_nb_points,
            dds_nb_repetitions => dds_nb_repetitions,
            dds_mode_strobe => open,
            dds_mode_time => dds_mode_time
        );

    bang        <=              bang_strobe 
                            and bang_field(0);


    --------------
    -- Wave Gen --
    --------------   
    
    wave_gen_bang           <=          fsm_bang_o;

    wave_gen_pulser_nb_repetitions_value    <= pulser_nb_repetitions_value;
    wave_gen_pulser_t1_value                <= pulser_t1_value;
    wave_gen_pulser_t2_value                <= pulser_t2_value;
    wave_gen_pulser_t3_value                <= pulser_t3_value;
    wave_gen_pulser_t4_value                <= pulser_t4_value;
    wave_gen_pulser_tdamp_value             <= pulser_tdamp_value;
    wave_gen_pulser_config_invert           <= pulser_config_invert(0);
    wave_gen_pulser_config_triple           <= pulser_config_triple(0);

    wave_gen_dds_phase_term_value           <= dds_phase_term_value;
    wave_gen_dds_init_phase_value           <= dds_init_phase_value;
    wave_gen_dds_nb_points                  <= dds_nb_points;
    wave_gen_dds_nb_repetitions             <= dds_nb_repetitions;
    wave_gen_dds_mode_time                  <= dds_mode_time(0);

    wave_gen_wave_config                    <= ( wave_config_win_type & wave_config_wave_type );   

    wave_gen_restart_wave                   <= fsm_restart_cycles;        

    wave_gen_inst : entity work.wave_generator
        generic map(
            OUTPUT_WIDTH                        => WAVE_GEN_OUTPUT_DATA_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => axi_aclk,
            areset_i                            => areset_i,
    
            -- Input interface
            bang_i                              => wave_gen_bang,
            wave_config_i                       => wave_gen_wave_config,
            restart_wave_i                      => wave_gen_restart_wave,

            pulser_nb_repetitions_value_i       => wave_gen_pulser_nb_repetitions_value,
            pulser_t1_value_i                   => wave_gen_pulser_t1_value,
            pulser_t2_value_i                   => wave_gen_pulser_t2_value,
            pulser_t3_value_i                   => wave_gen_pulser_t3_value,
            pulser_t4_value_i                   => wave_gen_pulser_t4_value,
            pulser_tdamp_value_i                => wave_gen_pulser_tdamp_value,
            pulser_config_invert_i              => wave_gen_pulser_config_invert,
            pulser_config_triple_i              => wave_gen_pulser_config_triple,

            -- Cordic 
            dds_phase_term_value_i              => wave_gen_dds_phase_term_value,
            dds_init_phase_value_i              => wave_gen_dds_init_phase_value,
            dds_nb_points_i                     => wave_gen_dds_nb_points,
            dds_nb_repetitions_i                => wave_gen_dds_nb_repetitions,
            dds_mode_time_i                     => wave_gen_dds_mode_time,
    
            -- Output interface
            valid_o                              => wave_gen_valid_o,
            wave_data_o                         => wave_gen_wave_data_o,
            wave_done_o                         => wave_gen_wave_done
        );

    ---------
    -- FSM --
    ---------

    fsm_bang_i          <=              bang;

    fsm_nb_shots  <= fsm_nb_shots_value;
    --fsm_delay_time      <= delay_timer_value;
    fsm_delay_time      <= tx_timer_value;
    fsm_tx_time         <= tx_timer_value;
    fsm_deadzone_time     <= deadzone_timer_value;
    fsm_rx_time         <= rx_timer_value;
    fsm_idle_time        <= idle_timer_value;
    fsm_output_valid    <= wave_gen_valid_o;
    fsm_system_busy     <= control_system_sending_i;

    fsm_zone_inst : entity work.fsm_time_zones_v2
        generic map(
            NB_SHOTS_WIDTH                      => NB_SHOTS_WIDTH
        )
        port map(
            -- Clock interface
            clock_i                             => axi_aclk,
            areset_i                            => areset_i,
    
            -- Input interface
            bang_i                              => fsm_bang_i,
            nb_shots_i                          => fsm_nb_shots,
            delay_time_i                        => fsm_delay_time,
            tx_time_i                           => fsm_tx_time,
            deadzone_time_i                     => fsm_deadzone_time,
            rx_time_i                           => fsm_rx_time,
            idle_time_i                         => fsm_idle_time,
            
            -- Feedback interface
            output_valid_i                      => fsm_output_valid,
            system_busy_i                       => fsm_system_busy,
            bang_o                              => fsm_bang_o,

            -- Control Interface
            enable_rx_o                         => fsm_enable_rx,
            restart_cycles_o                    => fsm_restart_cycles,
            end_zones_cycle_o                   => fsm_end_zons_cycles
        );

    -- Output

    wave_valid_o                        <= wave_gen_valid_o;
    wave_data_o                         <= wave_gen_wave_data_o;
    wave_done_o                         <= wave_gen_wave_done;

    -- Control
    control_bang_o                      <= fsm_bang_o;
    
    control_sample_frequency_valid_o    <= sample_frequency_strobe;
    control_sample_frequency_o          <= sample_frequency_value;

    control_enable_rx_o                 <= fsm_enable_rx;   
    control_reset_averager_o            <= fsm_end_zons_cycles;
    
    control_config_valid_o              <=          fsm_nb_shots_strobe
                                                or  wave_nb_points_strobe;
                                                
    control_nb_points_wave_o            <= wave_nb_points_value;
    control_nb_repetitions_wave_o       <= fsm_nb_shots_value;

end behavioral;
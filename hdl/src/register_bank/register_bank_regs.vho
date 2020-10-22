-- -----------------------------------------------------------------------------
-- 'register_bank' Register Component
-- Revision: 125
-- -----------------------------------------------------------------------------
-- Generated on 2020-10-20 at 01:09 (UTC) by airhdl version 2020.10.1
-- -----------------------------------------------------------------------------
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
-- POSSIBILITY OF SUCH DAMAGE.
-- -----------------------------------------------------------------------------

------------- Begin Cut here for COMPONENT Declaration -------------------------
component register_bank_regs
    generic(
        AXI_ADDR_WIDTH : integer := 32;  -- width of the AXI address bus
        BASEADDR : std_logic_vector(31 downto 0) := x"00000000" -- the register file's system base address
    );
    port(
        -- Clock and Reset
        axi_aclk    : in  std_logic;
        axi_aresetn : in  std_logic;
        -- AXI Write Address Channel
        s_axi_awaddr  : in  std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_awprot  : in  std_logic_vector(2 downto 0);
        s_axi_awvalid : in  std_logic;
        s_axi_awready : out std_logic;
        -- AXI Write Data Channel
        s_axi_wdata   : in  std_logic_vector(31 downto 0);
        s_axi_wstrb   : in  std_logic_vector(3 downto 0);
        s_axi_wvalid  : in  std_logic;
        s_axi_wready  : out std_logic;
        -- AXI Read Address Channel
        s_axi_araddr  : in  std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arprot  : in  std_logic_vector(2 downto 0);
        s_axi_arvalid : in  std_logic;
        s_axi_arready : out std_logic;
        -- AXI Read Data Channel
        s_axi_rdata   : out std_logic_vector(31 downto 0);
        s_axi_rresp   : out std_logic_vector(1 downto 0);
        s_axi_rvalid  : out std_logic;
        s_axi_rready  : in  std_logic;
        -- AXI Write Response Channel
        s_axi_bresp   : out std_logic_vector(1 downto 0);
        s_axi_bvalid  : out std_logic;
        s_axi_bready  : in  std_logic;
        -- User Ports          
        version_strobe : out std_logic; -- Strobe signal for register 'version' (pulsed when the register is read from the bus)
        version_field : in std_logic_vector(7 downto 0); -- Value of register 'version', field 'field'
        bang_strobe : out std_logic; -- Strobe signal for register 'bang' (pulsed when the register is written from the bus)
        bang_field : out std_logic_vector(0 downto 0); -- Value of register 'bang', field 'field'
        wave_config_strobe : out std_logic; -- Strobe signal for register 'wave_config' (pulsed when the register is written from the bus)
        wave_config_wave_type : out std_logic_vector(3 downto 0); -- Value of register 'wave_config', field 'wave_type'
        wave_config_win_type : out std_logic_vector(3 downto 0); -- Value of register 'wave_config', field 'win_type'
        sample_frequency_strobe : out std_logic; -- Strobe signal for register 'sample_frequency' (pulsed when the register is written from the bus)
        sample_frequency_value : out std_logic_vector(26 downto 0); -- Value of register 'sample_frequency', field 'value'
        wave_nb_points_strobe : out std_logic; -- Strobe signal for register 'wave_nb_points' (pulsed when the register is written from the bus)
        wave_nb_points_value : out std_logic_vector(31 downto 0); -- Value of register 'wave_nb_points', field 'value'
        fsm_nb_repetitions_strobe : out std_logic; -- Strobe signal for register 'fsm_nb_repetitions' (pulsed when the register is written from the bus)
        fsm_nb_repetitions_value : out std_logic_vector(5 downto 0); -- Value of register 'fsm_nb_repetitions', field 'value'
        tx_timer_strobe : out std_logic; -- Strobe signal for register 'tx_timer' (pulsed when the register is written from the bus)
        tx_timer_value : out std_logic_vector(17 downto 0); -- Value of register 'tx_timer', field 'value'
        deadzone_timer_strobe : out std_logic; -- Strobe signal for register 'deadzone_timer' (pulsed when the register is written from the bus)
        deadzone_timer_value : out std_logic_vector(17 downto 0); -- Value of register 'deadzone_timer', field 'value'
        rx_timer_strobe : out std_logic; -- Strobe signal for register 'rx_timer' (pulsed when the register is written from the bus)
        rx_timer_value : out std_logic_vector(17 downto 0); -- Value of register 'rx_timer', field 'value'
        idle_timer_strobe : out std_logic; -- Strobe signal for register 'idle_timer' (pulsed when the register is written from the bus)
        idle_timer_value : out std_logic_vector(17 downto 0); -- Value of register 'idle_timer', field 'value'
        pulser_nb_repetitions_strobe : out std_logic; -- Strobe signal for register 'pulser_nb_repetitions' (pulsed when the register is written from the bus)
        pulser_nb_repetitions_value : out std_logic_vector(9 downto 0); -- Value of register 'pulser_nb_repetitions', field 'value'
        pulser_t1_strobe : out std_logic; -- Strobe signal for register 'pulser_t1' (pulsed when the register is written from the bus)
        pulser_t1_value : out std_logic_vector(9 downto 0); -- Value of register 'pulser_t1', field 'value'
        pulser_t2_strobe : out std_logic; -- Strobe signal for register 'pulser_t2' (pulsed when the register is written from the bus)
        pulser_t2_value : out std_logic_vector(9 downto 0); -- Value of register 'pulser_t2', field 'value'
        pulser_t3_strobe : out std_logic; -- Strobe signal for register 'pulser_t3' (pulsed when the register is written from the bus)
        pulser_t3_value : out std_logic_vector(9 downto 0); -- Value of register 'pulser_t3', field 'value'
        pulser_t4_strobe : out std_logic; -- Strobe signal for register 'pulser_t4' (pulsed when the register is written from the bus)
        pulser_t4_value : out std_logic_vector(9 downto 0); -- Value of register 'pulser_t4', field 'value'
        pulser_tdamp_strobe : out std_logic; -- Strobe signal for register 'pulser_tdamp' (pulsed when the register is written from the bus)
        pulser_tdamp_value : out std_logic_vector(9 downto 0); -- Value of register 'pulser_tdamp', field 'value'
        pulser_config_strobe : out std_logic; -- Strobe signal for register 'pulser_config' (pulsed when the register is written from the bus)
        pulser_config_invert : out std_logic_vector(0 downto 0); -- Value of register 'pulser_config', field 'invert'
        pulser_config_triple : out std_logic_vector(0 downto 0); -- Value of register 'pulser_config', field 'triple'
        dds_phase_term_strobe : out std_logic; -- Strobe signal for register 'dds_phase_term' (pulsed when the register is written from the bus)
        dds_phase_term_value : out std_logic_vector(31 downto 0); -- Value of register 'dds_phase_term', field 'value'
        dds_init_phase_strobe : out std_logic; -- Strobe signal for register 'dds_init_phase' (pulsed when the register is written from the bus)
        dds_init_phase_value : out std_logic_vector(31 downto 0); -- Value of register 'dds_init_phase', field 'value'
        dds_nb_strobe : out std_logic; -- Strobe signal for register 'dds_nb' (pulsed when the register is written from the bus)
        dds_nb_points : out std_logic_vector(9 downto 0); -- Value of register 'dds_nb', field 'points'
        dds_nb_repetitions : out std_logic_vector(9 downto 0); -- Value of register 'dds_nb', field 'repetitions'
        dds_mode_strobe : out std_logic; -- Strobe signal for register 'dds_mode' (pulsed when the register is written from the bus)
        dds_mode_time : out std_logic_vector(0 downto 0) -- Value of register 'dds_mode', field 'time'
    );
end component;
------------- End COMPONENT Declaration ----------------------------------------

------------- Begin Cut here for CONSTANT and SIGNAL Declarations --------------
-- Constants:
constant AXI_ADDR_WIDTH : integer := 32;  -- width of the AXI address bus		
constant BASEADDR : std_logic_vector(31 downto 0) := x"00000000"; -- the register file's system base address

-- AXI interface signals:
signal axi_aclk    : std_logic;
signal axi_aresetn : std_logic;
signal s_axi_awaddr  : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
signal s_axi_awprot  : std_logic_vector(2 downto 0);
signal s_axi_awvalid : std_logic;
signal s_axi_awready : std_logic;
signal s_axi_wdata   : std_logic_vector(31 downto 0);
signal s_axi_wstrb   : std_logic_vector(3 downto 0);
signal s_axi_wvalid  : std_logic;
signal s_axi_wready  : std_logic;
signal s_axi_araddr  : std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
signal s_axi_arprot  : std_logic_vector(2 downto 0);
signal s_axi_arvalid : std_logic;
signal s_axi_arready : std_logic;
signal s_axi_rdata   : std_logic_vector(31 downto 0);
signal s_axi_rresp   : std_logic_vector(1 downto 0);
signal s_axi_rvalid  : std_logic;
signal s_axi_rready  : std_logic;
signal s_axi_bresp   : std_logic_vector(1 downto 0);
signal s_axi_bvalid  : std_logic;
signal s_axi_bready  : std_logic;

-- User signals:
signal version_strobe : std_logic;
signal version_field : std_logic_vector(7 downto 0);
signal bang_strobe : std_logic;
signal bang_field : std_logic_vector(0 downto 0);
signal wave_config_strobe : std_logic;
signal wave_config_wave_type : std_logic_vector(3 downto 0);
signal wave_config_win_type : std_logic_vector(3 downto 0);
signal sample_frequency_strobe : std_logic;
signal sample_frequency_value : std_logic_vector(26 downto 0);
signal wave_nb_points_strobe : std_logic;
signal wave_nb_points_value : std_logic_vector(31 downto 0);
signal fsm_nb_repetitions_strobe : std_logic;
signal fsm_nb_repetitions_value : std_logic_vector(5 downto 0);
signal tx_timer_strobe : std_logic;
signal tx_timer_value : std_logic_vector(17 downto 0);
signal deadzone_timer_strobe : std_logic;
signal deadzone_timer_value : std_logic_vector(17 downto 0);
signal rx_timer_strobe : std_logic;
signal rx_timer_value : std_logic_vector(17 downto 0);
signal idle_timer_strobe : std_logic;
signal idle_timer_value : std_logic_vector(17 downto 0);
signal pulser_nb_repetitions_strobe : std_logic;
signal pulser_nb_repetitions_value : std_logic_vector(9 downto 0);
signal pulser_t1_strobe : std_logic;
signal pulser_t1_value : std_logic_vector(9 downto 0);
signal pulser_t2_strobe : std_logic;
signal pulser_t2_value : std_logic_vector(9 downto 0);
signal pulser_t3_strobe : std_logic;
signal pulser_t3_value : std_logic_vector(9 downto 0);
signal pulser_t4_strobe : std_logic;
signal pulser_t4_value : std_logic_vector(9 downto 0);
signal pulser_tdamp_strobe : std_logic;
signal pulser_tdamp_value : std_logic_vector(9 downto 0);
signal pulser_config_strobe : std_logic;
signal pulser_config_invert : std_logic_vector(0 downto 0);
signal pulser_config_triple : std_logic_vector(0 downto 0);
signal dds_phase_term_strobe : std_logic;
signal dds_phase_term_value : std_logic_vector(31 downto 0);
signal dds_init_phase_strobe : std_logic;
signal dds_init_phase_value : std_logic_vector(31 downto 0);
signal dds_nb_strobe : std_logic;
signal dds_nb_points : std_logic_vector(9 downto 0);
signal dds_nb_repetitions : std_logic_vector(9 downto 0);
signal dds_mode_strobe : std_logic;
signal dds_mode_time : std_logic_vector(0 downto 0);
------------- End CONSTANT and SIGNAL Declarations -----------------------------

------------- Begin Cut here for INSTANTIATION Template ------------------------
your_instance_name : register_bank_regs
    generic map (
        AXI_ADDR_WIDTH => AXI_ADDR_WIDTH,
        BASEADDR => BASEADDR
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
        version_strobe => version_strobe,
        version_field => version_field,
        bang_strobe => bang_strobe,
        bang_field => bang_field,
        wave_config_strobe => wave_config_strobe,
        wave_config_wave_type => wave_config_wave_type,
        wave_config_win_type => wave_config_win_type,
        sample_frequency_strobe => sample_frequency_strobe,
        sample_frequency_value => sample_frequency_value,
        wave_nb_points_strobe => wave_nb_points_strobe,
        wave_nb_points_value => wave_nb_points_value,
        fsm_nb_repetitions_strobe => fsm_nb_repetitions_strobe,
        fsm_nb_repetitions_value => fsm_nb_repetitions_value,
        tx_timer_strobe => tx_timer_strobe,
        tx_timer_value => tx_timer_value,
        deadzone_timer_strobe => deadzone_timer_strobe,
        deadzone_timer_value => deadzone_timer_value,
        rx_timer_strobe => rx_timer_strobe,
        rx_timer_value => rx_timer_value,
        idle_timer_strobe => idle_timer_strobe,
        idle_timer_value => idle_timer_value,
        pulser_nb_repetitions_strobe => pulser_nb_repetitions_strobe,
        pulser_nb_repetitions_value => pulser_nb_repetitions_value,
        pulser_t1_strobe => pulser_t1_strobe,
        pulser_t1_value => pulser_t1_value,
        pulser_t2_strobe => pulser_t2_strobe,
        pulser_t2_value => pulser_t2_value,
        pulser_t3_strobe => pulser_t3_strobe,
        pulser_t3_value => pulser_t3_value,
        pulser_t4_strobe => pulser_t4_strobe,
        pulser_t4_value => pulser_t4_value,
        pulser_tdamp_strobe => pulser_tdamp_strobe,
        pulser_tdamp_value => pulser_tdamp_value,
        pulser_config_strobe => pulser_config_strobe,
        pulser_config_invert => pulser_config_invert,
        pulser_config_triple => pulser_config_triple,
        dds_phase_term_strobe => dds_phase_term_strobe,
        dds_phase_term_value => dds_phase_term_value,
        dds_init_phase_strobe => dds_init_phase_strobe,
        dds_init_phase_value => dds_init_phase_value,
        dds_nb_strobe => dds_nb_strobe,
        dds_nb_points => dds_nb_points,
        dds_nb_repetitions => dds_nb_repetitions,
        dds_mode_strobe => dds_mode_strobe,
        dds_mode_time => dds_mode_time
    );
------------- End INSTANTIATION Template ---------------------------------------
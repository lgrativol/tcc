-- -----------------------------------------------------------------------------
-- 'register_bank' Register Component
-- Revision: 70
-- -----------------------------------------------------------------------------
-- Generated on 2020-10-17 at 23:57 (UTC) by airhdl version 2020.09.1
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
        version_version : in std_logic_vector(7 downto 0); -- Value of register 'version', field 'version'
        bang_strobe : out std_logic; -- Strobe signal for register 'bang' (pulsed when the register is written from the bus)
        bang_bang : out std_logic_vector(0 downto 0); -- Value of register 'bang', field 'bang'
        sample_frequency_strobe : out std_logic; -- Strobe signal for register 'sample_frequency' (pulsed when the register is written from the bus)
        sample_frequency_sample_frequency : out std_logic_vector(26 downto 0); -- Value of register 'sample_frequency', field 'sample_frequency'
        target_frequency_strobe : out std_logic; -- Strobe signal for register 'target_frequency' (pulsed when the register is written from the bus)
        target_frequency_target_frequency : out std_logic_vector(31 downto 0); -- Value of register 'target_frequency', field 'target_frequency'
        phase_term_strobe : out std_logic; -- Strobe signal for register 'phase_term' (pulsed when the register is written from the bus)
        phase_term_phase_term : out std_logic_vector(31 downto 0); -- Value of register 'phase_term', field 'phase_term'
        init_phase_strobe : out std_logic; -- Strobe signal for register 'init_phase' (pulsed when the register is written from the bus)
        init_phase_init_phase : out std_logic_vector(31 downto 0); -- Value of register 'init_phase', field 'init_phase'
        numbers_strobe : out std_logic; -- Strobe signal for register 'numbers' (pulsed when the register is written from the bus)
        numbers_nb_points : out std_logic_vector(9 downto 0); -- Value of register 'numbers', field 'nb_points'
        numbers_nb_repetitions : out std_logic_vector(9 downto 0); -- Value of register 'numbers', field 'nb_repetitions'
        win_phase_term_strobe : out std_logic; -- Strobe signal for register 'win_phase_term' (pulsed when the register is written from the bus)
        win_phase_term_win_phase_term : out std_logic_vector(31 downto 0); -- Value of register 'win_phase_term', field 'win_phase_term'
        config_mode_strobe : out std_logic; -- Strobe signal for register 'config_mode' (pulsed when the register is written from the bus)
        config_mode_dds_type : out std_logic_vector(3 downto 0); -- Value of register 'config_mode', field 'dds_type'
        config_mode_mode_time : out std_logic_vector(0 downto 0); -- Value of register 'config_mode', field 'mode_time'
        config_mode_win_type : out std_logic_vector(3 downto 0); -- Value of register 'config_mode', field 'win_type'
        tx_timer_strobe : out std_logic; -- Strobe signal for register 'tx_timer' (pulsed when the register is written from the bus)
        tx_timer_tx_timer : out std_logic_vector(17 downto 0); -- Value of register 'tx_timer', field 'tx_timer'
        off_timer_strobe : out std_logic; -- Strobe signal for register 'off_timer' (pulsed when the register is written from the bus)
        off_timer_timer : out std_logic_vector(17 downto 0); -- Value of register 'off_timer', field 'timer'
        rx_timer_strobe : out std_logic; -- Strobe signal for register 'rx_timer' (pulsed when the register is written from the bus)
        rx_timer_timer : out std_logic_vector(17 downto 0); -- Value of register 'rx_timer', field 'timer'
        deadzone_timer_strobe : out std_logic; -- Strobe signal for register 'deadzone_timer' (pulsed when the register is written from the bus)
        deadzone_timer_timer : out std_logic_vector(17 downto 0) -- Value of register 'deadzone_timer', field 'timer'
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
signal version_version : std_logic_vector(7 downto 0);
signal bang_strobe : std_logic;
signal bang_bang : std_logic_vector(0 downto 0);
signal sample_frequency_strobe : std_logic;
signal sample_frequency_sample_frequency : std_logic_vector(26 downto 0);
signal target_frequency_strobe : std_logic;
signal target_frequency_target_frequency : std_logic_vector(31 downto 0);
signal phase_term_strobe : std_logic;
signal phase_term_phase_term : std_logic_vector(31 downto 0);
signal init_phase_strobe : std_logic;
signal init_phase_init_phase : std_logic_vector(31 downto 0);
signal numbers_strobe : std_logic;
signal numbers_nb_points : std_logic_vector(9 downto 0);
signal numbers_nb_repetitions : std_logic_vector(9 downto 0);
signal win_phase_term_strobe : std_logic;
signal win_phase_term_win_phase_term : std_logic_vector(31 downto 0);
signal config_mode_strobe : std_logic;
signal config_mode_dds_type : std_logic_vector(3 downto 0);
signal config_mode_mode_time : std_logic_vector(0 downto 0);
signal config_mode_win_type : std_logic_vector(3 downto 0);
signal tx_timer_strobe : std_logic;
signal tx_timer_tx_timer : std_logic_vector(17 downto 0);
signal off_timer_strobe : std_logic;
signal off_timer_timer : std_logic_vector(17 downto 0);
signal rx_timer_strobe : std_logic;
signal rx_timer_timer : std_logic_vector(17 downto 0);
signal deadzone_timer_strobe : std_logic;
signal deadzone_timer_timer : std_logic_vector(17 downto 0);
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
        version_version => version_version,
        bang_strobe => bang_strobe,
        bang_bang => bang_bang,
        sample_frequency_strobe => sample_frequency_strobe,
        sample_frequency_sample_frequency => sample_frequency_sample_frequency,
        target_frequency_strobe => target_frequency_strobe,
        target_frequency_target_frequency => target_frequency_target_frequency,
        phase_term_strobe => phase_term_strobe,
        phase_term_phase_term => phase_term_phase_term,
        init_phase_strobe => init_phase_strobe,
        init_phase_init_phase => init_phase_init_phase,
        numbers_strobe => numbers_strobe,
        numbers_nb_points => numbers_nb_points,
        numbers_nb_repetitions => numbers_nb_repetitions,
        win_phase_term_strobe => win_phase_term_strobe,
        win_phase_term_win_phase_term => win_phase_term_win_phase_term,
        config_mode_strobe => config_mode_strobe,
        config_mode_dds_type => config_mode_dds_type,
        config_mode_mode_time => config_mode_mode_time,
        config_mode_win_type => config_mode_win_type,
        tx_timer_strobe => tx_timer_strobe,
        tx_timer_tx_timer => tx_timer_tx_timer,
        off_timer_strobe => off_timer_strobe,
        off_timer_timer => off_timer_timer,
        rx_timer_strobe => rx_timer_strobe,
        rx_timer_timer => rx_timer_timer,
        deadzone_timer_strobe => deadzone_timer_strobe,
        deadzone_timer_timer => deadzone_timer_timer
    );
------------- End INSTANTIATION Template ---------------------------------------
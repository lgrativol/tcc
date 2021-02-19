-- -----------------------------------------------------------------------------
-- 'register_bank_cordic_weights' Register Component
-- Revision: 40
-- -----------------------------------------------------------------------------
-- Generated on 2020-12-20 at 11:37 (UTC) by airhdl version 2020.10.1
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
component register_bank_cordic_weights_regs
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
        sample_frequency_strobe : out std_logic; -- Strobe signal for register 'sample_frequency' (pulsed when the register is written from the bus)
        sample_frequency_value : out std_logic_vector(26 downto 0); -- Value of register 'sample_frequency', field 'value'
        wave_nb_periods_strobe : out std_logic; -- Strobe signal for register 'wave_nb_periods' (pulsed when the register is written from the bus)
        wave_nb_periods_value : out std_logic_vector(7 downto 0); -- Value of register 'wave_nb_periods', field 'value'
        wave_nb_points_strobe : out std_logic; -- Strobe signal for register 'wave_nb_points' (pulsed when the register is written from the bus)
        wave_nb_points_value : out std_logic_vector(31 downto 0); -- Value of register 'wave_nb_points', field 'value'
        conv_rate_strobe : out std_logic; -- Strobe signal for register 'conv_rate' (pulsed when the register is written from the bus)
        conv_rate_value : out std_logic_vector(6 downto 0); -- Value of register 'conv_rate', field 'value'
        weights_strobe : out std_logic_vector(0 to 9); -- Strobe signal for register 'weights' (pulsed when the register is written from the bus)
        weights_value : out slv16_array_t(0 to 9); -- Value of register 'weights', field 'value'
        dds_phase_term_strobe : out std_logic; -- Strobe signal for register 'dds_phase_term' (pulsed when the register is written from the bus)
        dds_phase_term_value : out std_logic_vector(31 downto 0); -- Value of register 'dds_phase_term', field 'value'
        dds_nb_points_strobe : out std_logic; -- Strobe signal for register 'dds_nb_points' (pulsed when the register is written from the bus)
        dds_nb_points_value : out std_logic_vector(17 downto 0); -- Value of register 'dds_nb_points', field 'value'
        dds_nb_periods_strobe : out std_logic; -- Strobe signal for register 'dds_nb_periods' (pulsed when the register is written from the bus)
        dds_nb_periods_value : out std_logic_vector(31 downto 0) -- Value of register 'dds_nb_periods', field 'value'
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
signal sample_frequency_strobe : std_logic;
signal sample_frequency_value : std_logic_vector(26 downto 0);
signal wave_nb_periods_strobe : std_logic;
signal wave_nb_periods_value : std_logic_vector(7 downto 0);
signal wave_nb_points_strobe : std_logic;
signal wave_nb_points_value : std_logic_vector(31 downto 0);
signal conv_rate_strobe : std_logic;
signal conv_rate_value : std_logic_vector(6 downto 0);
signal weights_strobe : std_logic_vector(0 to 9);
signal weights_value : slv16_array_t(0 to 9);
signal dds_phase_term_strobe : std_logic;
signal dds_phase_term_value : std_logic_vector(31 downto 0);
signal dds_nb_points_strobe : std_logic;
signal dds_nb_points_value : std_logic_vector(17 downto 0);
signal dds_nb_periods_strobe : std_logic;
signal dds_nb_periods_value : std_logic_vector(31 downto 0);
------------- End CONSTANT and SIGNAL Declarations -----------------------------

------------- Begin Cut here for INSTANTIATION Template ------------------------
your_instance_name : register_bank_cordic_weights_regs
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
        sample_frequency_strobe => sample_frequency_strobe,
        sample_frequency_value => sample_frequency_value,
        wave_nb_periods_strobe => wave_nb_periods_strobe,
        wave_nb_periods_value => wave_nb_periods_value,
        wave_nb_points_strobe => wave_nb_points_strobe,
        wave_nb_points_value => wave_nb_points_value,
        conv_rate_strobe => conv_rate_strobe,
        conv_rate_value => conv_rate_value,
        weights_strobe => weights_strobe,
        weights_value => weights_value,
        dds_phase_term_strobe => dds_phase_term_strobe,
        dds_phase_term_value => dds_phase_term_value,
        dds_nb_points_strobe => dds_nb_points_strobe,
        dds_nb_points_value => dds_nb_points_value,
        dds_nb_periods_strobe => dds_nb_periods_strobe,
        dds_nb_periods_value => dds_nb_periods_value
    );
------------- End INSTANTIATION Template ---------------------------------------
-- -----------------------------------------------------------------------------
-- 'register_bank' Register Component
-- Revision: 125
-- -----------------------------------------------------------------------------
-- Generated on 2020-10-20 at 01:08 (UTC) by airhdl version 2020.10.1
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.register_bank_regs_pkg.all;

entity register_bank_regs is
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
        s_axi_awprot  : in  std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        s_axi_awvalid : in  std_logic;
        s_axi_awready : out std_logic;
        -- AXI Write Data Channel
        s_axi_wdata   : in  std_logic_vector(31 downto 0);
        s_axi_wstrb   : in  std_logic_vector(3 downto 0);
        s_axi_wvalid  : in  std_logic;
        s_axi_wready  : out std_logic;
        -- AXI Read Address Channel
        s_axi_araddr  : in  std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arprot  : in  std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
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
end entity register_bank_regs;

architecture RTL of register_bank_regs is

    -- Constants
    constant AXI_OKAY           : std_logic_vector(1 downto 0) := "00";
    constant AXI_DECERR         : std_logic_vector(1 downto 0) := "11";

    -- Registered signals
    signal s_axi_awready_r    : std_logic;
    signal s_axi_wready_r     : std_logic;
    signal s_axi_awaddr_reg_r : unsigned(s_axi_awaddr'range);
    signal s_axi_bvalid_r     : std_logic;
    signal s_axi_bresp_r      : std_logic_vector(s_axi_bresp'range);
    signal s_axi_arready_r    : std_logic;
    signal s_axi_araddr_reg_r : unsigned(s_axi_araddr'range);
    signal s_axi_rvalid_r     : std_logic;
    signal s_axi_rresp_r      : std_logic_vector(s_axi_rresp'range);
    signal s_axi_wdata_reg_r  : std_logic_vector(s_axi_wdata'range);
    signal s_axi_wstrb_reg_r  : std_logic_vector(s_axi_wstrb'range);
    signal s_axi_rdata_r      : std_logic_vector(s_axi_rdata'range);
    
    -- User-defined registers
    signal s_version_strobe_r : std_logic;
    signal s_reg_version_field : std_logic_vector(7 downto 0);
    signal s_bang_strobe_r : std_logic;
    signal s_reg_bang_field_r : std_logic_vector(0 downto 0);
    signal s_wave_config_strobe_r : std_logic;
    signal s_reg_wave_config_wave_type_r : std_logic_vector(3 downto 0);
    signal s_reg_wave_config_win_type_r : std_logic_vector(3 downto 0);
    signal s_sample_frequency_strobe_r : std_logic;
    signal s_reg_sample_frequency_value_r : std_logic_vector(26 downto 0);
    signal s_wave_nb_points_strobe_r : std_logic;
    signal s_reg_wave_nb_points_value_r : std_logic_vector(31 downto 0);
    signal s_fsm_nb_repetitions_strobe_r : std_logic;
    signal s_reg_fsm_nb_repetitions_value_r : std_logic_vector(5 downto 0);
    signal s_tx_timer_strobe_r : std_logic;
    signal s_reg_tx_timer_value_r : std_logic_vector(17 downto 0);
    signal s_deadzone_timer_strobe_r : std_logic;
    signal s_reg_deadzone_timer_value_r : std_logic_vector(17 downto 0);
    signal s_rx_timer_strobe_r : std_logic;
    signal s_reg_rx_timer_value_r : std_logic_vector(17 downto 0);
    signal s_idle_timer_strobe_r : std_logic;
    signal s_reg_idle_timer_value_r : std_logic_vector(17 downto 0);
    signal s_pulser_nb_repetitions_strobe_r : std_logic;
    signal s_reg_pulser_nb_repetitions_value_r : std_logic_vector(9 downto 0);
    signal s_pulser_t1_strobe_r : std_logic;
    signal s_reg_pulser_t1_value_r : std_logic_vector(9 downto 0);
    signal s_pulser_t2_strobe_r : std_logic;
    signal s_reg_pulser_t2_value_r : std_logic_vector(9 downto 0);
    signal s_pulser_t3_strobe_r : std_logic;
    signal s_reg_pulser_t3_value_r : std_logic_vector(9 downto 0);
    signal s_pulser_t4_strobe_r : std_logic;
    signal s_reg_pulser_t4_value_r : std_logic_vector(9 downto 0);
    signal s_pulser_tdamp_strobe_r : std_logic;
    signal s_reg_pulser_tdamp_value_r : std_logic_vector(9 downto 0);
    signal s_pulser_config_strobe_r : std_logic;
    signal s_reg_pulser_config_invert_r : std_logic_vector(0 downto 0);
    signal s_reg_pulser_config_triple_r : std_logic_vector(0 downto 0);
    signal s_dds_phase_term_strobe_r : std_logic;
    signal s_reg_dds_phase_term_value_r : std_logic_vector(31 downto 0);
    signal s_dds_init_phase_strobe_r : std_logic;
    signal s_reg_dds_init_phase_value_r : std_logic_vector(31 downto 0);
    signal s_dds_nb_strobe_r : std_logic;
    signal s_reg_dds_nb_points_r : std_logic_vector(9 downto 0);
    signal s_reg_dds_nb_repetitions_r : std_logic_vector(9 downto 0);
    signal s_dds_mode_strobe_r : std_logic;
    signal s_reg_dds_mode_time_r : std_logic_vector(0 downto 0);

begin

    ----------------------------------------------------------------------------
    -- Inputs
    --
    s_reg_version_field <= version_field;

    ----------------------------------------------------------------------------
    -- Read-transaction FSM
    --    
    read_fsm : process(axi_aclk, axi_aresetn) is
        constant MEM_WAIT_COUNT : natural := 2;
        type t_state is (IDLE, READ_REGISTER, WAIT_MEMORY_RDATA, READ_RESPONSE, DONE);
        -- registered state variables
        variable v_state_r          : t_state;
        variable v_rdata_r          : std_logic_vector(31 downto 0);
        variable v_rresp_r          : std_logic_vector(s_axi_rresp'range);
        variable v_mem_wait_count_r : natural range 0 to MEM_WAIT_COUNT - 1;
        -- combinatorial helper variables
        variable v_addr_hit : boolean;
        variable v_mem_addr : unsigned(AXI_ADDR_WIDTH-1 downto 0);
    begin
        if axi_aresetn = '0' then
            v_state_r          := IDLE;
            v_rdata_r          := (others => '0');
            v_rresp_r          := (others => '0');
            v_mem_wait_count_r := 0;
            s_axi_arready_r    <= '0';
            s_axi_rvalid_r     <= '0';
            s_axi_rresp_r      <= (others => '0');
            s_axi_araddr_reg_r <= (others => '0');
            s_axi_rdata_r      <= (others => '0');
            s_version_strobe_r <= '0';
 
        elsif rising_edge(axi_aclk) then
            -- Default values:
            s_axi_arready_r <= '0';
            s_version_strobe_r <= '0';

            case v_state_r is

                -- Wait for the start of a read transaction, which is 
                -- initiated by the assertion of ARVALID
                when IDLE =>
                    v_mem_wait_count_r := 0;
                    --
                    if s_axi_arvalid = '1' then
                        s_axi_araddr_reg_r <= unsigned(s_axi_araddr); -- save the read address
                        s_axi_arready_r    <= '1'; -- acknowledge the read-address
                        v_state_r          := READ_REGISTER;
                    end if;

                -- Read from the actual storage element
                when READ_REGISTER =>
                    -- defaults:
                    v_addr_hit := false;
                    v_rdata_r  := (others => '0');
                    
                    -- register 'version' at address offset 0x0 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + VERSION_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(7 downto 0) := s_reg_version_field;
                        s_version_strobe_r <= '1';
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'wave_config' at address offset 0x8 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + WAVE_CONFIG_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(3 downto 0) := s_reg_wave_config_wave_type_r;
                        v_rdata_r(7 downto 4) := s_reg_wave_config_win_type_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'sample_frequency' at address offset 0xC 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + SAMPLE_FREQUENCY_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(26 downto 0) := s_reg_sample_frequency_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'wave_nb_points' at address offset 0x10 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + WAVE_NB_POINTS_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(31 downto 0) := s_reg_wave_nb_points_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'fsm_nb_repetitions' at address offset 0x28 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + FSM_NB_REPETITIONS_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(5 downto 0) := s_reg_fsm_nb_repetitions_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'tx_timer' at address offset 0x2C 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + TX_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(17 downto 0) := s_reg_tx_timer_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'deadzone_timer' at address offset 0x30 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + DEADZONE_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(17 downto 0) := s_reg_deadzone_timer_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'rx_timer' at address offset 0x34 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + RX_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(17 downto 0) := s_reg_rx_timer_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'idle_timer' at address offset 0x38 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + IDLE_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(17 downto 0) := s_reg_idle_timer_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'pulser_nb_repetitions' at address offset 0x3C 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + PULSER_NB_REPETITIONS_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(9 downto 0) := s_reg_pulser_nb_repetitions_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'pulser_t1' at address offset 0x40 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + PULSER_T1_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(9 downto 0) := s_reg_pulser_t1_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'pulser_t2' at address offset 0x44 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + PULSER_T2_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(9 downto 0) := s_reg_pulser_t2_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'pulser_t3' at address offset 0x48 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + PULSER_T3_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(9 downto 0) := s_reg_pulser_t3_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'pulser_t4' at address offset 0x4C 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + PULSER_T4_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(9 downto 0) := s_reg_pulser_t4_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'pulser_tdamp' at address offset 0x50 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + PULSER_TDAMP_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(9 downto 0) := s_reg_pulser_tdamp_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'pulser_config' at address offset 0x54 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + PULSER_CONFIG_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(0 downto 0) := s_reg_pulser_config_invert_r;
                        v_rdata_r(1 downto 1) := s_reg_pulser_config_triple_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'dds_phase_term' at address offset 0x58 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + DDS_PHASE_TERM_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(31 downto 0) := s_reg_dds_phase_term_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'dds_init_phase' at address offset 0x5C 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + DDS_INIT_PHASE_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(31 downto 0) := s_reg_dds_init_phase_value_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'dds_nb' at address offset 0x60 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + DDS_NB_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(9 downto 0) := s_reg_dds_nb_points_r;
                        v_rdata_r(19 downto 10) := s_reg_dds_nb_repetitions_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'dds_mode' at address offset 0x64 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + DDS_MODE_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(0 downto 0) := s_reg_dds_mode_time_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    --
                    if v_addr_hit then
                        v_rresp_r := AXI_OKAY;
                    else
                        v_rresp_r := AXI_DECERR;
                        -- pragma translate_off
                        report "ARADDR decode error" severity warning;
                        -- pragma translate_on
                        v_state_r := READ_RESPONSE;
                    end if;

                -- Wait for memory read data
                when WAIT_MEMORY_RDATA =>
                    if v_mem_wait_count_r = MEM_WAIT_COUNT-1 then
                        v_state_r      := READ_RESPONSE;
                    else
                        v_mem_wait_count_r := v_mem_wait_count_r + 1;
                    end if;

                -- Generate read response
                when READ_RESPONSE =>
                    s_axi_rvalid_r <= '1';
                    s_axi_rresp_r  <= v_rresp_r;
                    s_axi_rdata_r  <= v_rdata_r;
                    --
                    v_state_r      := DONE;

                -- Write transaction completed, wait for master RREADY to proceed
                when DONE =>
                    if s_axi_rready = '1' then
                        s_axi_rvalid_r <= '0';
                        s_axi_rdata_r   <= (others => '0');
                        v_state_r      := IDLE;
                    end if;
            end case;
        end if;
    end process read_fsm;

    ----------------------------------------------------------------------------
    -- Write-transaction FSM
    --    
    write_fsm : process(axi_aclk, axi_aresetn) is
        type t_state is (IDLE, ADDR_FIRST, DATA_FIRST, UPDATE_REGISTER, DONE);
        variable v_state_r  : t_state;
        variable v_addr_hit : boolean;
        variable v_mem_addr : unsigned(AXI_ADDR_WIDTH-1 downto 0);
    begin
        if axi_aresetn = '0' then
            v_state_r          := IDLE;
            s_axi_awready_r    <= '0';
            s_axi_wready_r     <= '0';
            s_axi_awaddr_reg_r <= (others => '0');
            s_axi_wdata_reg_r  <= (others => '0');
            s_axi_wstrb_reg_r  <= (others => '0');
            s_axi_bvalid_r     <= '0';
            s_axi_bresp_r      <= (others => '0');
            --            
            s_bang_strobe_r <= '0';
            s_reg_bang_field_r <= BANG_FIELD_RESET;
            s_wave_config_strobe_r <= '0';
            s_reg_wave_config_wave_type_r <= WAVE_CONFIG_WAVE_TYPE_RESET;
            s_reg_wave_config_win_type_r <= WAVE_CONFIG_WIN_TYPE_RESET;
            s_sample_frequency_strobe_r <= '0';
            s_reg_sample_frequency_value_r <= SAMPLE_FREQUENCY_VALUE_RESET;
            s_wave_nb_points_strobe_r <= '0';
            s_reg_wave_nb_points_value_r <= WAVE_NB_POINTS_VALUE_RESET;
            s_fsm_nb_repetitions_strobe_r <= '0';
            s_reg_fsm_nb_repetitions_value_r <= FSM_NB_REPETITIONS_VALUE_RESET;
            s_tx_timer_strobe_r <= '0';
            s_reg_tx_timer_value_r <= TX_TIMER_VALUE_RESET;
            s_deadzone_timer_strobe_r <= '0';
            s_reg_deadzone_timer_value_r <= DEADZONE_TIMER_VALUE_RESET;
            s_rx_timer_strobe_r <= '0';
            s_reg_rx_timer_value_r <= RX_TIMER_VALUE_RESET;
            s_idle_timer_strobe_r <= '0';
            s_reg_idle_timer_value_r <= IDLE_TIMER_VALUE_RESET;
            s_pulser_nb_repetitions_strobe_r <= '0';
            s_reg_pulser_nb_repetitions_value_r <= PULSER_NB_REPETITIONS_VALUE_RESET;
            s_pulser_t1_strobe_r <= '0';
            s_reg_pulser_t1_value_r <= PULSER_T1_VALUE_RESET;
            s_pulser_t2_strobe_r <= '0';
            s_reg_pulser_t2_value_r <= PULSER_T2_VALUE_RESET;
            s_pulser_t3_strobe_r <= '0';
            s_reg_pulser_t3_value_r <= PULSER_T3_VALUE_RESET;
            s_pulser_t4_strobe_r <= '0';
            s_reg_pulser_t4_value_r <= PULSER_T4_VALUE_RESET;
            s_pulser_tdamp_strobe_r <= '0';
            s_reg_pulser_tdamp_value_r <= PULSER_TDAMP_VALUE_RESET;
            s_pulser_config_strobe_r <= '0';
            s_reg_pulser_config_invert_r <= PULSER_CONFIG_INVERT_RESET;
            s_reg_pulser_config_triple_r <= PULSER_CONFIG_TRIPLE_RESET;
            s_dds_phase_term_strobe_r <= '0';
            s_reg_dds_phase_term_value_r <= DDS_PHASE_TERM_VALUE_RESET;
            s_dds_init_phase_strobe_r <= '0';
            s_reg_dds_init_phase_value_r <= DDS_INIT_PHASE_VALUE_RESET;
            s_dds_nb_strobe_r <= '0';
            s_reg_dds_nb_points_r <= DDS_NB_POINTS_RESET;
            s_reg_dds_nb_repetitions_r <= DDS_NB_REPETITIONS_RESET;
            s_dds_mode_strobe_r <= '0';
            s_reg_dds_mode_time_r <= DDS_MODE_TIME_RESET;

        elsif rising_edge(axi_aclk) then
            -- Default values:
            s_axi_awready_r <= '0';
            s_axi_wready_r  <= '0';
            s_bang_strobe_r <= '0';
            s_wave_config_strobe_r <= '0';
            s_sample_frequency_strobe_r <= '0';
            s_wave_nb_points_strobe_r <= '0';
            s_fsm_nb_repetitions_strobe_r <= '0';
            s_tx_timer_strobe_r <= '0';
            s_deadzone_timer_strobe_r <= '0';
            s_rx_timer_strobe_r <= '0';
            s_idle_timer_strobe_r <= '0';
            s_pulser_nb_repetitions_strobe_r <= '0';
            s_pulser_t1_strobe_r <= '0';
            s_pulser_t2_strobe_r <= '0';
            s_pulser_t3_strobe_r <= '0';
            s_pulser_t4_strobe_r <= '0';
            s_pulser_tdamp_strobe_r <= '0';
            s_pulser_config_strobe_r <= '0';
            s_dds_phase_term_strobe_r <= '0';
            s_dds_init_phase_strobe_r <= '0';
            s_dds_nb_strobe_r <= '0';
            s_dds_mode_strobe_r <= '0';

            -- Self-clearing fields:
            s_reg_bang_field_r <= (others => '0');

            case v_state_r is

                -- Wait for the start of a write transaction, which may be 
                -- initiated by either of the following conditions:
                --   * assertion of both AWVALID and WVALID
                --   * assertion of AWVALID
                --   * assertion of WVALID
                when IDLE =>
                    if s_axi_awvalid = '1' and s_axi_wvalid = '1' then
                        s_axi_awaddr_reg_r <= unsigned(s_axi_awaddr); -- save the write-address 
                        s_axi_awready_r    <= '1'; -- acknowledge the write-address
                        s_axi_wdata_reg_r  <= s_axi_wdata; -- save the write-data
                        s_axi_wstrb_reg_r  <= s_axi_wstrb; -- save the write-strobe
                        s_axi_wready_r     <= '1'; -- acknowledge the write-data
                        v_state_r          := UPDATE_REGISTER;
                    elsif s_axi_awvalid = '1' then
                        s_axi_awaddr_reg_r <= unsigned(s_axi_awaddr); -- save the write-address 
                        s_axi_awready_r    <= '1'; -- acknowledge the write-address
                        v_state_r          := ADDR_FIRST;
                    elsif s_axi_wvalid = '1' then
                        s_axi_wdata_reg_r <= s_axi_wdata; -- save the write-data
                        s_axi_wstrb_reg_r <= s_axi_wstrb; -- save the write-strobe
                        s_axi_wready_r    <= '1'; -- acknowledge the write-data
                        v_state_r         := DATA_FIRST;
                    end if;

                -- Address-first write transaction: wait for the write-data
                when ADDR_FIRST =>
                    if s_axi_wvalid = '1' then
                        s_axi_wdata_reg_r <= s_axi_wdata; -- save the write-data
                        s_axi_wstrb_reg_r <= s_axi_wstrb; -- save the write-strobe
                        s_axi_wready_r    <= '1'; -- acknowledge the write-data
                        v_state_r         := UPDATE_REGISTER;
                    end if;

                -- Data-first write transaction: wait for the write-address
                when DATA_FIRST =>
                    if s_axi_awvalid = '1' then
                        s_axi_awaddr_reg_r <= unsigned(s_axi_awaddr); -- save the write-address 
                        s_axi_awready_r    <= '1'; -- acknowledge the write-address
                        v_state_r          := UPDATE_REGISTER;
                    end if;

                -- Update the actual storage element
                when UPDATE_REGISTER =>
                    s_axi_bresp_r               <= AXI_OKAY; -- default value, may be overriden in case of decode error
                    s_axi_bvalid_r              <= '1';
                    --
                    v_addr_hit := false;
                    -- register 'bang' at address offset 0x4
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + BANG_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_bang_strobe_r <= '1';
                        -- field 'field':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_bang_field_r(0) <= s_axi_wdata_reg_r(0); -- field(0)
                        end if;
                    end if;
                    -- register 'wave_config' at address offset 0x8
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + WAVE_CONFIG_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_wave_config_strobe_r <= '1';
                        -- field 'wave_type':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_config_wave_type_r(0) <= s_axi_wdata_reg_r(0); -- wave_type(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_config_wave_type_r(1) <= s_axi_wdata_reg_r(1); -- wave_type(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_config_wave_type_r(2) <= s_axi_wdata_reg_r(2); -- wave_type(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_config_wave_type_r(3) <= s_axi_wdata_reg_r(3); -- wave_type(3)
                        end if;
                        -- field 'win_type':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_config_win_type_r(0) <= s_axi_wdata_reg_r(4); -- win_type(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_config_win_type_r(1) <= s_axi_wdata_reg_r(5); -- win_type(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_config_win_type_r(2) <= s_axi_wdata_reg_r(6); -- win_type(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_config_win_type_r(3) <= s_axi_wdata_reg_r(7); -- win_type(3)
                        end if;
                    end if;
                    -- register 'sample_frequency' at address offset 0xC
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + SAMPLE_FREQUENCY_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_sample_frequency_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_value_r(10) <= s_axi_wdata_reg_r(10); -- value(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_value_r(11) <= s_axi_wdata_reg_r(11); -- value(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_value_r(12) <= s_axi_wdata_reg_r(12); -- value(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_value_r(13) <= s_axi_wdata_reg_r(13); -- value(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_value_r(14) <= s_axi_wdata_reg_r(14); -- value(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_value_r(15) <= s_axi_wdata_reg_r(15); -- value(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_value_r(16) <= s_axi_wdata_reg_r(16); -- value(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_value_r(17) <= s_axi_wdata_reg_r(17); -- value(17)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_value_r(18) <= s_axi_wdata_reg_r(18); -- value(18)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_value_r(19) <= s_axi_wdata_reg_r(19); -- value(19)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_value_r(20) <= s_axi_wdata_reg_r(20); -- value(20)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_value_r(21) <= s_axi_wdata_reg_r(21); -- value(21)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_value_r(22) <= s_axi_wdata_reg_r(22); -- value(22)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_value_r(23) <= s_axi_wdata_reg_r(23); -- value(23)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_sample_frequency_value_r(24) <= s_axi_wdata_reg_r(24); -- value(24)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_sample_frequency_value_r(25) <= s_axi_wdata_reg_r(25); -- value(25)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_sample_frequency_value_r(26) <= s_axi_wdata_reg_r(26); -- value(26)
                        end if;
                    end if;
                    -- register 'wave_nb_points' at address offset 0x10
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + WAVE_NB_POINTS_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_wave_nb_points_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_nb_points_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_nb_points_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_nb_points_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_nb_points_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_nb_points_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_nb_points_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_nb_points_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_wave_nb_points_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_wave_nb_points_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_wave_nb_points_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_wave_nb_points_value_r(10) <= s_axi_wdata_reg_r(10); -- value(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_wave_nb_points_value_r(11) <= s_axi_wdata_reg_r(11); -- value(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_wave_nb_points_value_r(12) <= s_axi_wdata_reg_r(12); -- value(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_wave_nb_points_value_r(13) <= s_axi_wdata_reg_r(13); -- value(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_wave_nb_points_value_r(14) <= s_axi_wdata_reg_r(14); -- value(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_wave_nb_points_value_r(15) <= s_axi_wdata_reg_r(15); -- value(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_wave_nb_points_value_r(16) <= s_axi_wdata_reg_r(16); -- value(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_wave_nb_points_value_r(17) <= s_axi_wdata_reg_r(17); -- value(17)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_wave_nb_points_value_r(18) <= s_axi_wdata_reg_r(18); -- value(18)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_wave_nb_points_value_r(19) <= s_axi_wdata_reg_r(19); -- value(19)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_wave_nb_points_value_r(20) <= s_axi_wdata_reg_r(20); -- value(20)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_wave_nb_points_value_r(21) <= s_axi_wdata_reg_r(21); -- value(21)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_wave_nb_points_value_r(22) <= s_axi_wdata_reg_r(22); -- value(22)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_wave_nb_points_value_r(23) <= s_axi_wdata_reg_r(23); -- value(23)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_wave_nb_points_value_r(24) <= s_axi_wdata_reg_r(24); -- value(24)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_wave_nb_points_value_r(25) <= s_axi_wdata_reg_r(25); -- value(25)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_wave_nb_points_value_r(26) <= s_axi_wdata_reg_r(26); -- value(26)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_wave_nb_points_value_r(27) <= s_axi_wdata_reg_r(27); -- value(27)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_wave_nb_points_value_r(28) <= s_axi_wdata_reg_r(28); -- value(28)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_wave_nb_points_value_r(29) <= s_axi_wdata_reg_r(29); -- value(29)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_wave_nb_points_value_r(30) <= s_axi_wdata_reg_r(30); -- value(30)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_wave_nb_points_value_r(31) <= s_axi_wdata_reg_r(31); -- value(31)
                        end if;
                    end if;
                    -- register 'fsm_nb_repetitions' at address offset 0x28
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + FSM_NB_REPETITIONS_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_fsm_nb_repetitions_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_fsm_nb_repetitions_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_fsm_nb_repetitions_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_fsm_nb_repetitions_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_fsm_nb_repetitions_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_fsm_nb_repetitions_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_fsm_nb_repetitions_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                    end if;
                    -- register 'tx_timer' at address offset 0x2C
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + TX_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_tx_timer_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_value_r(10) <= s_axi_wdata_reg_r(10); -- value(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_value_r(11) <= s_axi_wdata_reg_r(11); -- value(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_value_r(12) <= s_axi_wdata_reg_r(12); -- value(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_value_r(13) <= s_axi_wdata_reg_r(13); -- value(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_value_r(14) <= s_axi_wdata_reg_r(14); -- value(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_value_r(15) <= s_axi_wdata_reg_r(15); -- value(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_tx_timer_value_r(16) <= s_axi_wdata_reg_r(16); -- value(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_tx_timer_value_r(17) <= s_axi_wdata_reg_r(17); -- value(17)
                        end if;
                    end if;
                    -- register 'deadzone_timer' at address offset 0x30
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + DEADZONE_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_deadzone_timer_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_value_r(10) <= s_axi_wdata_reg_r(10); -- value(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_value_r(11) <= s_axi_wdata_reg_r(11); -- value(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_value_r(12) <= s_axi_wdata_reg_r(12); -- value(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_value_r(13) <= s_axi_wdata_reg_r(13); -- value(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_value_r(14) <= s_axi_wdata_reg_r(14); -- value(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_value_r(15) <= s_axi_wdata_reg_r(15); -- value(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_deadzone_timer_value_r(16) <= s_axi_wdata_reg_r(16); -- value(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_deadzone_timer_value_r(17) <= s_axi_wdata_reg_r(17); -- value(17)
                        end if;
                    end if;
                    -- register 'rx_timer' at address offset 0x34
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + RX_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_rx_timer_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_value_r(10) <= s_axi_wdata_reg_r(10); -- value(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_value_r(11) <= s_axi_wdata_reg_r(11); -- value(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_value_r(12) <= s_axi_wdata_reg_r(12); -- value(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_value_r(13) <= s_axi_wdata_reg_r(13); -- value(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_value_r(14) <= s_axi_wdata_reg_r(14); -- value(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_value_r(15) <= s_axi_wdata_reg_r(15); -- value(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_rx_timer_value_r(16) <= s_axi_wdata_reg_r(16); -- value(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_rx_timer_value_r(17) <= s_axi_wdata_reg_r(17); -- value(17)
                        end if;
                    end if;
                    -- register 'idle_timer' at address offset 0x38
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + IDLE_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_idle_timer_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_idle_timer_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_idle_timer_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_idle_timer_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_idle_timer_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_idle_timer_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_idle_timer_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_idle_timer_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_idle_timer_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_idle_timer_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_idle_timer_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_idle_timer_value_r(10) <= s_axi_wdata_reg_r(10); -- value(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_idle_timer_value_r(11) <= s_axi_wdata_reg_r(11); -- value(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_idle_timer_value_r(12) <= s_axi_wdata_reg_r(12); -- value(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_idle_timer_value_r(13) <= s_axi_wdata_reg_r(13); -- value(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_idle_timer_value_r(14) <= s_axi_wdata_reg_r(14); -- value(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_idle_timer_value_r(15) <= s_axi_wdata_reg_r(15); -- value(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_idle_timer_value_r(16) <= s_axi_wdata_reg_r(16); -- value(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_idle_timer_value_r(17) <= s_axi_wdata_reg_r(17); -- value(17)
                        end if;
                    end if;
                    -- register 'pulser_nb_repetitions' at address offset 0x3C
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + PULSER_NB_REPETITIONS_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_pulser_nb_repetitions_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_nb_repetitions_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_nb_repetitions_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_nb_repetitions_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_nb_repetitions_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_nb_repetitions_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_nb_repetitions_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_nb_repetitions_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_nb_repetitions_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_nb_repetitions_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_nb_repetitions_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                    end if;
                    -- register 'pulser_t1' at address offset 0x40
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + PULSER_T1_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_pulser_t1_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t1_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t1_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t1_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t1_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t1_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t1_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t1_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t1_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_t1_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_t1_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                    end if;
                    -- register 'pulser_t2' at address offset 0x44
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + PULSER_T2_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_pulser_t2_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t2_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t2_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t2_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t2_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t2_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t2_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t2_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t2_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_t2_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_t2_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                    end if;
                    -- register 'pulser_t3' at address offset 0x48
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + PULSER_T3_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_pulser_t3_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t3_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t3_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t3_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t3_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t3_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t3_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t3_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t3_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_t3_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_t3_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                    end if;
                    -- register 'pulser_t4' at address offset 0x4C
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + PULSER_T4_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_pulser_t4_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t4_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t4_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t4_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t4_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t4_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t4_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t4_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_t4_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_t4_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_t4_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                    end if;
                    -- register 'pulser_tdamp' at address offset 0x50
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + PULSER_TDAMP_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_pulser_tdamp_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_tdamp_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_tdamp_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_tdamp_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_tdamp_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_tdamp_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_tdamp_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_tdamp_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_tdamp_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_tdamp_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_pulser_tdamp_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                    end if;
                    -- register 'pulser_config' at address offset 0x54
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + PULSER_CONFIG_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_pulser_config_strobe_r <= '1';
                        -- field 'invert':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_config_invert_r(0) <= s_axi_wdata_reg_r(0); -- invert(0)
                        end if;
                        -- field 'triple':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_pulser_config_triple_r(0) <= s_axi_wdata_reg_r(1); -- triple(0)
                        end if;
                    end if;
                    -- register 'dds_phase_term' at address offset 0x58
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + DDS_PHASE_TERM_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_dds_phase_term_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_phase_term_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_phase_term_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_phase_term_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_phase_term_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_phase_term_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_phase_term_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_phase_term_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_phase_term_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_phase_term_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_phase_term_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_phase_term_value_r(10) <= s_axi_wdata_reg_r(10); -- value(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_phase_term_value_r(11) <= s_axi_wdata_reg_r(11); -- value(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_phase_term_value_r(12) <= s_axi_wdata_reg_r(12); -- value(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_phase_term_value_r(13) <= s_axi_wdata_reg_r(13); -- value(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_phase_term_value_r(14) <= s_axi_wdata_reg_r(14); -- value(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_phase_term_value_r(15) <= s_axi_wdata_reg_r(15); -- value(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_phase_term_value_r(16) <= s_axi_wdata_reg_r(16); -- value(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_phase_term_value_r(17) <= s_axi_wdata_reg_r(17); -- value(17)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_phase_term_value_r(18) <= s_axi_wdata_reg_r(18); -- value(18)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_phase_term_value_r(19) <= s_axi_wdata_reg_r(19); -- value(19)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_phase_term_value_r(20) <= s_axi_wdata_reg_r(20); -- value(20)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_phase_term_value_r(21) <= s_axi_wdata_reg_r(21); -- value(21)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_phase_term_value_r(22) <= s_axi_wdata_reg_r(22); -- value(22)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_phase_term_value_r(23) <= s_axi_wdata_reg_r(23); -- value(23)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_phase_term_value_r(24) <= s_axi_wdata_reg_r(24); -- value(24)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_phase_term_value_r(25) <= s_axi_wdata_reg_r(25); -- value(25)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_phase_term_value_r(26) <= s_axi_wdata_reg_r(26); -- value(26)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_phase_term_value_r(27) <= s_axi_wdata_reg_r(27); -- value(27)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_phase_term_value_r(28) <= s_axi_wdata_reg_r(28); -- value(28)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_phase_term_value_r(29) <= s_axi_wdata_reg_r(29); -- value(29)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_phase_term_value_r(30) <= s_axi_wdata_reg_r(30); -- value(30)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_phase_term_value_r(31) <= s_axi_wdata_reg_r(31); -- value(31)
                        end if;
                    end if;
                    -- register 'dds_init_phase' at address offset 0x5C
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + DDS_INIT_PHASE_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_dds_init_phase_strobe_r <= '1';
                        -- field 'value':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_init_phase_value_r(0) <= s_axi_wdata_reg_r(0); -- value(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_init_phase_value_r(1) <= s_axi_wdata_reg_r(1); -- value(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_init_phase_value_r(2) <= s_axi_wdata_reg_r(2); -- value(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_init_phase_value_r(3) <= s_axi_wdata_reg_r(3); -- value(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_init_phase_value_r(4) <= s_axi_wdata_reg_r(4); -- value(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_init_phase_value_r(5) <= s_axi_wdata_reg_r(5); -- value(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_init_phase_value_r(6) <= s_axi_wdata_reg_r(6); -- value(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_init_phase_value_r(7) <= s_axi_wdata_reg_r(7); -- value(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_init_phase_value_r(8) <= s_axi_wdata_reg_r(8); -- value(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_init_phase_value_r(9) <= s_axi_wdata_reg_r(9); -- value(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_init_phase_value_r(10) <= s_axi_wdata_reg_r(10); -- value(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_init_phase_value_r(11) <= s_axi_wdata_reg_r(11); -- value(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_init_phase_value_r(12) <= s_axi_wdata_reg_r(12); -- value(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_init_phase_value_r(13) <= s_axi_wdata_reg_r(13); -- value(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_init_phase_value_r(14) <= s_axi_wdata_reg_r(14); -- value(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_init_phase_value_r(15) <= s_axi_wdata_reg_r(15); -- value(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_init_phase_value_r(16) <= s_axi_wdata_reg_r(16); -- value(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_init_phase_value_r(17) <= s_axi_wdata_reg_r(17); -- value(17)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_init_phase_value_r(18) <= s_axi_wdata_reg_r(18); -- value(18)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_init_phase_value_r(19) <= s_axi_wdata_reg_r(19); -- value(19)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_init_phase_value_r(20) <= s_axi_wdata_reg_r(20); -- value(20)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_init_phase_value_r(21) <= s_axi_wdata_reg_r(21); -- value(21)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_init_phase_value_r(22) <= s_axi_wdata_reg_r(22); -- value(22)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_init_phase_value_r(23) <= s_axi_wdata_reg_r(23); -- value(23)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_init_phase_value_r(24) <= s_axi_wdata_reg_r(24); -- value(24)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_init_phase_value_r(25) <= s_axi_wdata_reg_r(25); -- value(25)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_init_phase_value_r(26) <= s_axi_wdata_reg_r(26); -- value(26)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_init_phase_value_r(27) <= s_axi_wdata_reg_r(27); -- value(27)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_init_phase_value_r(28) <= s_axi_wdata_reg_r(28); -- value(28)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_init_phase_value_r(29) <= s_axi_wdata_reg_r(29); -- value(29)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_init_phase_value_r(30) <= s_axi_wdata_reg_r(30); -- value(30)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_dds_init_phase_value_r(31) <= s_axi_wdata_reg_r(31); -- value(31)
                        end if;
                    end if;
                    -- register 'dds_nb' at address offset 0x60
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + DDS_NB_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_dds_nb_strobe_r <= '1';
                        -- field 'points':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_nb_points_r(0) <= s_axi_wdata_reg_r(0); -- points(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_nb_points_r(1) <= s_axi_wdata_reg_r(1); -- points(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_nb_points_r(2) <= s_axi_wdata_reg_r(2); -- points(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_nb_points_r(3) <= s_axi_wdata_reg_r(3); -- points(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_nb_points_r(4) <= s_axi_wdata_reg_r(4); -- points(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_nb_points_r(5) <= s_axi_wdata_reg_r(5); -- points(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_nb_points_r(6) <= s_axi_wdata_reg_r(6); -- points(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_nb_points_r(7) <= s_axi_wdata_reg_r(7); -- points(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_nb_points_r(8) <= s_axi_wdata_reg_r(8); -- points(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_nb_points_r(9) <= s_axi_wdata_reg_r(9); -- points(9)
                        end if;
                        -- field 'repetitions':
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_nb_repetitions_r(0) <= s_axi_wdata_reg_r(10); -- repetitions(0)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_nb_repetitions_r(1) <= s_axi_wdata_reg_r(11); -- repetitions(1)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_nb_repetitions_r(2) <= s_axi_wdata_reg_r(12); -- repetitions(2)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_nb_repetitions_r(3) <= s_axi_wdata_reg_r(13); -- repetitions(3)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_nb_repetitions_r(4) <= s_axi_wdata_reg_r(14); -- repetitions(4)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_dds_nb_repetitions_r(5) <= s_axi_wdata_reg_r(15); -- repetitions(5)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_nb_repetitions_r(6) <= s_axi_wdata_reg_r(16); -- repetitions(6)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_nb_repetitions_r(7) <= s_axi_wdata_reg_r(17); -- repetitions(7)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_nb_repetitions_r(8) <= s_axi_wdata_reg_r(18); -- repetitions(8)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_dds_nb_repetitions_r(9) <= s_axi_wdata_reg_r(19); -- repetitions(9)
                        end if;
                    end if;
                    -- register 'dds_mode' at address offset 0x64
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + DDS_MODE_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_dds_mode_strobe_r <= '1';
                        -- field 'time':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_dds_mode_time_r(0) <= s_axi_wdata_reg_r(0); -- time(0)
                        end if;
                    end if;
                    --
                    if not v_addr_hit then
                        s_axi_bresp_r <= AXI_DECERR;
                        -- pragma translate_off
                        report "AWADDR decode error" severity warning;
                        -- pragma translate_on
                    end if;
                    --
                    v_state_r := DONE;

                -- Write transaction completed, wait for master BREADY to proceed
                when DONE =>
                    if s_axi_bready = '1' then
                        s_axi_bvalid_r <= '0';
                        v_state_r      := IDLE;
                    end if;

            end case;


        end if;
    end process write_fsm;

    ----------------------------------------------------------------------------
    -- Outputs
    --
    s_axi_awready <= s_axi_awready_r;
    s_axi_wready  <= s_axi_wready_r;
    s_axi_bvalid  <= s_axi_bvalid_r;
    s_axi_bresp   <= s_axi_bresp_r;
    s_axi_arready <= s_axi_arready_r;
    s_axi_rvalid  <= s_axi_rvalid_r;
    s_axi_rresp   <= s_axi_rresp_r;
    s_axi_rdata   <= s_axi_rdata_r;

    version_strobe <= s_version_strobe_r;
    bang_strobe <= s_bang_strobe_r;
    bang_field <= s_reg_bang_field_r;
    wave_config_strobe <= s_wave_config_strobe_r;
    wave_config_wave_type <= s_reg_wave_config_wave_type_r;
    wave_config_win_type <= s_reg_wave_config_win_type_r;
    sample_frequency_strobe <= s_sample_frequency_strobe_r;
    sample_frequency_value <= s_reg_sample_frequency_value_r;
    wave_nb_points_strobe <= s_wave_nb_points_strobe_r;
    wave_nb_points_value <= s_reg_wave_nb_points_value_r;
    fsm_nb_repetitions_strobe <= s_fsm_nb_repetitions_strobe_r;
    fsm_nb_repetitions_value <= s_reg_fsm_nb_repetitions_value_r;
    tx_timer_strobe <= s_tx_timer_strobe_r;
    tx_timer_value <= s_reg_tx_timer_value_r;
    deadzone_timer_strobe <= s_deadzone_timer_strobe_r;
    deadzone_timer_value <= s_reg_deadzone_timer_value_r;
    rx_timer_strobe <= s_rx_timer_strobe_r;
    rx_timer_value <= s_reg_rx_timer_value_r;
    idle_timer_strobe <= s_idle_timer_strobe_r;
    idle_timer_value <= s_reg_idle_timer_value_r;
    pulser_nb_repetitions_strobe <= s_pulser_nb_repetitions_strobe_r;
    pulser_nb_repetitions_value <= s_reg_pulser_nb_repetitions_value_r;
    pulser_t1_strobe <= s_pulser_t1_strobe_r;
    pulser_t1_value <= s_reg_pulser_t1_value_r;
    pulser_t2_strobe <= s_pulser_t2_strobe_r;
    pulser_t2_value <= s_reg_pulser_t2_value_r;
    pulser_t3_strobe <= s_pulser_t3_strobe_r;
    pulser_t3_value <= s_reg_pulser_t3_value_r;
    pulser_t4_strobe <= s_pulser_t4_strobe_r;
    pulser_t4_value <= s_reg_pulser_t4_value_r;
    pulser_tdamp_strobe <= s_pulser_tdamp_strobe_r;
    pulser_tdamp_value <= s_reg_pulser_tdamp_value_r;
    pulser_config_strobe <= s_pulser_config_strobe_r;
    pulser_config_invert <= s_reg_pulser_config_invert_r;
    pulser_config_triple <= s_reg_pulser_config_triple_r;
    dds_phase_term_strobe <= s_dds_phase_term_strobe_r;
    dds_phase_term_value <= s_reg_dds_phase_term_value_r;
    dds_init_phase_strobe <= s_dds_init_phase_strobe_r;
    dds_init_phase_value <= s_reg_dds_init_phase_value_r;
    dds_nb_strobe <= s_dds_nb_strobe_r;
    dds_nb_points <= s_reg_dds_nb_points_r;
    dds_nb_repetitions <= s_reg_dds_nb_repetitions_r;
    dds_mode_strobe <= s_dds_mode_strobe_r;
    dds_mode_time <= s_reg_dds_mode_time_r;

end architecture RTL;

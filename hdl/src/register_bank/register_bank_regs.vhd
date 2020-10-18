-- -----------------------------------------------------------------------------
-- 'pig_register_bank' Register Component
-- Revision: 70
-- -----------------------------------------------------------------------------
-- Generated on 2020-10-17 at 23:34 (UTC) by airhdl version 2020.09.1
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
        AXI_ADDR_WIDTH                      : positive := 32;  -- width of the AXI address bus
        BASEADDR                            : std_logic_vector(31 downto 0) := x"00000000" -- the register file's system base address		
    );
    port(
        -- Clock and Reset
        axi_aclk                            : in  std_logic;
        axi_aresetn                         : in  std_logic;
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
        -- User Ports
        version_strobe                      : out std_logic; -- Strobe signal for register 'version' (pulsed when the register is read from the bus)
        version_version                     : in std_logic_vector(7 downto 0); -- Value of register 'version', field 'version'
        
        bang_strobe                         : out std_logic; -- Strobe signal for register 'bang' (pulsed when the register is written from the bus)
        bang_bang                           : out std_logic_vector(0 downto 0); -- Value of register 'bang', field 'bang'
        
        sample_frequency_strobe             : out std_logic; -- Strobe signal for register 'sample_frequency' (pulsed when the register is written from the bus)
        sample_frequency_sample_frequency   : out std_logic_vector(26 downto 0); -- Value of register 'sample_frequency', field 'sample_frequency'
        
        target_frequency_strobe             : out std_logic; -- Strobe signal for register 'target_frequency' (pulsed when the register is written from the bus)
        target_frequency_target_frequency   : out std_logic_vector(31 downto 0); -- Value of register 'target_frequency', field 'target_frequency'
        
        phase_term_strobe                   : out std_logic; -- Strobe signal for register 'phase_term' (pulsed when the register is written from the bus)
        phase_term_phase_term               : out std_logic_vector(31 downto 0); -- Value of register 'phase_term', field 'phase_term'
        
        init_phase_strobe                   : out std_logic; -- Strobe signal for register 'init_phase' (pulsed when the register is written from the bus)
        init_phase_init_phase               : out std_logic_vector(31 downto 0); -- Value of register 'init_phase', field 'init_phase'
        
        numbers_strobe                      : out std_logic; -- Strobe signal for register 'numbers' (pulsed when the register is written from the bus)
        numbers_nb_points                   : out std_logic_vector(9 downto 0); -- Value of register 'numbers', field 'nb_points'
        numbers_nb_repetitions              : out std_logic_vector(9 downto 0); -- Value of register 'numbers', field 'nb_repetitions'
        
        win_phase_term_strobe               : out std_logic; -- Strobe signal for register 'win_phase_term' (pulsed when the register is written from the bus)
        win_phase_term_win_phase_term       : out std_logic_vector(31 downto 0); -- Value of register 'win_phase_term', field 'win_phase_term'
        
        config_mode_strobe                  : out std_logic; -- Strobe signal for register 'config_mode' (pulsed when the register is written from the bus)
        config_mode_dds_type                : out std_logic_vector(3 downto 0); -- Value of register 'config_mode', field 'dds_type'
        config_mode_mode_time               : out std_logic_vector(0 downto 0); -- Value of register 'config_mode', field 'mode_time'
        config_mode_win_type                : out std_logic_vector(3 downto 0); -- Value of register 'config_mode', field 'win_type'
        
        tx_timer_strobe                     : out std_logic; -- Strobe signal for register 'tx_timer' (pulsed when the register is written from the bus)
        tx_timer_tx_timer                   : out std_logic_vector(17 downto 0); -- Value of register 'tx_timer', field 'tx_timer'
        
        off_timer_strobe                    : out std_logic; -- Strobe signal for register 'off_timer' (pulsed when the register is written from the bus)
        off_timer_timer                     : out std_logic_vector(17 downto 0); -- Value of register 'off_timer', field 'timer'
        
        rx_timer_strobe                     : out std_logic; -- Strobe signal for register 'rx_timer' (pulsed when the register is written from the bus)
        rx_timer_timer                      : out std_logic_vector(17 downto 0); -- Value of register 'rx_timer', field 'timer'
        
        deadzone_timer_strobe               : out std_logic; -- Strobe signal for register 'deadzone_timer' (pulsed when the register is written from the bus)
        deadzone_timer_timer                : out std_logic_vector(17 downto 0) -- Value of register 'deadzone_timer', field 'timer'
    );
end entity register_bank_regs;

architecture RTL of register_bank_regs is
    
    ---------------
    -- Constants --
    ---------------
    constant AXI_OKAY           : std_logic_vector(1 downto 0) := "00";
    constant AXI_DECERR         : std_logic_vector(1 downto 0) := "11";

    -------------
    -- Signals --
    -------------

    -- Registered signals
    signal s_axi_awready_r                              : std_logic;
    signal s_axi_wready_r                               : std_logic;
    signal s_axi_awaddr_reg_r                           : unsigned(s_axi_awaddr'range);
    signal s_axi_bvalid_r                               : std_logic;
    signal s_axi_bresp_r                                : std_logic_vector(s_axi_bresp'range);
    signal s_axi_arready_r                              : std_logic;
    signal s_axi_araddr_reg_r                           : unsigned(s_axi_araddr'range);
    signal s_axi_rvalid_r                               : std_logic;
    signal s_axi_rresp_r                                : std_logic_vector(s_axi_rresp'range);
    signal s_axi_wdata_reg_r                            : std_logic_vector(s_axi_wdata'range);
    signal s_axi_wstrb_reg_r                            : std_logic_vector(s_axi_wstrb'range);
    signal s_axi_rdata_r                                : std_logic_vector(s_axi_rdata'range);
    
    -- User-defined registers
    signal s_version_strobe_r                           : std_logic;
    signal s_reg_version_version                        : std_logic_vector(7 downto 0);
    
    signal s_bang_strobe_r                              : std_logic;
    signal s_reg_bang_bang_r                            : std_logic_vector(0 downto 0);
    
    signal s_sample_frequency_strobe_r                  : std_logic;
    signal s_reg_sample_frequency_sample_frequency_r    : std_logic_vector(26 downto 0);
    
    signal s_target_frequency_strobe_r                  : std_logic;
    signal s_reg_target_frequency_target_frequency_r    : std_logic_vector(31 downto 0);
    
    signal s_phase_term_strobe_r                        : std_logic;
    signal s_reg_phase_term_phase_term_r                : std_logic_vector(31 downto 0);
    
    signal s_init_phase_strobe_r                        : std_logic;
    signal s_reg_init_phase_init_phase_r                : std_logic_vector(31 downto 0);
    
    signal s_numbers_strobe_r                           : std_logic;
    signal s_reg_numbers_nb_points_r                    : std_logic_vector(9 downto 0);
    signal s_reg_numbers_nb_repetitions_r               : std_logic_vector(9 downto 0);
    
    signal s_win_phase_term_strobe_r                    : std_logic;
    signal s_reg_win_phase_term_win_phase_term_r        : std_logic_vector(31 downto 0);
    
    signal s_config_mode_strobe_r                       : std_logic;
    signal s_reg_config_mode_dds_type_r                 : std_logic_vector(3 downto 0);
    signal s_reg_config_mode_mode_time_r                : std_logic_vector(0 downto 0);
    signal s_reg_config_mode_win_type_r                 : std_logic_vector(3 downto 0);
    
    signal s_tx_timer_strobe_r                          : std_logic;
    signal s_reg_tx_timer_tx_timer_r                    : std_logic_vector(17 downto 0);
    
    signal s_off_timer_strobe_r                         : std_logic;
    signal s_reg_off_timer_timer_r                      : std_logic_vector(17 downto 0);
    
    signal s_rx_timer_strobe_r                          : std_logic;
    signal s_reg_rx_timer_timer_r                       : std_logic_vector(17 downto 0);
    
    signal s_deadzone_timer_strobe_r                    : std_logic;
    signal s_reg_deadzone_timer_timer_r                 : std_logic_vector(17 downto 0);

begin

    ----------------------------------------------------------------------------
    -- Inputs
    --
    s_reg_version_version <= version_version;

    ----------------------------------------------------------------------------
    -- Read-transaction FSM
    --    
    read_fsm : process(axi_aclk, axi_aresetn) is
        constant MEM_WAIT_COUNT     : natural := 2;
        type t_state is (IDLE, READ_REGISTER, WAIT_MEMORY_RDATA, READ_RESPONSE, DONE);
        -- registered state variables
        variable v_state_r          : t_state;
        variable v_rdata_r          : std_logic_vector(31 downto 0);
        variable v_rresp_r          : std_logic_vector(s_axi_rresp'range);
        variable v_mem_wait_count_r : natural range 0 to MEM_WAIT_COUNT - 1;
        -- combinatorial helper variables
        variable v_addr_hit         : boolean;
        variable v_mem_addr         : unsigned(AXI_ADDR_WIDTH-1 downto 0);
    begin
        if (axi_aresetn = '0') then
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
 
        elsif (rising_edge(axi_aclk)) then
            -- Default values:
            s_axi_arready_r     <= '0';
            s_version_strobe_r  <= '0';

            case v_state_r is

                -- Wait for the start of a read transaction, which is 
                -- initiated by the assertion of ARVALID
                when IDLE =>
                    v_mem_wait_count_r := 0;
                    --
                    if (s_axi_arvalid = '1') then
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
                    if (s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + VERSION_OFFSET, AXI_ADDR_WIDTH)) then
                        v_addr_hit := true;
                        v_rdata_r(7 downto 0) := s_reg_version_version;
                        s_version_strobe_r <= '1';
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'sample_frequency' at address offset 0x20 
                    if (s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + SAMPLE_FREQUENCY_OFFSET, AXI_ADDR_WIDTH)) then
                        v_addr_hit := true;
                        v_rdata_r(26 downto 0) := s_reg_sample_frequency_sample_frequency_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'target_frequency' at address offset 0x24 
                    if (s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + TARGET_FREQUENCY_OFFSET, AXI_ADDR_WIDTH)) then
                        v_addr_hit := true;
                        v_rdata_r(31 downto 0) := s_reg_target_frequency_target_frequency_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'phase_term' at address offset 0x28 
                    if (s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + PHASE_TERM_OFFSET, AXI_ADDR_WIDTH)) then
                        v_addr_hit := true;
                        v_rdata_r(31 downto 0) := s_reg_phase_term_phase_term_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'init_phase' at address offset 0x2C 
                    if (s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + INIT_PHASE_OFFSET, AXI_ADDR_WIDTH)) then
                        v_addr_hit := true;
                        v_rdata_r(31 downto 0) := s_reg_init_phase_init_phase_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'numbers' at address offset 0x30 
                    if (s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + NUMBERS_OFFSET, AXI_ADDR_WIDTH)) then
                        v_addr_hit := true;
                        v_rdata_r(9 downto 0)   := s_reg_numbers_nb_points_r;
                        v_rdata_r(19 downto 10) := s_reg_numbers_nb_repetitions_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'win_phase_term' at address offset 0x34 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + WIN_PHASE_TERM_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(31 downto 0) := s_reg_win_phase_term_win_phase_term_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'config_mode' at address offset 0x38 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + CONFIG_MODE_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(3 downto 0) := s_reg_config_mode_dds_type_r;
                        v_rdata_r(4 downto 4) := s_reg_config_mode_mode_time_r;
                        v_rdata_r(8 downto 5) := s_reg_config_mode_win_type_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'tx_timer' at address offset 0x3C 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + TX_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(17 downto 0) := s_reg_tx_timer_tx_timer_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'off_timer' at address offset 0x40 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + OFF_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(17 downto 0) := s_reg_off_timer_timer_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'rx_timer' at address offset 0x44 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + RX_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(17 downto 0) := s_reg_rx_timer_timer_r;
                        v_state_r := READ_RESPONSE;
                    end if;
                    -- register 'deadzone_timer' at address offset 0x48 
                    if s_axi_araddr_reg_r = resize(unsigned(BASEADDR) + DEADZONE_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;
                        v_rdata_r(17 downto 0) := s_reg_deadzone_timer_timer_r;
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
            s_reg_bang_bang_r <= BANG_BANG_RESET;
            s_sample_frequency_strobe_r <= '0';
            s_reg_sample_frequency_sample_frequency_r <= SAMPLE_FREQUENCY_SAMPLE_FREQUENCY_RESET;
            s_target_frequency_strobe_r <= '0';
            s_reg_target_frequency_target_frequency_r <= TARGET_FREQUENCY_TARGET_FREQUENCY_RESET;
            s_phase_term_strobe_r <= '0';
            s_reg_phase_term_phase_term_r <= PHASE_TERM_PHASE_TERM_RESET;
            s_init_phase_strobe_r <= '0';
            s_reg_init_phase_init_phase_r <= INIT_PHASE_INIT_PHASE_RESET;
            s_numbers_strobe_r <= '0';
            s_reg_numbers_nb_points_r <= NUMBERS_NB_POINTS_RESET;
            s_reg_numbers_nb_repetitions_r <= NUMBERS_NB_REPETITIONS_RESET;
            s_win_phase_term_strobe_r <= '0';
            s_reg_win_phase_term_win_phase_term_r <= WIN_PHASE_TERM_WIN_PHASE_TERM_RESET;
            s_config_mode_strobe_r <= '0';
            s_reg_config_mode_dds_type_r <= CONFIG_MODE_DDS_TYPE_RESET;
            s_reg_config_mode_mode_time_r <= CONFIG_MODE_MODE_TIME_RESET;
            s_reg_config_mode_win_type_r <= CONFIG_MODE_WIN_TYPE_RESET;
            s_tx_timer_strobe_r <= '0';
            s_reg_tx_timer_tx_timer_r <= TX_TIMER_TX_TIMER_RESET;
            s_off_timer_strobe_r <= '0';
            s_reg_off_timer_timer_r <= OFF_TIMER_TIMER_RESET;
            s_rx_timer_strobe_r <= '0';
            s_reg_rx_timer_timer_r <= RX_TIMER_TIMER_RESET;
            s_deadzone_timer_strobe_r <= '0';
            s_reg_deadzone_timer_timer_r <= DEADZONE_TIMER_TIMER_RESET;

        elsif rising_edge(axi_aclk) then
            -- Default values:
            s_axi_awready_r <= '0';
            s_axi_wready_r  <= '0';
            s_bang_strobe_r <= '0';
            s_sample_frequency_strobe_r <= '0';
            s_target_frequency_strobe_r <= '0';
            s_phase_term_strobe_r <= '0';
            s_init_phase_strobe_r <= '0';
            s_numbers_strobe_r <= '0';
            s_win_phase_term_strobe_r <= '0';
            s_config_mode_strobe_r <= '0';
            s_tx_timer_strobe_r <= '0';
            s_off_timer_strobe_r <= '0';
            s_rx_timer_strobe_r <= '0';
            s_deadzone_timer_strobe_r <= '0';

            -- Self-clearing fields:
            s_reg_bang_bang_r <= (others => '0');

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
                        -- field 'bang':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_bang_bang_r(0) <= s_axi_wdata_reg_r(0); -- bang(0)
                        end if;
                    end if;
                    -- register 'sample_frequency' at address offset 0x20
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + SAMPLE_FREQUENCY_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_sample_frequency_strobe_r <= '1';
                        -- field 'sample_frequency':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(0) <= s_axi_wdata_reg_r(0); -- sample_frequency(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(1) <= s_axi_wdata_reg_r(1); -- sample_frequency(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(2) <= s_axi_wdata_reg_r(2); -- sample_frequency(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(3) <= s_axi_wdata_reg_r(3); -- sample_frequency(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(4) <= s_axi_wdata_reg_r(4); -- sample_frequency(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(5) <= s_axi_wdata_reg_r(5); -- sample_frequency(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(6) <= s_axi_wdata_reg_r(6); -- sample_frequency(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(7) <= s_axi_wdata_reg_r(7); -- sample_frequency(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(8) <= s_axi_wdata_reg_r(8); -- sample_frequency(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(9) <= s_axi_wdata_reg_r(9); -- sample_frequency(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(10) <= s_axi_wdata_reg_r(10); -- sample_frequency(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(11) <= s_axi_wdata_reg_r(11); -- sample_frequency(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(12) <= s_axi_wdata_reg_r(12); -- sample_frequency(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(13) <= s_axi_wdata_reg_r(13); -- sample_frequency(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(14) <= s_axi_wdata_reg_r(14); -- sample_frequency(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(15) <= s_axi_wdata_reg_r(15); -- sample_frequency(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(16) <= s_axi_wdata_reg_r(16); -- sample_frequency(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(17) <= s_axi_wdata_reg_r(17); -- sample_frequency(17)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(18) <= s_axi_wdata_reg_r(18); -- sample_frequency(18)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(19) <= s_axi_wdata_reg_r(19); -- sample_frequency(19)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(20) <= s_axi_wdata_reg_r(20); -- sample_frequency(20)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(21) <= s_axi_wdata_reg_r(21); -- sample_frequency(21)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(22) <= s_axi_wdata_reg_r(22); -- sample_frequency(22)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(23) <= s_axi_wdata_reg_r(23); -- sample_frequency(23)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(24) <= s_axi_wdata_reg_r(24); -- sample_frequency(24)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(25) <= s_axi_wdata_reg_r(25); -- sample_frequency(25)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_sample_frequency_sample_frequency_r(26) <= s_axi_wdata_reg_r(26); -- sample_frequency(26)
                        end if;
                    end if;
                    -- register 'target_frequency' at address offset 0x24
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + TARGET_FREQUENCY_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_target_frequency_strobe_r <= '1';
                        -- field 'target_frequency':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_target_frequency_target_frequency_r(0) <= s_axi_wdata_reg_r(0); -- target_frequency(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_target_frequency_target_frequency_r(1) <= s_axi_wdata_reg_r(1); -- target_frequency(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_target_frequency_target_frequency_r(2) <= s_axi_wdata_reg_r(2); -- target_frequency(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_target_frequency_target_frequency_r(3) <= s_axi_wdata_reg_r(3); -- target_frequency(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_target_frequency_target_frequency_r(4) <= s_axi_wdata_reg_r(4); -- target_frequency(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_target_frequency_target_frequency_r(5) <= s_axi_wdata_reg_r(5); -- target_frequency(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_target_frequency_target_frequency_r(6) <= s_axi_wdata_reg_r(6); -- target_frequency(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_target_frequency_target_frequency_r(7) <= s_axi_wdata_reg_r(7); -- target_frequency(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_target_frequency_target_frequency_r(8) <= s_axi_wdata_reg_r(8); -- target_frequency(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_target_frequency_target_frequency_r(9) <= s_axi_wdata_reg_r(9); -- target_frequency(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_target_frequency_target_frequency_r(10) <= s_axi_wdata_reg_r(10); -- target_frequency(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_target_frequency_target_frequency_r(11) <= s_axi_wdata_reg_r(11); -- target_frequency(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_target_frequency_target_frequency_r(12) <= s_axi_wdata_reg_r(12); -- target_frequency(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_target_frequency_target_frequency_r(13) <= s_axi_wdata_reg_r(13); -- target_frequency(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_target_frequency_target_frequency_r(14) <= s_axi_wdata_reg_r(14); -- target_frequency(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_target_frequency_target_frequency_r(15) <= s_axi_wdata_reg_r(15); -- target_frequency(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_target_frequency_target_frequency_r(16) <= s_axi_wdata_reg_r(16); -- target_frequency(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_target_frequency_target_frequency_r(17) <= s_axi_wdata_reg_r(17); -- target_frequency(17)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_target_frequency_target_frequency_r(18) <= s_axi_wdata_reg_r(18); -- target_frequency(18)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_target_frequency_target_frequency_r(19) <= s_axi_wdata_reg_r(19); -- target_frequency(19)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_target_frequency_target_frequency_r(20) <= s_axi_wdata_reg_r(20); -- target_frequency(20)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_target_frequency_target_frequency_r(21) <= s_axi_wdata_reg_r(21); -- target_frequency(21)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_target_frequency_target_frequency_r(22) <= s_axi_wdata_reg_r(22); -- target_frequency(22)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_target_frequency_target_frequency_r(23) <= s_axi_wdata_reg_r(23); -- target_frequency(23)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_target_frequency_target_frequency_r(24) <= s_axi_wdata_reg_r(24); -- target_frequency(24)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_target_frequency_target_frequency_r(25) <= s_axi_wdata_reg_r(25); -- target_frequency(25)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_target_frequency_target_frequency_r(26) <= s_axi_wdata_reg_r(26); -- target_frequency(26)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_target_frequency_target_frequency_r(27) <= s_axi_wdata_reg_r(27); -- target_frequency(27)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_target_frequency_target_frequency_r(28) <= s_axi_wdata_reg_r(28); -- target_frequency(28)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_target_frequency_target_frequency_r(29) <= s_axi_wdata_reg_r(29); -- target_frequency(29)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_target_frequency_target_frequency_r(30) <= s_axi_wdata_reg_r(30); -- target_frequency(30)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_target_frequency_target_frequency_r(31) <= s_axi_wdata_reg_r(31); -- target_frequency(31)
                        end if;
                    end if;
                    -- register 'phase_term' at address offset 0x28
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + PHASE_TERM_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_phase_term_strobe_r <= '1';
                        -- field 'phase_term':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_phase_term_phase_term_r(0) <= s_axi_wdata_reg_r(0); -- phase_term(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_phase_term_phase_term_r(1) <= s_axi_wdata_reg_r(1); -- phase_term(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_phase_term_phase_term_r(2) <= s_axi_wdata_reg_r(2); -- phase_term(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_phase_term_phase_term_r(3) <= s_axi_wdata_reg_r(3); -- phase_term(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_phase_term_phase_term_r(4) <= s_axi_wdata_reg_r(4); -- phase_term(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_phase_term_phase_term_r(5) <= s_axi_wdata_reg_r(5); -- phase_term(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_phase_term_phase_term_r(6) <= s_axi_wdata_reg_r(6); -- phase_term(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_phase_term_phase_term_r(7) <= s_axi_wdata_reg_r(7); -- phase_term(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_phase_term_phase_term_r(8) <= s_axi_wdata_reg_r(8); -- phase_term(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_phase_term_phase_term_r(9) <= s_axi_wdata_reg_r(9); -- phase_term(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_phase_term_phase_term_r(10) <= s_axi_wdata_reg_r(10); -- phase_term(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_phase_term_phase_term_r(11) <= s_axi_wdata_reg_r(11); -- phase_term(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_phase_term_phase_term_r(12) <= s_axi_wdata_reg_r(12); -- phase_term(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_phase_term_phase_term_r(13) <= s_axi_wdata_reg_r(13); -- phase_term(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_phase_term_phase_term_r(14) <= s_axi_wdata_reg_r(14); -- phase_term(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_phase_term_phase_term_r(15) <= s_axi_wdata_reg_r(15); -- phase_term(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_phase_term_phase_term_r(16) <= s_axi_wdata_reg_r(16); -- phase_term(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_phase_term_phase_term_r(17) <= s_axi_wdata_reg_r(17); -- phase_term(17)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_phase_term_phase_term_r(18) <= s_axi_wdata_reg_r(18); -- phase_term(18)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_phase_term_phase_term_r(19) <= s_axi_wdata_reg_r(19); -- phase_term(19)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_phase_term_phase_term_r(20) <= s_axi_wdata_reg_r(20); -- phase_term(20)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_phase_term_phase_term_r(21) <= s_axi_wdata_reg_r(21); -- phase_term(21)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_phase_term_phase_term_r(22) <= s_axi_wdata_reg_r(22); -- phase_term(22)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_phase_term_phase_term_r(23) <= s_axi_wdata_reg_r(23); -- phase_term(23)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_phase_term_phase_term_r(24) <= s_axi_wdata_reg_r(24); -- phase_term(24)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_phase_term_phase_term_r(25) <= s_axi_wdata_reg_r(25); -- phase_term(25)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_phase_term_phase_term_r(26) <= s_axi_wdata_reg_r(26); -- phase_term(26)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_phase_term_phase_term_r(27) <= s_axi_wdata_reg_r(27); -- phase_term(27)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_phase_term_phase_term_r(28) <= s_axi_wdata_reg_r(28); -- phase_term(28)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_phase_term_phase_term_r(29) <= s_axi_wdata_reg_r(29); -- phase_term(29)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_phase_term_phase_term_r(30) <= s_axi_wdata_reg_r(30); -- phase_term(30)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_phase_term_phase_term_r(31) <= s_axi_wdata_reg_r(31); -- phase_term(31)
                        end if;
                    end if;
                    -- register 'init_phase' at address offset 0x2C
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + INIT_PHASE_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_init_phase_strobe_r <= '1';
                        -- field 'init_phase':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_init_phase_init_phase_r(0) <= s_axi_wdata_reg_r(0); -- init_phase(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_init_phase_init_phase_r(1) <= s_axi_wdata_reg_r(1); -- init_phase(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_init_phase_init_phase_r(2) <= s_axi_wdata_reg_r(2); -- init_phase(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_init_phase_init_phase_r(3) <= s_axi_wdata_reg_r(3); -- init_phase(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_init_phase_init_phase_r(4) <= s_axi_wdata_reg_r(4); -- init_phase(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_init_phase_init_phase_r(5) <= s_axi_wdata_reg_r(5); -- init_phase(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_init_phase_init_phase_r(6) <= s_axi_wdata_reg_r(6); -- init_phase(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_init_phase_init_phase_r(7) <= s_axi_wdata_reg_r(7); -- init_phase(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_init_phase_init_phase_r(8) <= s_axi_wdata_reg_r(8); -- init_phase(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_init_phase_init_phase_r(9) <= s_axi_wdata_reg_r(9); -- init_phase(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_init_phase_init_phase_r(10) <= s_axi_wdata_reg_r(10); -- init_phase(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_init_phase_init_phase_r(11) <= s_axi_wdata_reg_r(11); -- init_phase(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_init_phase_init_phase_r(12) <= s_axi_wdata_reg_r(12); -- init_phase(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_init_phase_init_phase_r(13) <= s_axi_wdata_reg_r(13); -- init_phase(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_init_phase_init_phase_r(14) <= s_axi_wdata_reg_r(14); -- init_phase(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_init_phase_init_phase_r(15) <= s_axi_wdata_reg_r(15); -- init_phase(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_init_phase_init_phase_r(16) <= s_axi_wdata_reg_r(16); -- init_phase(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_init_phase_init_phase_r(17) <= s_axi_wdata_reg_r(17); -- init_phase(17)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_init_phase_init_phase_r(18) <= s_axi_wdata_reg_r(18); -- init_phase(18)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_init_phase_init_phase_r(19) <= s_axi_wdata_reg_r(19); -- init_phase(19)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_init_phase_init_phase_r(20) <= s_axi_wdata_reg_r(20); -- init_phase(20)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_init_phase_init_phase_r(21) <= s_axi_wdata_reg_r(21); -- init_phase(21)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_init_phase_init_phase_r(22) <= s_axi_wdata_reg_r(22); -- init_phase(22)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_init_phase_init_phase_r(23) <= s_axi_wdata_reg_r(23); -- init_phase(23)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_init_phase_init_phase_r(24) <= s_axi_wdata_reg_r(24); -- init_phase(24)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_init_phase_init_phase_r(25) <= s_axi_wdata_reg_r(25); -- init_phase(25)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_init_phase_init_phase_r(26) <= s_axi_wdata_reg_r(26); -- init_phase(26)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_init_phase_init_phase_r(27) <= s_axi_wdata_reg_r(27); -- init_phase(27)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_init_phase_init_phase_r(28) <= s_axi_wdata_reg_r(28); -- init_phase(28)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_init_phase_init_phase_r(29) <= s_axi_wdata_reg_r(29); -- init_phase(29)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_init_phase_init_phase_r(30) <= s_axi_wdata_reg_r(30); -- init_phase(30)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_init_phase_init_phase_r(31) <= s_axi_wdata_reg_r(31); -- init_phase(31)
                        end if;
                    end if;
                    -- register 'numbers' at address offset 0x30
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + NUMBERS_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_numbers_strobe_r <= '1';
                        -- field 'nb_points':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_numbers_nb_points_r(0) <= s_axi_wdata_reg_r(0); -- nb_points(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_numbers_nb_points_r(1) <= s_axi_wdata_reg_r(1); -- nb_points(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_numbers_nb_points_r(2) <= s_axi_wdata_reg_r(2); -- nb_points(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_numbers_nb_points_r(3) <= s_axi_wdata_reg_r(3); -- nb_points(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_numbers_nb_points_r(4) <= s_axi_wdata_reg_r(4); -- nb_points(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_numbers_nb_points_r(5) <= s_axi_wdata_reg_r(5); -- nb_points(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_numbers_nb_points_r(6) <= s_axi_wdata_reg_r(6); -- nb_points(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_numbers_nb_points_r(7) <= s_axi_wdata_reg_r(7); -- nb_points(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_numbers_nb_points_r(8) <= s_axi_wdata_reg_r(8); -- nb_points(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_numbers_nb_points_r(9) <= s_axi_wdata_reg_r(9); -- nb_points(9)
                        end if;
                        -- field 'nb_repetitions':
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_numbers_nb_repetitions_r(0) <= s_axi_wdata_reg_r(10); -- nb_repetitions(0)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_numbers_nb_repetitions_r(1) <= s_axi_wdata_reg_r(11); -- nb_repetitions(1)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_numbers_nb_repetitions_r(2) <= s_axi_wdata_reg_r(12); -- nb_repetitions(2)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_numbers_nb_repetitions_r(3) <= s_axi_wdata_reg_r(13); -- nb_repetitions(3)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_numbers_nb_repetitions_r(4) <= s_axi_wdata_reg_r(14); -- nb_repetitions(4)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_numbers_nb_repetitions_r(5) <= s_axi_wdata_reg_r(15); -- nb_repetitions(5)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_numbers_nb_repetitions_r(6) <= s_axi_wdata_reg_r(16); -- nb_repetitions(6)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_numbers_nb_repetitions_r(7) <= s_axi_wdata_reg_r(17); -- nb_repetitions(7)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_numbers_nb_repetitions_r(8) <= s_axi_wdata_reg_r(18); -- nb_repetitions(8)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_numbers_nb_repetitions_r(9) <= s_axi_wdata_reg_r(19); -- nb_repetitions(9)
                        end if;
                    end if;
                    -- register 'win_phase_term' at address offset 0x34
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + WIN_PHASE_TERM_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_win_phase_term_strobe_r <= '1';
                        -- field 'win_phase_term':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(0) <= s_axi_wdata_reg_r(0); -- win_phase_term(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(1) <= s_axi_wdata_reg_r(1); -- win_phase_term(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(2) <= s_axi_wdata_reg_r(2); -- win_phase_term(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(3) <= s_axi_wdata_reg_r(3); -- win_phase_term(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(4) <= s_axi_wdata_reg_r(4); -- win_phase_term(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(5) <= s_axi_wdata_reg_r(5); -- win_phase_term(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(6) <= s_axi_wdata_reg_r(6); -- win_phase_term(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(7) <= s_axi_wdata_reg_r(7); -- win_phase_term(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(8) <= s_axi_wdata_reg_r(8); -- win_phase_term(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(9) <= s_axi_wdata_reg_r(9); -- win_phase_term(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(10) <= s_axi_wdata_reg_r(10); -- win_phase_term(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(11) <= s_axi_wdata_reg_r(11); -- win_phase_term(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(12) <= s_axi_wdata_reg_r(12); -- win_phase_term(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(13) <= s_axi_wdata_reg_r(13); -- win_phase_term(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(14) <= s_axi_wdata_reg_r(14); -- win_phase_term(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(15) <= s_axi_wdata_reg_r(15); -- win_phase_term(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(16) <= s_axi_wdata_reg_r(16); -- win_phase_term(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(17) <= s_axi_wdata_reg_r(17); -- win_phase_term(17)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(18) <= s_axi_wdata_reg_r(18); -- win_phase_term(18)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(19) <= s_axi_wdata_reg_r(19); -- win_phase_term(19)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(20) <= s_axi_wdata_reg_r(20); -- win_phase_term(20)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(21) <= s_axi_wdata_reg_r(21); -- win_phase_term(21)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(22) <= s_axi_wdata_reg_r(22); -- win_phase_term(22)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(23) <= s_axi_wdata_reg_r(23); -- win_phase_term(23)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(24) <= s_axi_wdata_reg_r(24); -- win_phase_term(24)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(25) <= s_axi_wdata_reg_r(25); -- win_phase_term(25)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(26) <= s_axi_wdata_reg_r(26); -- win_phase_term(26)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(27) <= s_axi_wdata_reg_r(27); -- win_phase_term(27)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(28) <= s_axi_wdata_reg_r(28); -- win_phase_term(28)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(29) <= s_axi_wdata_reg_r(29); -- win_phase_term(29)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(30) <= s_axi_wdata_reg_r(30); -- win_phase_term(30)
                        end if;
                        if s_axi_wstrb_reg_r(3) = '1' then
                            s_reg_win_phase_term_win_phase_term_r(31) <= s_axi_wdata_reg_r(31); -- win_phase_term(31)
                        end if;
                    end if;
                    -- register 'config_mode' at address offset 0x38
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + CONFIG_MODE_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_config_mode_strobe_r <= '1';
                        -- field 'dds_type':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_config_mode_dds_type_r(0) <= s_axi_wdata_reg_r(0); -- dds_type(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_config_mode_dds_type_r(1) <= s_axi_wdata_reg_r(1); -- dds_type(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_config_mode_dds_type_r(2) <= s_axi_wdata_reg_r(2); -- dds_type(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_config_mode_dds_type_r(3) <= s_axi_wdata_reg_r(3); -- dds_type(3)
                        end if;
                        -- field 'mode_time':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_config_mode_mode_time_r(0) <= s_axi_wdata_reg_r(4); -- mode_time(0)
                        end if;
                        -- field 'win_type':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_config_mode_win_type_r(0) <= s_axi_wdata_reg_r(5); -- win_type(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_config_mode_win_type_r(1) <= s_axi_wdata_reg_r(6); -- win_type(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_config_mode_win_type_r(2) <= s_axi_wdata_reg_r(7); -- win_type(2)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_config_mode_win_type_r(3) <= s_axi_wdata_reg_r(8); -- win_type(3)
                        end if;
                    end if;
                    -- register 'tx_timer' at address offset 0x3C
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + TX_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_tx_timer_strobe_r <= '1';
                        -- field 'tx_timer':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_tx_timer_r(0) <= s_axi_wdata_reg_r(0); -- tx_timer(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_tx_timer_r(1) <= s_axi_wdata_reg_r(1); -- tx_timer(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_tx_timer_r(2) <= s_axi_wdata_reg_r(2); -- tx_timer(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_tx_timer_r(3) <= s_axi_wdata_reg_r(3); -- tx_timer(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_tx_timer_r(4) <= s_axi_wdata_reg_r(4); -- tx_timer(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_tx_timer_r(5) <= s_axi_wdata_reg_r(5); -- tx_timer(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_tx_timer_r(6) <= s_axi_wdata_reg_r(6); -- tx_timer(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_tx_timer_tx_timer_r(7) <= s_axi_wdata_reg_r(7); -- tx_timer(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_tx_timer_r(8) <= s_axi_wdata_reg_r(8); -- tx_timer(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_tx_timer_r(9) <= s_axi_wdata_reg_r(9); -- tx_timer(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_tx_timer_r(10) <= s_axi_wdata_reg_r(10); -- tx_timer(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_tx_timer_r(11) <= s_axi_wdata_reg_r(11); -- tx_timer(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_tx_timer_r(12) <= s_axi_wdata_reg_r(12); -- tx_timer(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_tx_timer_r(13) <= s_axi_wdata_reg_r(13); -- tx_timer(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_tx_timer_r(14) <= s_axi_wdata_reg_r(14); -- tx_timer(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_tx_timer_tx_timer_r(15) <= s_axi_wdata_reg_r(15); -- tx_timer(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_tx_timer_tx_timer_r(16) <= s_axi_wdata_reg_r(16); -- tx_timer(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_tx_timer_tx_timer_r(17) <= s_axi_wdata_reg_r(17); -- tx_timer(17)
                        end if;
                    end if;
                    -- register 'off_timer' at address offset 0x40
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + OFF_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_off_timer_strobe_r <= '1';
                        -- field 'timer':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_off_timer_timer_r(0) <= s_axi_wdata_reg_r(0); -- timer(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_off_timer_timer_r(1) <= s_axi_wdata_reg_r(1); -- timer(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_off_timer_timer_r(2) <= s_axi_wdata_reg_r(2); -- timer(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_off_timer_timer_r(3) <= s_axi_wdata_reg_r(3); -- timer(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_off_timer_timer_r(4) <= s_axi_wdata_reg_r(4); -- timer(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_off_timer_timer_r(5) <= s_axi_wdata_reg_r(5); -- timer(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_off_timer_timer_r(6) <= s_axi_wdata_reg_r(6); -- timer(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_off_timer_timer_r(7) <= s_axi_wdata_reg_r(7); -- timer(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_off_timer_timer_r(8) <= s_axi_wdata_reg_r(8); -- timer(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_off_timer_timer_r(9) <= s_axi_wdata_reg_r(9); -- timer(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_off_timer_timer_r(10) <= s_axi_wdata_reg_r(10); -- timer(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_off_timer_timer_r(11) <= s_axi_wdata_reg_r(11); -- timer(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_off_timer_timer_r(12) <= s_axi_wdata_reg_r(12); -- timer(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_off_timer_timer_r(13) <= s_axi_wdata_reg_r(13); -- timer(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_off_timer_timer_r(14) <= s_axi_wdata_reg_r(14); -- timer(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_off_timer_timer_r(15) <= s_axi_wdata_reg_r(15); -- timer(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_off_timer_timer_r(16) <= s_axi_wdata_reg_r(16); -- timer(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_off_timer_timer_r(17) <= s_axi_wdata_reg_r(17); -- timer(17)
                        end if;
                    end if;
                    -- register 'rx_timer' at address offset 0x44
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + RX_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_rx_timer_strobe_r <= '1';
                        -- field 'timer':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_timer_r(0) <= s_axi_wdata_reg_r(0); -- timer(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_timer_r(1) <= s_axi_wdata_reg_r(1); -- timer(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_timer_r(2) <= s_axi_wdata_reg_r(2); -- timer(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_timer_r(3) <= s_axi_wdata_reg_r(3); -- timer(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_timer_r(4) <= s_axi_wdata_reg_r(4); -- timer(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_timer_r(5) <= s_axi_wdata_reg_r(5); -- timer(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_timer_r(6) <= s_axi_wdata_reg_r(6); -- timer(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_rx_timer_timer_r(7) <= s_axi_wdata_reg_r(7); -- timer(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_timer_r(8) <= s_axi_wdata_reg_r(8); -- timer(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_timer_r(9) <= s_axi_wdata_reg_r(9); -- timer(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_timer_r(10) <= s_axi_wdata_reg_r(10); -- timer(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_timer_r(11) <= s_axi_wdata_reg_r(11); -- timer(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_timer_r(12) <= s_axi_wdata_reg_r(12); -- timer(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_timer_r(13) <= s_axi_wdata_reg_r(13); -- timer(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_timer_r(14) <= s_axi_wdata_reg_r(14); -- timer(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_rx_timer_timer_r(15) <= s_axi_wdata_reg_r(15); -- timer(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_rx_timer_timer_r(16) <= s_axi_wdata_reg_r(16); -- timer(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_rx_timer_timer_r(17) <= s_axi_wdata_reg_r(17); -- timer(17)
                        end if;
                    end if;
                    -- register 'deadzone_timer' at address offset 0x48
                    if s_axi_awaddr_reg_r = resize(unsigned(BASEADDR) + DEADZONE_TIMER_OFFSET, AXI_ADDR_WIDTH) then
                        v_addr_hit := true;                        
                        s_deadzone_timer_strobe_r <= '1';
                        -- field 'timer':
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_timer_r(0) <= s_axi_wdata_reg_r(0); -- timer(0)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_timer_r(1) <= s_axi_wdata_reg_r(1); -- timer(1)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_timer_r(2) <= s_axi_wdata_reg_r(2); -- timer(2)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_timer_r(3) <= s_axi_wdata_reg_r(3); -- timer(3)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_timer_r(4) <= s_axi_wdata_reg_r(4); -- timer(4)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_timer_r(5) <= s_axi_wdata_reg_r(5); -- timer(5)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_timer_r(6) <= s_axi_wdata_reg_r(6); -- timer(6)
                        end if;
                        if s_axi_wstrb_reg_r(0) = '1' then
                            s_reg_deadzone_timer_timer_r(7) <= s_axi_wdata_reg_r(7); -- timer(7)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_timer_r(8) <= s_axi_wdata_reg_r(8); -- timer(8)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_timer_r(9) <= s_axi_wdata_reg_r(9); -- timer(9)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_timer_r(10) <= s_axi_wdata_reg_r(10); -- timer(10)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_timer_r(11) <= s_axi_wdata_reg_r(11); -- timer(11)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_timer_r(12) <= s_axi_wdata_reg_r(12); -- timer(12)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_timer_r(13) <= s_axi_wdata_reg_r(13); -- timer(13)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_timer_r(14) <= s_axi_wdata_reg_r(14); -- timer(14)
                        end if;
                        if s_axi_wstrb_reg_r(1) = '1' then
                            s_reg_deadzone_timer_timer_r(15) <= s_axi_wdata_reg_r(15); -- timer(15)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_deadzone_timer_timer_r(16) <= s_axi_wdata_reg_r(16); -- timer(16)
                        end if;
                        if s_axi_wstrb_reg_r(2) = '1' then
                            s_reg_deadzone_timer_timer_r(17) <= s_axi_wdata_reg_r(17); -- timer(17)
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
    bang_bang <= s_reg_bang_bang_r;
    sample_frequency_strobe <= s_sample_frequency_strobe_r;
    sample_frequency_sample_frequency <= s_reg_sample_frequency_sample_frequency_r;
    target_frequency_strobe <= s_target_frequency_strobe_r;
    target_frequency_target_frequency <= s_reg_target_frequency_target_frequency_r;
    phase_term_strobe <= s_phase_term_strobe_r;
    phase_term_phase_term <= s_reg_phase_term_phase_term_r;
    init_phase_strobe <= s_init_phase_strobe_r;
    init_phase_init_phase <= s_reg_init_phase_init_phase_r;
    numbers_strobe <= s_numbers_strobe_r;
    numbers_nb_points <= s_reg_numbers_nb_points_r;
    numbers_nb_repetitions <= s_reg_numbers_nb_repetitions_r;
    win_phase_term_strobe <= s_win_phase_term_strobe_r;
    win_phase_term_win_phase_term <= s_reg_win_phase_term_win_phase_term_r;
    config_mode_strobe <= s_config_mode_strobe_r;
    config_mode_dds_type <= s_reg_config_mode_dds_type_r;
    config_mode_mode_time <= s_reg_config_mode_mode_time_r;
    config_mode_win_type <= s_reg_config_mode_win_type_r;
    tx_timer_strobe <= s_tx_timer_strobe_r;
    tx_timer_tx_timer <= s_reg_tx_timer_tx_timer_r;
    off_timer_strobe <= s_off_timer_strobe_r;
    off_timer_timer <= s_reg_off_timer_timer_r;
    rx_timer_strobe <= s_rx_timer_strobe_r;
    rx_timer_timer <= s_reg_rx_timer_timer_r;
    deadzone_timer_strobe <= s_deadzone_timer_strobe_r;
    deadzone_timer_timer <= s_reg_deadzone_timer_timer_r;

end architecture RTL;

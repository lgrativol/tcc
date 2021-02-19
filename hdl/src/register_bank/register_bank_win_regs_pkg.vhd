-- -----------------------------------------------------------------------------
-- 'register_bank_win' Register Definitions
-- Revision: 23
-- -----------------------------------------------------------------------------
-- Generated on 2020-12-20 at 01:37 (UTC) by airhdl version 2020.10.1
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

package register_bank_win_regs_pkg is

    -- Type definitions
    type slv1_array_t is array(natural range <>) of std_logic_vector(0 downto 0);
    type slv2_array_t is array(natural range <>) of std_logic_vector(1 downto 0);
    type slv3_array_t is array(natural range <>) of std_logic_vector(2 downto 0);
    type slv4_array_t is array(natural range <>) of std_logic_vector(3 downto 0);
    type slv5_array_t is array(natural range <>) of std_logic_vector(4 downto 0);
    type slv6_array_t is array(natural range <>) of std_logic_vector(5 downto 0);
    type slv7_array_t is array(natural range <>) of std_logic_vector(6 downto 0);
    type slv8_array_t is array(natural range <>) of std_logic_vector(7 downto 0);
    type slv9_array_t is array(natural range <>) of std_logic_vector(8 downto 0);
    type slv10_array_t is array(natural range <>) of std_logic_vector(9 downto 0);
    type slv11_array_t is array(natural range <>) of std_logic_vector(10 downto 0);
    type slv12_array_t is array(natural range <>) of std_logic_vector(11 downto 0);
    type slv13_array_t is array(natural range <>) of std_logic_vector(12 downto 0);
    type slv14_array_t is array(natural range <>) of std_logic_vector(13 downto 0);
    type slv15_array_t is array(natural range <>) of std_logic_vector(14 downto 0);
    type slv16_array_t is array(natural range <>) of std_logic_vector(15 downto 0);
    type slv17_array_t is array(natural range <>) of std_logic_vector(16 downto 0);
    type slv18_array_t is array(natural range <>) of std_logic_vector(17 downto 0);
    type slv19_array_t is array(natural range <>) of std_logic_vector(18 downto 0);
    type slv20_array_t is array(natural range <>) of std_logic_vector(19 downto 0);
    type slv21_array_t is array(natural range <>) of std_logic_vector(20 downto 0);
    type slv22_array_t is array(natural range <>) of std_logic_vector(21 downto 0);
    type slv23_array_t is array(natural range <>) of std_logic_vector(22 downto 0);
    type slv24_array_t is array(natural range <>) of std_logic_vector(23 downto 0);
    type slv25_array_t is array(natural range <>) of std_logic_vector(24 downto 0);
    type slv26_array_t is array(natural range <>) of std_logic_vector(25 downto 0);
    type slv27_array_t is array(natural range <>) of std_logic_vector(26 downto 0);
    type slv28_array_t is array(natural range <>) of std_logic_vector(27 downto 0);
    type slv29_array_t is array(natural range <>) of std_logic_vector(28 downto 0);
    type slv30_array_t is array(natural range <>) of std_logic_vector(29 downto 0);
    type slv31_array_t is array(natural range <>) of std_logic_vector(30 downto 0);
    type slv32_array_t is array(natural range <>) of std_logic_vector(31 downto 0);


    -- Revision number of the 'register_bank_win' register map
    constant REGISTER_BANK_WIN_REVISION : natural := 23;

    -- Default base address of the 'register_bank_win' register map 
    constant REGISTER_BANK_WIN_DEFAULT_BASEADDR : unsigned(31 downto 0) := unsigned'(x"00000000");
    
    -- Register 'version'
    constant VERSION_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000000"); -- address offset of the 'version' register
    -- Field 'version.field'
    constant VERSION_FIELD_BIT_OFFSET : natural := 0; -- bit offset of the 'field' field
    constant VERSION_FIELD_BIT_WIDTH : natural := 8; -- bit width of the 'field' field
    constant VERSION_FIELD_RESET : std_logic_vector(7 downto 0) := std_logic_vector'("00000000"); -- reset value of the 'field' field
    
    -- Register 'bang'
    constant BANG_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000004"); -- address offset of the 'bang' register
    -- Field 'bang.field'
    constant BANG_FIELD_BIT_OFFSET : natural := 0; -- bit offset of the 'field' field
    constant BANG_FIELD_BIT_WIDTH : natural := 1; -- bit width of the 'field' field
    constant BANG_FIELD_RESET : std_logic_vector(0 downto 0) := std_logic_vector'("0"); -- reset value of the 'field' field
    
    -- Register 'sample_frequency'
    constant SAMPLE_FREQUENCY_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000008"); -- address offset of the 'sample_frequency' register
    -- Field 'sample_frequency.value'
    constant SAMPLE_FREQUENCY_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant SAMPLE_FREQUENCY_VALUE_BIT_WIDTH : natural := 27; -- bit width of the 'value' field
    constant SAMPLE_FREQUENCY_VALUE_RESET : std_logic_vector(26 downto 0) := std_logic_vector'("101111101011110000100000000"); -- reset value of the 'value' field
    
    -- Register 'wave_nb_periods'
    constant WAVE_NB_PERIODS_OFFSET : unsigned(31 downto 0) := unsigned'(x"0000000C"); -- address offset of the 'wave_nb_periods' register
    -- Field 'wave_nb_periods.value'
    constant WAVE_NB_PERIODS_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant WAVE_NB_PERIODS_VALUE_BIT_WIDTH : natural := 8; -- bit width of the 'value' field
    constant WAVE_NB_PERIODS_VALUE_RESET : std_logic_vector(7 downto 0) := std_logic_vector'("00000000"); -- reset value of the 'value' field
    
    -- Register 'wave_nb_points'
    constant WAVE_NB_POINTS_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000010"); -- address offset of the 'wave_nb_points' register
    -- Field 'wave_nb_points.value'
    constant WAVE_NB_POINTS_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant WAVE_NB_POINTS_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant WAVE_NB_POINTS_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'wave_config'
    constant WAVE_CONFIG_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000014"); -- address offset of the 'wave_config' register
    -- Field 'wave_config.wave_type'
    constant WAVE_CONFIG_WAVE_TYPE_BIT_OFFSET : natural := 0; -- bit offset of the 'wave_type' field
    constant WAVE_CONFIG_WAVE_TYPE_BIT_WIDTH : natural := 1; -- bit width of the 'wave_type' field
    constant WAVE_CONFIG_WAVE_TYPE_RESET : std_logic_vector(0 downto 0) := std_logic_vector'("0"); -- reset value of the 'wave_type' field
    
    -- Register 'fsm_nb_repetitions'
    constant FSM_NB_REPETITIONS_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000024"); -- address offset of the 'fsm_nb_repetitions' register
    -- Field 'fsm_nb_repetitions.value'
    constant FSM_NB_REPETITIONS_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant FSM_NB_REPETITIONS_VALUE_BIT_WIDTH : natural := 6; -- bit width of the 'value' field
    constant FSM_NB_REPETITIONS_VALUE_RESET : std_logic_vector(5 downto 0) := std_logic_vector'("000000"); -- reset value of the 'value' field
    
    -- Register 'fsm_setup_timer'
    constant FSM_SETUP_TIMER_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000028"); -- address offset of the 'fsm_setup_timer' register
    -- Field 'fsm_setup_timer.value'
    constant FSM_SETUP_TIMER_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant FSM_SETUP_TIMER_VALUE_BIT_WIDTH : natural := 18; -- bit width of the 'value' field
    constant FSM_SETUP_TIMER_VALUE_RESET : std_logic_vector(17 downto 0) := std_logic_vector'("000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'fsm_tx_timer'
    constant FSM_TX_TIMER_OFFSET : unsigned(31 downto 0) := unsigned'(x"0000002C"); -- address offset of the 'fsm_tx_timer' register
    -- Field 'fsm_tx_timer.value'
    constant FSM_TX_TIMER_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant FSM_TX_TIMER_VALUE_BIT_WIDTH : natural := 18; -- bit width of the 'value' field
    constant FSM_TX_TIMER_VALUE_RESET : std_logic_vector(17 downto 0) := std_logic_vector'("000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'fsm_deadzone_timer'
    constant FSM_DEADZONE_TIMER_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000030"); -- address offset of the 'fsm_deadzone_timer' register
    -- Field 'fsm_deadzone_timer.value'
    constant FSM_DEADZONE_TIMER_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant FSM_DEADZONE_TIMER_VALUE_BIT_WIDTH : natural := 18; -- bit width of the 'value' field
    constant FSM_DEADZONE_TIMER_VALUE_RESET : std_logic_vector(17 downto 0) := std_logic_vector'("000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'fsm_rx_timer'
    constant FSM_RX_TIMER_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000034"); -- address offset of the 'fsm_rx_timer' register
    -- Field 'fsm_rx_timer.value'
    constant FSM_RX_TIMER_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant FSM_RX_TIMER_VALUE_BIT_WIDTH : natural := 18; -- bit width of the 'value' field
    constant FSM_RX_TIMER_VALUE_RESET : std_logic_vector(17 downto 0) := std_logic_vector'("000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'fsm_idle_timer'
    constant FSM_IDLE_TIMER_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000038"); -- address offset of the 'fsm_idle_timer' register
    -- Field 'fsm_idle_timer.value'
    constant FSM_IDLE_TIMER_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant FSM_IDLE_TIMER_VALUE_BIT_WIDTH : natural := 18; -- bit width of the 'value' field
    constant FSM_IDLE_TIMER_VALUE_RESET : std_logic_vector(17 downto 0) := std_logic_vector'("000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'pulser_t1'
    constant PULSER_T1_OFFSET : unsigned(31 downto 0) := unsigned'(x"0000003C"); -- address offset of the 'pulser_t1' register
    -- Field 'pulser_t1.value'
    constant PULSER_T1_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant PULSER_T1_VALUE_BIT_WIDTH : natural := 10; -- bit width of the 'value' field
    constant PULSER_T1_VALUE_RESET : std_logic_vector(9 downto 0) := std_logic_vector'("0000000000"); -- reset value of the 'value' field
    
    -- Register 'pulser_t2'
    constant PULSER_T2_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000040"); -- address offset of the 'pulser_t2' register
    -- Field 'pulser_t2.value'
    constant PULSER_T2_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant PULSER_T2_VALUE_BIT_WIDTH : natural := 10; -- bit width of the 'value' field
    constant PULSER_T2_VALUE_RESET : std_logic_vector(9 downto 0) := std_logic_vector'("0000000000"); -- reset value of the 'value' field
    
    -- Register 'pulser_t3'
    constant PULSER_T3_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000044"); -- address offset of the 'pulser_t3' register
    -- Field 'pulser_t3.value'
    constant PULSER_T3_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant PULSER_T3_VALUE_BIT_WIDTH : natural := 10; -- bit width of the 'value' field
    constant PULSER_T3_VALUE_RESET : std_logic_vector(9 downto 0) := std_logic_vector'("0000000000"); -- reset value of the 'value' field
    
    -- Register 'pulser_t4'
    constant PULSER_T4_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000048"); -- address offset of the 'pulser_t4' register
    -- Field 'pulser_t4.value'
    constant PULSER_T4_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant PULSER_T4_VALUE_BIT_WIDTH : natural := 10; -- bit width of the 'value' field
    constant PULSER_T4_VALUE_RESET : std_logic_vector(9 downto 0) := std_logic_vector'("0000000000"); -- reset value of the 'value' field
    
    -- Register 'pulser_t5'
    constant PULSER_T5_OFFSET : unsigned(31 downto 0) := unsigned'(x"0000004C"); -- address offset of the 'pulser_t5' register
    -- Field 'pulser_t5.value'
    constant PULSER_T5_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant PULSER_T5_VALUE_BIT_WIDTH : natural := 10; -- bit width of the 'value' field
    constant PULSER_T5_VALUE_RESET : std_logic_vector(9 downto 0) := std_logic_vector'("0000000000"); -- reset value of the 'value' field
    
    -- Register 'pulser_config'
    constant PULSER_CONFIG_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000050"); -- address offset of the 'pulser_config' register
    -- Field 'pulser_config.invert'
    constant PULSER_CONFIG_INVERT_BIT_OFFSET : natural := 0; -- bit offset of the 'invert' field
    constant PULSER_CONFIG_INVERT_BIT_WIDTH : natural := 1; -- bit width of the 'invert' field
    constant PULSER_CONFIG_INVERT_RESET : std_logic_vector(0 downto 0) := std_logic_vector'("0"); -- reset value of the 'invert' field
    -- Field 'pulser_config.triple'
    constant PULSER_CONFIG_TRIPLE_BIT_OFFSET : natural := 1; -- bit offset of the 'triple' field
    constant PULSER_CONFIG_TRIPLE_BIT_WIDTH : natural := 1; -- bit width of the 'triple' field
    constant PULSER_CONFIG_TRIPLE_RESET : std_logic_vector(1 downto 1) := std_logic_vector'("0"); -- reset value of the 'triple' field
    
    -- Register 'dds_win_mode'
    constant DDS_WIN_MODE_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000054"); -- address offset of the 'dds_win_mode' register
    -- Field 'dds_win_mode.value'
    constant DDS_WIN_MODE_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant DDS_WIN_MODE_VALUE_BIT_WIDTH : natural := 3; -- bit width of the 'value' field
    constant DDS_WIN_MODE_VALUE_RESET : std_logic_vector(2 downto 0) := std_logic_vector'("000"); -- reset value of the 'value' field
    
    -- Register 'dds_win_phase_term'
    constant DDS_WIN_PHASE_TERM_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000058"); -- address offset of the 'dds_win_phase_term' register
    -- Field 'dds_win_phase_term.value'
    constant DDS_WIN_PHASE_TERM_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant DDS_WIN_PHASE_TERM_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant DDS_WIN_PHASE_TERM_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'dds_win_window_term'
    constant DDS_WIN_WINDOW_TERM_OFFSET : unsigned(31 downto 0) := unsigned'(x"0000005C"); -- address offset of the 'dds_win_window_term' register
    -- Field 'dds_win_window_term.value'
    constant DDS_WIN_WINDOW_TERM_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant DDS_WIN_WINDOW_TERM_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant DDS_WIN_WINDOW_TERM_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'dds_win_init_phase'
    constant DDS_WIN_INIT_PHASE_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000060"); -- address offset of the 'dds_win_init_phase' register
    -- Field 'dds_win_init_phase.value'
    constant DDS_WIN_INIT_PHASE_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant DDS_WIN_INIT_PHASE_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant DDS_WIN_INIT_PHASE_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'dds_win_nb_points'
    constant DDS_WIN_NB_POINTS_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000064"); -- address offset of the 'dds_win_nb_points' register
    -- Field 'dds_win_nb_points.value'
    constant DDS_WIN_NB_POINTS_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant DDS_WIN_NB_POINTS_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant DDS_WIN_NB_POINTS_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'dds_win_mode_time'
    constant DDS_WIN_MODE_TIME_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000068"); -- address offset of the 'dds_win_mode_time' register
    -- Field 'dds_win_mode_time.time'
    constant DDS_WIN_MODE_TIME_TIME_BIT_OFFSET : natural := 0; -- bit offset of the 'time' field
    constant DDS_WIN_MODE_TIME_TIME_BIT_WIDTH : natural := 1; -- bit width of the 'time' field
    constant DDS_WIN_MODE_TIME_TIME_RESET : std_logic_vector(0 downto 0) := std_logic_vector'("0"); -- reset value of the 'time' field

end register_bank_win_regs_pkg;

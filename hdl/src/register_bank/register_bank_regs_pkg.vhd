-- -----------------------------------------------------------------------------
-- 'pig_register_bank' Register Definitions
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

package register_bank_regs_pkg is

    -- Type definitions
    -- type slv1_array_t is array(natural range <>) of std_logic_vector(0 downto 0);
    -- type slv2_array_t is array(natural range <>) of std_logic_vector(1 downto 0);
    -- type slv3_array_t is array(natural range <>) of std_logic_vector(2 downto 0);
    -- type slv4_array_t is array(natural range <>) of std_logic_vector(3 downto 0);
    -- type slv5_array_t is array(natural range <>) of std_logic_vector(4 downto 0);
    -- type slv6_array_t is array(natural range <>) of std_logic_vector(5 downto 0);
    -- type slv7_array_t is array(natural range <>) of std_logic_vector(6 downto 0);
    -- type slv8_array_t is array(natural range <>) of std_logic_vector(7 downto 0);
    -- type slv9_array_t is array(natural range <>) of std_logic_vector(8 downto 0);
    -- type slv10_array_t is array(natural range <>) of std_logic_vector(9 downto 0);
    -- type slv11_array_t is array(natural range <>) of std_logic_vector(10 downto 0);
    -- type slv12_array_t is array(natural range <>) of std_logic_vector(11 downto 0);
    -- type slv13_array_t is array(natural range <>) of std_logic_vector(12 downto 0);
    -- type slv14_array_t is array(natural range <>) of std_logic_vector(13 downto 0);
    -- type slv15_array_t is array(natural range <>) of std_logic_vector(14 downto 0);
    -- type slv16_array_t is array(natural range <>) of std_logic_vector(15 downto 0);
    -- type slv17_array_t is array(natural range <>) of std_logic_vector(16 downto 0);
    -- type slv18_array_t is array(natural range <>) of std_logic_vector(17 downto 0);
    -- type slv19_array_t is array(natural range <>) of std_logic_vector(18 downto 0);
    -- type slv20_array_t is array(natural range <>) of std_logic_vector(19 downto 0);
    -- type slv21_array_t is array(natural range <>) of std_logic_vector(20 downto 0);
    -- type slv22_array_t is array(natural range <>) of std_logic_vector(21 downto 0);
    -- type slv23_array_t is array(natural range <>) of std_logic_vector(22 downto 0);
    -- type slv24_array_t is array(natural range <>) of std_logic_vector(23 downto 0);
    -- type slv25_array_t is array(natural range <>) of std_logic_vector(24 downto 0);
    -- type slv26_array_t is array(natural range <>) of std_logic_vector(25 downto 0);
    -- type slv27_array_t is array(natural range <>) of std_logic_vector(26 downto 0);
    -- type slv28_array_t is array(natural range <>) of std_logic_vector(27 downto 0);
    -- type slv29_array_t is array(natural range <>) of std_logic_vector(28 downto 0);
    -- type slv30_array_t is array(natural range <>) of std_logic_vector(29 downto 0);
    -- type slv31_array_t is array(natural range <>) of std_logic_vector(30 downto 0);
    -- type slv32_array_t is array(natural range <>) of std_logic_vector(31 downto 0);


    -- Revision number of the 'pig_register_bank' register map
    constant PIG_REGISTER_BANK_REVISION : natural := 70;

    -- Default base address of the 'pig_register_bank' register map 
    constant PIG_REGISTER_BANK_DEFAULT_BASEADDR : unsigned(31 downto 0) := unsigned'(x"00000000");
    
    -- Register 'version'
    constant VERSION_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000000"); -- address offset of the 'version' register
    -- Field 'version.version'
    constant VERSION_VERSION_BIT_OFFSET : natural := 0; -- bit offset of the 'version' field
    constant VERSION_VERSION_BIT_WIDTH : natural := 8; -- bit width of the 'version' field
    constant VERSION_VERSION_RESET : std_logic_vector(7 downto 0) := std_logic_vector'("00000000"); -- reset value of the 'version' field
    
    -- Register 'bang'
    constant BANG_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000004"); -- address offset of the 'bang' register
    -- Field 'bang.bang'
    constant BANG_BANG_BIT_OFFSET : natural := 0; -- bit offset of the 'bang' field
    constant BANG_BANG_BIT_WIDTH : natural := 1; -- bit width of the 'bang' field
    constant BANG_BANG_RESET : std_logic_vector(0 downto 0) := std_logic_vector'("0"); -- reset value of the 'bang' field
    
    -- Register 'sample_frequency'
    constant SAMPLE_FREQUENCY_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000020"); -- address offset of the 'sample_frequency' register
    -- Field 'sample_frequency.sample_frequency'
    constant SAMPLE_FREQUENCY_SAMPLE_FREQUENCY_BIT_OFFSET : natural := 0; -- bit offset of the 'sample_frequency' field
    constant SAMPLE_FREQUENCY_SAMPLE_FREQUENCY_BIT_WIDTH : natural := 27; -- bit width of the 'sample_frequency' field
    constant SAMPLE_FREQUENCY_SAMPLE_FREQUENCY_RESET : std_logic_vector(26 downto 0) := std_logic_vector'("101111101011110000100000000"); -- reset value of the 'sample_frequency' field
    
    -- Register 'target_frequency'
    constant TARGET_FREQUENCY_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000024"); -- address offset of the 'target_frequency' register
    -- Field 'target_frequency.target_frequency'
    constant TARGET_FREQUENCY_TARGET_FREQUENCY_BIT_OFFSET : natural := 0; -- bit offset of the 'target_frequency' field
    constant TARGET_FREQUENCY_TARGET_FREQUENCY_BIT_WIDTH : natural := 32; -- bit width of the 'target_frequency' field
    constant TARGET_FREQUENCY_TARGET_FREQUENCY_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000001111010000100100000"); -- reset value of the 'target_frequency' field
    
    -- Register 'phase_term'
    constant PHASE_TERM_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000028"); -- address offset of the 'phase_term' register
    -- Field 'phase_term.phase_term'
    constant PHASE_TERM_PHASE_TERM_BIT_OFFSET : natural := 0; -- bit offset of the 'phase_term' field
    constant PHASE_TERM_PHASE_TERM_BIT_WIDTH : natural := 32; -- bit width of the 'phase_term' field
    constant PHASE_TERM_PHASE_TERM_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00001000000010101101111111001001"); -- reset value of the 'phase_term' field
    
    -- Register 'init_phase'
    constant INIT_PHASE_OFFSET : unsigned(31 downto 0) := unsigned'(x"0000002C"); -- address offset of the 'init_phase' register
    -- Field 'init_phase.init_phase'
    constant INIT_PHASE_INIT_PHASE_BIT_OFFSET : natural := 0; -- bit offset of the 'init_phase' field
    constant INIT_PHASE_INIT_PHASE_BIT_WIDTH : natural := 32; -- bit width of the 'init_phase' field
    constant INIT_PHASE_INIT_PHASE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'init_phase' field
    
    -- Register 'numbers'
    constant NUMBERS_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000030"); -- address offset of the 'numbers' register
    -- Field 'numbers.nb_points'
    constant NUMBERS_NB_POINTS_BIT_OFFSET : natural := 0; -- bit offset of the 'nb_points' field
    constant NUMBERS_NB_POINTS_BIT_WIDTH : natural := 10; -- bit width of the 'nb_points' field
    constant NUMBERS_NB_POINTS_RESET : std_logic_vector(9 downto 0) := std_logic_vector'("0011001000"); -- reset value of the 'nb_points' field
    -- Field 'numbers.nb_repetitions'
    constant NUMBERS_NB_REPETITIONS_BIT_OFFSET : natural := 10; -- bit offset of the 'nb_repetitions' field
    constant NUMBERS_NB_REPETITIONS_BIT_WIDTH : natural := 10; -- bit width of the 'nb_repetitions' field
    constant NUMBERS_NB_REPETITIONS_RESET : std_logic_vector(19 downto 10) := std_logic_vector'("0000000001"); -- reset value of the 'nb_repetitions' field
    
    -- Register 'win_phase_term'
    constant WIN_PHASE_TERM_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000034"); -- address offset of the 'win_phase_term' register
    -- Field 'win_phase_term.win_phase_term'
    constant WIN_PHASE_TERM_WIN_PHASE_TERM_BIT_OFFSET : natural := 0; -- bit offset of the 'win_phase_term' field
    constant WIN_PHASE_TERM_WIN_PHASE_TERM_BIT_WIDTH : natural := 32; -- bit width of the 'win_phase_term' field
    constant WIN_PHASE_TERM_WIN_PHASE_TERM_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'win_phase_term' field
    
    -- Register 'config_mode'
    constant CONFIG_MODE_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000038"); -- address offset of the 'config_mode' register
    -- Field 'config_mode.dds_type'
    constant CONFIG_MODE_DDS_TYPE_BIT_OFFSET : natural := 0; -- bit offset of the 'dds_type' field
    constant CONFIG_MODE_DDS_TYPE_BIT_WIDTH : natural := 4; -- bit width of the 'dds_type' field
    constant CONFIG_MODE_DDS_TYPE_RESET : std_logic_vector(3 downto 0) := std_logic_vector'("0000"); -- reset value of the 'dds_type' field
    -- Field 'config_mode.mode_time'
    constant CONFIG_MODE_MODE_TIME_BIT_OFFSET : natural := 4; -- bit offset of the 'mode_time' field
    constant CONFIG_MODE_MODE_TIME_BIT_WIDTH : natural := 1; -- bit width of the 'mode_time' field
    constant CONFIG_MODE_MODE_TIME_RESET : std_logic_vector(4 downto 4) := std_logic_vector'("0"); -- reset value of the 'mode_time' field
    -- Field 'config_mode.win_type'
    constant CONFIG_MODE_WIN_TYPE_BIT_OFFSET : natural := 5; -- bit offset of the 'win_type' field
    constant CONFIG_MODE_WIN_TYPE_BIT_WIDTH : natural := 4; -- bit width of the 'win_type' field
    constant CONFIG_MODE_WIN_TYPE_RESET : std_logic_vector(8 downto 5) := std_logic_vector'("0000"); -- reset value of the 'win_type' field
    
    -- Register 'tx_timer'
    constant TX_TIMER_OFFSET : unsigned(31 downto 0) := unsigned'(x"0000003C"); -- address offset of the 'tx_timer' register
    -- Field 'tx_timer.tx_timer'
    constant TX_TIMER_TX_TIMER_BIT_OFFSET : natural := 0; -- bit offset of the 'tx_timer' field
    constant TX_TIMER_TX_TIMER_BIT_WIDTH : natural := 18; -- bit width of the 'tx_timer' field
    constant TX_TIMER_TX_TIMER_RESET : std_logic_vector(17 downto 0) := std_logic_vector'("000000000000000000"); -- reset value of the 'tx_timer' field
    
    -- Register 'off_timer'
    constant OFF_TIMER_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000040"); -- address offset of the 'off_timer' register
    -- Field 'off_timer.timer'
    constant OFF_TIMER_TIMER_BIT_OFFSET : natural := 0; -- bit offset of the 'timer' field
    constant OFF_TIMER_TIMER_BIT_WIDTH : natural := 18; -- bit width of the 'timer' field
    constant OFF_TIMER_TIMER_RESET : std_logic_vector(17 downto 0) := std_logic_vector'("000000000000000000"); -- reset value of the 'timer' field
    
    -- Register 'rx_timer'
    constant RX_TIMER_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000044"); -- address offset of the 'rx_timer' register
    -- Field 'rx_timer.timer'
    constant RX_TIMER_TIMER_BIT_OFFSET : natural := 0; -- bit offset of the 'timer' field
    constant RX_TIMER_TIMER_BIT_WIDTH : natural := 18; -- bit width of the 'timer' field
    constant RX_TIMER_TIMER_RESET : std_logic_vector(17 downto 0) := std_logic_vector'("000000000000000000"); -- reset value of the 'timer' field
    
    -- Register 'deadzone_timer'
    constant DEADZONE_TIMER_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000048"); -- address offset of the 'deadzone_timer' register
    -- Field 'deadzone_timer.timer'
    constant DEADZONE_TIMER_TIMER_BIT_OFFSET : natural := 0; -- bit offset of the 'timer' field
    constant DEADZONE_TIMER_TIMER_BIT_WIDTH : natural := 18; -- bit width of the 'timer' field
    constant DEADZONE_TIMER_TIMER_RESET : std_logic_vector(17 downto 0) := std_logic_vector'("000000000000000000"); -- reset value of the 'timer' field

end register_bank_regs_pkg;

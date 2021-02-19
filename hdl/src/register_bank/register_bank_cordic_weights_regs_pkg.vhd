-- -----------------------------------------------------------------------------
-- 'register_bank_cordic_weights' Register Definitions
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package register_bank_cordic_weights_regs_pkg is

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


    -- Revision number of the 'register_bank_cordic_weights' register map
    constant REGISTER_BANK_CORDIC_WEIGHTS_REVISION : natural := 40;

    -- Default base address of the 'register_bank_cordic_weights' register map 
    constant REGISTER_BANK_CORDIC_WEIGHTS_DEFAULT_BASEADDR : unsigned(31 downto 0) := unsigned'(x"00000000");
    
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
    
    -- Register 'conv_rate'
    constant CONV_RATE_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000014"); -- address offset of the 'conv_rate' register
    -- Field 'conv_rate.value'
    constant CONV_RATE_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant CONV_RATE_VALUE_BIT_WIDTH : natural := 7; -- bit width of the 'value' field
    constant CONV_RATE_VALUE_RESET : std_logic_vector(6 downto 0) := std_logic_vector'("0000000"); -- reset value of the 'value' field
    
    -- Register 'weights'
    constant WEIGHTS_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000018"); -- address offset of the 'weights' register
    constant WEIGHTS_ARRAY_LENGTH : natural := 10; -- length of the 'weights' register array, in elements
    -- Field 'weights.value'
    constant WEIGHTS_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant WEIGHTS_VALUE_BIT_WIDTH : natural := 16; -- bit width of the 'value' field
    constant WEIGHTS_VALUE_RESET : std_logic_vector(15 downto 0) := std_logic_vector'("0000000000000000"); -- reset value of the 'value' field
    
    -- Register 'dds_phase_term'
    constant DDS_PHASE_TERM_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000040"); -- address offset of the 'dds_phase_term' register
    -- Field 'dds_phase_term.value'
    constant DDS_PHASE_TERM_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant DDS_PHASE_TERM_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant DDS_PHASE_TERM_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'dds_nb_points'
    constant DDS_NB_POINTS_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000044"); -- address offset of the 'dds_nb_points' register
    -- Field 'dds_nb_points.value'
    constant DDS_NB_POINTS_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant DDS_NB_POINTS_VALUE_BIT_WIDTH : natural := 18; -- bit width of the 'value' field
    constant DDS_NB_POINTS_VALUE_RESET : std_logic_vector(17 downto 0) := std_logic_vector'("000000000000000000"); -- reset value of the 'value' field
    
    -- Register 'dds_nb_periods'
    constant DDS_NB_PERIODS_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000048"); -- address offset of the 'dds_nb_periods' register
    -- Field 'dds_nb_periods.value'
    constant DDS_NB_PERIODS_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant DDS_NB_PERIODS_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant DDS_NB_PERIODS_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'value' field

end register_bank_cordic_weights_regs_pkg;


#####################################
##  Compile ieee_proposed library  ##
#####################################

vlib ieee_proposed.lib
vmap ieee_proposedx ieee_proposed.lib

## Sources 
# Supression of warning 1246 "Range 0 downto 1 ..."

vcom -work ieee_proposed ../hdl/pkg/ieee_proposed/standard_additions_c.vhdl
vcom -work ieee_proposed ../hdl/pkg/ieee_proposed/standard_textio_additions_c.vhdl
vcom -work ieee_proposed ../hdl/pkg/ieee_proposed/env_c.vhdl
vcom -work ieee_proposed ../hdl/pkg/ieee_proposed/std_logic_1164_additions.vhdl
vcom -work ieee_proposed ../hdl/pkg/ieee_proposed/numeric_std_additions.vhdl
vcom -work ieee_proposed ../hdl/pkg/ieee_proposed/numeric_std_unsigned_c.vhdl
vcom -work ieee_proposed ../hdl/pkg/ieee_proposed/fixed_float_types_c.vhdl
vcom -work -suppress 1246 ieee_proposed ../hdl/pkg/ieee_proposed/fixed_pkg_c.vhdl 
vcom -work -suppress 1246 ieee_proposed ../hdl/pkg/ieee_proposed/float_pkg_c.vhdl
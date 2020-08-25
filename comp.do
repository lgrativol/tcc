###############################
###  Compile project files  ###
###############################

## Compile work lib

if {[file isdirectory work]} { vdel -all -lib work }

vlib work
vmap work work

########################
##  Compile packages  ##
########################

vcom -93 ../hdl/pkg/utils_pkg.vhd


############################
##  Compile source files  ##
############################
## Checking for vhdl-93 rules and synthesable code

vcom -93 -check_synthesis -novopt -O0 ../hdl/src/cordic_slice.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/cordic_core.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/phase_acc_v2.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/preproc.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/posproc.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_cordic.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/fsm_time_zones.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/double_driver.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/cordic_slice_recp.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/cordic_core_recp.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/reciprocal_xy.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/generic_shift_reg.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/phase_adjust.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/hh_win.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/blackman_win.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/blackman_harris_win.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_cordic_win.vhd


################################
##  Compile simulation files  ##
################################
## Checking for vhdl-93 rules

vcom -93  -novopt -O0 ../hdl/sim/sim_input_pkg.vhd
vcom -93  -novopt -O0 ../hdl/sim/sim_write2file.vhd
vcom -93  -novopt -O0 ../hdl/sim/cordic_tb.vhd
vcom -93  -novopt -O0 ../hdl/sim/dds_cordic_tb.vhd
vcom -93  -novopt -O0 ../hdl/sim/fsm_time_zones_tb.vhd
vcom  -novopt -O0 ../hdl/sim/double_driver_tb.vhd
vcom -93  -novopt -O0 ../hdl/sim/reciprocal_xy_tb.vhd
vcom -93  -novopt -O0 ../hdl/sim/phase_adjust_tb.vhd
##vcom -93  -novopt -O0 ../hdl/sim/dds_cordic_win_tb.vhd
##vcom -93  -novopt -O0 ../hdl/sim/hh_win_tb.vhd


############
## Unused ##
############

##vcom -93 -check_synthesis -novopt -O0 ../hdl/src/phase_acc.vhd
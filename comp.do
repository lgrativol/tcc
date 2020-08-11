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

vcom -93 -check_synthesis -novopt -O0 ../hdl/src/cordic_core.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/cordic_slice.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/phase_acc.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/preproc.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_cordic.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/fsm_time_zones.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/top_dds_cordic.vhd

################################
##  Compile simulation files  ##
################################
## Checking for vhdl-93 rules

vcom -93  -novopt -O0 ../hdl/sim/sim_input_pkg.vhd
vcom -93  -novopt -O0 ../hdl/sim/sim_write2file.vhd
vcom -93  -novopt -O0 ../hdl/sim/cordic_tb.vhd
vcom -93  -novopt -O0 ../hdl/sim/top_dds_cordic_tb.vhd
vcom -93  -novopt -O0 ../hdl/sim/fsm_time_zones_tb.vhd
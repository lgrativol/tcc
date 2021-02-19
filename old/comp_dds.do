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

## CORDIC 
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/cordic/cordic_slice.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/cordic/cordic_core.vhd

## DDS CORDIC
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_cordic/phase_acc_v2.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_cordic/preproc.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_cordic/posproc.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_cordic/dds_cordic.vhd

################################
##  Compile simulation files  ##
################################
## Checking for vhdl-93 rules

vcom -93  -novopt -O0 ../hdl/sim/sim_input_pkg.vhd

## Testbench tools
vcom -93  -novopt -O0 ../hdl/sim/testbench_tools/sim_write2file.vhd

## DDS cordic
vcom -93  -novopt -O0 ../hdl/sim/dds_cordic/dds_cordic_tb.vhd
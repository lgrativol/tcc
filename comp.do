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

## FSM Control
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/fsm_control/fsm_time_zones.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/fsm_control/fsm_time_zones_v2.vhd

## Double Driver
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/double_driver/double_driver.vhd

## Reciprocal
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/reciprocal/cordic_slice_recp.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/reciprocal/cordic_core_recp.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/reciprocal/reciprocal_xy.vhd

## Generic Shift-reg
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/generic_shift_reg/generic_shift_reg.vhd

## Windows (+ DDS Windows)
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_windows/phase_adjust.vhd
##vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_windows/hanning_hamming/hh_win.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_windows/hanning_hamming/hh_win_v2.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_windows/blackman/blackman_win.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_windows/blackman_harris/blackman_harris_win.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_windows/tukey/tukey_phase_acc.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_windows/tukey/tukey_win.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/dds_windows/dds_cordic_win.vhd

## Pulser
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/pulser/pulser.vhd

## Averager
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/averager/ring_fifo.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/averager/averager.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/averager/averager_v2.vhd

## Register Bank
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/register_bank/register_bank_regs_pkg.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/register_bank/register_bank_regs.vhd

## Wave Generator
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/wave_generator/wave_generator.vhd

## TOP
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/top/top_tx.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/top/top_rx.vhd
vcom -93 -check_synthesis -novopt -O0 ../hdl/src/top/top.vhd


################################
##  Compile simulation files  ##
################################
## Checking for vhdl-93 rules

vcom -93  -novopt -O0 ../hdl/sim/sim_input_pkg.vhd

## Testbench tools
vcom -93  -novopt -O0 ../hdl/sim/testbench_tools/sim_write2file.vhd

## cordic
vcom -93  -novopt -O0 ../hdl/sim/cordic/cordic_tb.vhd

## DDS cordic
vcom -93  -novopt -O0 ../hdl/sim/dds_cordic/dds_cordic_tb.vhd

## FSM Control
vcom -93  -novopt -O0 ../hdl/sim/fsm_control/fsm_time_zones_tb.vhd

## Double Driver
vcom  -novopt -O0 ../hdl/sim/double_driver/double_driver_tb.vhd

## Reciprocal
vcom -93  -novopt -O0 ../hdl/sim/reciprocal/reciprocal_xy_tb.vhd

## DDS Win
vcom -93  -novopt -O0 ../hdl/sim/dds_win/dds_cordic_win_tb.vhd

## Pulser
vcom -93  -novopt -O0 ../hdl/sim/pulser/pulser_tb.vhd

## Averager
vcom -93 -novopt -O0 ../hdl/sim/averager/ring_fifo_tb.vhd
vcom -93 -novopt -O0 ../hdl/sim/averager/averager_tb.vhd
vcom -93 -novopt -O0 ../hdl/sim/averager/averager_v2_tb.vhd

## TOP
vcom -93 -novopt -O0 ../hdl/sim/top/top_tx_tb.vhd
vcom -93 -novopt -O0 ../hdl/sim/top/top_tb.vhd

## Misc
##vcom -93  -novopt -O0 ../hdl/sim/misc/phase_adjust_tb.vhd
##vcom -93  -novopt -O0 ../hdl/sim/misc/hh_win_tb.vhd
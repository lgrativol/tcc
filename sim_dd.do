vsim work.double_driver_tb

add wave -divider Clock
add wave sim:/double_driver_tb/UUT/clock_i 
add wave sim:/double_driver_tb/UUT/areset_i

add wave -divider FsmTimeZones

add wave sim:/double_driver_tb/UUT/strb_i 
add wave -radix ufixed sim:/double_driver_tb/UUT/phase_term_i 
add wave -radix ufixed sim:/double_driver_tb/UUT/initial_phase_i 
add wave -radix unsigned sim:/double_driver_tb/UUT/nb_points_i 
add wave -radix unsigned sim:/double_driver_tb/UUT/nb_repetitions_i

add wave -divider Zones

add wave -radix unsigned sim:/double_driver_tb/UUT/tx_time_i 
add wave -radix unsigned sim:/double_driver_tb/UUT/tx_off_time_i 
add wave -radix unsigned sim:/double_driver_tb/UUT/rx_time_i 
add wave -radix unsigned sim:/double_driver_tb/UUT/off_time_i 

add wave -divider

add wave sim:/double_driver_tb/UUT/stage_1_control/time_state

add wave -divider DriverA
add wave sim:/double_driver_tb/UUT/A_strb_o 
add wave -radix sfixed sim:/double_driver_tb/UUT/A_sine_phase_o 
add wave sim:/double_driver_tb/UUT/A_done_cycles_o 
add wave sim:/double_driver_tb/UUT/A_flag_full_cycle_o 

add wave -divider DriverB
add wave sim:/double_driver_tb/UUT/B_strb_o 
add wave -radix sfixed sim:/double_driver_tb/UUT/B_sine_phase_o 
add wave sim:/double_driver_tb/UUT/B_done_cycles_o
add wave sim:/double_driver_tb/UUT/B_flag_full_cycle_o 

add wave -divider

add wave sim:/double_driver_tb/UUT/end_zones_cycle_o
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider

restart -f 
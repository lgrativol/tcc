vsim work.dds_cordic_win_tb

add wave -divider Clock
add wave sim:/dds_cordic_win_tb/UUT/clock_i
add wave sim:/dds_cordic_win_tb/UUT/areset_i
add wave -divider DDS
add wave sim:/dds_cordic_win_tb/UUT/dds_cordic_strb_i 
add wave -radix ufixed sim:/dds_cordic_win_tb/UUT/dds_cordic_phase_term 
add wave -radix unsigned sim:/dds_cordic_win_tb/UUT/dds_cordic_nb_points 
add wave -radix unsigned sim:/dds_cordic_win_tb/UUT/dds_cordic_nb_repetitions 
add wave -radix ufixed sim:/dds_cordic_win_tb/UUT/dds_cordic_initial_phase 
add wave sim:/dds_cordic_win_tb/UUT/dds_cordic_restart_cycles 
add wave -divider
add wave sim:/dds_cordic_win_tb/UUT/dds_cordic_strb_o 
add wave -radix sfixed sim:/dds_cordic_win_tb/UUT/dds_cordic_sine_phase
add wave -divider Window
add wave sim:/dds_cordic_win_tb/UUT/win_strb_i 
add wave -radix ufixed sim:/dds_cordic_win_tb/UUT/win_window_term 
add wave -radix unsigned sim:/dds_cordic_win_tb/UUT/win_nb_points 
add wave sim:/dds_cordic_win_tb/UUT/win_restart_cycles 
add wave -divider
add wave sim:/dds_cordic_win_tb/UUT/win_strb_o 
add wave -radix sfixed sim:/dds_cordic_win_tb/UUT/win_result
add wave -divider DDS_Shift
add wave -radix decimal sim:/dds_cordic_win_tb/UUT/WIN_TO_DDS_LATENCY 
add wave sim:/dds_cordic_win_tb/UUT/dds_generic_shift_strb_i 
add wave sim:/dds_cordic_win_tb/UUT/dds_generic_shift_input_data 
add wave -divider
add wave sim:/dds_cordic_win_tb/UUT/dds_generic_shift_strb_o 
add wave sim:/dds_cordic_win_tb/UUT/dds_generic_shift_output_data
add wave -divider WIN_Shift
add wave -radix decimal sim:/dds_cordic_win_tb/UUT/DDS_TO_WIN_LATENCY
add wave sim:/dds_cordic_win_tb/UUT/win_generic_shift_strb_i 
add wave sim:/dds_cordic_win_tb/UUT/win_generic_shift_input_data 
add wave -divider
add wave sim:/dds_cordic_win_tb/UUT/win_generic_shift_strb_o 
add wave sim:/dds_cordic_win_tb/UUT/win_generic_shift_output_data
add wave -divider Result
add wave sim:/dds_cordic_win_tb/UUT/stage_4_strb_i 
add wave -radix sfixed sim:/dds_cordic_win_tb/UUT/stage_4_sine_phase 
add wave -radix sfixed sim:/dds_cordic_win_tb/UUT/stage_4_win_result 
add wave -divider
add wave sim:/dds_cordic_win_tb/UUT/stage_4_strb_reg 
add wave -radix sfixed sim:/dds_cordic_win_tb/UUT/stage_4_result
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider

restart -f 
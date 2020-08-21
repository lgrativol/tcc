vsim work.dds_cordic_tb

add wave -divider Clock
add wave sim:/dds_cordic_tb/UUT/clock_i 
add wave sim:/dds_cordic_tb/UUT/areset_i

add wave -divider PhaseAcc
add wave sim:/dds_cordic_tb/UUT/phase_acc_strb_i
add wave -radix ufixed sim:/dds_cordic_tb/UUT/phase_acc_phase_term
add wave -radix ufixed sim:/dds_cordic_tb/UUT/phase_acc_initial_phase
add wave -radix unsigned sim:/dds_cordic_tb/UUT/phase_acc_nb_points
add wave -radix unsigned sim:/dds_cordic_tb/UUT/phase_acc_nb_repetitions
add wave sim:/dds_cordic_tb/UUT/phase_acc_restart_cycles
add wave -divider
add wave sim:/dds_cordic_tb/UUT/phase_acc_strb_o
add wave -radix ufixed sim:/dds_cordic_tb/UUT/phase_acc_phase

add wave -divider Preproc
add wave sim:/dds_cordic_tb/UUT/preproc_strb_i
add wave sim:/dds_cordic_tb/UUT/preproc_phase
add wave -divider
add wave sim:/dds_cordic_tb/UUT/preproc_phase_info
add wave sim:/dds_cordic_tb/UUT/preproc_strb_o
add wave -radix sfixed sim:/dds_cordic_tb/UUT/preproc_reduced_phase

add wave -divider Cordic
add wave sim:/dds_cordic_tb/UUT/cordic_core_strb_i
add wave -radix sfixed sim:/dds_cordic_tb/UUT/cordic_core_x_i
add wave -radix sfixed sim:/dds_cordic_tb/UUT/cordic_core_y_i
add wave -radix sfixed sim:/dds_cordic_tb/UUT/cordic_core_z_i
add wave sim:/dds_cordic_tb/UUT/cordic_core_sideband_i
add wave -divider
add wave sim:/dds_cordic_tb/UUT/cordic_core_strb_o
add wave -radix sfixed sim:/dds_cordic_tb/UUT/cordic_core_x_o
add wave -radix sfixed sim:/dds_cordic_tb/UUT/cordic_core_y_o
add wave -radix sfixed sim:/dds_cordic_tb/UUT/cordic_core_z_o
add wave sim:/dds_cordic_tb/UUT/cordic_core_sideband_o

add wave -divider Posproc
add wave sim:/dds_cordic_tb/UUT/posproc_strb_i
add wave -radix sfixed sim:/dds_cordic_tb/UUT/posproc_sin_phase_i
add wave -radix sfixed sim:/dds_cordic_tb/UUT/posproc_cos_phase_i
add wave sim:/dds_cordic_tb/UUT/posproc_phase_info
add wave -divider
add wave sim:/dds_cordic_tb/UUT/posproc_strb_o
add wave -radix sfixed sim:/dds_cordic_tb/UUT/posproc_sin_phase_o
add wave -radix sfixed sim:/dds_cordic_tb/UUT/posproc_cos_phase_o
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider

restart -f 
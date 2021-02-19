onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/clock_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/areset_i
add wave -noupdate -divider <NULL>
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/valid_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/win_mode_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/phase_term_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/window_term_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/initial_phase_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/nb_points_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/nb_repetitions_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/mode_time_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/restart_cycles_i
add wave -noupdate -divider <NULL>
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/win_mode
add wave -noupdate -divider <NULL>
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/win_hh_blkm_blkh_valid_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/win_type
add wave -noupdate -divider <NULL>
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/dds_2pi_valid_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/dds_2pi_phase_term
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/dds_2pi_nb_repetitions
add wave -noupdate -divider <NULL>
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/stage_1_dds_2pi/valid_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/stage_1_dds_2pi/phase_term_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/stage_1_dds_2pi/initial_phase_i
add wave -noupdate -radix unsigned /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/stage_1_dds_2pi/nb_points_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/stage_1_dds_2pi/nb_repetitions_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/stage_1_dds_2pi/mode_time_i
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/stage_1_dds_2pi/valid_o
add wave -noupdate -divider <NULL>
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/valid_o
add wave -noupdate /top_win_tb/UUT/TX/wave_gen_inst/wave_window/stage_2_hh_blkm_blkh_win/win_result_o
add wave -noupdate -divider <NULL>
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 12} {3086 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 228
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {15750 ns}

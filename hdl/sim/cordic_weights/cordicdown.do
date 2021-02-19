onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cordic_down_weights_tb/UUT/wave_cordic/clock_i
add wave -noupdate /cordic_down_weights_tb/UUT/wave_cordic/areset_i
add wave -noupdate -divider <NULL>
add wave -noupdate /cordic_down_weights_tb/UUT/wave_cordic/valid_i
add wave -noupdate /cordic_down_weights_tb/UUT/wave_cordic/phase_term_i
add wave -noupdate /cordic_down_weights_tb/UUT/wave_cordic/nb_points_i
add wave -noupdate /cordic_down_weights_tb/UUT/wave_cordic/nb_repetitions_i
add wave -noupdate -divider <NULL>
add wave -noupdate /cordic_down_weights_tb/UUT/wave_cordic/valid_o
add wave -noupdate /cordic_down_weights_tb/UUT/wave_cordic/sine_phase_o
add wave -noupdate /cordic_down_weights_tb/UUT/wave_cordic/done_cycles_o
add wave -noupdate -divider <NULL>
add wave -noupdate /cordic_down_weights_tb/UUT/downsampler_inst/downsample_factor_valid_i
add wave -noupdate /cordic_down_weights_tb/UUT/downsampler_inst/downsample_factor_i
add wave -noupdate -divider <NULL>
add wave -noupdate /cordic_down_weights_tb/UUT/downsampler_inst/weights_valid_i
add wave -noupdate /cordic_down_weights_tb/UUT/downsampler_inst/weights_data_i
add wave -noupdate -divider <NULL>
add wave -noupdate /cordic_down_weights_tb/UUT/downsampler_inst/wave_valid_i
add wave -noupdate /cordic_down_weights_tb/UUT/downsampler_inst/wave_data_i
add wave -noupdate /cordic_down_weights_tb/UUT/downsampler_inst/wave_last_i
add wave -noupdate -divider <NULL>
add wave -noupdate /cordic_down_weights_tb/UUT/downsampler_inst/wave_valid_o
add wave -noupdate /cordic_down_weights_tb/UUT/downsampler_inst/wave_data_o
add wave -noupdate /cordic_down_weights_tb/UUT/downsampler_inst/wave_last_o
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {264 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ns} {1 us}
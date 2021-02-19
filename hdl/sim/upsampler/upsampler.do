onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/clock_i
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/areset_i
add wave -noupdate -divider <NULL>
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/upsample_factor_valid_i
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/upsample_factor_i
add wave -noupdate -divider <NULL>
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/weights_valid_i
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/weights_data_i
add wave -noupdate -divider <NULL>
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/wave_enable_o
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/wave_valid_i
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/wave_data_i
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/wave_last_i
add wave -noupdate -divider <NULL>
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/wave_valid_reg
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/wave_data_reg
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/wave_last_reg
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/valid_sample
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/counter_samples
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/counter_samples_zero
add wave -noupdate -divider <NULL>
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/wave_valid_o
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/wave_data_o
add wave -noupdate /upsampler_tb/UTT_UPSAMPLER/wave_last_o
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {185 ns} 0} {{Cursor 5} {1707 ns} 0}
quietly wave cursor active 2
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
WaveRestoreZoom {0 ns} {4200 ns}

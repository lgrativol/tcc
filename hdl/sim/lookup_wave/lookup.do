onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /lookup_wave_tb/UUT/clock_i
add wave -noupdate /lookup_wave_tb/UUT/areset_i
add wave -noupdate -divider <NULL>
add wave -noupdate /lookup_wave_tb/UUT/mem_write_addr_i
add wave -noupdate /lookup_wave_tb/UUT/mem_write_enable_i
add wave -noupdate /lookup_wave_tb/UUT/mem_write_data_i
add wave -noupdate -divider <NULL>
add wave -noupdate /lookup_wave_tb/UUT/memory_ent/ram_name
add wave -noupdate -divider <NULL>
add wave -noupdate /lookup_wave_tb/UUT/bang_i
add wave -noupdate -radix unsigned /lookup_wave_tb/UUT/nb_points_i
add wave -noupdate -radix unsigned /lookup_wave_tb/UUT/nb_repetitions_i
add wave -noupdate /lookup_wave_tb/UUT/restart_i
add wave -noupdate -divider <NULL>
add wave -noupdate /lookup_wave_tb/UUT/nb_points_reg
add wave -noupdate /lookup_wave_tb/UUT/nb_repetitions_reg
add wave -noupdate -divider <NULL>
add wave -noupdate /lookup_wave_tb/UUT/falling_restart
add wave -noupdate -divider <NULL>
add wave -noupdate /lookup_wave_tb/UUT/enable_wave
add wave -noupdate /lookup_wave_tb/UUT/enable_wave_reg
add wave -noupdate /lookup_wave_tb/UUT/start_new_cycle_trigger
add wave -noupdate /lookup_wave_tb/UUT/valid_output
add wave -noupdate /lookup_wave_tb/UUT/read_last_word
add wave -noupdate -divider <NULL>
add wave -noupdate /lookup_wave_tb/UUT/mem_read_addr
add wave -noupdate /lookup_wave_tb/UUT/mem_read_enable
add wave -noupdate /lookup_wave_tb/UUT/mem_read_data
add wave -noupdate -divider <NULL>
add wave -noupdate /lookup_wave_tb/UUT/enable_counters
add wave -noupdate /lookup_wave_tb/UUT/restart_counters
add wave -noupdate /lookup_wave_tb/UUT/counter_nb_points
add wave -noupdate /lookup_wave_tb/UUT/counter_nb_repetitions
add wave -noupdate /lookup_wave_tb/UUT/counter_nb_points_done
add wave -noupdate /lookup_wave_tb/UUT/counter_nb_repetitions_done
add wave -noupdate -divider <NULL>
add wave -noupdate /lookup_wave_tb/UUT/valid_o
add wave -noupdate /lookup_wave_tb/UUT/data_o
add wave -noupdate /lookup_wave_tb/UUT/last_word_o
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {1665 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 200
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
WaveRestoreZoom {0 ns} {2346 ns}

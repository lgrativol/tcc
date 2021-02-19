onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /averager_v2_tb/UUT/clock_i
add wave -noupdate /averager_v2_tb/UUT/areset_i
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/config_valid_i
add wave -noupdate /averager_v2_tb/UUT/config_max_addr_i
add wave -noupdate /averager_v2_tb/UUT/config_nb_repetitions_i
add wave -noupdate /averager_v2_tb/UUT/config_reset_pointers_i
add wave -noupdate /averager_v2_tb/UUT/config_nb_repetitions_reg
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/input_valid_reg
add wave -noupdate /averager_v2_tb/UUT/input_data_reg
add wave -noupdate /averager_v2_tb/UUT/input_last_word_reg
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/acc_point
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/acc_en
add wave -noupdate /averager_v2_tb/UUT/acc_en_reg
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/fifo_wr_input_valid
add wave -noupdate /averager_v2_tb/UUT/fifo_wr_data
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/fifo_rd_enable_from_input
add wave -noupdate /averager_v2_tb/UUT/fifo_rd_enable_from_output
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/fifo_rd_en
add wave -noupdate /averager_v2_tb/UUT/fifo_rd_data
add wave -noupdate /averager_v2_tb/UUT/fifo_output_valid
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/fifo_empty
add wave -noupdate /averager_v2_tb/UUT/fifo_full
add wave -noupdate -radix unsigned /averager_v2_tb/UUT/ring_fifo_ent/pointer_head
add wave -noupdate -radix unsigned /averager_v2_tb/UUT/ring_fifo_ent/pointer_tail
add wave -noupdate -radix unsigned /averager_v2_tb/UUT/ring_fifo_ent/fill_count
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/enable_counter
add wave -noupdate /averager_v2_tb/UUT/reset_counter_repetitions
add wave -noupdate /averager_v2_tb/UUT/counter_repetitions
add wave -noupdate /averager_v2_tb/UUT/counter_repetitions_done
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/nb_shifts
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/fifo_rd_en
add wave -noupdate /averager_v2_tb/UUT/fifo_output_valid
add wave -noupdate /averager_v2_tb/UUT/fifo_rd_data
add wave -noupdate /averager_v2_tb/UUT/enable_one_fifo
add wave -noupdate /averager_v2_tb/UUT/one_fifo_valid_reg
add wave -noupdate /averager_v2_tb/UUT/one_fifo_data
add wave -noupdate /averager_v2_tb/UUT/one_fifo_last
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/mux_valid
add wave -noupdate /averager_v2_tb/UUT/mux_data
add wave -noupdate /averager_v2_tb/UUT/mux_last
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/s_axis_st_tready_i
add wave -noupdate /averager_v2_tb/UUT/s_axis_st_tvalid_o
add wave -noupdate -radix hexadecimal /averager_v2_tb/UUT/s_axis_st_tdata_o
add wave -noupdate /averager_v2_tb/UUT/s_axis_st_tlast_o
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/UUT/ring_fifo_ent/ram
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/empty_ready_o
add wave -noupdate /averager_v2_tb/empty_data_valid_i
add wave -noupdate /averager_v2_tb/empty_data_i
add wave -noupdate /averager_v2_tb/empty_sideband_i
add wave -noupdate -divider <NULL>
add wave -noupdate /averager_v2_tb/empty_ready_i
add wave -noupdate /averager_v2_tb/empty_data_valid_o
add wave -noupdate /averager_v2_tb/empty_data_o
add wave -noupdate /averager_v2_tb/empty_sideband_o
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4205 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 202
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
WaveRestoreZoom {0 ns} {5250 ns}

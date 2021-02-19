onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb/UUT_TX/axi_aclk
add wave -noupdate /top_tb/UUT_TX/axi_aresetn
add wave -noupdate /top_tb/areset
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/UUT_TX/wave_strb_o
add wave -noupdate -radix unsigned /top_tb/UUT_TX/wave_data_o
add wave -noupdate /top_tb/UUT_TX/wave_done_o
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/UUT_TX/control_bang_o
add wave -noupdate /top_tb/UUT_TX/control_sample_frequency_strb_o
add wave -noupdate /top_tb/UUT_TX/control_sample_frequency_o
add wave -noupdate /top_tb/UUT_TX/control_start_rx_o
add wave -noupdate /top_tb/UUT_TX/control_reset_averager_o
add wave -noupdate /top_tb/UUT_TX/control_config_strb_o
add wave -noupdate /top_tb/UUT_TX/control_nb_points_wave_o
add wave -noupdate /top_tb/UUT_TX/control_nb_repetitions_wave_o
add wave -noupdate -divider <NULL>
add wave -noupdate -radix unsigned /top_tb/noise_data
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/gsr_strb_i
add wave -noupdate /top_tb/gsr_input_data
add wave -noupdate /top_tb/gsr_sideband_data_i
add wave -noupdate /top_tb/gsr_strb_o
add wave -noupdate /top_tb/gsr_output_data
add wave -noupdate /top_tb/gsr_sideband_data_o
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/rx_wave_strb_i
add wave -noupdate /top_tb/rx_wave_data_i
add wave -noupdate /top_tb/rx_wave_done_i
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/UUT_RX/averager/config_strb_i
add wave -noupdate -radix unsigned /top_tb/UUT_RX/averager/config_max_addr_i
add wave -noupdate /top_tb/UUT_RX/averager/config_nb_repetitions_i
add wave -noupdate /top_tb/UUT_RX/averager/config_reset_pointers_i
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/UUT_RX/averager/input_strb_i
add wave -noupdate /top_tb/UUT_RX/averager/input_data_i
add wave -noupdate /top_tb/UUT_RX/averager/input_last_word_i
add wave -noupdate /top_tb/UUT_RX/averager/config_reset_pointers_i
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/UUT_RX/averager/fifo_wr_data
add wave -noupdate /top_tb/UUT_RX/averager/fifo_rd_en
add wave -noupdate /top_tb/UUT_RX/averager/fifo_output_strb
add wave -noupdate /top_tb/UUT_RX/averager/fifo_rd_data
add wave -noupdate /top_tb/UUT_RX/averager/fifo_empty
add wave -noupdate /top_tb/UUT_RX/averager/fifo_full
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/UUT_RX/averager/output_strb_o
add wave -noupdate /top_tb/UUT_RX/averager/output_data_o
add wave -noupdate /top_tb/UUT_RX/averager/output_last_word_o
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {13053 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 276
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
WaveRestoreZoom {0 ns} {55387 ns}

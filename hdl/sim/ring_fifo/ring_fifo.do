onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ring_fifo_tb/UUT/clock_i
add wave -noupdate /ring_fifo_tb/UUT/areset_i
add wave -noupdate -divider <NULL>
add wave -noupdate /ring_fifo_tb/UUT/config_strb_i
add wave -noupdate -radix unsigned /ring_fifo_tb/UUT/config_max_addr_i
add wave -noupdate /ring_fifo_tb/UUT/config_reset_pointers_i
add wave -noupdate -divider <NULL>
add wave -noupdate /ring_fifo_tb/UUT/wr_strb_i
add wave -noupdate /ring_fifo_tb/UUT/wr_data_i
add wave -noupdate /ring_fifo_tb/UUT/pointer_head
add wave -noupdate /ring_fifo_tb/UUT/max_wr_reached
add wave -noupdate -divider <NULL>
add wave -noupdate -expand /ring_fifo_tb/UUT/ram
add wave -noupdate -divider <NULL>
add wave -noupdate /ring_fifo_tb/UUT/rd_valid
add wave -noupdate /ring_fifo_tb/UUT/config_max_addr_reg
add wave -noupdate /ring_fifo_tb/UUT/fill_count
add wave -noupdate -divider <NULL>
add wave -noupdate /ring_fifo_tb/UUT/rd_en_i
add wave -noupdate /ring_fifo_tb/UUT/rd_strb_o
add wave -noupdate /ring_fifo_tb/UUT/rd_data_o
add wave -noupdate /ring_fifo_tb/UUT/pointer_tail
add wave -noupdate /ring_fifo_tb/UUT/max_rd_reached
add wave -noupdate -divider <NULL>
add wave -noupdate /ring_fifo_tb/UUT/empty
add wave -noupdate /ring_fifo_tb/UUT/full
add wave -noupdate -divider <NULL>
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {245 ns} 0}
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
WaveRestoreZoom {0 ns} {420 ns}

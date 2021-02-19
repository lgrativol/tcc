onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/UUT/axi_aclk
add wave -noupdate /top_tb/UUT/axi_aresetn
add wave -noupdate -divider <NULL>
add wave -noupdate -divider {AXI WRITE ADDRESS}
add wave -noupdate /top_tb/UUT/s_axi_awready
add wave -noupdate /top_tb/UUT/s_axi_awvalid
add wave -noupdate /top_tb/UUT/s_axi_awaddr
add wave -noupdate -divider <NULL>
add wave -noupdate -divider {AXI WRITE DATA}
add wave -noupdate /top_tb/UUT/s_axi_wready
add wave -noupdate /top_tb/UUT/s_axi_wvalid
add wave -noupdate /top_tb/UUT/s_axi_wstrb
add wave -noupdate /top_tb/UUT/s_axi_wdata
add wave -noupdate -divider {FSM de Controle}
add wave -noupdate /top_tb/UUT/TX/fsm_zone_inst/time_state
add wave -noupdate -divider <NULL>
add wave -noupdate -divider {DDS CORDIC}
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/dds_phase_term_value_i
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/dds_init_phase_value_i
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/dds_nb_points_i
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/dds_nb_repetitions_i
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/dds_mode_time_i
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/wave_cordic/valid_o
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/wave_cordic/sine_phase_o
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/wave_cordic/done_cycles_o
add wave -noupdate -divider <NULL>
add wave -noupdate -divider Pulser
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/pulser_nb_repetitions
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/pulser_timer1
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/pulser_timer2
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/pulser_timer3
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/pulser_timer4
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/pulser_timer_damp
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/pulser_invert_pulser
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/pulser_triple_pulser
add wave -noupdate -divider <NULL>
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/wave_pulser/valid_o
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/wave_pulser/pulser_data_o
add wave -noupdate /top_tb/UUT/TX/wave_gen_inst/wave_pulser/pulser_done_o
add wave -noupdate -divider <NULL>
add wave -noupdate -divider TX
add wave -noupdate /top_tb/UUT/tx_wave_valid_o
add wave -noupdate /top_tb/UUT/tx_wave_data_o
add wave -noupdate /top_tb/UUT/tx_wave_done_o
add wave -noupdate -divider <NULL>
add wave -noupdate -divider RX
add wave -noupdate /top_tb/UUT/rx_wave_valid_i
add wave -noupdate /top_tb/UUT/rx_wave_data_i
add wave -noupdate -divider <NULL>
add wave -noupdate -divider {Bloco de mÃ©dias}
add wave -noupdate /top_tb/UUT/s_axis_s2mm_0_tready
add wave -noupdate /top_tb/UUT/s_axis_s2mm_0_tvalid
add wave -noupdate /top_tb/UUT/s_axis_s2mm_0_tdata
add wave -noupdate /top_tb/UUT/s_axis_s2mm_0_tkeep
add wave -noupdate /top_tb/UUT/s_axis_s2mm_0_tlast
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {155695 ns} 0} {{Cursor 2} {152035 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 192
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
WaveRestoreZoom {0 ns} {210 us}

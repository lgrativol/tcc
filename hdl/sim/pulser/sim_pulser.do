
add wave -noupdate /pulser_tb/UUT/clock_i
add wave -noupdate /pulser_tb/UUT/areset_i
add wave -noupdate -divider <NULL>
add wave -noupdate /pulser_tb/UUT/valid_i
add wave -noupdate -radix unsigned /pulser_tb/UUT/nb_repetitions_reg
add wave -noupdate -radix unsigned /pulser_tb/UUT/timer1_reg
add wave -noupdate -radix unsigned /pulser_tb/UUT/timer2_reg
add wave -noupdate -radix unsigned /pulser_tb/UUT/timer3_reg
add wave -noupdate -radix unsigned /pulser_tb/UUT/timer4_reg
add wave -noupdate -radix unsigned /pulser_tb/UUT/timer_damp_reg
add wave -noupdate /pulser_tb/UUT/invert_pulser_reg
add wave -noupdate /pulser_tb/UUT/triple_pulser_reg
add wave -noupdate -divider <NULL>
add wave -noupdate /pulser_tb/UUT/pulser_state
add wave -noupdate /pulser_tb/UUT/next_state
add wave -noupdate /pulser_tb/UUT/first_non_zero_state
add wave -noupdate /pulser_tb/UUT/all_zero_lock
add wave -noupdate /pulser_tb/UUT/enable_repetitions_counter
add wave -noupdate /pulser_tb/UUT/reset_repetitions_counter
add wave -noupdate -radix unsigned /pulser_tb/UUT/repetitions_counter
add wave -noupdate -divider <NULL>
add wave -noupdate /pulser_tb/UUT/pulser_valid
add wave -noupdate /pulser_tb/UUT/pulser_done
add wave -noupdate -radix sfixed /pulser_tb/UUT/pulser_data
add wave -noupdate -divider <NULL>
add wave -noupdate /pulser_tb/UUT/counter_timer1
add wave -noupdate /pulser_tb/UUT/timer1_done
add wave -noupdate /pulser_tb/UUT/timer1_zero
add wave -noupdate /pulser_tb/UUT/counter_timer2
add wave -noupdate /pulser_tb/UUT/timer2_done
add wave -noupdate /pulser_tb/UUT/timer2_zero
add wave -noupdate /pulser_tb/UUT/counter_timer3
add wave -noupdate /pulser_tb/UUT/timer3_done
add wave -noupdate /pulser_tb/UUT/timer3_zero
add wave -noupdate /pulser_tb/UUT/counter_timer4
add wave -noupdate /pulser_tb/UUT/timer4_done
add wave -noupdate /pulser_tb/UUT/timer4_zero
add wave -noupdate /pulser_tb/UUT/counter_timer_damp
add wave -noupdate /pulser_tb/UUT/timer_damp_done
add wave -noupdate /pulser_tb/UUT/timer_damp_zero
add wave -noupdate -divider <NULL>
add wave -noupdate /pulser_tb/UUT/valid_o
add wave -noupdate /pulser_tb/UUT/pulser_done_o
add wave -noupdate -radix decimal /pulser_tb/UUT/pulser_data_o
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>

configure wave -signalnamewidth 1


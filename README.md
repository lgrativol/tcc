# tcc
Repo TCC 2020: Lucas Grativol Ribeiro.

Contact email: lucasgrativolr@gmail.com

*All important project details are found in the manuscript and the slide presentation. Both can be found in the references folder.

--------------------------------------------------------------------------------------------------------------
* Project directory structure :

├───figures  (Figures for the python script)     
├───hdl      (All HLD sources)
│   ├───pkg (VHDL packages)
│   │   └───ieee_proposed
│   ├───sim (Testebenchs)
│   │   ├───averager
│   │   ├───cordic
│   │   ├───cordic_weights
│   │   ├───dds_cordic
│   │   ├───dds_win
│   │   ├───downsampler
│   │   ├───lookup_wave
│   │   ├───pulser
│   │   ├───ring_fifo
│   │   ├───testbench_tools
│   │   ├───top
│   │   └───upsampler
│   └───src (Description of the project blocks, each with its own folder and associated files)
│       ├───averager
│       ├───cordic
│       ├───cordic_weights (simulation only)
│       ├───dds_cordic
│       ├───dds_windows
│       │   ├───blackman
│       │   ├───blackman_harris
│       │   ├───hanning_hamming
│       │   └───tukey
│       ├───downsampler
│       ├───fsm_control
│       ├───generic_shift_reg
│       ├───gen_fir
│       ├───lookup_wave
│       ├───pulser
│       ├───register_bank
│       ├───ring_fifo
│       ├───top
│       ├───upsampler
│       ├───wave_fifo
│       └───wave_generator
├───old (old files, not used)
├───references (Reference work)
├───scripts (Old simulation files)
└───work (Modelsim/Questasim folder)

--------------------------------------------------------------------------------------------------------------

* About the library ieee_proposed :

It is the library that implements fixed-point arithmetic in VHDL. In VHDL 2008 this library is supported
natively, but not in earlier versions. Vivado only began to support ieee_proposed natively in more recent versions, 2020.1+.

The project was based on VHDL-93 (even though it uses some features from VHDL-2002 and 2008, for convenience).

To compile the ieee_proposed library to be used in QuestaSim/ModelSim, follow these steps
only needed once:

In the QuestaSim/ModelSim terminal or using its terminal version:

$ mkdir work
$ cd work
$ vsim -c -do "do ../scripts/comp_lib.do ; quit -f" 

--------------------------------------------------------------------------------------------------------------
To run ieee_proposed in Vivado, there are two options:

1) In Vivado versions that support the library, mark all files as VHDL-2008
natively all files are considered as VHDL-93 (at least in Vivado 2017.4 it was like this)

2) Import the files that form the ieee_proposed library directly and request
that Vivado identifies them as ieee_proposed link: [Xilinx Support Answer 52575](https://www.xilinx.com/support/answers/52575.html)

--------------------------------------------------------------------------------------------------------------

Both methods were tested on win10, QuestaSim 10.6c 64-bit, and Vivado 2017.4 and 2019.2

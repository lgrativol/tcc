# tcc
Repositório TCC 2020: Lucas Grativol Ribeiro.


1) Compile "ieee_proposed" libs, only needed the first time:

$ mkdir work
$ cd work
$ vsim -c -do "do ../scripts/comp_lib.do ; quit -f" 



2) Launch python simulation script:

From "./tcc"

$ python scripts/sim_dds.py


Tested with win10, python 3.8, questasim 10.6c 64 bits.

Python libs:  - matplotlib 
              - numpy
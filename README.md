# tcc
Repositório TCC 2020: Lucas Grativol Ribeiro.

email de contato : lucasgrativolr@gmail.com

* Todos os detalhes importantes do projeto são encontrados no manuscrito e na apresentação de slides
* referentes ao projeto. Ambos se encontram na pasta references.

--------------------------------------------------------------------------------------------------------------
* Arborescência do projeto:

├───figures  (Figuras do script python)     
├───hdl      (todos os arquivos HDL do projeto)
│   ├───pkg (pacotes HDL do projeto)
│   │   └───ieee_proposed
│   ├───sim (testebenchs)
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
│   └───src (descrição dos blocos do projeto, cada um com sua pasta e arquivos associados)
│       ├───averager
│       ├───cordic
│       ├───cordic_weights(sim)
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
├───old (antigos arquivos ou versões de arquivo que não são mais úteis/utilizadas)
├───references (Pdfs de referência para o projeto)
├───scripts (Scripts em python para simulação (depreciado))
└───work (Pasta para compilar arquivos do modelsim/questim)

--------------------------------------------------------------------------------------------------------------

* Sobre a library ieee_proposed :

É a biblioteca que implementa a aritmética de ponto-fixo em VHDL. No VHDL 2008 essa library é suportada
nativamente, nas versões anteriores não. O Vivado só passou a suportar nativamente a ieee_proposed nas
versões mais recentes 2020.1+ (na 2019 o suporte existe mais é precário, padrão Xilinx.)

O projeto foi baseado em VHDL-93 ( mesmo que utilize coisas de VHDL-2002 e 2008, por comodidade)


Para compilar a biblioteca ieee_proposed para ser usada no questasim/modelsim siga os passos
só necessário uma vez:

Dentro do terminal do questasim/modelsim ou usando a versão terminal dele:

$ mkdir work
$ cd work
$ vsim -c -do "do ../scripts/comp_lib.do ; quit -f" 

---------------------

Para rodar o ieee_proposed no Vivado existem duas Opções

1) Em versões que suportam a biblioteca, marcar todos os arquivos como VHDL-2008
   nativamente todos os arquivos são considerados como sendo VHDL-93 
   (pelo menos no vivado 2017.4 foi assim)

2) Importar os arquivos que formam a library ieee_proposed diretamente e pedir
   que o Vivado identifique eles como ieee_proposed
   link : https://www.xilinx.com/support/answers/52575.html

---------------------

Os dois métodos foram testados no win10, questasim 10.6c 64 bits e vivado 2017.4 e 2019.2
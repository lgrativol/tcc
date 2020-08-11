#############
## Imports ##
#############

import numpy as np
import matplotlib.pyplot as plt
import subprocess as sb
from   pylib.FixedPoint import FXfamily, FXnum
import fileinput
import sys
import shutil


###########
## Class ##
###########

class SimDDS:

    SAMPLING_FREQ         = 100E6 ## DDS Cordic clock 
    UTILS_FILE            = "hdl/pkg/utils_pkg.vhd"
    SIM_INPUT_FILE        = "hdl/sim/sim_input_pkg.vhd"
    CONFIG_FILE           = "hdl/pkg/utils_pkg.vhd"
    SRC_FILE_PATH         = "work/output.txt"
    NB_CYCLES_WIDTH       = 10 # bits
    TX_TIME_WIDTH         = 18 # bits
    TX_OFF_TIME_WIDTH     = 18 # bits
    RX_TIME_WIDTH         = 18 # bits
    OFF_TIME_WIDTH        = 18 # bits
    ACCEPTABLE_TIME_UNIT  = ['ns','us','ms']
    
    def __init__(self,target_freq, nb_cycles):
        """
        target_freq = Generated sine frequency
        nb_cycles   = Number of periods of the generated sine 

        Notes:
        
        For <tx_time> | <tx_off_time> | <rx_time> | <off_time>

        Two possibilities:
        1) Integer value, meaning the *number o cycles*, considering the SAMPLING_FREQ (FPFA clock)
        2) A string with a number and a time constant, e.g. 10 us, 2.62 ms, 800 ns
            Minimum value :  (1 / SAMPLING_FREQ), with 100e6 -> 10 ns
            Acceptable time constants : n (nano), u "micro", m "mili", nothing "seconds"
        **MAX TIME = 2.62 ms**
        
        If <tx_time> is an empty string "" or zero 0, tx_time = ((SAMPLING_FREQ/target_freq) * nb_cycles)
        
        """
        self._target_freq = target_freq
        self._nb_cycles = nb_cycles
        self._tx_time = ""
        self._tx_off_time = 20 
        self._rx_time = "10 us"
        self._off_time = 15
        self._cordic_word_interger_width = 2 # bits FIX VALUE
        self._cordic_word_frac_width = 19 # bits
        self._cordic_word_width = self.cordic_word_interger_width + self.cordic_word_frac_width  # bits
        self._nb_cordic_stages = 21
        self._need_reconfig = False


    @property
    def target_freq(self):
        return self._target_freq

    @target_freq.setter
    def target_freq(self,value):
        if(value > self.SAMPLING_FREQ/2):
            print("WARNING: Maximum frequency = SAMPLING_FREQ/2 : %d [Nyquist]" %(self.SAMPLING_FREQ/2))
            self._target_freq = self.SAMPLING_FREQ/2
        else:
            self._target_freq = self.SAMPLING_FREQ/2

    @property
    def nb_cycles(self):
        return self._nb_cycles

    @nb_cycles.setter
    def nb_cycles(self,value):
        if(value < 0):
            self._nb_cycles = 1
        else:
            if(value > (2** self.NB_CYCLES_WIDTH - 1)):
                self._nb_cycles = (2** self.NB_CYCLES_WIDTH - 1)
            else:
                self._nb_cycles = value
    @property
    def cordic_word_interger_width(self):
        return self._cordic_word_interger_width

    @cordic_word_interger_width.setter
    def cordic_word_interger_width(self,value):
        self._cordic_word_interger_width = value
    
    @property
    def cordic_word_frac_width(self):
        return self._cordic_word_frac_width

    @cordic_word_frac_width.setter
    def cordic_word_frac_width(self,value):
        self._need_reconfig = True
        self._cordic_word_frac_width = value

    @property
    def cordic_word_width(self):
        return self._cordic_word_width
    
    @cordic_word_width.setter
    def cordic_word_width(self,value):
        self._cordic_word_width = value
    
    @property
    def nb_cordic_stages(self):
        return self._nb_cordic_stages

    @nb_cordic_stages.setter
    def nb_cordic_stages(self,value):
        self._need_reconfig = True
        self._nb_cordic_stages = value

    @property
    def tx_time(self):
        return self._tx_time

    @tx_time.setter
    def tx_time(self,value):
        if (value != "" and value != 0):
            if (type(value) is str):
                if(value[-2:] in self.ACCEPTABLE_TIME_UNIT):
                    self._tx_time = value
            else:
                if (value > (2** self.TX_TIME_WIDTH - 1)):
                    self._tx_time = (2** self.TX_TIME_WIDTH - 1)
                else:
                    self._tx_time = value 
    @property
    def tx_off_time(self):
        return self._tx_off_time

    @tx_off_time.setter
    def tx_off_time(self,value):

        if (type(value) is str):
            if(value[-2:-1] in self.ACCEPTABLE_TIME_UNIT):
                self._tx_off_time = value
        else:
            if (value > (2** self.TX_OFF_TIME_WIDTH - 1)):
                self._tx_off_time = (2** self.TX_OFF_TIME_WIDTH - 1)
            else:
                self._tx_off_time = value if value > 0 else 1

    @property
    def rx_time(self):
        return self._rx_time

    @rx_time.setter
    def rx_time(self,value):

        if (type(value) is str):
            if(value[-2:-1] in self.ACCEPTABLE_TIME_UNIT):
                self._rx_time = value
        else:
            if (value > (2** self.RX_TIME_WIDTH - 1)):
                self._rx_time = (2** self.RX_TIME_WIDTH - 1)
            else:
                self._rx_time = value if value > 0 else 1

    @property
    def off_time(self):
        return self._off_time
    
    @off_time.setter
    def off_time(self,value):

        if (type(value) is str):
            if(value[-2:-1] in self.ACCEPTABLE_TIME_UNIT):
                self._off_time = value
        else:
            if (value > (2** self.OFF_TIME_WIDTH - 1)):
                self._off_time = (2** self.OFF_TIME_WIDTH - 1)
            else:
                self._off_time = value if value > 0 else 1


    def _replace_all (self,file,replace_search,replace_term):
        """
        file : file to modify
        replace_search : LIST with elements to be search on one line
        replace_term : LIST with elements to be replaced on one line
        """
        for line in fileinput.input(file, inplace=1):
            for i, search_exp in enumerate(replace_search):
                if search_exp in line:
                    line = replace_term[i]
            sys.stdout.write(line)
        

    def _write_sim_input(self):
        
        search_freq        = "SIM_INPUT_TARGETFREQ"
        search_nbcycles    = "SIM_INPUT_NBCYCLES"
        search_tx_time     = "SIM_INPUT_TX_TIME"     
        search_tx_off_time = "SIM_INPUT_TX_OFF_TIME"
        search_rx_time     = "SIM_INPUT_RX_TIME"      
        search_off_time    = "SIM_INPUT_OFF_TIME"   

        search_list = [search_freq,search_nbcycles,search_tx_time,search_tx_off_time,search_rx_time,search_off_time]
        
        term_target_frequency = "   constant SIM_INPUT_TARGETFREQ     : positive  := %d;\n" %(self._target_freq)
        term_nb_cycles        = "   constant SIM_INPUT_NBCYCLES       : natural   := %d;\n" %(self._nb_cycles)
        term_tx_time          = "   constant SIM_INPUT_TX_TIME        : positive  := %d;\n" %(self._format_time_zone(self._tx_time))
        term_tx_off_time      = "   constant SIM_INPUT_TX_OFF_TIME    : positive  := %d;\n" %(self._format_time_zone(self._tx_off_time))
        term_rx_time          = "   constant SIM_INPUT_RX_TIME        : positive  := %d;\n" %(self._format_time_zone(self._rx_time))
        term_off_time         = "   constant SIM_INPUT_OFF_TIME       : positive  := %d;\n" %(self._format_time_zone(self._off_time))
 
        term_list = [term_target_frequency,term_nb_cycles,term_tx_time,term_tx_off_time,term_rx_time,term_off_time]

        self._replace_all(self.SIM_INPUT_FILE,search_list,term_list)

    def _format_time_zone(self,time_zone):

        if(type(time_zone) is str):
            if (time_zone == ""):
                return ((self.SAMPLING_FREQ/self.target_freq) * self.nb_cycles)
            else:
                index = self.ACCEPTABLE_TIME_UNIT.index(time_zone[-2:])
                time_in_ns = ( float(time_zone[0:-3]) * (10**(-9)) ) * (1000**index)
                return time_in_ns * self.SAMPLING_FREQ
        else:
            if (time_zone == 0):
                return ((self.SAMPLING_FREQ/self.target_freq) * self.nb_cycles)
            else:
                return int(time_zone)
 
    def _write_config(self):
        
        search_cordic_frac_part     = "CORDIC_FRAC_PART"     
        search_nb_cordic_iterations = "N_CORDIC_ITERATIONS"


        search_list = [search_cordic_frac_part,search_nb_cordic_iterations]

        term_cordic_frac_part     = "    constant N_CORDIC_ITERATIONS    : natural  := %d;\n" %(self._cordic_word_frac_width)
        term_nb_cordic_iterations = "    constant CORDIC_FRAC_PART       : integer  := %d;\n" %(self._nb_cordic_stages)

        term_list = [term_cordic_frac_part,term_nb_cordic_iterations]

        self._replace_all(self.CONFIG_FILE,search_list,term_list)
        self._need_reconfig = False      

    def conv (self,shex):

        value = int(shex,16)

        if value & (1 << (self.cordic_word_width-1)):
            value -= 1 << self.cordic_word_width
    
        value /= (2**self.cordic_word_frac_width)
        
        return FXnum(value,FXfamily(self.cordic_word_frac_width)).toDecimalString()
    
    def _annot_max(self,x,y, ax=None,xlabel="",ylabel=""):
        xmax = x[np.argmax(y)]
        ymax = y.max()
        text= ("x={:1.3f} "+ xlabel+", y={:1.6f} " + ylabel).format(xmax, ymax)
        if not ax:
            ax=plt.gca()
        bbox_props = dict(boxstyle="square,pad=0.3", fc="w", ec="k", lw=0.72)
        arrowprops=dict(arrowstyle="->",connectionstyle="angle,angleA=0,angleB=60")
        kw = dict(xycoords='data',textcoords="axes fraction",
                arrowprops=arrowprops, bbox=bbox_props, ha="right", va="top")
        ax.annotate(text, xy=(xmax, ymax), xytext=(0.9,0.92), **kw)
    
    def _freq_stringformat (self,freq):
        freq_mag = ["","K","M"]

        for i in range(len(freq_mag)):
            if freq < 1000 :
                return "%3.1f %s" % (freq , freq_mag[i])
            freq /= 1000.0
        return "%3.2f %s" % (freq , freq_mag[i])

    def _time_stringformat (self,time):
        time_cte = ["s","ms","us","ns"]

        for i in range(len(time_cte)):
            if time >= 1.0 :
                return "%1.5f %s" %(time,time_cte[i])
            time *= 1000

    def do(self,compile = True , save_plot = True, dB_fft = True, normalized_freq = False):

        if (compile):
            self._write_sim_input()

            if (self._need_reconfig):
                self._write_config() 

            time = (1.0/self._target_freq) * float(self._nb_cycles)
            sim_time = self._time_stringformat(time)

            print("Simulating ....")

            vsim_cmd = "vsim -batch -do \"cd work ; do ../comp.do ; vsim work.top_dds_cordic_tb ; run %s ; quit -f \" " % (sim_time)
            sb.call(vsim_cmd) ## TODO: add support for compilation errors

            print("Simulation done!")

        cordic_data = np.loadtxt(self.SRC_FILE_PATH, converters={0 : self.conv})

        nb_samplepoints = len(cordic_data) # Number of samplepoints
        sample_spacing = 1.0 / self.SAMPLING_FREQ # sample spacing

        x_axis = np.linspace(0.0, (nb_samplepoints*sample_spacing), nb_samplepoints)
        ref_sin_y = np.sin(self.target_freq * 2.0 * np.pi * x_axis)

        mae = np.abs(cordic_data - ref_sin_y) / nb_samplepoints # Mean absolute error
        x_axis_rad = self.target_freq * 2.0 * x_axis

        cordic_fft = np.fft.fft(cordic_data,nb_samplepoints) / nb_samplepoints
        cordic_freqs = np.fft.fftfreq(nb_samplepoints,sample_spacing)

        if (normalized_freq):
            cordic_freqs /= self.SAMPLING_FREQ

        cordic_fft_plot = np.abs(cordic_fft)
        y_fftlabel = ""

        if (dB_fft):
            y_fftlabel = "dB"
            cordic_fft_plot = 10.0 * np.log10(cordic_fft_plot)

        ## Plot
        fig, ax = plt.subplots(2,2)

        ax[0][0].grid(True)
        ax[0][0].set_title("DDS vs Python Sine %sHz" % (self._freq_stringformat(self.target_freq)))
        ax[0][0].plot(x_axis_rad,cordic_data,"-b", label="DDS")
        ax[0][0].plot(x_axis_rad,ref_sin_y,"-r", label="Python")
        ax[0][0].set_xlabel("Pi radians")
        ax[0][0].legend(loc='best')
        
        ax[0][1].grid(True)
        ax[0][1].set_title("Mean Absolute Error")
        ax[0][1].plot(x_axis_rad,mae)
        ax[0][1].set_xlabel("Pi radians")
        self._annot_max(x_axis_rad,mae,ax[0][1],xlabel="rads")

        ax[1][0].grid(True)
        ax[1][0].set_title("Magnitude")
        ax[1][0].semilogx(cordic_freqs[:nb_samplepoints//2],cordic_fft_plot[:nb_samplepoints//2]) ## Only the real half
        ax[1][0].set_xlabel("Frequency")
        self._annot_max(cordic_freqs[:nb_samplepoints//2],cordic_fft_plot,ax[1][0],xlabel=" Hz",ylabel=y_fftlabel)

        ax[1][1].set_visible(False)

        if(save_plot):
            fig_name = "fig_%s_%d.png" % (self._freq_stringformat(self.target_freq) , self.nb_cycles)
            plt.savefig(fig_name)
        plt.tight_layout()
        plt.show()    

##########
## MAIN ##
##########

def main():
    target_frequency = 500e3 
    number_cycles =  10
    sim = SimDDS(target_frequency,number_cycles)
    sim.do(compile=False)

if __name__ == "__main__":
    main()
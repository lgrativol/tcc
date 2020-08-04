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

    SAMPLING_FREQ = 100E6 ## DDS Cordic clock 
    UTILS_FILE     = "hdl/pkg/utils_pkg.vhd"
    SIM_INPUT_FILE = "hdl/sim/sim_input_pkg.vhd"
    SRC_FILE_PATH  = "work/output.txt"
    
    def __init__(self,target_freq, nb_cycles ):
        """
        target_freq = Generated sine frequency
        nb_cycles   = Number of periods of the generated sine 
        """
        self.target_freq = target_freq
        self.nb_cycles = nb_cycles
        self.cordic_word_width = 21 # bits
        self.cordic_word_frac_width = 19 # bits
            
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
        
        search_freq = "SIM_INPUT_TARGETFREQ"
        search_nbcycles = "SIM_INPUT_NBCYCLES"
        
        term_target_frequency = "   constant SIM_INPUT_TARGETFREQ     : positive  := %d;\n" %(self.target_freq)
        term_nb_cycles        = "   constant SIM_INPUT_NBCYCLES       : natural   := %d;\n" %(self.nb_cycles)

        self._replace_all(self.SIM_INPUT_FILE,[search_freq,search_nbcycles],[term_target_frequency,term_nb_cycles])

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
            time = (1.0/self.target_freq) * float(self.nb_cycles)
            sim_time = self._time_stringformat(time)

            print("Simulating ....")

            vsim_cmd = "vsim -batch -do \"cd work ; do ../comp.do ; vsim work.top_dds_cordic_tb ; run %s ; quit -f \" " % (sim_time)
            sb.call(vsim_cmd) ## TODO: add support for compilation errors

            print("Simulation done!")

        cordic_data = np.loadtxt(self.SRC_FILE_PATH, converters={0 : self.conv})

        nb_samplepoints = len(cordic_data) # Number of samplepoints
        sample_spacing = 1.0 / self. SAMPLING_FREQ # sample spacing

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
        ax[0][0].legend(loc='best')
        
        ax[0][1].grid(True)
        ax[0][1].set_title("Mean Absolute Error")
        ax[0][1].plot(x_axis_rad,mae)
        self._annot_max(x_axis_rad,mae,ax[0][1],xlabel="rads")

        ax[1][0].grid(True)
        ax[1][0].set_title("Magnitude")
        ax[1][0].semilogx(cordic_freqs[:nb_samplepoints//2],cordic_fft_plot[:nb_samplepoints//2]) ## Only the real half
        self._annot_max(cordic_freqs[:nb_samplepoints//2],cordic_fft_plot,ax[1][0],xlabel=" Hz",ylabel=y_fftlabel)

        ax[1][1].set_visible(False)

        if(save_plot):
            fig_name = "fig_%s_%d.png" % (self._freq_stringformat(self.target_freq) , self.nb_cycles)
            plt.savefig(fig_name)
        plt.show()    

def main():
    sim = SimDDS(100e3,200)

    sim.do(compile=True)

if __name__ == "__main__":
    main()
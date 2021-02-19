#############
## Imports ##
#############

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
import subprocess as sb
from   pylib.FixedPoint import FXfamily, FXnum
import fileinput
import sys
import shutil
import math
from scipy import signal
import csv

###########
## Class ##
###########

class SimDDS:

    SAMPLING_FREQ         = 100E6 ## DDS Cordic clock 
    SIM_INPUT_FILE        = "hdl/sim/sim_input_pkg.vhd"
    CONFIG_FILE           = "hdl/pkg/defs_pkg.vhd"

    SRC_FILE_DDS_PATH     = "work/output_dds_cordic_sine.txt"
    SRC_FILE_DDA_PATH     = "work/output_dd_a.txt"
    SRC_FILE_DDB_PATH     = "work/output_dd_b.txt"
    SRC_FILE_DWS_PATH     = "work/output_sine.txt"
    SRC_FILE_DWW_PATH     = "work/output_win.txt"
    SRC_FILE_DWR_PATH     = "work/output_sine_win.txt"

    TUKEY_ALFA            =  0.5
    
    NB_CYCLES_WIDTH       = 5 # bits
    TX_TIME_WIDTH         = 18 # bits
    DEADZONE_TIME_WIDTH     = 18 # bits
    RX_TIME_WIDTH         = 18 # bits
    IDLE_TIME_WIDTH        = 18 # bits
    PHASE_WIDTH           = 32 # bits
    PHASE_INTEGER_PART    = 4
    PHASE_FRAC_PART       = PHASE_WIDTH - PHASE_INTEGER_PART - 1 # 1 for sign bit

    FIGSIZE               = (12,9)

    FIX_LATENCY           = 4  
    ACCEPTABLE_TIME_UNIT  = ['ns','us','ms']
    
    def __init__(self,target_freq = 500e3,  nb_cycles = 10, initial_phase = 0.0 ,mode_time = False):
        """       
        """
        self._target_freq = target_freq
        self._nb_cycles = nb_cycles
        self._initial_phase = initial_phase
        self._tx_time = ""
        self._tx_off_time = 300 
        self._rx_time = "3 us"
        self._off_time = 100
        self._mode_time = mode_time
        self._cordic_word_int_width = 2 # bits FIX VALUE
        self._cordic_word_frac_width = 8 # bits
        self._cordic_word_width = self.cordic_word_int_width + self.cordic_word_frac_width  # bits
        self._nb_cordic_stages = 10
        self._win_mode = "NONE"
        self.need_reconfig = False

    @property
    def target_freq(self):
        return self._target_freq

    @target_freq.setter
    def target_freq(self,value):
        if(value > self.SAMPLING_FREQ/2):
            print("WARNING: Maximum frequency = SAMPLING_FREQ/2 : %d [Nyquist]" %(self.SAMPLING_FREQ/2))
            self._target_freq = self.SAMPLING_FREQ/2
        else:
            self._target_freq = value

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
    def initial_phase(self):
        return self._initial_phase

    @initial_phase.setter
    def initial_phase(self,value):
        self._initial_phase = value

    @property
    def cordic_word_int_width(self):
        return self._cordic_word_int_width

    @cordic_word_int_width.setter
    def cordic_word_int_width(self,value):
        self.need_reconfig = True
        self._cordic_word_int_width = value
    
    @property
    def cordic_word_frac_width(self):
        return self._cordic_word_frac_width

    @cordic_word_frac_width.setter
    def cordic_word_frac_width(self,value):
        self.need_reconfig = True
        self._cordic_word_frac_width = value

    @property
    def cordic_word_width(self):
        return self._cordic_word_width
    
    @cordic_word_width.setter
    def cordic_word_width(self,value):
        self.need_reconfig = True
        self._cordic_word_width = value
    
    @property
    def nb_cordic_stages(self):
        return self._nb_cordic_stages

    @nb_cordic_stages.setter
    def nb_cordic_stages(self,value):
        self.need_reconfig = True
        self._nb_cordic_stages = value

    @property
    def tx_time(self):
        return self._tx_time

    @tx_time.setter
    def tx_time(self,value):
        self.need_reconfig = True
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
        self.need_reconfig = True
        if (type(value) is str):
            if(value[-2:-1] in self.ACCEPTABLE_TIME_UNIT):
                self._tx_off_time = value
        else:
            if (value > (2** self.DEADZONE_TIME_WIDTH - 1)):
                self._tx_off_time = (2** self.DEADZONE_TIME_WIDTH - 1)
            else:
                self._tx_off_time = value if value > 0 else 1

    @property
    def rx_time(self):
        return self._rx_time

    @rx_time.setter
    def rx_time(self,value):
        self.need_reconfig = True
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
        self.need_reconfig = True
        if (type(value) is str):
            if(value[-2:-1] in self.ACCEPTABLE_TIME_UNIT):
                self._off_time = value
        else:
            if (value > (2** self.IDLE_TIME_WIDTH - 1)):
                self._off_time = (2** self.IDLE_TIME_WIDTH - 1)
            else:
                self._off_time = value if value > 0 else 1
    @property
    def mode_time(self):
        return self._mode_time

    @mode_time.setter
    def mode_time(self,value):
        if (value):
            self._mode_time = '1'
        else:
            self._mode_time = '0'
    
    @property
    def win_mode(self):
        return self._win_mode

    @win_mode.setter
    def win_mode(self,value):
        self._win_mode = value

    def _format_phase(self,phase):
        phase = int( phase * 2**(self.PHASE_FRAC_PART))
        nb_digit = str(int(self.PHASE_WIDTH/4))
        phase_str = '%08x' %(phase) ## TODO: Pass it to generic f(PHASE_FRAC_PART)
        return phase_str

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

        search_phase_term       = "SIM_INPUT_PHASE_TERM"
        search_win_term         = "SIM_INPUT_WIN_TERM"
        search_initial_phase    = "SIM_INPUT_INIT_PHASE"
        search_nb_points        = "SIM_INPUT_NBPOINTS"
        search_nb_cycles        = "SIM_INPUT_NBREPET"
        search_mode_time        = "SIM_INPUT_MODE_TIME"   
        search_win_mode         = "SIM_INPUT_WIN_MODE"   
        search_tx_time          = "SIM_INPUT_TX_TIME"     
        search_tx_off_time      = "SIM_INPUT_TX_OFF_TIME"
        search_rx_time          = "SIM_INPUT_RX_TIME"      
        search_off_time         = "SIM_INPUT_OFF_TIME"   

        search_list             = [search_phase_term,search_win_term,search_nb_points,search_nb_cycles,search_initial_phase,
                                   search_tx_time,search_tx_off_time,search_rx_time,search_off_time,search_mode_time,search_win_mode]
        
        nb_points  = self.SAMPLING_FREQ/self.target_freq
        phase_term = ( 2.0 * np.pi  / nb_points)

        if(self.win_mode == "TKEY"):
            win_term = ( 2.0 * np.pi  / ( (nb_points * self.nb_cycles + 1)*self.TUKEY_ALFA ))
        else:
            win_term = ( 2.0 * np.pi  / (nb_points * self.nb_cycles))

        term_phase_term       = "   constant SIM_INPUT_PHASE_TERM     : std_logic_vector((PHASE_WIDTH - 1) downto 0) := x\"%s\";\n" %(self._format_phase(phase_term))
        term_win_term         = "   constant SIM_INPUT_WIN_TERM       : std_logic_vector((PHASE_WIDTH - 1) downto 0) := x\"%s\";\n" %(self._format_phase(win_term))
        term_nb_points        = "   constant SIM_INPUT_NBPOINTS       : natural   := %d;\n" %(nb_points)
        term_nb_cycles        = "   constant SIM_INPUT_NBREPET        : natural   := %d;\n" %(self.nb_cycles)
        term_initial_phase    = "   constant SIM_INPUT_INIT_PHASE     : std_logic_vector((PHASE_WIDTH - 1) downto 0) := x\"%s\";\n" %(self._format_phase(self.initial_phase))
        term_tx_time          = "   constant SIM_INPUT_TX_TIME        : positive  := %d;\n" %(self._format_time_zone(self.tx_time))
        term_tx_off_time      = "   constant SIM_INPUT_TX_OFF_TIME    : positive  := %d;\n" %(self._format_time_zone(self.tx_off_time))
        term_rx_time          = "   constant SIM_INPUT_RX_TIME        : positive  := %d;\n" %(self._format_time_zone(self.rx_time))
        term_off_time         = "   constant SIM_INPUT_OFF_TIME       : positive  := %d;\n" %(self._format_time_zone(self.off_time))
        term_mode_time        = "   constant SIM_INPUT_MODE_TIME      : std_logic := \'%s\';\n" %(self.mode_time)
        term_win_mode         = "   constant SIM_INPUT_WIN_MODE       : string    := \"%s\";\n" %(self.win_mode)
 
        term_list = [term_phase_term, term_win_term, term_nb_points,term_nb_cycles,term_initial_phase,term_tx_time,
                     term_tx_off_time,term_rx_time,term_off_time,term_mode_time,term_win_mode]

        self._replace_all(self.SIM_INPUT_FILE,search_list,term_list)

    def _format_time_zone(self,time_zone):

        if(type(time_zone) is str):
            if (time_zone == ""):
                amount = ((self.SAMPLING_FREQ/self.target_freq) * self.nb_cycles) 
                
                if (self.mode_time):
                    amount +=  int( ((self.initial_phase/(2 * np.pi * self.target_freq)) * self.SAMPLING_FREQ) ) 

                return amount 
            else:
                index = self.ACCEPTABLE_TIME_UNIT.index(time_zone[-2:])
                time_in_ns = ( float(time_zone[0:-3]) * (10**(-9)) ) * (1000**index)
                return time_in_ns * self.SAMPLING_FREQ
        else:
            if (time_zone == 0):
                amount = ((self.SAMPLING_FREQ/self.target_freq) * self.nb_cycles) 
                
                if (self.mode_time):
                    amount +=  int( ((self.initial_phase/(2 * np.pi * self.target_freq)) * self.SAMPLING_FREQ) ) 

                return amount             
            else:
                return int(time_zone)
 
    def _write_config(self):
       
        #search_cordic_frac_part     = "CORDIC_FRAC_PART"     
        search_nb_cordic_iterations = "constant N_CORDIC_ITERATIONS"

        #search_list = [search_cordic_frac_part,search_nb_cordic_iterations]
        search_list = [search_nb_cordic_iterations]

        term_nb_cordic_iterations     = "    constant N_CORDIC_ITERATIONS    : natural  := %d;\n" %(self.cordic_word_frac_width + self.cordic_word_int_width)
        #term_cordic_frac_part  = "    constant CORDIC_FRAC_PART       : integer  := %d;\n" %(self.nb_cordic_stages)

        #term_list = [term_cordic_frac_part,term_nb_cordic_iterations]
        term_list = [term_nb_cordic_iterations]

        self._replace_all(self.CONFIG_FILE,search_list,term_list)
        self.need_reconfig = False      

    def conv (self,shex):

        value = int(shex,16)

        cordic_word_width = self.cordic_word_int_width + self.cordic_word_frac_width

        if value & (1 << (cordic_word_width-1)):
            value -= 1 << cordic_word_width
    
        value /= (2**self.cordic_word_frac_width)
        
        return FXnum(value,FXfamily(self.cordic_word_frac_width)).toDecimalString()
    
    def _annot_max(self,x,y,ax=None,xlabel="",ylabel="",xytext = (0.9,0.92)):

        xmax = x[np.argmax(y)]
        ymax = y.max()
        annot_pos = (xmax,ymax)
        text= ("x={:1.3f} "+ xlabel+", y={:1.6f} " + ylabel).format(xmax, ymax)
        if not ax:
            ax=plt.gca()
        bbox_props = dict(boxstyle="square,pad=0.3", fc="w", ec="k", lw=0.72)
        arrowprops=dict(arrowstyle="->",connectionstyle="angle,angleA=0,angleB=60")
        kw = dict(xycoords='data',textcoords="axes fraction",
                arrowprops=arrowprops, bbox=bbox_props, ha="right", va="top")
        ax.annotate(text, xy=annot_pos, xytext=xytext, **kw)

    def _freq_stringformat (self,freq):
        freq_mag = ["","K","M"]

        for i in range(len(freq_mag)):
            if freq < 1000 :
                return "%3.1f %s" % (freq , freq_mag[i])
            freq /= 1000.0

    def _time_stringformat (self,time):
        time_cte = ["s","ms","us","ns"]

        for i in range(len(time_cte)):
            if time >= 1.0 :
                return "%1.5f %s" %(time,time_cte[i])
            time *= 1000

    def _sim_hdl(self,hdl_entity,run_all = False):

        dds_latency_time = (self.nb_cordic_stages + self.FIX_LATENCY) * (1/self.SAMPLING_FREQ)
        time = (1.0/self.target_freq) * float(self.nb_cycles + 1000) + dds_latency_time
        sim_time = ""

        if (run_all):
            sim_time = "-all"
        else:
            sim_time = self._time_stringformat(time)

        print("Simulating ....")

        vsim_cmd_sim = "vsim -batch -do \"cd work ; vsim work.%s ; run %s ; quit -f \" " % (hdl_entity,sim_time)
        sb.call(vsim_cmd_sim,stdout=sb.DEVNULL) 

        print("Simulation done!")

    def compile(self):
        self._write_sim_input()

        if(self.need_reconfig):
            self._write_config() 

        print("Compiling ....")

        #vsim_cmd_compile = "vsim -batch -do \" cd work ; do ../comp.do ; quit -f \" "
        vsim_cmd_compile = "vsim -batch -do \" cd work ; do ../comp_dds.do ; quit -f \" "
        sb.call(vsim_cmd_compile,stdout=sb.DEVNULL) ## TODO: add support for compilation errors

        print("Compilation done!")

    def do_fft(self,data,nb_points):
        sample_spacing  = 1.0 / self.SAMPLING_FREQ 
        data_fft        = np.fft.fft(data,nb_points)
        fft_freqs       = np.fft.fftfreq(nb_points,sample_spacing)

        return [data_fft,fft_freqs]

    def extract_data(self, source_file):
        data            = np.loadtxt(source_file, converters={0 : self.conv})
        nb_samples      = len(data) 
        sample_spacing  = 1.0 / self.SAMPLING_FREQ 
        x_axis          = np.linspace(0.0, (nb_samples*sample_spacing), nb_samples)

        return [data, nb_samples, x_axis]
 
    def do_dds(self, simulate = True, save_plot = True, dB_fft = True, normalized_freq = False, no_plot = False):

        if (simulate):
            hdl_entity = "dds_cordic_tb"
            self._sim_hdl(hdl_entity)

        [cordic_data, nb_samplepoints, x_axis] = self.extract_data(self.SRC_FILE_DDS_PATH)

        print("cordic data 0",cordic_data[0])

        if (self.mode_time):
            ref_sin_y                 = np.sin(self.target_freq * 2.0 * np.pi * x_axis)
            nb_samplepoints_mode_time = int( ((self.initial_phase/(2 * np.pi * self.target_freq)) * self.SAMPLING_FREQ) ) 
            zeros_array               = np.zeros(nb_samplepoints_mode_time)
            ref_sin_y_resized         = ref_sin_y[0:(nb_samplepoints-nb_samplepoints_mode_time)]
            ref_sin_y                 = np.concatenate((zeros_array,ref_sin_y_resized))
            pi_char                   = "" 
            axis_formater = mtick.FormatStrFormatter('%.2e')
            text_xlabel   = " seconds"
        else:
            ref_sin_y                = np.sin(self.target_freq * 2.0 * np.pi * x_axis + self.initial_phase)
            pi_char                  = str("\u03C0") ## Pi character 
            axis_formater            = mtick.FormatStrFormatter('%.3f'+pi_char)
            x_axis       = self.target_freq * 2.0 * x_axis
            text_xlabel  = " rads"
        
        mae = np.abs(cordic_data - ref_sin_y) / nb_samplepoints # Mean absolute error
        
        [cordic_fft , cordic_freqs] = self.do_fft(cordic_data,nb_samplepoints)

        if (normalized_freq):
            cordic_freqs /= self.SAMPLING_FREQ

        cordic_fft = np.abs(cordic_fft)  / nb_samplepoints
        y_fftlabel = ""

        if (dB_fft):
            y_fftlabel = "dB"
            cordic_fft = 20.0 * np.log10(2.0*cordic_fft)

        ## Formating data

        cordic_fft_plot = cordic_fft[:nb_samplepoints//2]
        cordic_fft_freq = cordic_freqs[:nb_samplepoints//2]

        ## Plot
        #if(not no_plot):
        fig, ax = plt.subplots(2,2,figsize=self.FIGSIZE)

        ax[0][0].grid(True)
        ax[0][0].set_title("DDS vs Python Sine %sHz" % (self._freq_stringformat(self.target_freq)))
        ax[0][0].plot(x_axis,cordic_data,"-b", label="DDS")
        ax[0][0].plot(x_axis,ref_sin_y,"-r", label="Python")
        ax[0][0].set_xlabel(text_xlabel)
        ax[0][0].xaxis.set_major_formatter(axis_formater)
        ax[0][0].legend(loc='best')
        
        ax[0][1].grid(True)
        ax[0][1].set_title("Mean Absolute Error")
        ax[0][1].plot(x_axis,mae)
        ax[0][1].set_xlabel(text_xlabel)
        ax[0][1].xaxis.set_major_formatter(axis_formater)
        self._annot_max (x_axis,mae,ax[0][1],xlabel=(pi_char + text_xlabel))

        ax[1][0].grid(True)
        ax[1][0].set_title("Magnitude")
        ax[1][0].semilogx(cordic_fft_freq,cordic_fft_plot) ## Only the real half
        ax[1][0].set_xlabel("Frequency")
        self._annot_max (cordic_fft_freq , cordic_fft_plot, ax[1][0], xlabel=" Hz",ylabel=y_fftlabel)
        cordic_fft_plot[np.argmax(cordic_fft_plot)] = -1000
        self._annot_max (cordic_fft_freq , cordic_fft_plot, ax[1][0], xlabel=" Hz",ylabel=y_fftlabel,xytext=(0.7,0.72))

        ax[1][1].set_visible(False)

        if(save_plot):
            fig_name = "fig_dds_%s_%d.png" % (self._freq_stringformat(self.target_freq) , self.nb_cycles)
            plt.savefig(fig_name)

    
        #plt.tight_layout()
        plt.show()    

        return max(mae)
    
    def do_double_driver(self, simulate = True,save_plot = True):
        
        if (simulate):
            hdl_entity = "double_driver_tb"
            self._sim_hdl(hdl_entity,run_all=True)

        [cordic_data_a, nb_samplepoints, x_axis] = self.extract_data(self.SRC_FILE_DDA_PATH)
        cordic_data_b = self.extract_data(self.SRC_FILE_DDB_PATH)[0]

        tx_pos      = self._format_time_zone(self.tx_time)
        tx_off_pos  = tx_pos + self._format_time_zone(self.tx_off_time)
        rx_pos      = tx_off_pos + self._format_time_zone(self.rx_time)
        off_pos     = rx_pos + self._format_time_zone(self.off_time)

        x_line_annots = [ [0," "],
                          [tx_pos, "TX ZONE"],
                          [tx_off_pos, "TX_OFF_ZONE"],
                          [rx_pos, "RX ZONE"] ,
                          [off_pos, "OFF ZONE" ]]

        ## Plot

        fig, ax = plt.subplots(2,1,figsize=self.FIGSIZE)

        time_xlabel = "seconds"

        ax[0].grid(False)
        ax[0].set_title("Driver A signal %sHz" % (self._freq_stringformat(self.target_freq)))
        ax[0].plot(x_axis,cordic_data_a,"-b")
        ax[0].set_xlabel(time_xlabel)
        ax[0].xaxis.set_major_formatter(mtick.FormatStrFormatter('%.2e'))

        ax[1].grid(False)
        ax[1].set_title("Driver B signal %sHz" % (self._freq_stringformat(self.target_freq)))
        ax[1].plot(x_axis,cordic_data_b,"-r")
        ax[1].set_xlabel(time_xlabel)
        ax[1].xaxis.set_major_formatter(mtick.FormatStrFormatter('%.2e'))

        sample_spacing =  1.0 / self.SAMPLING_FREQ 

        for axis in ax:
            for annot in x_line_annots :
                xline_point = annot[0] * sample_spacing
                axis.axvline(x=xline_point, linestyle=':', color = 'black', alpha=0.7)

        if(save_plot):
            fig_name = "fig_double_driver_%s_%d.png" % (self._freq_stringformat(self.target_freq) , self.nb_cycles)
            plt.savefig(fig_name)

        plt.tight_layout()
        plt.show()    

    def do_win(self ,simulate = True, no_plot = False, save_plot = True, normalized_freq = False):

        if (simulate):
            hdl_entity = "dds_cordic_win_tb"
            self.mode_time = False
            self._sim_hdl(hdl_entity)

        win_dict = {"NONE":"None" , "HANN" : "Hanning" , "HAMM" : "Hamming" , 
                    "BLKM" : "Blackman", "BLKH" : "Blackman-Harris", "TKEY" : "Tukey"}
        
        [sine_data, nb_samplepoints, x_axis] = self.extract_data(self.SRC_FILE_DWS_PATH)
        win_data = self.extract_data(self.SRC_FILE_DWW_PATH)[0]
        result_data = self.extract_data(self.SRC_FILE_DWR_PATH)[0]

        x_axis = self.target_freq * 2.0 * x_axis
        win_axis = np.linspace(0.0, nb_samplepoints, nb_samplepoints)

        pi_char = str("\u03C0") ## Pi character 
        axis_formater = mtick.FormatStrFormatter('%.3f'+pi_char)
        text_xlabel = " rads"
    
        [cordic_fft , cordic_freqs] = self.do_fft(sine_data,nb_samplepoints)
        [result_fft , result_freqs] = self.do_fft(result_data,nb_samplepoints)

        if (normalized_freq):
            cordic_freqs /= self.SAMPLING_FREQ
            result_freqs /= self.SAMPLING_FREQ

        cordic_fft = np.abs(cordic_fft)  / nb_samplepoints
        result_fft = np.abs(result_fft)  / nb_samplepoints

        y_fftlabel = "dB"
        cordic_fft = 20.0 * np.log10(2*cordic_fft)
        result_fft = 20.0 * np.log10(2*result_fft)

        ## Formating data

        cordic_fft_plot = cordic_fft[:nb_samplepoints//2]
        cordic_fft_freq = cordic_freqs[:nb_samplepoints//2]

        result_fft_plot = result_fft[:nb_samplepoints//2]
        result_fft_freq = result_freqs[:nb_samplepoints//2]

        ## Plot
        fig, ax = plt.subplots(2,2,figsize=self.FIGSIZE)

        ax[0][0].grid(True)
        ax[0][0].set_title("Sine %sHz" % (self._freq_stringformat(self.target_freq)))
        ax[0][0].plot(x_axis,sine_data)
        ax[0][0].set_xlabel(text_xlabel)
        ax[0][0].xaxis.set_major_formatter(axis_formater)
        
        ax[0][1].grid(True)
        ax[0][1].set_title( "Windowed Sine (%s)" %(win_dict[self.win_mode]))
        ax[0][1].plot(win_axis,result_data)
        ax[0][1].set_xlabel("Nb Points")

        ax[1][0].grid(True)
        ax[1][0].set_title("Magnitude Pure sine wave")
        ax[1][0].semilogx(cordic_fft_freq,cordic_fft_plot) ## Only the real half
        ax[1][0].set_xlabel("Frequency")
        self._annot_max (cordic_fft_freq,cordic_fft_plot,ax[1][0],xlabel=" Hz",ylabel=y_fftlabel)
        cordic_fft_plot[np.argmax(cordic_fft_plot)] = -1000
        self._annot_max (cordic_fft_freq , cordic_fft_plot, ax[1][0], xlabel=" Hz",ylabel=y_fftlabel,xytext=(0.8,0.82))

        ax[1][1].grid(True)
        ax[1][1].set_title("Magnitude Windowed sine (%s)" %( win_dict[self.win_mode]))
        ax[1][1].semilogx(result_fft_freq,result_fft_plot) ## Only the real half
        ax[1][1].set_xlabel("Frequency")
        self._annot_max (result_fft_freq,result_fft_plot,ax[1][1],xlabel=" Hz",ylabel=y_fftlabel)
        result_fft_plot[np.argmax(result_fft_plot)] = -1000
        self._annot_max (result_fft_freq , result_fft_plot, ax[1][1], xlabel=" Hz",ylabel=y_fftlabel,xytext=(0.8,0.82))

        plt.tight_layout()
        
        if(save_plot):
            fig_name = "figures/fig_dds_win_%s_%d_%s.png" % (self._freq_stringformat(self.target_freq) , self.nb_cycles, win_dict[self.win_mode])
            plt.savefig(fig_name)
        
        if (not no_plot):
            plt.show()       


##########
## MAIN ##
##########

def main():

    win_list = ["TKEY","HANN","HAMM","BLKM","BLKH","NONE"]

    sim = SimDDS()
    sim.nb_cycles = 10
    sim.initial_phase = 0.0
    sim.win_mode = "NONE"

    word_fracs = [6,8,10]

    # target_freqs = np.linspace(20e3,500e3,240)
    # #target_freqs = [100e3]
    
    # results = [ [] for _ in range(len(word_fracs)) ]
    
    # for i,frac in enumerate(word_fracs):
    #     sim.cordic_word_frac_width = frac
    #     print("############### Executing %d bits ###############" %(frac + 2))
    #     for j,freq in enumerate(target_freqs):
    #         print("#### Doing %d of %d freqs ####" %(j+1,len(target_freqs)))
    #         sim.target_freq = freq
    #         sim.compile()
    #         mae_max = sim.do_dds(save_plot=False, no_plot=True)
    #         results[i].append(mae_max)

    # with open("out.csv","w") as f:
    #     wr = csv.writer(f)
    #     wr.writerows(results)

    sim.target_freq = 500e3

    #print(sim.cordic_word_width)

    sim.compile()
    sim.do_dds(save_plot=True)
    
    #sim.do_win()
    #print(mae_max)

 
if __name__ == "__main__":
    main()
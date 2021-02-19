#############
## Imports ##
#############

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
from   pylib.FixedPoint import FXfamily, FXnum
import fileinput
import sys
import shutil
import math
from scipy import signal
import csv


###############
## Constants ##
###############

SRC_FILE_UP_PATH        = "work/output_cordic_up_weights.txt"
SRC_FILE_DOWN_PATH      = "work/output_cordic_down_weights.txt"

SINE_FREQ               = 500e3
NB_PERIODS              = 2
CONV_RATE               = 4

NB_TAPS                 = 10
FIR_COEF = [0.00726318359375,0.032623291015625,0.081573486328125,0.141357421875,0.183502197265625,
            0.183502197265625,0.141357421875,0.081573486328125,0.032623291015625,0.00726318359375]

##############
## Functios ##
##############

def conv (shex):

    value = int(shex,16)
    word_int_width = 2
    word_frac_width = 8

    cordic_word_width = word_int_width + word_frac_width

    if value & (1 << (cordic_word_width-1)):
        value -= 1 << cordic_word_width

    value /= (2**word_frac_width)
    
    return FXnum(value,FXfamily(word_frac_width)).toDecimalString()

def extract_data(mode):

    if(mode=="up"):
        source_file = SRC_FILE_UP_PATH
    elif(mode=="down"):
        source_file = SRC_FILE_DOWN_PATH

    data            = np.loadtxt(source_file, converters={0 : conv})
    nb_samples      = len(data) 
    
    if(mode=="up"):
        sample_spacing  = 1.0 / (100e6*CONV_RATE)
    elif(mode=="down"):
        sample_spacing  = 1.0 / (100e6/CONV_RATE)
        
    x_axis          = np.linspace(0.0, (nb_samples*sample_spacing), nb_samples)

    return [data, nb_samples, x_axis]

def do_fir(data):
    
    fir_data = np.zeros(len(data))

    for i in range(len(data)):
        acc = 0
        for k in range(NB_TAPS):
            if (i>=k):
                acc+= FIR_COEF[k]*data[i-k]
        
        fir_data[i] = acc
  
    return fir_data

def pad_signal(data):

    padded_data = np.zeros(len(data)*CONV_RATE)
    
    for i in range(len(data)):
        padded_data[i*CONV_RATE] = data[i]

    return padded_data

def discart_signal(data):
    discarted_data = np.zeros(math.ceil(len(data)/CONV_RATE))

    for i in range(len(discarted_data)):
        discarted_data[i] = data[i*CONV_RATE]
    
    return discarted_data
                
def make_ref(mode):

    nb_samples          = int( (100e6/SINE_FREQ) * NB_PERIODS)
    sample_spacing      = 1.0 / (100e6)
    x_axis              = np.linspace(0.0, (nb_samples*sample_spacing), nb_samples)

    ref_sine = np.sin(SINE_FREQ * 2.0 * np.pi * x_axis)

    if(mode=="up"):
        data = pad_signal(ref_sine)
        return do_fir(data)
    elif (mode=="down"):
        data = do_fir(ref_sine)
        return discart_signal(data)

    return 0

def do_fft(data,nb_points):
    sample_spacing  = 1.0 / (100e6*CONV_RATE) 
    data_fft        = np.fft.fft(data,nb_points)
    fft_freqs       = np.fft.fftfreq(nb_points,sample_spacing)

    data_fft = np.abs(data_fft)  / nb_points

    data_fft = data_fft[:nb_points//2]
    fft_freqs = fft_freqs[:nb_points//2]

    return [data_fft,fft_freqs]

def annot_max(x,y,ax=None,xlabel="",ylabel="",xytext = (0.9,0.92)):

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

##########
## Main ##
##########

mode ="up"

if (mode =="down"):
    title ="Comparação Python Downsampler vs Downsampler VHDL"
else:
    title ="Comparação Python Upsampler vs Upsampler VHDL"

[wave_data, nb_samplepoints, x_axis] = extract_data(mode)
ref_data = make_ref(mode)

mae = np.abs(wave_data - ref_data) / nb_samplepoints # Mean absolute error

fig, ax = plt.subplots(1,2,figsize=(12,9))

[wave_fft , wave_freqs] = do_fft(wave_data,nb_samplepoints)

ax[0].set_title(title)
ax[0].plot(x_axis,wave_data,"-b", label="VHDL")
ax[0].plot(x_axis,ref_data,"-r", label="Python")
ax[0].set_xlabel("Tempo [s]")
ax[0].set_ylabel("Amplitude")
ax[0].legend(loc='best')

ax[1].set_title("Erro médio quadrático")
ax[1].plot(x_axis,mae)
ax[1].set_xlabel("Tempo [s]")
ax[1].set_ylabel("Amplitude")

#ax[2].set_title("FFT")
#ax[2].semilogx(wave_freqs,wave_fft)
#ax[2].set_xlabel("Frequency")
#y_fftlabel = "dB"
#annot_max(wave_freqs , wave_fft, ax[2], xlabel=" Hz",ylabel=y_fftlabel)

plt.show()    
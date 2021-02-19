##################
##  Libraries   ##
##################

from scipy import signal 
import matplotlib.pyplot as plt
import numpy as np
#import math


##################
##  Constants   ##
##################


################################# && #################################

f_sampling      = 100e6
f_target        = 500e3
nb_periods      = 4

nb_points       = int(f_sampling/f_target)*nb_periods
sampling_space  = (1.0 / f_sampling)
x_axis          = np.linspace(0.0, (nb_points*sampling_space), nb_points)
x_cos_axis      = np.linspace(0.0, (nb_points*sampling_space), nb_points)

ref_sine = np.sin(f_target * 2.0 * np.pi * x_axis)

ref_cos = np.cos((f_target/nb_periods) * 2.0 * np.pi * x_axis)
ref_cos4 = np.cos((f_target/nb_periods) * 4.0 * np.pi * x_axis)
ref_cos6 = np.cos((f_target/nb_periods) * 6.0 * np.pi * x_axis)

alfa_blkm = 0.16
#winhnn = 0.5 - 0.5*ref_cos 
#winhmm = 0.53836 - (1 - 0.53836)*ref_cos 
#winblkm = (1-alfa_blkm)/2 -0.5*ref_cos +  (alfa_blkm/2)*ref_cos4
#winblkh = 0.35875 - 0.48829*ref_cos +  0.14128*ref_cos4 - 0.01168*ref_cos6

result = winblkh * ref_sine

plt.grid(True)
#plt.plot(x_axis,ref_sine,"-b", label="SINE")
#plt.plot(x_axis,ref_cos,"-r", label="COS")
plt.plot(result,"-r", label="COS")

plt.legend(loc='best')

plt.show()

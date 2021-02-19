import matplotlib.pyplot as plt
import matplotlib.ticker as mtick

import numpy as np
from csv import reader

file_name = "outbom.csv"

word_fracs = [6,8,10]
target_freqs = [100,200,300,400,500]

results = [ [] for _ in range(len(word_fracs)) ]

with open(file_name, 'r') as read_obj:
    # pass the file object to reader() to get the reader object
    csv_reader = reader(read_obj)
    # Pass reader object to list() to get a list of lists
    results = list(csv_reader)
    
    
#print(results)

fig = plt.figure()
ax = fig.add_subplot(111)

alt_res = np.array(results)
ax.grid(True)
ax.plot(target_freqs,alt_res[0],'r',label="12 bits")
ax.plot(target_freqs,alt_res[1],'g',label="10 bits")
ax.plot(target_freqs,alt_res[2],'b',label="8 bits")
ax.yaxis.set_major_formatter(mtick.FormatStrFormatter("%.2f E-6"))
ax.xaxis.set_major_formatter(mtick.FormatStrFormatter("%d KHz"))
ax.legend(loc='upper left', frameon=True)
ax.set_xlabel("Frequências")
ax.set_ylabel("Máximo erro médio quadrático")
plt.show()

print(alt_res[0][0])

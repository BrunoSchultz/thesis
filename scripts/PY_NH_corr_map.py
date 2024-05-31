#!/usr/bin/env python3

import argparse
from astropy.io import fits
import numpy as np
import pandas as pd
import os, subprocess, shutil
from numba import njit

script_version = 0.0
script_descr="""Create NH correction map.
"""

# Open argument parser
parser = argparse.ArgumentParser(description=script_descr)
parser.add_argument('--version',action='version',version='%(prog)s v{}'.format(script_version))

# Define expected arguments
# Mandatory
parser.add_argument('path',help='path to file')
parser.add_argument('cut_nh_map',help='The name of the cut and reprojected NH map, e.g., AIT_-600_600_cuttoA222_repr')
parser.add_argument('sim_results',help='NH simulation result, e.g., RESULTS_SIM_TM1_NH_A222')
parser.add_argument('tm',help='which TM?, e.g., TM1')
parser.add_argument('--low', nargs='+', type=float, help='low E value, e.g., 0.2 or 0.2 1.6')
parser.add_argument('--hie', nargs='+', type=float, help='high E value, e.g., 2.3 or 1.35 2.3')

args = parser.parse_args()
path = '{}'.format(args.path)  # path to the file
cut_nh_map = '{}.fits'.format(args.cut_nh_map)  # source file name.fits
sim_results = '{0}.txt'.format(args.sim_results)  # list of NH value (in e22) in the observation
tm = '{0}'.format(args.tm)  # list of NH value (in e22) in the observation
low = args.low
hie = args.hie

if len(low) == 1:
    suff = ""
else:
    suff = "_uni"

###############
nh_map = fits.open('{0}/{1}'.format(path, cut_nh_map))
img = nh_map[0].data    # numpy array
nh_ar = np.concatenate(img) # get all nH values in one array

nh_ar_e22 = nh_ar / 1e22
nh_ar_e22 = np.unique(np.round(nh_ar_e22, 4))

inFile1 = '{0}/{1}'.format(path, sim_results)  # output file from simulation
Data1 = pd.read_csv(inFile1, skiprows=[], sep='\s+')
nh = Data1['nh'].to_numpy()
nh = np.array(np.round(nh, 4))
rate = Data1['rate'].to_numpy()
index_nh_median = np.where(nh == np.round(np.median(nh), 4))
print("median_nh =", nh[index_nh_median][0],"e22 atoms/cm^-2.\nCount-rates =", rate[index_nh_median][0], "cts/s\n")
rate_corr = rate[index_nh_median]/rate    # NEED TO BE MEDIAN NH CR
rate_corr = np.array(rate_corr)
img_e22 = img / 1e22
img_e22 = np.round(img_e22, 4)
print("Relative diff to max rate=", (np.max(rate) - rate[index_nh_median]) * 100 / rate[index_nh_median], "%")
print("Relative diff to min rate=", (np.min(rate) - rate[index_nh_median]) * 100 / rate[index_nh_median], "%")

print("CORRECTING...")
@njit
def corr_map(nh_map_ine22):
    img_corr = nh_map_ine22
    for z in range(len(nh)):
        for x in range(len(nh_map_ine22)):
            for y in range(len(nh_map_ine22)):
                if nh_map_ine22[x][y] == nh[z]:
                    img_corr[x][y] = rate_corr[z]
    return img_corr

nh_corr_map = '{0}_{1}_{2}-{3}keV{4}_CORR_map.fits'.format(args.cut_nh_map, args.tm, args.low[0], args.hie[-1], suff)  # source file name.fits
print("Putting into fits...")
nh_map[0].data = corr_map(img_e22)
nh_map.writeto('{0}/{1}'.format(path, nh_corr_map))
print("{0} DONE!".format(nh_corr_map))

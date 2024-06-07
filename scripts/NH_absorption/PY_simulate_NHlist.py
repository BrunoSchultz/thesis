#!/usr/bin/env python3

import argparse
from astropy.io import fits
import numpy as np
import pandas as pd
import os, subprocess, shutil
# from numba import njit

script_version = 0.0
script_descr="""
List NH values of a given NH map and simulate them into CXB model in XSPEC via Xspec_sim.sh script."""

# Open argument parser
parser = argparse.ArgumentParser(description=script_descr)
parser.add_argument('--version',action='version',version='%(prog)s v{}'.format(script_version))

# Define expected arguments
# Mandatory
parser.add_argument('path',help='path to file')
parser.add_argument('cut_nh_map',help='The name of the cut and reprojected NH map, e.g., AIT_-600_600_cuttoA222_repr')
parser.add_argument('cluster',help='cluster name, e.g., A222')
parser.add_argument('--lo8', nargs='+', type=float, help='low E value TM8, e.g., 0.2 or 0.2 1.6')
parser.add_argument('--lo9', nargs='+', type=float, help='low E value TM9, e.g., 0.8 or 0.8 1.6')
parser.add_argument('--hi', nargs='+', type=float, help='high E value, e.g., 2.3 or 1.35 2.3')

args = parser.parse_args()
path = '{}'.format(args.path)  # path to the file
cut_nh_map = '{}.fits'.format(args.cut_nh_map)  # source file name.fits
list_nh_map = '{0}_LIST.txt'.format(args.cut_nh_map)  # list of NH value (in e22) in the observation
cluster = '{0}'.format(args.cluster)  # list of NH value (in e22) in the observation
low8 = args.lo8
low9 = args.lo9
hie = args.hi

nh_map = fits.open('{0}/{1}'.format(path, cut_nh_map))
img = nh_map[0].data    # numpy array
nh_ar = np.concatenate(img)  # get all nH values in one array

nh_ar_e22 = nh_ar / 1e22
nh_ar_e22 = np.unique(np.round(nh_ar_e22, 4))
nh_ar_e22 = nh_ar_e22[~np.isnan(nh_ar_e22)]

with open('{0}'.format(list_nh_map), 'w') as f:  # print the NHe22 in text file
    for item in nh_ar_e22:
        f.write("%s\n" % item)

print("{0} is created!\n".format(list_nh_map))

print("Running simulation for {0} NH values...".format(len(nh_ar_e22)))
print("Energy band {0}({1})-{2} keV".format(" ".join("{}".format(x) for x in low8), " ".join("{}".format(x) for x in low9), " ".join("{}".format(x) for x in hie)))

p1 = subprocess.call('./Xspec_sim.sh {0} {1} "{2}" "{3}" "{4}"'.format(list_nh_map, cluster, " ".join("{}".format(x) for x in low8), " ".join("{}".format(x) for x in low9), " ".join("{}".format(x) for x in hie)), shell=True)

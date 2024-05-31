#!/usr/bin/env python3
import argparse
from astropy.io import fits
from astropy.nddata import Cutout2D
from astropy.wcs import WCS, FITSFixedWarning
from reproject import reproject_interp

script_version = 'Feb2323'
script_descr="""
cut and reproject all-sky NH map (i.e., AIT_-600_600.fits from HI4PI paper https://ui.adsabs.harvard.edu/abs/2016A%26A...594A.116H/abstract) into the observation. Output example: AIT_-600_600_cuttoA548_repr.fits."""

# Open argument parser
parser = argparse.ArgumentParser(description=script_descr)
parser.add_argument('--version',action='version',version='%(prog)s v{}'.format(script_version))

# Define expected arguments
# Mandatory
parser.add_argument('path',help='path to file')
# parser.add_argument('nh_map',help='The name of the all-sky NH map, e.g., AIT_-600_600')
parser.add_argument('obs_name',help='The name of an observation image, e.g., c001_allobs_es201009_0BG0_CLCRBGSUB-single_0308-2keV')
parser.add_argument('cluster',help="Cluster's name")

args = parser.parse_args()
path = '{}'.format(args.path)  # path to the file
cluster = '{}'.format(args.cluster)
eROSITA_image = '{}.fits'.format(args.obs_name)  # source file name.fits
nH_map = 'AIT_-600_600.fits' # allsky NH map from HI4PI # .format(args.nh_map)
cut_repr_nh_map = 'AIT_-600_600_cutto{0}_repr.fits'.format(args.cluster)  # cut/cropped file name.fits

hdu = fits.open('/vol/erosita1/data1/averonica/SHARE/Script/{0}'.format(nH_map))[0]
hdu_eRO = fits.open('{0}/{1}'.format(path, eROSITA_image))[0]
array, footprint = reproject_interp(hdu, hdu_eRO.header)
fits.writeto('{0}/{1}'.format(path, cut_repr_nh_map ), array, hdu_eRO.header, overwrite=True)

print("DONE!")

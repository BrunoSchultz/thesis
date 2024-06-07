#!/usr/bin/env python3
import argparse
import requests
from bs4 import BeautifulSoup
from astropy import wcs
from astropy.io import fits
import numpy as np
from multiprocessing import Pool, cpu_count
from tqdm import tqdm
import math

script_version = 'Apr2624'
script_descr="""
Script to query 2NH2 weighted values from https://www.swift.ac.uk/analysis/nhtot/donhtot.php and add it with NHI map to create a NHtot map.
A. Veronica
"""
# Open argument parser
parser = argparse.ArgumentParser(description=script_descr)
parser.add_argument('--version',action='version',version='%(prog)s v{}'.format(script_version))

# Mandatory
parser.add_argument('path',help='path to file')
parser.add_argument('nh_map',help='The name of the cut and reprojected NHI map, e.g., AIT_-600_600')
parser.add_argument('cluster',help="Cluster's name")

args = parser.parse_args()
path = f'{args.path}'
fits_file = f'{path}/{args.nh_map}'
cluster = f'{args.cluster}'

x_start = 0
y_start = 0
box_size_d = 3.5 / 60  # resolution of the sampled grid in degree

# Load the FITS file
hdul = fits.open(fits_file)
hdu = hdul[0].data
prihdr = hdul[0].header
w = wcs.WCS(prihdr, relax=False)
im_size = prihdr['NAXIS1']
pixsize = prihdr['CDELT2']  # in degree
box_size = math.floor(box_size_d / pixsize)

n = math.floor(im_size/box_size)
#nh2_out = f'NH2_Willingale_{box_size}x{box_size}box'
file_out= f'NHtot_{cluster}_{box_size}x{box_size}box'

def query_nh2_weighted_value(ra_deg, dec_deg):
    url = "https://www.swift.ac.uk/analysis/nhtot/donhtot.php"
    payload = {
        "Coords": f"{ra_deg}, {dec_deg}",
        "equinox": "2000",
        "submit": "Calculate NH"
    }
    response = requests.post(url, data=payload)
    if response.ok:
        # Extract NH2 weighted value from response content
        nh2_weighted_value = extract_nh2_weighted_value(response.text)
        return nh2_weighted_value
    else:
        print("Failed to retrieve NH2 weighted value.")
        return None


def extract_nh2_weighted_value(html_content):
    # Parse the HTML content to extract NH2 weighted value
    soup = BeautifulSoup(html_content, "html.parser")
    nh2_weighted_element = soup.find("td", headers="h2w")
    if nh2_weighted_element:
        nh2_weighted_value = nh2_weighted_element.text.strip()
        # Replace '×' with 'e+'
        nh2_weighted_value = nh2_weighted_value.replace(' ×10', 'e+')
        return nh2_weighted_value
    else:
        print("NH2 weighted value not found on the page.")
        return None


ra_cen = []
dec_cen = []
x_cen = []
y_cen = []
for i in range(n):
    for j in range(n):
        pixim_ra_i, pixim_dec_i = x_start + (i+0.5)*box_size, y_start + (j+0.5)*box_size
        radec_i = w.pixel_to_world_values(pixim_ra_i, pixim_dec_i)
        #ra_i, dec_i = radec_i[0], radec_i[1]
        ra_cen.append(radec_i[0])
        dec_cen.append(radec_i[1])
        x_cen.append(pixim_ra_i)
        y_cen.append(pixim_dec_i)

print(len(x_cen))


# Define the process_pixel function
def process_pixel(coords):
    ra, dec = coords
    nh_pix = query_nh2_weighted_value(ra, dec)
    #print(ra, dec, nh_pix)
    return nh_pix


print("Getting NH2_weighted from Swift webpage...")
# Define the number of processes to be equal to the number of available CPU cores
num_processes = int(cpu_count() / 4)
print(num_processes)
# Parallelize processing of pixel coordinates
with Pool(processes=num_processes) as pool:
    # Use tqdm to create a progress bar
    with tqdm(total=len(ra_cen)) as pbar:
        nh2_ar = []
        for nh_pix in pool.imap(process_pixel, zip(ra_cen, dec_cen)):
            nh2_ar.append(nh_pix)
            pbar.update(1)

print("Done!")

hdu0 = np.copy(hdu) * 0
print("Fill the map...")
for i in range(len(x_cen)):
    x_i_min, x_i_max = x_cen[i] - box_size / 2, x_cen[i] + box_size / 2
    y_i_min, y_i_max = y_cen[i] - box_size / 2, y_cen[i] + box_size / 2
    # Fill the square region in hdu0 with the corresponding erobub_rate_soft value
    hdu0[int(y_i_min):int(y_i_max), int(x_i_min):int(x_i_max)] = nh2_ar[i]

# Save NH2 values to FITS file
print("Saving NH2 to map...")
hdul[0].data = hdu0
#hdul.writeto(f'{path}/{nh2_out}.fits', overwrite=True)
hdul[0].data = hdu0 + hdu
hdul.writeto(f'{path}/{file_out}.fits', overwrite=True)
print(f"NHtot map (HI4PI + 2NH2 weighted from Willingale method) is created\n===> {file_out}.fits")

from MyFits import *

fits = MyFits("/vol/erosita1/data1/bdarochaschultz/thesis/data/filtered/PIBsub_0.2-2.3_combinedtiles/c010_em01_NGC1550_combined_tiles_8_CLevlistBGSUB_0.2-2.3keV.fits")

fig = fits.plot()

fig.savefig('my_test_fig.pdf')

center_ra, center_dec = fits.wcs.crval

center = SkyCoord(center_ra, center_dec, unit='deg')
radius = Angle(50, 'arcminute')
region = CircleSkyRegion(center, radius)

pix_region = region.to_pixel(fits.wcs)
pix_region.visual['color'] = 'white'
pix_region.visual['linewidth'] = 0.4

fig.plot()
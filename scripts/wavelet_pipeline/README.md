# wavefilt_detection_pipeline

A collection of scripts to run the eROSITA detection pipeline based on wavelet filtering

## Using the pipeline

Although individual scripts may be used as needed, the main script ero_wavedet_pipeline
is a wrapper that will call individual subtasks in a consistent way.

Calling the script without argument will print the help, which should mostly be 
self-explanatory:

```

   Usage: ero_wavedet_pipeline dataDir PhotonImage ExpImage pipePref [Option=...]

   Positional arguments:
          dataDir         =  Main processing folder
	  PhotonImage     =  Raw photon image over which to perform detection
	  ExpImage        =  Exposure map relevant to the photon image
	  pipePref        =  Global prefix of all output files
 
   Optional wavelet arguments:
          do_wavelet      =  Whether to run the wavelet filtering (default: yes)
	  wv_thresh       =  Wavelet significance threshold  (default: "5.0,3.3,3.0,2.8")
	  wv_expThresh    =  Pixels with a lower exposure will be masked (default: 30)
	  wv_scalemin     =  Minimum significant scale (default: 2)
	  wv_scalemax     =  Maximum scale (default: all scales)
          wv_postfix      =  Postfix of wavelet filtered products
 
   Optional SExtractor arguments:
          do_secat        =  Whether to run SExtractor (default: yes)
	  se_thresh       =  Detection signal to noise threshold (default: 5.0)
	  se_deblendThr   =  Fractional flux threshold for Deblending (default: 0.002)
	  se_backSize     =  Background cell size in pixels (default: 64)
	  se_bgfiltersize =  Number of cells for background median filtering (default: 5)
          se_postfix      =  Postfix of SExtractor data products
 
   Optional background map arguments:
          do_bgmap        =  Whether to compute the background map (default: yes)
	  bg_mode         =  Background estimation mode: fit/fullfit/fixed/sextractor (default: fit) 
	  bg_Template     =  Template for additionnal background component (default: none)
          bg_postfix      =  Postfix of background data products
 
   Optional ermldet arguments:
          do_ermldet      =  Whether to run ermldet (default: yes)
          ml_shapeletpsf  =  Whether to use the shapelet PSF (default: yes)
          ml_photonmode   =  Whether to use the event based likelihood (default: yes)
          ml_extmax       =  Maximum source extent in pixels (default: 60.0)
          ml_nmaxfit      =  Maximum number of sources for joint fits (default: 1)
          ml_multrad      =  Maximum source distance for joint fits (default: 150.0)
          ml_nmulsou      =  Maximum new sources for source splitting (default: 1)
          ml_scalefactor  =  Fit radius in units of input source extent (default: 3.0)
          ml_cutrad       =  Minimum fit radius in pixels or EEF if < 1 (default: 20.0)
          ml_likemin      =  Detection likelihood threshold (default: -1)
          ml_extlikemin   =  Extention likelihood thereshold (default: -1)
          ml_nproc        =  Number of simultaneous processes (default: 1)
          ml_postfix      =  Postfix of ermldet data products

```

## Background modes

The pipeline can estimate the background in the observation, possibly adding an 
independent background contribution (e.g. known particle background) using the 
bg_Template option.

It includes 5 different background estimation modes.
 * ` fixed ` : Use the image provided with bg_Template as a background map
 * ` fit ` : Fit source free areas to the exposure map, possibly adding bg_Template
 * ` fullfit ` : Same as 'fit' but computing also a normalisation for the bg_Template  
 * ` SExtractor ` : Use the background map determined by SExtractor
 * ` IterSE ` : Run the SExtractor procedure twice to improve the wavelet filtering 

Since the wavelet code rely by default on a background disribution which follows the 
exposure map, the `fullfit` and `IterSE` will run the wavelets and SExtractor twice, 
to account for the improved background estimate in the filtering.

A background mode based on erbackmap and taking advantage of the SExtractor SEgmentation
map will be added soon (requires small changes to erbackmap first).
 
## Requirements

Requires:
* C-shell capable environment
* IDL/GDL (no specific library required, to use GDL an alias for IDL is needed)
* eSASS
* SExtractor (a Ubuntu 18 binary is included, which may be compatible with your system)

----
Contact: F. Pacaud @ Uni-Bonn

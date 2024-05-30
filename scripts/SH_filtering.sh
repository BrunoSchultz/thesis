#!/bin/bash
############################################################
# Help                                                     #
############################################################
if [[ $# -ne 7 ]] || [ $1 == '-h' ]
then
    echo "   *** eROSITA combining and flare-filtering script ***"
    echo "USAGE : $ ./Script.sh obs clus proc ra dec size FPfilt"
    echo "obs   : observation name (e.g., sm03, em01)"
    echo "clus  : cluster name (e.g., A3391)"
    echo "proc  : processing version (e.g., c946, c010, c020)"
    echo "ra    : Right Ascension (degree) of the image center"
    echo "dec   : Declination (degree) of the image center"
    echo "size  : image size in pixels (maximum is 18000)"
    echo -e "FPfilt: whether to filter light curve using Florian's flare filtering script (ero_FlareFilter.csh).\n         0 using flaregti, 1 using Florian's script"
    echo "   *** Latest version 06.04.23 @A.Veronica ***"
    echo "   *** Filtering script ero_FlareFilter.csh @F.Pacaud ***"
    echo "Print this help: $ ./Script.sh -h"
    exit
fi
############################################################
# Main                                                    #
############################################################
obs=$1
cluster=$2
procver=$3
ra=$4
dec=$5
size=$6
fpfilt=$7

timebin=20  # flaregti timebin in s

tm=({1..7})
cwd=$PWD
if [ ! -d "$cwd/log/" ]
then
    echo "Creating log directory... All log files will be here."
    mkdir log
else
    echo "log exists. Log file will be here"
fi

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>log/LOG_${procver}_${obs}_${cluster}_filtering.log 2>&1

if [ ! -d "$cwd/filtered/" ]
then
    echo "Creating filtered directory... All output will be here."
    mkdir filtered
else
    echo "filtered/ exists"
fi

ls -1 *_020_* > TM0.txt
for tile in $(cat TM0.txt)
    do
    cp ${tile} filtered/
    done
mv TM0.txt filtered/
cd filtered

if [ ${fpfilt} -eq 1 ]
then
    echo -e "CHECK if there is 'FAILED' in any processes!\n>>>>>>>>>>>>>>>>>>>>Filtering using Florian Pacaud's script!\nRe-position tiles' center..."
    for tile in $(cat TM0.txt)
        do
        radec2xy file="${tile}" ra0=${ra} dec0=${dec}
        done

    echo "Combining tiles..."
    evtool eventfiles="@TM0.txt" outfile="${procver}_${obs}_${cluster}_combined_tiles_0_CL.fits" flag=0xe00fff30 gti="GTI" pattern=15 image=yes size=${size} repair_gtis=yes

    for tile in $(cat TM0.txt)
        do
        rm ${tile}
        done

    rm TM0.txt

    echo -e "Separate TM0 to TM1 2 3 4 5 6 7\nCHECK if there are only 10 BINTABLEs corresponds to each TM"
    for i in "${!tm[@]}"
    do
        echo "************************* TM${tm[i]} *************************"
        evtool eventfiles="${procver}_${obs}_${cluster}_combined_tiles_0_CL.fits" telid="${tm[i]}" outfile="${procver}_${obs}_${cluster}_combined_tiles_${tm[i]}_CL.fits" flag=0xe00fff30 gti="GTI" pattern=15 emin=0.2 emax=10.0 image=yes size=${size} repair_gtis=yes
        fstruct ${procver}_${obs}_${cluster}_combined_tiles_${tm[i]}_CL.fits
        echo ">>>>>>>>>>Filtering..."
        /vol/erosita1/data1/eROSITA/eRoScripts/ero_FlareFilter.csh ${procver}_${obs}_${cluster}_combined_tiles_${tm[i]}_CL.fits FPfilt_${tm[i]} ${tm[i]}
        echo -e "Applying new GTIs to event file... \n\n"
        evtool eventfiles="${procver}_${obs}_${cluster}_combined_tiles_${tm[i]}_CL.fits" outfile="${procver}_${obs}_${cluster}_combined_tiles_${tm[i]}_CLfilt.fits" flag=0xe00fff30 gti=FPfilt_${tm[i]}_GTIs.fits pattern=15 emin=0.2 emax=10.0 image=yes size=${size} repair_gtis=yes
    done
    evtool eventfiles="@TM0filt.txt" outfile="${procver}_${obs}_${cluster}_combined_tiles_0_CLfilt.fits" flag=0xe00fff30 gti="GTI" pattern=15 image=yes size=${size} repair_gtis=yes
else
    echo -e ">>>>>>>>>>>>>>>>>>>>Filtering using flaregti...\n"
    sed -i 's/.fits//g' TM0.txt

    for tile in $(cat TM0.txt)
        do
        evtool eventfiles="${tile}.fits" outfile="${tile}_CL.fits" flag=0xe00fff30 gti="GTI" pattern=15 emin=0.2 emax=10.0 image=yes repair_gtis=yes
        # rerun radec2xy using tile centre
        fkeypar ${tile}_CL.fits'[EVENTS]' RA_CEN
        ra1=$(pget fkeypar value)
        fkeypar ${tile}_CL.fits'[EVENTS]' DEC_CEN
        dec1=$(pget fkeypar value)
        radec2xy ra0="$ra1" dec0="$dec1" ${tile}_CL.fits
        # run flaregti for large source size and higher grid size (as area is larger)
        flaregti ${tile}_CL.fits pimin=5000 source_size=150 gridsize=26 lightcurve=${tile}_CL_lightcurve1_${timebin}s.fits write_mask=no timebin=${timebin}
        threshold=$(../PY_lightcurve_check_temp.py . ${tile}_CL --nsigma 3.0 --timebin ${timebin})
        flaregti ${tile}_CL.fits pimin=5000 source_size=150 gridsize=26 lightcurve=${tile}_CL_lightcurve_${timebin}s.fits write_mask=no threshold=${threshold} timebin=${timebin}
        evtool eventfiles="${tile}_CL.fits" outfile="${tile}_CLfilt.fits" flag=0xe00fff30 gti="FLAREGTI" pattern=15 emin=0.2 emax=10.0 image=yes repair_gtis=yes
        done

    ls -1 *_CLfilt.fits > TM0filt.txt
    tile_listfilt=TM0filt.txt

    echo "Re-position tiles' center..."
    for tilefilt in $(cat ${tile_listfilt})
        do
        radec2xy file="${tilefilt}" ra0=${ra} dec0=${dec}
        done
    
    ls -1 *_CL.fits > TM0_1.txt
    for tilecl in $(cat TM0_1.txt)
        do
        radec2xy file="${tilecl}" ra0=${ra} dec0=${dec}
        done

    echo "Combining tiles CL.fits..."
    evtool eventfiles="@TM0_1.txt" outfile="${procver}_${obs}_${cluster}_combined_tiles_0_CL.fits" flag=0xe00fff30 gti="GTI" pattern=15 image=yes size=${size} repair_gtis=yes

    echo "Combining tiles CLfilt..."
    evtool eventfiles="@${tile_listfilt}" outfile="${procver}_${obs}_${cluster}_combined_tiles_0_CLfilt.fits" flag=0xe00fff30 gti="FLAREGTI" pattern=15 emin=0.2 emax=10.0 image=yes size=${size} repair_gtis=yes
    
    for tile in $(cat TM0.txt)
        do
        rm ${tile}.fits ${tile}_CL.fits ${tile}_CLfilt.fits
        done

    echo -e "Separate TM0 to TM1 2 3 4 5 6 7\nCHECK if there are only 10 BINTABLEs corresponds to each TM"
    for i in "${!tm[@]}"
        do
        echo "************************* TM${tm[i]} *************************"
        evtool eventfiles="${procver}_${obs}_${cluster}_combined_tiles_0_CLfilt.fits" telid="${tm[i]}" outfile="${procver}_${obs}_${cluster}_combined_tiles_${tm[i]}_CLfilt.fits" flag=0xe00fff30 gti="FLAREGTI" pattern=15 emin=0.2 emax=10.0 image=yes size=${size} repair_gtis=yes
        fstruct ${procver}_${obs}_${cluster}_combined_tiles_${tm[i]}_CLfilt.fits
        done
        
    rm TM0*.txt

    if [ ! -d "$cwd/filtered/lightcurve/" ]
    then
        echo "Creating lightcurve/ directory..."
        mkdir lightcurve
    else
        echo "lightcurve/ exists"
    fi

    mv PLT_* *lightcurve*fits lightcurve/

    echo "DONE!"
fi

OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_0_CLfilt.fits" emin=0.2 emax=10.0 templateimage="${procver}_${obs}_${cluster}_combined_tiles_0_CLfilt.fits" mergedmaps="${procver}_${obs}_${cluster}_combined_tiles_0_CLfiltexpmap.fits" gtitype=FLAREGTI withdetmaps=yes

OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_0_CL.fits" emin=0.2 emax=10.0 templateimage="${procver}_${obs}_${cluster}_combined_tiles_0_CL.fits" mergedmaps="${procver}_${obs}_${cluster}_combined_tiles_0_CLexpmap.fits" gtitype=GTI withdetmaps=yes

echo -e "\nHard-band images..."
hard_min=(5.0)
hard_max=(10.0)
for i in "${!hard_min[@]}"
    do
    echo -e "${hard_min[i]}-${hard_max[i]} keV\nCL: evtool"
    evtool eventfiles="${procver}_${obs}_${cluster}_combined_tiles_0_CLfilt.fits" outfile="${procver}_${obs}_${cluster}_combined_tiles_0_CLfilt_${hard_min[i]}-${hard_max[i]}keV.fits" flag=0xe00fff30 gti="FLAREGTI" pattern=15 emin=${hard_min[i]} emax=${hard_max[i]} image=yes size=${size} repair_gtis=yes
    evtool eventfiles="${procver}_${obs}_${cluster}_combined_tiles_0_CL.fits" outfile="${procver}_${obs}_${cluster}_combined_tiles_0_CL_${hard_min[i]}-${hard_max[i]}keV.fits" flag=0xe00fff30 gti="GTI" pattern=15 emin=${hard_min[i]} emax=${hard_max[i]} image=yes size=${size} repair_gtis=yes
    echo -e "\n******************expmap******************"
    OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_0_CLfilt_${hard_min[i]}-${hard_max[i]}keV.fits" emin=${hard_min[i]} emax=${hard_max[i]} templateimage="${procver}_${obs}_${cluster}_combined_tiles_0_CLfilt_${hard_min[i]}-${hard_max[i]}keV.fits" mergedmaps="${procver}_${obs}_${cluster}_combined_tiles_0_CLfiltexpmap_${hard_min[i]}-${hard_max[i]}keV.fits" gtitype=FLAREGTI withdetmaps=yes
    OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_0_CL_${hard_min[i]}-${hard_max[i]}keV.fits" emin=${hard_min[i]} emax=${hard_max[i]} templateimage="${procver}_${obs}_${cluster}_combined_tiles_0_CL_${hard_min[i]}-${hard_max[i]}keV.fits" mergedmaps="${procver}_${obs}_${cluster}_combined_tiles_0_CLexpmap_${hard_min[i]}-${hard_max[i]}keV.fits" gtitype=GTI withdetmaps=yes
    echo -e "\n******************CR-map******************"
    farith ${procver}_${obs}_${cluster}_combined_tiles_0_CLfilt_${hard_min[i]}-${hard_max[i]}keV.fits ${procver}_${obs}_${cluster}_combined_tiles_0_CLfiltexpmap_${hard_min[i]}-${hard_max[i]}keV.fits ${procver}_${obs}_${cluster}_combined_tiles_0_CLfiltCR_${hard_min[i]}-${hard_max[i]}keV.fits DIV blank=0 clobber=yes
    farith ${procver}_${obs}_${cluster}_combined_tiles_0_CL_${hard_min[i]}-${hard_max[i]}keV.fits ${procver}_${obs}_${cluster}_combined_tiles_0_CLexpmap_${hard_min[i]}-${hard_max[i]}keV.fits ${procver}_${obs}_${cluster}_combined_tiles_0_CLCR_${hard_min[i]}-${hard_max[i]}keV.fits DIV blank=0 clobber=yes
    echo -e "\n******************Exposure Lost******************"
    exp=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_0_CLexpmap_${hard_min[i]}-${hard_max[i]}keV.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
    expf=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_0_CLfiltexpmap_${hard_min[i]}-${hard_max[i]}keV.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
    diff=$(awk "BEGIN {printf \"%.7f\n\", (${expf} - ${exp}) * 100 / ${exp}}")
    echo "Exposure lost/gain = ${diff}%"
    done
echo "DONE!"

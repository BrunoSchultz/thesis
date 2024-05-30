#!/bin/bash
############################################################
# Help                                                     #
############################################################
if [[ $# -ne 9 ]] || [ $1 == '-h' ]
then
    echo "   *** Image generation script ***"
    echo "Print this help: $ ./Script.sh -h"
    echo "USAGE : $ ./Script.sh obs tm clus proc size lowE hiE fpfilt abslo"
    echo "obs   : observation name (e.g., sm03, em01)"
    echo "tm    : TM (between 1-7)"
    echo "clus  : cluster name (e.g., A3391)"
    echo "proc  : processing version (e.g., c946, c010, c020)"
    echo "size  : size of the image in pixels unit"
    echo "lowE  : lower energy limit used for each TM. Also accept an array of 2 (e.g., 0.2 or "0.2 1.6" for TM8 or "0.8 1.6" for TM9)"
    echo "hiE   : high energy limit of both TM types. Also accept an array of 2 (e.g., 2.3 or "1.35 2.3")"
    echo -e "FPfilt: whether the parent files were filtered using Florian's flare filtering script (ero_FlareFilter.csh).\n         0 using flaregti, 1 using Florian's script"
    echo "abslo   : absolute lowest energy limit (typically the value from lower limit from on-chip TMs, e.g., 0.2)"
    echo "   *** Latest version 06.04.23 @A.Veronica ***"
    exit
fi
############################################################
# Main                                                    #
############################################################
obs=$1
TM=$2
cluster=$3
procver=$4
size=$5
lowe=( $6 )
hie=( $7 )
fpfilt=$8
abslo=$9

if [ ${fpfilt} -eq 1 ]
then
    gtiext=GTI
else
    gtiext=FLAREGTI
fi

if [[ ${#lowe[@]} == 1 ]]
then
    suff=""
else
    suff="_uni"
    echo "===> Files of the union of the two sub-bands end with *_uni* "
fi

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>log/LOG_${procver}_${obs}_${cluster}_${TM}_${lowe[0]}-${hie[-1]}keV${suff}_prep.log 2>&1

cwd=$PWD
cwdf=$cwd/filtered
cd $cwdf
if [ ! -d "$cwdf/PIBsub_${abslo}-${hie[-1]}${suff}_combinedtiles/" ]
then
    echo "Creating PIBsub_${abslo}-${hie[-1]}${suff}_combinedtiles directory... All output will be here."
    mkdir PIBsub_${abslo}-${hie[-1]}${suff}_combinedtiles
else
    echo "PIBsub_${abslo}-${hie[-1]}${suff}_combinedtiles exists"
fi

cp *_${TM}_CLfilt.fits PIBsub_${abslo}-${hie[-1]}${suff}_combinedtiles/
cd $cwdf/PIBsub_${abslo}-${hie[-1]}${suff}_combinedtiles

echo -e "\nRe-sizing event list in hard-bands keV for TM${TM}..."
hard_min=(6.0 5.5 6.7)
hard_max=(9.0 6.15 9.0)
for i in "${!hard_min[@]}"
do
    echo -e "\n${hard_min[i]}-${hard_max[i]}keV"
    evtool eventfiles="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLfilt.fits" outfile="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${hard_min[i]}-${hard_max[i]}keV.fits" flag=0xe00fff30 gti="${gtiext}" pattern=15 emin=${hard_min[i]} emax=${hard_max[i]} image=yes size=${size} repair_gtis=yes
done

echo -e "\nRe-sizing event list in (${lowe[*]})-(${hie[*]}) keV for TM${TM}..."
evtool eventfiles="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLfilt.fits" outfile="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits" flag=0xe00fff30 gti="${gtiext}" pattern=15 emin="${lowe[*]}" emax="${hie[*]}" image=yes size=${size} repair_gtis=yes

if [[ ${#lowe[@]} == 2 ]]
then
    echo -e "\nRe-sizing event list in full continuous ${lowe[0]}-${hie[-1]} keV for TM${TM}..."
    evtool eventfiles="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLfilt.fits" outfile="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV.fits" flag=0xe00fff30 gti="${gtiext}" pattern=15 emin="${lowe[0]}" emax="${hie[-1]}" image=yes size=${size} repair_gtis=yes
fi

rm *_${TM}_CLfilt.fits

if [[ ${#lowe[@]} == 1 ]]
then
    echo -e "\nRe-sizing expmap in ${lowe[*]}-${hie[*]} keV for TM${TM}..."
    OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits" emin="${lowe[*]}" emax="${hie[*]}" templateimage="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits" mergedmaps="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits" gtitype=${gtiext} withdetmaps=yes
    echo -e "\nRe-sizing expmap-SINGLE in ${lowe[*]}-${hie[*]} keV for TM${TM}..."
    OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits" emin="${lowe[*]}" emax="${hie[*]}" templateimage="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits" singlemaps="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits" gtitype=${gtiext} withdetmaps=yes withmergedmaps=NO withsinglemaps=YES
    echo -e "\nFlat exposure map TM${TM}..."
    OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits" emin="${lowe[*]}" emax="${hie[*]}" templateimage="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits" mergedmaps="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits" gtitype=${gtiext} withdetmaps=yes withvignetting=no
    OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits" emin="${lowe[*]}" emax="${hie[*]}" templateimage="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits" singlemaps="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLexpmap-single_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits" gtitype=${gtiext} withdetmaps=yes withvignetting=no withmergedmaps=NO withsinglemaps=YES
else
    echo -e "\nRe-sizing expmap in full ${lowe[0]} - ${hie[-1]} keV band for TM${TM}.\n*${suff}* is used for file name suffix..."
    OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV.fits" emin="${lowe[0]}" emax="${hie[-1]}" templateimage="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV.fits" mergedmaps="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits" gtitype=${gtiext} withdetmaps=yes
    echo -e "\nRe-sizing expmap-SINGLE in ${lowe[*]}-${hie[*]} keV for TM${TM}..."
    OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV.fits" emin="${lowe[0]}" emax="${hie[-1]}" templateimage="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV.fits" singlemaps="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits" gtitype=${gtiext} withdetmaps=yes withmergedmaps=NO withsinglemaps=YES
    echo -e "\nFlat exposure map TM${TM}..."
    OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV.fits" emin="${lowe[0]}" emax="${hie[-1]}" templateimage="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV.fits" mergedmaps="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits" gtitype=${gtiext} withdetmaps=yes withvignetting=no
    OMP_NUM_THREADS=10 expmap inputdatasets="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV.fits" emin="${lowe[0]}" emax="${hie[-1]}" templateimage="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLevlist_${lowe[0]}-${hie[-1]}keV.fits" singlemaps="${procver}_${obs}_${cluster}_combined_tiles_${TM}_CLexpmap-single_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits" gtitype=${gtiext} withdetmaps=yes withvignetting=no withmergedmaps=NO withsinglemaps=YES
fi

echo "DONE!"

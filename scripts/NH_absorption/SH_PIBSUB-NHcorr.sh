#!/bin/bash
############################################################
# Help                                                     #
############################################################
if [[ $# -ne 8 ]] || [ $1 == '-h' ]
then
    echo "   *** NHcorr & PIBSub Script ***"
    echo "USAGE: $ ./Script.sh obs clus proc lowE8 lowE9 hiE nhcormap1 nhcormap5"
    echo "obs: observation name (e.g., sm03, em01)"
    echo "cluster: cluster name (e.g., A3391)"
    echo "proc: processing version (e.g., c946, c010, c020)"
    echo "lowE8: lower energy limit used for TM8 (e.g., 0.2)"
    echo "lowE9: lower energy limit used for TM9 (e.g., 0.8)"
    echo "hiE: high energy limit of both TM types (e.g., 2.3)"
    echo "nhcormap1: NH correction factor map using on-chip filter response files (TM1) (e.g., AIT_-600_600_cuttoA3391_repr_TM1_0.2-2.3keV_CORR_map)"
    echo "nhcormap5: NH correction factor map using no on-chip filter response files (TM5) (e.g., AIT_-600_600_cuttoA3391_repr_TM5_0.8-2.3keV_CORR_map)"
    echo "   *** Latest version 23.02.23 @A.Veronica ***"
    echo "Print this help: $ ./Script.sh -h"
    exit
fi
############################################################
# Main                                                    #
############################################################
obs=$1
cluster=$2
procver=$3
lowe=( $4 )
lowe9=( $5 )
hie=( $6 )
nhcorrmaptm1=$7
nhcorrmaptm5=$8

cwd=$PWD
if [ ! -d "$cwd/log/" ]
then
    echo "Creating log directory... All log files will be here."
    mkdir log
else
    echo "log file will be at log/ dir."
fi

if [[ ${#lowe[@]} == 1 ]]
then
    suff=""
else
    suff="_uni"
fi

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>log/LOG_${procver}_${obs}_${cluster}_${lowe[0]}-${hie[-1]}keV${suff}_PIBSUB_expoNHcorr.log 2>&1

cd $cwd/filtered/PIBsub_${lowe[0]}-${hie[-1]}${suff}_combinedtiles

echo -e "\nCreating NHcorr exposure map: TM8"
farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${nhcorrmaptm1}.fits ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr.fits DIV blank=0 clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${nhcorrmaptm1}.fits ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr.fits DIV blank=0 clobber=yes

echo -e "\nCreating NHcorr exposure map: TM9"
farith ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${nhcorrmaptm5}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr.fits DIV blank=0 clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${nhcorrmaptm5}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr.fits DIV blank=0 clobber=yes

echo -e "\nCalculating correction factor for exposuremap-NHcorr TM9..."
totevBGSUB8=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_8_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totevBGSUB9=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_9_CLevlistBGSUB_${lowe9[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totexp8=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totexp9=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
corr=$(awk "BEGIN {printf \"%.7f\n\", ($totevBGSUB9 / $totevBGSUB8) * ($totexp8 / $totexp9)}")
echo "total counts in CLevlistBGSUB_8: ${totevBGSUB8}"
echo "total counts in CLevlistBGSUB_9: ${totevBGSUB9}"
echo "total exposure in CLexp_8_NHcorr: ${totexp8}"
echo "total exposure in CLexp_9_NHcorr: ${totexp9}"
echo "correction factor (count-rate_9/count-rate_8): ${corr}"

echo "Correcting ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits..."
fcarith ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr.fits ${corr} ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits MUL clobber=yes
echo "===> ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits is created!"

farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits ADD clobber=yes
echo "===> corrected TM0 expoosure mape ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits is created!"

echo "PIB-subtracted, exposure corrected, all TMs combined in ${lowe[0]}-${hie[-1]}${suff} keV with seven on-chip TM's effective area:"
farith ${procver}_${obs}_${cluster}_combined_tiles_0_CLevlistBGSUB_${lowe}${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLCRBGSUB_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits DIV clobber=yes blank=0
echo "===> ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLCRBGSUB_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits is created!"

echo -e "\nCalculating correction factor for exposuremap-single_NHcorr TM9..."
totevBGSUB8=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_8_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totevBGSUB9=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_9_CLevlistBGSUB_${lowe9[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totexps8=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totexps9=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
corrs=$(awk "BEGIN {printf \"%.7f\n\", ($totevBGSUB9 / $totevBGSUB8) * ($totexps8 / $totexps9)}")
echo "total counts in CLevlistBGSUB_8: ${totevBGSUB8}"
echo "total counts in CLevlistBGSUB_9: ${totevBGSUB9}"
echo "total exposure in CLexp_8_NHcorr: ${totexps8}"
echo "total exposure in CLexp_9_NHcorr: ${totexps9}"
echo "correction factor (count-rate_9/count-rate_8): ${corrs}"

echo "Correcting ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr.fits..."
fcarith ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr.fits ${corrs} ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits MUL clobber=yes
echo "===> ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits is created!"

farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits ADD clobber=yes
echo "===> corrected TM0 expoosure mape ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits is created!"

echo "PIB-subtracted, exposure corrected, all TMs combined in ${lowe[0]}-${hie[-1]}${suff} keV with one single on-chip TM's effective area:"
farith ${procver}_${obs}_${cluster}_combined_tiles_0_CLevlistBGSUB_${lowe}${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLCRBGSUB-single_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits DIV clobber=yes blank=0
echo "===> ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLCRBGSUB-single_${lowe[0]}-${hie[-1]}keV${suff}_NHcorr_corr.fits is created!"

echo "Done!"

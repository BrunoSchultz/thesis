#!/bin/bash
############################################################
# Help                                                     #
############################################################
if [[ $# -le 5 ]] || [[ $# -ge 8 ]] || [ $1 == '-h' ]
then
    echo "   *** PIBSub Script ***"
    echo "USAGE: $ ./SH_PIBSUB.sh obs clus proc lowE8 lowE9 hiE [FWCproc]"
    echo "obs: observation name (e.g., sm03, em01)"
    echo "cluster: cluster name (e.g., A3391)"
    echo "proc: processing version (e.g., c946, c010, c020)"
    echo "lowE8: lower energy limit used for TM8. Also accept an array of 2 (e.g., 0.2 or "0.2 1.5")"
    echo "lowE9: lower energy limit used for TM9. Also accept an array of 2 (e.g., 0.8 or "0.8 1.5")"
    echo "hiE: high energy limit of both TM types. Also accept an array of 2 (e.g., 2.3 or "1.3 2.3")"
    echo "[FWCproc]: FWC processing version optional. If not specified, the processing version will be set as default."
    echo "   *** Latest version 11.04.23 @A.Veronica ***"
    echo "   *** compute FWC ratio script cmp_FWCratio.csh @F.Pacaud ***"
    echo "Print this help: $ ./SH_PIBSUB.sh -h"
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

if [[ $# == 6 ]]
then
    fwcproc=$3
else
    fwcproc=$7
fi

tm=({1..7})
lowe_ar=("${lowe[*]}" "${lowe[*]}" "${lowe[*]}" "${lowe[*]}" "${lowe9[*]}" "${lowe[*]}" "${lowe9[*]}")
lowe_ar_min=(${lowe[0]} ${lowe[0]} ${lowe[0]} ${lowe[0]} ${lowe9[0]} ${lowe[0]} ${lowe9[0]})

if [[ ${#lowe[@]} == 1 ]]
then
    suff=""
else
    suff="_uni"
fi

cwd=$PWD
if [ ! -d "$cwd/log/" ]
then
    echo "Creating log directory... All log files will be here."
    mkdir log
else
    echo "log file will be at log/ dir."
fi

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>log/LOG_${procver}_${obs}_${cluster}_${lowe[0]}-${hie[-1]}keV${suff}_PIBSUB_expocorr.log 2>&1

cd $cwd/filtered/PIBsub_${lowe[0]}-${hie[-1]}${suff}_combinedtiles

echo -e "\nCombining TM8 (image only)..."
farith ${procver}_${obs}_${cluster}_combined_tiles_1_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_2_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_12_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_12_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_3_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_123_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_123_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_4_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_1234_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_1234_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_6_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_8_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_1_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_2_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_12_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_12_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_3_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_123_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_123_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_4_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_1234_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_1234_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_6_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_1_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_2_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_12_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_12_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_3_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_123_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_123_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_4_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_1234_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_1234_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_6_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap_novign_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_1_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_2_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_12_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_12_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_3_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_123_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_123_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_4_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_1234_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_1234_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_6_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes
rm ${procver}_${obs}_${cluster}_combined_tiles_12*${suff}.fits

echo -e "\nCombining TM9 (image only)..."
farith ${procver}_${obs}_${cluster}_combined_tiles_5_CLevlist_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_7_CLevlist_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLevlist_${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_5_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_7_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_5_CLexpmap_novign_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_7_CLexpmap_novign_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_novign_${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_5_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_7_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

echo -e "\nCombining TM8+TM9=TM0 (image only)...\n"
farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLevlist_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLevlist_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_0_CLevlist_${lowe[0]}${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_0_CLexpmap_${lowe[0]}${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_0_CLexpmap-single_${lowe[0]}${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

# FWC ratio (R) in lowe(lowe9)-hie keV/6.7-9.0 keV
echo "FWC ratio values (FWC type used: ${fwcproc})"
fwcrat=()
for j in "${!tm[@]}"
do
    fwcrat+=($(csh -f /vol/erosita1/data1/eROSITA/public/eRoScripts "${lowe_ar[j]}" "${hie[*]}" $[j+1] proc=${fwcproc} refEmin=6.7 refEmax=9.0))
done
echo -e "${fwcrat[0]}\n${fwcrat[1]}\n${fwcrat[2]}\n${fwcrat[3]}\n${fwcrat[4]}\n${fwcrat[5]}\n${fwcrat[6]}"

echo "Unvignetted values"
tot_unvig=()
for i in "${!tm[@]}"
do
    tot_unvig+=($(ftstat ${procver}_${obs}_${cluster}_combined_tiles_$[i+1]_CLexpmap_novign_${lowe_ar_min[i]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}'))
done
echo -e "${tot_unvig[0]}\n${tot_unvig[1]}\n${tot_unvig[2]}\n${tot_unvig[3]}\n${tot_unvig[4]}\n${tot_unvig[5]}\n${tot_unvig[6]}\n"

echo "Hard count (6.7-9.0 keV) values"
hard=()
for i in "${!tm[@]}"
do
    hard+=($(ftstat ${procver}_${obs}_${cluster}_combined_tiles_$[i+1]_CLevlist_6.7-9.0keV.fits > /dev/null && pget ftstat sum | awk '{print $1}'))
done
echo -e "${hard[0]}\n${hard[1]}\n${hard[2]}\n${hard[3]}\n${hard[4]}\n${hard[5]}\n${hard[6]}\n"

hr=()
for i in "${!tm[@]}"
do
    hr+=($(awk "BEGIN {printf \"%.7f\n\", ${hard[i]} * ${fwcrat[i]}}"))
done
echo -e "Calculated PIB counts of the observation in ${lowe[0]}(${lowe9[0]})-${hie[-1]}${suff} keV band:\n${hr[0]}\n${hr[1]}\n${hr[2]}\n${hr[3]}\n${hr[4]}\n${hr[5]}\n${hr[6]}"

echo -e "\nCreating PIB maps (CLBGmap.fits) and PIB subtracted photon maps (CLevlistBGSUB)..."
for i in "${!tm[@]}"
do
    fcarith ${procver}_${obs}_${cluster}_combined_tiles_$[i+1]_CLexpmap_novign_${lowe_ar_min[i]}-${hie[-1]}keV${suff}.fits ${tot_unvig[i]} ${procver}_${obs}_${cluster}_combined_tiles_$[i+1]_CLexpmap_novign_${lowe_ar_min[i]}-${hie[-1]}keV${suff}_renorm.fits DIV clobber=yes
    fcarith ${procver}_${obs}_${cluster}_combined_tiles_$[i+1]_CLexpmap_novign_${lowe_ar_min[i]}-${hie[-1]}keV${suff}_renorm.fits ${hr[i]} ${procver}_${obs}_${cluster}_combined_tiles_$[i+1]_CLBGmap_${lowe_ar_min[i]}-${hie[-1]}keV${suff}.fits MUL clobber=yes datatype=float
    farith ${procver}_${obs}_${cluster}_combined_tiles_$[i+1]_CLevlist_${lowe_ar_min[i]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_$[i+1]_CLBGmap_${lowe_ar_min[i]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_$[i+1]_CLevlistBGSUB_${lowe_ar_min[i]}-${hie[-1]}keV${suff}.fits SUB clobber=yes
done

echo "CHECK: Sum of renormed CLexpmap_novign should ~1!"
for i in "${!tm[@]}"
do
    echo "TM$[i+1]: $(ftstat infile=${procver}_${obs}_${cluster}_combined_tiles_$[i+1]_CLexpmap_novign_${lowe_ar_min[i]}-${hie[-1]}keV${suff}_renorm.fits > /dev/null && pget ftstat sum)"
done

echo "Combine BGSUB products of all TMs..."
farith ${procver}_${obs}_${cluster}_combined_tiles_5_CLevlistBGSUB_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_7_CLevlistBGSUB_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLevlistBGSUB_${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_5_CLBGmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_7_CLBGmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLBGmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

farith ${procver}_${obs}_${cluster}_combined_tiles_1_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_2_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_12_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_12_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_3_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_123_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_123_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_4_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_1234_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_1234_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_6_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_8_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes
farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLevlistBGSUB_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_0_CLevlistBGSUB_${lowe[0]}${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes
echo "===> ${procver}_${obs}_${cluster}_combined_tiles_0_CLevlistBGSUB_${lowe[0]}${lowe9[0]}-${hie[-1]}keV${suff}.fits is created!"

farith ${procver}_${obs}_${cluster}_combined_tiles_1_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_2_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_12_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_12_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_3_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_123_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_123_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_4_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_1234_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes && farith ${procver}_${obs}_${cluster}_combined_tiles_1234_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_6_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_8_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes
farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLBGmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLBGmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_0_CLBGmap_${lowe[0]}${lowe9[0]}-${hie[-1]}keV${suff}.fits ADD clobber=yes

rm ${procver}_${obs}_${cluster}_combined_tiles_12*.fits

echo "===> ${procver}_${obs}_${cluster}_combined_tiles_0_CLBGmap_${lowe[0]}${lowe9[0]}-${hie[-1]}keV${suff}.fits is created!"

echo -e "\nCalculating correction factor for exposuremap TM9..."
totevBGSUB8=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_8_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totevBGSUB9=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_9_CLevlistBGSUB_${lowe9[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totexp8=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totexp9=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
corr=$(awk "BEGIN {printf \"%.7f\n\", ($totevBGSUB9 / $totevBGSUB8) * ($totexp8 / $totexp9)}")
echo "total counts in CLevlistBGSUB_8: ${totevBGSUB8}"
echo "total counts in CLevlistBGSUB_9: ${totevBGSUB9}"
echo "total exposure in CLexp_8: ${totexp8}"
echo "total exposure in CLexp_9: ${totexp9}"
echo "correction factor (count-rate_9/count-rate_8): ${corr}"

echo "Correcting ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits..."
fcarith ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${corr} ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}_corr.fits MUL clobber=yes
echo "===> ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}_corr.fits is created!"

farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap_${lowe9[0]}-${hie[-1]}keV${suff}_corr.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}_corr.fits ADD clobber=yes
echo "===> corrected TM0 expoosure mape ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}_corr.fits is created!"

echo "PIB-subtracted, exposure corrected, all TMs combined in ${lowe[0]}-${hie[-1]} keV with seven on-chip TM's effective area:"
farith ${procver}_${obs}_${cluster}_combined_tiles_0_CLevlistBGSUB_${lowe[0]}${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap_${lowe[0]}-${hie[-1]}keV${suff}_corr.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLCRBGSUB_${lowe[0]}-${hie[-1]}keV${suff}_corr.fits DIV clobber=yes blank=0
echo "===> ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLCRBGSUB_${lowe[0]}-${hie[-1]}keV${suff}_corr.fits is created!"

echo -e "\nCalculating correction factor for exposuremap-single TM9..."
totevBGSUB8=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_8_CLevlistBGSUB_${lowe[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totevBGSUB9=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_9_CLevlistBGSUB_${lowe9[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totexps8=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
totexps9=$(ftstat ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}.fits > /dev/null && pget ftstat sum | awk '{printf "%.5f\n", $1}')
corrs=$(awk "BEGIN {printf \"%.7f\n\", ($totevBGSUB9 / $totevBGSUB8) * ($totexps8 / $totexps9)}")
echo "total counts in CLevlistBGSUB_8: ${totevBGSUB8}"
echo "total counts in CLevlistBGSUB_9: ${totevBGSUB9}"
echo "total exposure in CLexp_8: ${totexps8}"
echo "total exposure in CLexp_9: ${totexps9}"
echo "correction factor (count-rate_9/count-rate_8): ${corrs}"

echo "Correcting ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}.fits..."
fcarith ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}.fits ${corrs} ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}_corr.fits MUL clobber=yes
echo "===> ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}_corr.fits is created!"

farith ${procver}_${obs}_${cluster}_combined_tiles_8_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_9_CLexpmap-single_${lowe9[0]}-${hie[-1]}keV${suff}_corr.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}_corr.fits ADD clobber=yes
echo "===> corrected TM0 expoosure mape ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}_corr.fits is created!"

echo "PIB-subtracted, exposure corrected, all TMs combined in ${lowe[0]}-${hie[-1]} keV with one single on-chip TM's effective area:"
farith ${procver}_${obs}_${cluster}_combined_tiles_0_CLevlistBGSUB_${lowe[0]}${lowe9[0]}-${hie[-1]}keV${suff}.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLexpmap-single_${lowe[0]}-${hie[-1]}keV${suff}_corr.fits ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLCRBGSUB-single_${lowe[0]}-${hie[-1]}keV${suff}_corr.fits DIV clobber=yes blank=0
echo "===> ${procver}_${obs}_${cluster}_combined_tiles_0BG0_CLCRBGSUB-single_${lowe[0]}-${hie[-1]}keV${suff}_corr.fits is created!"

# FWC ratio (R) in lowe(lowe9)-hie keV/Hfull or H1 checks
hard_min=(6.0 5.5)
hard_max=(9.0 6.15)
hname=(Hfull H1)
echo -e "\n\n===> Comparing different hard bands for calculating PIB counts in ${lowe[0]}(${lowe9[0]})-${hie[-1]}${suff} keV <=== \n Consult if the relative differences are too large!"
for i in "${!hard_min[@]}"
do
    echo "FWC ratio values (reference hard band: ${hard_min[i]}-${hard_max[i]} keV (${hname[i]})) (FWC type used: ${fwcproc})"
    fwcrath=()
    for j in "${!tm[@]}"
    do
        fwcrath+=($(csh -f /vol/erosita1/data1/eROSITA/public/eRoScripts "${lowe_ar[j]}" "${hie[*]}" $[j+1] proc=${fwcproc} refEmin=${hard_min[i]} refEmax=${hard_max[i]}))
    done
    echo -e "${fwcrath[0]}\n${fwcrath[1]}\n${fwcrath[2]}\n${fwcrath[3]}\n${fwcrath[4]}\n${fwcrath[5]}\n${fwcrath[6]}"


    echo "hard count (${hard_min[i]}-${hard_max[i]} keV) values"
    hardh_ar=()
    for j in "${!tm[@]}"
    do
        hardh_ar+=($(ftstat ${procver}_${obs}_${cluster}_combined_tiles_$[j+1]_CLevlist_${hard_min[i]}-${hard_max[i]}keV.fits > /dev/null && pget ftstat sum | awk '{print $1}'))
    done
    echo -e "${hardh_ar[0]}\n${hardh_ar[1]}\n${hardh_ar[2]}\n${hardh_ar[3]}\n${hardh_ar[4]}\n${hardh_ar[5]}\n${hardh_ar[6]}"

    hrh_ar=()
    for j in "${!tm[@]}"
    do
        hrh_ar+=($(awk "BEGIN {printf \"%.5f\n\", ${hardh_ar[j]} * ${fwcrath[j]}}"))
    done
    echo -e "Calculated PIB counts of the observation in ${lowe[0]}(${lowe9})-${hie} keV band (${hname[i]})):\n${hrh_ar[0]}\n${hrh_ar[1]}\n${hrh_ar[2]}\n${hrh_ar[3]}\n${hrh_ar[4]}\n${hrh_ar[5]}\n${hrh_ar[6]}"
    
    reldif_ar=()
    for j in "${!tm[@]}"
    do
        reldif_ar+=($(awk "BEGIN {printf \"%.5f\n\", ( ${hrh_ar[j]} - ${hr[j]} ) * 100 / ${hr[j]} } "))
    done
    echo -e "===> Relative difference to 6.7-9.0 keV band [%]: ${reldif_ar[0]} ${reldif_ar[1]} ${reldif_ar[2]} ${reldif_ar[3]} ${reldif_ar[4]} ${reldif_ar[5]} ${reldif_ar[6]}\n"
done
echo "Done!"

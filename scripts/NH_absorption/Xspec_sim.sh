#!/bin/bash

nh_list="$1"
cluster=$2
low8=( $3 )
low9=( $4 )
hie=( $5 )  # high energy limit
declare -a tms=(1 5)  # TMs
declare -a band=("${low8[*]}" "${low9[*]}")  # low energy limit TM8 TM9

if [[ ${#hie[@]} == 1 ]]
then
    suff=""
else
    suff="_uni"
fi

# Create Xspec Script, v1: statistics chi2, counting statistic=no, no fitting
echo "model apec + TBabs*(apec + pow)"
echo "Abundance table: Asplund"
for i in "${!tms[@]}"
do
  echo "Simulating NH values for TM${tms[i]}. Will take a while..."
  for nh in $(cat ${nh_list})
  do
    XsScript="XSPEC_SIM_TM${tms[i]}_${nh}_${cluster}_${band[$i]%% *}-${hie[-1]}keV${suff}_v1.xcm"
    XsLog="XSPEC_SIM_TM${tms[i]}_${nh}_${cluster}_${band[$i]%% *}-${hie[-1]}keV${suff}_v1.log"

    echo  > $XsScript
    echo "# Main settings" >> $XsScript
    echo "query yes" >> $XsScript
    echo "xsect bcmc" >> $XsScript
    echo "abund aspl" >> $XsScript
    echo "statistic chi2" >> $XsScript
    echo "cosmo 70 0 0.70" >> $XsScript
    echo "xset delta 0.01" >> $XsScript
    echo "systematic 0" >> $XsScript
    echo  >> $XsScript

    echo "" >> $XsScript
    echo "# Define model" >> $XsScript
    echo "mo apec + TBabs*(apec + pow) & 0.099 & 1.0 & 0.0 & 0.0019 & ${nh} & 0.225 & 1.0 & 0.0 & 0.0041 & 1.4 & 0.0036" >> $XsScript
    echo "fakeit none & c001_300016_es201009_f_BGNONE_TM${tms[i]}_an3-A3391_${tms[i]}20_RMF_00001.fits & c001_300016_es201009_f_BGNONE_TM${tms[i]}_an3-A3391_${tms[i]}20_ARF_00001.fits & n & & XSPEC_SIM_TM${tms[i]}_${nh}_v1.fak & 2500" >> $XsScript
    echo "" >>  $XsScript
    
    if [[ ${#hie[@]} == 1 ]]
    then
        echo "ign *:**-${band[$i]} ${hie[-1]}-**" >>  $XsScript
    else
        echo "ign *:**-${band[$i]%% *} ${hie[0]}-**" >>  $XsScript
        # echo "notice *:${hie[0]}-**" >>  $XsScript
        bandi=(${band[$i]})
        sublow2=${bandi[1]}
        echo "notice ${sublow2}-${hie[1]}" >>  $XsScript
    fi
    echo "" >>  $XsScript

    #echo "# Plot best fit" >> $XsScript
    #echo "cpd XSPEC_SIM_TM${tms[i]}_${nh}_${band[$i]%% *}-${hie[-1]}keV${suff}_EPS_v1.eps/CPS" >>  $XsScript
    #echo "setplot energy"  >> $XsScript
    #echo "plot ldata delchi" >> $XsScript
    #echo "cpd none" >>  $XsScript
    #echo "" >>  $XsScript

    echo "# GET NH" >>  $XsScript
    echo "tclout param 5" >>  $XsScript
    echo 'set nh [lindex $xspec_tclout 0]' >>  $XsScript
    echo "" >>  $XsScript

    echo "# GET RATE" >>  $XsScript
    echo "tclout rate 1" >>  $XsScript
    echo 'set rate [lindex $xspec_tclout 0]' >>  $XsScript
    echo "" >>  $XsScript

    echo "# GET FLUX" >>  $XsScript
    echo "flux ${band[i]} 2" >>  $XsScript
    echo "tclout flux" >>  $XsScript
    echo 'set flux [lindex $xspec_tclout 0]' >>  $XsScript
    echo "tclout expos" >>  $XsScript
    echo 'set expos [lindex $xspec_tclout 0]' >>  $XsScript
    echo "" >>  $XsScript

    echo "" >>  $XsScript
    echo "/bin/rm -f XSPEC_SIM_TM${tms[i]}_${nh}_${cluster}_${band[$i]%% *}-${hie[-1]}keV${suff}_v1.xcm" >>  $XsScript
    echo "save model XSPEC_SIM_TM${tms[i]}_${nh}_${cluster}_${band[$i]%% *}-${hie[-1]}keV${suff}_v1.xcm" >>  $XsScript
    echo "open XSPEC_SIM_TM${tms[i]}_L_${nh}_${cluster}_${band[$i]%% *}-${hie[-1]}keV${suff}_v1.txt w" >>  $XsScript
    echo "set fname [open XSPEC_SIM_TM${tms[i]}_L_${nh}_${cluster}_${band[$i]%% *}-${hie[-1]}keV${suff}_v1.txt w]" >>  $XsScript
    echo "" >>  $XsScript
    echo 'puts $fname "$nh $rate $flux $expos"' >> $XsScript
    echo 'close $fname' >> $XsScript
    echo "exit" >> $XsScript

    # Run it
    # echo "Launching Xspec for nh=${nh}..."
    xspec - $XsScript >& $XsLog
    rm XSPEC_SIM_TM${tms[i]}_${nh}_v1.fak $XsScript $XsLog
  done

  echo "Compiling simulation results RESULTS_SIM_TM${tms[i]}_${band[$i]%% *}-${hie[-1]}keV${suff}_NH_${cluster}.txt"
  cat XSPEC_SIM_TM${tms[i]}_L_* > RESULTS_SIM_TM${tms[i]}_${band[$i]%% *}-${hie[-1]}keV${suff}_NH_${cluster}.txt
  sed -i '1i\nh rate flux exp' RESULTS_SIM_TM${tms[i]}_${band[$i]%% *}-${hie[-1]}keV${suff}_NH_${cluster}.txt
  mv RESULTS_SIM_TM${tms[i]}_${band[$i]%% *}-${hie[-1]}keV${suff}_NH_${cluster}.txt filtered/PIBsub_${low8[0]}-${hie[-1]}${suff}_combinedtiles/
  
  rm XSPEC_SIM_TM${tms[i]}_L_*
done
echo "DONE!"

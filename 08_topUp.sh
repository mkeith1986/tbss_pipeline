#!/bin/bash
#PBS -N topup
#PBS -l mem=15gb
#PBS -l nodes=1:ppn=1
#PBS -l walltime=8:00:00
set -e
STARTTIME=$(date +%s)

# Module loads
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# Global variables
rundir=/scratch/u/mkeith/ECP
cd $rundir
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}
topup_config_file=$FSLDIR/etc/flirtsch/b02b0.cnf
echo "Running topUp in ${sbj}..."

# Run TopUp
# imain has the first b0 of each series (4 in total if all series exist for the subject)
# Should generate these files:
# Pos_Neg_b0.topup_log
# topup_Pos_Neg_b0_fieldcoef.nii.gz: contains spline coefficients defining the field
# topup_Pos_Neg_b0_movpar.txt: each line contains the movement parameters for each volume of imain (4 lines if all series exist for the subject)
echo "1. topup ${sbj}..."
topup --imain=$sbj/Pos_Neg_b0 --datain=$sbj/acqparams.txt --config=${topup_config_file} --out=$sbj/topup_Pos_Neg_b0 -v

# Apply topup to get a hifi b0 (used to create the nodif_brain_mask)
# Only the first b0 of 75PA (positive) and the first b0 of 75AP (negative) is used
# Unless one of 75 series is missing, then should use the two 76 series
# PA is called positive because when I go from posterior of the brain to anterior of the brain the value of Y increases
# So it is acquired in the positive way of the axis
# Including both 75 and 76 would led to averaging across data acquired with different diffusion gradients which is not valid
# the hifib0 output will have one volume and the size of the series
echo "2. Define indices to apply topup"
dimt=$(cat $sbj/acqparams.txt | wc -l)
if [ $dimt -eq 4 ]
then
        echo "All series present"
        index="1,3"
elif [ $dimt -eq 2 ]
then
        echo "Two series present"
        index="1,2"
elif [ $dimt -eq 3 ]
then
        echo "Three series present"
        if [ ! -f $sbj/PA_1.bval ]
        then
                echo "75PA missing"
                index="1,3"
        elif [ ! -f $sbj/PA_2.bval ]
        then
                echo "76PA missing"
                index="1,2"
        elif [ ! -f $sbj/AP_1.bval ]
        then
                echo "75AP missing"
                index="2,3"
        else
                echo "76AP missing"
                index="1,3"
        fi
else
        echo "ERROR: Number of series: ${dimt}. This doesnt make sense"
        exit 1
fi
echo "Indices: ${index}"

if [ -f $sbj/Pos_b0.nii.gz ] && [ -f $sbj/Neg_b0.nii.gz ]
then
        echo "3. Apply topup..."
        fslroi $sbj/Pos_b0 $sbj/Pos_b01 0 1
        fslroi $sbj/Neg_b0 $sbj/Neg_b01 0 1
        applytopup --imain=$sbj/Pos_b01,$sbj/Neg_b01 --topup=$sbj/topup_Pos_Neg_b0 --datain=$sbj/acqparams.txt --inindex=$index --out=$sbj/hifib0

        # Generate the nodif_brain_mask
        echo "4. Generate nodif brain mask..."
        bet $sbj/hifib0 $sbj/nodif_brain -n -m -f 0.2
else
        echo "ERROR: Cannot apply topup. Either all positive or negative series are missing. Use eddy_correct instead."
        exit 1
fi
echo "DONE topup"

# Compute execution time
FINISHTIME=$(date +%s)
TOTDURATION_S=$((FINISHTIME - STARTTIME))
DURATION_H=$((TOTDURATION_S / 3600))
REMAINDER_S=$((TOTDURATION_S - (3600*DURATION_H)))
DURATION_M=$((REMAINDER_S / 60))
DURATION_S=$((REMAINDER_S - (60*DURATION_M)))
DUR_H=$(printf "%02d" ${DURATION_H})
DUR_M=$(printf "%02d" ${DURATION_M})
DUR_S=$(printf "%02d" ${DURATION_S})
echo "Total execution time was ${DUR_H} hrs ${DUR_M} mins ${DUR_S} secs"

#!/bin/bash
#SBATCH --job-name="finaldtifit"
#SBATCH --mem-per-cpu=5gb
#SBATCH --time=2:00:00
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
cd $sbj

echo "Running final dtifit on ${sbj} using weighted least squares..."
dtifit --data=data --out=dti --mask=nodif_brain_mask --bvecs=bvecs --bvals=bvals --wls
echo "DONE finaldtifit"

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

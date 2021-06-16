#!/bin/bash
#SBATCH --job-name="dtifitPreTopUp"
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
dtifit=dtifit_ecc
mkdir -p $dtifit

# Run dtifit in each series
for diffdirs in 75_AP 75_PA 76_AP 76_PA
do
        img=${sbj}_3T_DWI_dir${diffdirs}
        if [ -f ${img}_masked_ds_gs_ecc.nii.gz ]
        then
                echo $sbj $diffdirs
                dtifit --data=${img}_masked_ds_gs_ecc --out=$dtifit/dti_${diffdirs} --mask=${img}_brain_mask --bvecs=${img}.bvec --bvals=${img}.bval
                echo "Done"
        fi
done

# Remove files that are not needed for QC
rm -f $dtifit/dti*L?.nii.gz $dtifit/dti*M?.nii.gz $dtifit/dti*S0.nii.gz $dtifit/dti*V2.nii.gz $dtifit/dti*V3.nii.gz
echo "DONE dtifitPreTopUp"

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

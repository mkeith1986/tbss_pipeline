#!/bin/bash
#SBATCH --job-name="gibbs_correction"
#SBATCH --mem-per-cpu=5gb
#SBATCH --time=2:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
set -e
STARTTIME=$(date +%s)

# Module loads
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh
module load mrtrix3

# Global variables
rundir=/scratch/u/mkeith/ECP
cd $rundir
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}

echo "Running Gibbs correction on ${sbj}..."
for img in $sbj/${sbj}_3T_DWI_dir75_AP_masked_ds $sbj/${sbj}_3T_DWI_dir75_PA_masked_ds $sbj/${sbj}_3T_DWI_dir76_AP_masked_ds $sbj/${sbj}_3T_DWI_dir76_PA_masked_ds
do
        if [ -f $img.nii.gz ]
        then
                echo "${img}..."
                rm -f ${img}_gs.nii.gz
                mrdegibbs -nthreads 10 $img.nii.gz ${img}_gs.nii.gz
                fslmaths ${img}_gs.nii.gz -thr 0.000001 ${img}_gs.nii.gz
        fi
done
echo "DONE gibbs_correction"

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

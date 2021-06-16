#!/bin/bash
#SBATCH --job-name="denoise"
#SBATCH --mem-per-cpu=50gb
#SBATCH --time=10:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
set -e
STARTTIME=$(date +%s)

# Module loads
module load ants
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# Global variables
rundir=/scratch/u/mkeith/ECP
cd $rundir
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}

echo "Running Denoise on ${sbj}..."
for n in 75 76
do
        for d in AP PA
        do
                echo ${n}_${d}
                img=$sbj/${sbj}_3T_DWI_dir${n}_${d}_masked
                mask=$sbj/${sbj}_3T_DWI_dir${n}_${d}_brain_mask.nii.gz
                mask4d=$sbj/${sbj}_3T_DWI_dir${n}_${d}_brain_4dmask.nii.gz

                if [ -f $img.nii.gz ]
                then
                        [ ! -f $mask ] && cp $sbj/${sbj}_${d}_brain_mask.nii.gz $mask
                        DenoiseImage -d 4 -i $img.nii.gz -o ${img}_ds.nii.gz -x $mask4d -v -r 1
                        fslmaths $sbj/${img}_ds.nii.gz -mul $mask -thr 0.00001 $sbj/${img}_ds.nii.gz
                fi
        done
done
echo "DONE denoise"

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

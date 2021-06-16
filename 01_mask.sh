#!/bin/bash
#SBATCH --job-name="3dmask"
#SBATCH --mem-per-cpu=5gb
#SBATCH --time=1:00:00
set -e
STARTTIME=$(date +%s)

# Module loads
module load afni
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# Global variables
rundir=/scratch/u/mkeith/ECP
cd $rundir
sbjS=($(cat sbj_list.txt))
sbj=${sbjS[PBS_ARRAYID-1]}

echo "Masking ${sbj}..."
for diffdir in "75_AP" "75_PA" "76_AP" "76_PA"
do
        img=$sbj/${sbj}_3T_DWI_dir${diffdir}
        if [ -f $img.nii.gz ]
        then
                echo $img
                bet $img ${img}_bet -f 0.1 -g 0 -n -m
                3dSkullStrip -overwrite -input $img.nii.gz -prefix ${img}_skullStrip.nii.gz -push_to_edge
                fslmaths ${img}_skullStrip.nii.gz -bin ${img}_skullStrip.nii.gz
        fi
done
echo "DONE 3dmask"

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

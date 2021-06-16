#!/bin/bash
#SBATCH --job-name="preStats_part2"
#SBATCH --mem-per-cpu=20gb
#SBATCH --time=00:05:00
set -e
STARTTIME=$(date +%s)

# Module loads
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# Global variables
outDir=TBSS
rundir=/scratch/u/mkeith/ECP/$outDir
cd $outDir
thr=0.2

# 5. Create skeleton mask using threshold to threshold areas of low mean FA and high inter-subject variability
echo "Creating skeleton mask..."
fslmaths mean_FA_skeleton -thr $thr -bin mean_FA_skeleton_mask
echo "done"

# 6. Create skeleton distance map (for use in projection search)
echo "Creating skeleton distance map..."
fslmaths mean_FA_mask -mul -1 -add 1 -add mean_FA_skeleton_mask mean_FA_skeleton_mask_dst
distancemap -i mean_FA_skeleton_mask_dst -o mean_FA_skeleton_mask_dst
echo "done"

# 7. Project all FA data onto skeleton
# In the projected images, each skeletton voxel takes the value from the local centre of the nearest relevant track
echo "Projecting data..."
tbss_skeleton -i mean_FA -p $thr mean_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm all_FA all_FA_skeletonised
echo "done"
echo "DONE preStats_part2"

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

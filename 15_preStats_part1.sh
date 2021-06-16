#!/bin/bash
#SBATCH --job-name="preStats_part1"
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

# 1. Merge all transformed FA images into a single 4D file
echo "Merging all files..."
cmd="fslmerge -t all_FA"
for sbj in $(cat list.txt)
do
        cmd="${cmd} FA/${sbj}"
done
echo $cmd
echo ""
eval $cmd
echo "done"

# 2. Create the mean FA
echo "Creating mean FA..."
fslmaths all_FA -max 0 -Tmin -bin mean_FA_mask -odt char
fslmaths all_FA -mas mean_FA_mask all_FA
fslmaths all_FA -Tmean mean_FA
echo "done"

# 4. Create skeleton
# The skeletonized FA represents the centres of all fibre bundles that are generally common to the subjects involved in the study.
echo "Creating sekeleton..."
tbss_skeleton -i mean_FA -o mean_FA_skeleton
echo "done"
echo "DONE preStats_part1"

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

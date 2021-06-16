#!/bin/bash
#SBATCH --job-name="randomise"
#SBATCH --time=168:00:00
#SBATCH --mem-per-cpu=5gb
set -e
STARTTIME=$(date +%s)

# Module loads
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# Global variables
outDir=TBSS
cd $outDir

# -n 500: generate 500 permutations of the data when building the null distribution to test against. If it runs fast could test with more (up to 2000)
# -D: demean data first (necessary if not modeling the mean of the imaging data in the design matrix)
# --T2: using TFCE for the test statistic
# -x: voxel-based thresholded:
#       raw test statistic: _tstat/fstat: This is the best image to get the clusters and peak information from, it can be thresholded using the significant voxels from corrp so that only significant voxels are reported
#       uncorrected outputs (using Threshold-Free Cluster enhancement): _tfce_p_tstat/fstat (1-uncorrectedP)
#       uncorrected outputs (using voxel-based thresholding): _vox_p_tstat/fstat (1-uncorrectedP)
#       corrected outputs (using Threshold-Free Cluster enhancement): _tfce_corrp_tstat/fstat (1-FWE correctedP, Family Wise Error rate controled)
#       corrected outputs (using voxel-based thresholding): _vox_corrp_tstat/fstat (1-FWE correctedP, Family Wise Error rate controled)
# For two groups no need to use f-tests
# -d: design matrix: each column contains a predictor
echo "Running randomise ${outDir}"
randomise -i all_FA_skeletonised.nii.gz -o ttest -m mean_FA_skeleton_mask.nii.gz -d design.mat -t design.con -n 500 --T2
echo "DONE randomise"

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

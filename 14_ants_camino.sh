#!/bin/bash
#SBATCH --job-name="ants_camino"
#SBATCH --mem-per-cpu=5gb
#SBATCH --time=2:00:00
set -e
STARTTIME=$(date +%s)

# Module loads
module load ants
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# General variables
rundir=/scratch/u/mkeith/ECP
cd $rundir
REFERENCE=${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}

# FA variables
origFA=$sbj/fa.nii.gz
INPUT=$sbj/fa_erode.nii.gz
OUTPUT=$sbj/${sbj}_FA
AFFINE=$sbj/${sbj}_FAAffine.txt
WARP=$sbj/${sbj}_FAWarp.nii.gz

# Removed the erode because that's done during the QA of previous steps
echo "${sbj}..."
X=$(fslval $origFA dim1); X=$(echo "$X 2 - p" | dc -)
Y=$(fslval $origFA dim2); Y=$(echo "$Y 2 - p" | dc -)
Z=$(fslval $origFA dim3); Z=$(echo "$Z 2 - p" | dc -)
fslmaths $origFA -min 1 -roi 1 $X 1 $Y 1 $Z 0 1 $INPUT

# Run ANTS
echo "Running ANTS on sbj ${sbj}..."
ANTS 3 -m CC[$REFERENCE,$INPUT,1,5] -o $OUTPUT.nii.gz -r Gauss[2,0] -t SyN[0.25] -i 30x99x11 --use-Histogram-Matching
echo "done calculating transformation"

# Apply ANTS
echo "Applying direct transformation..."
WarpImageMultiTransform 3 $INPUT $OUTPUT.nii.gz -R $REFERENCE $WARP $AFFINE
echo "done applying transformation"
echo "DONE ants_camino"

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

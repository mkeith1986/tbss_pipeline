#!/bin/bash
#SBATCH --job-name="eddyCuda"
#SBATCH --mem-per-cpu=60gb
#SBATCH --gres=gpu:1
#SBATCH --time=68:00:00
set -e
STARTTIME=$(date +%s)

# Module loads
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# Variables
rundir=/scratch/u/mkeith/ECP
cd $rundir
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}
imain=$sbj/Pos_Neg
mask=$sbj/nodif_brain_mask
index=$sbj/index.txt
acqp=$sbj/acqparams.txt
bvecs=$sbj/Pos_Neg.bvec
bvals=$sbj/Pos_Neg.bval
topup=$sbj/topup_Pos_Neg_b0
specFile=$sbj/slspecFile.txt
out=$sbj/eddy_unwarped_images

echo "Running eddy in ${sbj}..."
eddy_cuda --imain=$imain --mask=$mask --index=$index --acqp=$acqp --bvecs=$bvecs --bvals=$bvals --topup=$topup --out=$out --fwhm=10,8,6,4,2,0,0,0,0 --repol --resamp=lsr --fep --ol_nstd=3 --ol_type=both --slspec=$specFile --mporder=12 --very_verbose --s2v_niter=10 --cnr_maps --niter=9 --s2v_lambda=10 --nvoxhp=2000
echo "DONE eddyCuda"

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

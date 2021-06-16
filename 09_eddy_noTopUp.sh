#!/bin/bash
#SBATCH --job-name="eddyCuda"
#SBATCH --mem-per-cpu=60gb
#SBATCH --gres=gpu:1
#SBATCH --time=52:00:00
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
imain=$sbj/${sbj}_3T_DWI_dir76_PA_masked_ds_gs_ecc.nii.gz
mask=$sbj/${sbj}_3T_DWI_dir76_PA_brain_mask.nii.gz
index=$sbj/index.txt
acqp=$sbj/acqparams.txt
bvecs=$sbj/${sbj}_3T_DWI_dir76_PA.bvec
bvals=$sbj/${sbj}_3T_DWI_dir76_PA.bval
out=$sbj/eddy_unwarped_images
echo "Running eddyCuda noTopup on ${sbj}"

#### CREATE INDEX AND ACQP FILES ####
rm -f $index $acqp
echo "Creating index file..."
nvols=$(fslval $imain dim4)
for ((i=1; i<=$nvols; i+=1)); do echo 1 >> $index; done
echo "Creating acqparams file..."
echo "0 -1 0 .125970" >> $acqp

#### RUN EDDY ####
echo "Running eddy..."
eddy_cuda --imain=$imain --mask=$mask --index=$index --acqp=$acqp --bvecs=$bvecs --bvals=$bvals --out=$out --fwhm=10,0,0,0,0 --repol --resamp=jac --fep --ol_type=sw --mporder=12 --very_verbose --cnr_maps

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

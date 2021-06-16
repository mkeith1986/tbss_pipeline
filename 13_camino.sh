#!/bin/bash
set -e
STARTTIME=$(date +%s)

# Global variables
sbj=$1
dataDir=/group/jbinder/ECP/Data_Release/$sbj/Diffusion_clean_v2/data
diffDir=$dataDir/camino
rm -rf $diffDir
mkdir $diffDir
echo "##### Running camino on ${sbj} #####"

## Create schemefile
echo "##### Creating shemefile #####"
fsl2scheme -bvecfile $dataDir/bvecs -bvalfile $dataDir/bvals > $diffDir/bvector.scheme
echo "##### Finished creating schemefile #####"

## Convert the DWI data
echo "##### Converting DWI data #####"
dt=$(fslval $dataDir/data data_type)
[ "${dt/ /}" != "FLOAT32" ] && echo "ERROR: ${dt}data type" && exit 1
image2voxel -4dimage $dataDir/data.nii.gz -outputfile $diffDir/dwi.Bfloat
echo "##### Finished converting the DWI data to camino format #####"

## Generate WM ROI
echo "##### Generating WM ROI #####"
tbss_skeleton -i $dataDir/dtifit/dti_FA -o $diffDir/WM_ROI
3dmask_tool -input $dataDir/nodif_brain_mask.nii.gz -dilate_input -5 -prefix $diffDir/tmp.nii.gz
thr=0.7
nvox=0
n_iter=5
while [ $nvox -lt 50 ] && [ $n_iter -gt 0 ]
do
        echo "##### threshold ${thr} #####"
        fslmaths $diffDir/WM_ROI -mul $diffDir/tmp -thr $thr -bin $diffDir/tmp2
        nvox=$(fslstats $diffDir/tmp2 -V | awk '{print $1}')
        thr=$(echo "$thr - 0.1" | bc -l)
        n_iter=$(( $n_iter + 1 ))
done
rm $diffDir/tmp.nii.gz
mv $diffDir/tmp2.nii.gz $diffDir/WM_ROI.nii.gz
[ $nvox -lt 50 ] && echo "ERROR: wm has less than 50 voxels" && exit 1
echo "##### Finished creating wm mask with ${nvox} voxels #####"

## Calculate the estimate of the noise standard deviation (SIGMA)
# This program estimates the noise variance and the signal to noise ratio in a given ROI, for the b=0 data for a given scan.
# The noise standard deviation from estimatesnr is a good starting point, but can cause too many measurements to be rejected as outliers. Will need to experiment to find the correct sigma.
# Larger values of sigma makes the algorithm less likely to classify a data point as an outlier.
# sigma diff only uses the first two b0s while sigma mult uses all b0s
estimatesnr -inputfile $diffDir/dwi.Bfloat -schemefile $diffDir/bvector.scheme -bgmask $diffDir/WM_ROI.nii.gz > $diffDir/estimatesnr.txt
cat $diffDir/estimatesnr.txt
sigma=$(cat $diffDir/estimatesnr.txt | grep "sigma mult" | awk '{print $3}')
echo "##### using sigma ${sigma} #####"

## Use RESTORE to fit the diffusion tensor
restore $diffDir/dwi.Bfloat $diffDir/bvector.scheme $sigma $diffDir/outliermap.nii.gz -bgmask $dataDir/nodif_brain_mask.nii.gz > $diffDir/dt_RESTORE.Bdouble

## Get the FA and MD maps
for PROG in fa md
do
        cat $diffDir/dt_RESTORE.Bdouble | ${PROG} | voxel2image -outputroot $diffDir/${PROG} -header $dataDir/data.nii.gz
        echo "##### ${PROG} #####"
done

## Get the vectors
cat $diffDir/dt_RESTORE.Bdouble | dteig > $diffDir/dteig.Bdouble
echo "DONE camino"

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

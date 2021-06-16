#!/bin/bash
#SBATCH --job-name="intensity_normalization"
#SBATCH --mem-per-cpu=5gb
#SBATCH --time=00:30:00
set -e
STARTTIME=$(date +%s)

# Module loads
module load fsl/6.0.4
PATH=${FSLDIR}/bin:$PATH
. ${FSLDIR}/etc/fslconf/fsl.sh

# Global variables
rundir=/scratch/u/mkeith/ECP
cd $rundir
SUBJECTS=($(cat sbj_list.txt))
sbj=${SUBJECTS[PBS_ARRAYID-1]}

# Copy files to output directory
echo "Running intensity normalization on ${sbj}..."
if [ -f $sbj/${sbj}_3T_DWI_dir75_AP_masked_ds_gs_ecc.nii.gz ]
then
        echo "Copying AP1 files"
        cp $sbj/${sbj}_3T_DWI_dir75_AP_masked_ds_gs_ecc.nii.gz $sbj/AP_1.nii.gz
        cp $sbj/${sbj}_3T_DWI_dir75_AP.bval $sbj/AP_1.bval
        cp $sbj/${sbj}_3T_DWI_dir75_AP.bvec $sbj/AP_1.bvec
fi
if [ -f $sbj/${sbj}_3T_DWI_dir76_AP_masked_ds_gs_ecc.nii.gz ]
then
        echo "Copying AP2 files"
        cp $sbj/${sbj}_3T_DWI_dir76_AP_masked_ds_gs_ecc.nii.gz $sbj/AP_2.nii.gz
        cp $sbj/${sbj}_3T_DWI_dir76_AP.bval $sbj/AP_2.bval
        cp $sbj/${sbj}_3T_DWI_dir76_AP.bvec $sbj/AP_2.bvec
fi
if [ -f $sbj/${sbj}_3T_DWI_dir75_PA_masked_ds_gs_ecc.nii.gz ]
then
        echo "Copying PA1 files"
        cp $sbj/${sbj}_3T_DWI_dir75_PA_masked_ds_gs_ecc.nii.gz $sbj/PA_1.nii.gz
        cp $sbj/${sbj}_3T_DWI_dir75_PA.bval $sbj/PA_1.bval
        cp $sbj/${sbj}_3T_DWI_dir75_PA.bvec $sbj/PA_1.bvec
fi
if [ -f $sbj/${sbj}_3T_DWI_dir76_PA_masked_ds_gs_ecc.nii.gz ]
then
        echo "Copying PA2 files"
        cp $sbj/${sbj}_3T_DWI_dir76_PA_masked_ds_gs_ecc.nii.gz $sbj/PA_2.nii.gz
        cp $sbj/${sbj}_3T_DWI_dir76_PA.bval $sbj/PA_2.bval
        cp $sbj/${sbj}_3T_DWI_dir76_PA.bvec $sbj/PA_2.bvec
fi

# For each series, get the mean b0 and rescale to match the first series baseline
num_entry=0
for entry in $sbj/PA_1 $sbj/PA_2 $sbj/AP_1 $sbj/AP_2
do
        if [ -f $entry.nii.gz ]
        then
                echo $entry.nii.gz

                # Get the mean value of each volume
                echo "Getting mean value..."
                mean=${entry}_mean
                fslmaths $entry -Xmean -Ymean -Zmean $mean

                # Extract all b0s for the series
                echo "Extracting b0s..."
                bvals=$(cat $entry.bval)
                i=0
                for bval in ${bvals}
                do
                        n=$(zeropad $i 4)
                        [ $bval -eq 0 ] && fslroi ${mean} ${entry}_b0_${n} ${i} 1
                        i=$(( $i + 1 ))
                done

                # Merge B0s
                echo "Merging b0s..."
                fslmerge -t $mean ${entry}_b0_????.nii.gz

                # This is the mean baseline b0 intensity for the series
                echo "Getting mean baseline..."
                fslmaths $mean -Tmean $mean
                imrm ${entry}_b0_????.nii.gz
                
                # Do not rescale the first series, just save the scaling value
                # For the rest, replace the original dataseries with the rescaled one
                if [ $num_entry -eq 0 ]
                then
                        echo "First series, do not rescale"
                        resc=$(fslmeants -i $mean)
                else
                        echo "Rescale"
                        sc=$(fslmeants -i $mean)
                        fslmaths $entry -mul $resc -div $sc $entry
                fi
                
                # Make sure no negatives crept in
                echo "Removing negative values..." 
                fslmaths $entry -thr 0.00001 $entry

                imrm $mean
                num_entry=$(( $num_entry + 1 ))
                echo "${entry} done"
        fi
done
echo "DONE intensity_normalization"

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

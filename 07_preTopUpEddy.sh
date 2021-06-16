#!/bin/bash
#SBATCH --job-name="preTopupEddy"
#SBATCH --mem-per-cpu=24gb
#SBATCH --time=1:00:00
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

# 1. Calculate the total readout time in seconds
# Try using ES=0.494 in all, if it doesnt work in those before scanner upgrade, change to 0.489 for those
# This number is supposed to not matter as long as it is constant
echo "Calculating total readout time..."
ES=0.494
any=$(ls $sbj/??_?.nii.gz | head -n1)
dimP=$(fslval ${any} dim2)
nPEsteps=$(($dimP - 1))
ro_time=$(echo "${ES} * ${nPEsteps}" | bc -l)
ro_time=$(echo "scale=6; ${ro_time} / 1000" | bc -l)

# 2. Extract positive (PA) b0s and create index and acquisition parameters files
echo "Extracting positive b0s..."
rm -f $sbj/index.txt $sbj/acqparams.txt
entry_index=1
for i in 1 2
do
        entry=$sbj/PA_${i}
        if [ -f $entry.nii.gz ]
        then
                echo "PA_${i}"
                # Extract first b0
                n=$(( $i - 1 ))
                fslroi $entry $sbj/Pos_b0_000${n} 0 1

                # For each bval (volume), write an entry in the index file
                IFS=' ' read -a ARRAY <<< "$(cat $entry.bval)"
                for bval in ${ARRAY[@]}; do echo $entry_index >> $sbj/index.txt; done
                ((entry_index++))

                # Write the corresponding line for the entry in the acqparams file
                echo 0 1 0 ${ro_time} >> $sbj/acqparams.txt
        fi
done

# 3. Extract the negative (AP) b0s and continue writing the index and acquisition parameters files
echo "Extracting negative b0s..."
for i in 1 2
do
        entry=$sbj/AP_${i}
        if [ -f $entry.nii.gz ]
        then
                echo "AP_${i}"
                # Extract first b0
                n=$(( $i - 1 ))
                fslroi $entry $sbj/Neg_b0_000${n} 0 1

                # For each bval (volume), write an entry in the index file
                IFS=' ' read -a ARRAY <<< "$(cat $entry.bval)"
                for bval in ${ARRAY[@]}; do echo $entry_index >> $sbj/index.txt; done
                ((entry_index++))

                # Write the corresponding line for the entry in the acqparams file
                echo 0 -1 0 ${ro_time} >> $sbj/acqparams.txt
        fi
done

# 4.Merge files and correct number of slices (remove one to get an even number if necessary)
# Merge positive b0s and correct z dim
if [ -f $sbj/Pos_b0_0000.nii.gz ] || [ -f $sbj/Pos_b0_0001.nii.gz ]
then
        echo "Merging positive b0s and correcting zdim..."
        fslmerge -t $sbj/Pos_b0 $sbj/Pos_b0_000?.nii.gz
        dimz=$(fslval $sbj/Pos_b0 dim3)
        [ $(( $dimz % 2 )) -eq 1 ] && fslroi $sbj/Pos_b0 $sbj/Pos_b0 0 -1 0 -1 1 -1
fi

# Merge negative b0s and correct z dim
if [ -f $sbj/Neg_b0_0000.nii.gz ] || [ -f $sbj/Neg_b0_0001.nii.gz ]
then
        echo "Merging negative b0s and correcting zdim..."
        fslmerge -t $sbj/Neg_b0 $sbj/Neg_b0_000?.nii.gz
        dimz=$(fslval $sbj/Neg_b0 dim3)
        [ $(( $dimz % 2 )) -eq 1 ] && fslroi $sbj/Neg_b0 $sbj/Neg_b0 0 -1 0 -1 1 -1
fi

# Merge positive and negative b0s
if [ -f $sbj/Pos_b0.nii.gz ] && [ -f $sbj/Neg_b0.nii.gz ]
then
        echo "Merging positive and negative b0s..."
        fslmerge -t $sbj/Pos_Neg_b0 $sbj/Pos_b0 $sbj/Neg_b0
elif [ -f $sbj/Pos_b0.nii.gz ]
then
        echo "No negative b0s, copying the positive as Pos_Neg_b0..."
        cp $sbj/Pos_b0.nii.gz $sbj/Pos_Neg_b0.nii.gz
elif [ -f $sbj/Neg_b0.nii.gz ]
then
        echo "No positive b0s, copying the negative as Pos_Neg_b0..."
        cp $sbj/Neg_b0.nii.gz $sbj/Pos_Neg_b0.nii.gz
fi

# Merge positive files and correct z dim
rm -f $sbj/Pos.bval $sbj/Pos.bvec
if [ -f $sbj/PA_1.nii.gz ] || [ -f $sbj/PA_2.nii.gz ]
then
        echo "Merging positive files and correcting zdim..."
        fslmerge -t $sbj/Pos $sbj/PA_?.nii.gz
        dimz=$(fslval $sbj/Pos dim3)
        [ $(( $dimz % 2 )) -eq 1 ] && fslroi $sbj/Pos $sbj/Pos 0 -1 0 -1 1 -1
        if [ -f $sbj/PA_1.nii.gz ] && [ -f $sbj/PA_2.nii.gz ]
        then
                paste -d ' ' $sbj/PA_1.bval $sbj/PA_2.bval >> $sbj/Pos.bval
                paste -d ' ' $sbj/PA_1.bvec $sbj/PA_2.bvec >> $sbj/Pos.bvec
        elif [ -f $sbj/PA_1.nii.gz ]
        then
                cp $sbj/PA_1.bval $sbj/Pos.bval
                cp $sbj/PA_1.bvec $sbj/Pos.bvec
        else
                cp $sbj/PA_2.bval $sbj/Pos.bval
                cp $sbj/PA_2.bvec $sbj/Pos.bvec
        fi
fi

# Merge negative files and correct z dim
rm -f $sbj/Neg.bval $sbj/Neg.bvec
if [ -f $sbj/AP_1.nii.gz ] || [ -f $sbj/AP_2.nii.gz ]
then
        echo "Merging negative files and correcting zdim..."
        fslmerge -t $sbj/Neg $sbj/AP_?.nii.gz
        dimz=$(fslval $sbj/Neg dim3)
        [ $(( $dimz % 2 )) -eq 1 ] && fslroi $sbj/Neg $sbj/Neg 0 -1 0 -1 1 -1
        if [ -f $sbj/AP_1.nii.gz ] && [ -f $sbj/AP_2.nii.gz ]
        then
                paste -d ' ' $sbj/AP_1.bval $sbj/AP_2.bval >> $sbj/Neg.bval
                paste -d ' ' $sbj/AP_1.bvec $sbj/AP_2.bvec >> $sbj/Neg.bvec
        elif [ -f $sbj/AP_1.nii.gz ]
        then
                cp $sbj/AP_1.bval $sbj/Neg.bval
                cp $sbj/AP_1.bvec $sbj/Neg.bvec
        else
                cp $sbj/AP_2.bval $sbj/Neg.bval
                cp $sbj/AP_2.bvec $sbj/Neg.bvec
        fi
fi

# Merge positive and negative files
rm -f $sbj/Pos_Neg.bval $sbj/Pos_Neg.bvec
if [ -f $sbj/Pos.nii.gz ] && [ -f $sbj/Neg.nii.gz ]
then
        echo "Merging positive and negative files..."
        fslmerge -t $sbj/Pos_Neg $sbj/Pos $sbj/Neg
        paste -d ' ' $sbj/Pos.bval $sbj/Neg.bval >> $sbj/Pos_Neg.bval
        paste -d ' ' $sbj/Pos.bvec $sbj/Neg.bvec >> $sbj/Pos_Neg.bvec
elif [ -f $sbj/Pos.nii.gz ]
then
        echo "Copying positive files as Pos_Neg (negative series missing)..."
        cp $sbj/Pos.nii.gz $sbj/Pos_Neg.nii.gz
        cp $sbj/Pos.bval $sbj/Pos_Neg.bval
        cp $sbj/Pos.bvec $sbj/Pos_Neg.bvec
elif [ -f $sbj/Neg.nii.gz ]
then
        echo "Copying negative files as Pos_Neg (positive series missing)..."
        cp $sbj/Neg.nii.gz $sbj/Pos_Neg.nii.gz
        cp $sbj/Neg.bval $sbj/Pos_Neg.bval
        cp $sbj/Neg.bvec $sbj/Pos_Neg.bvec
fi
echo "DONE preTopupEddy"

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

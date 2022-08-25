#!/bin/bash

# Converting IMA files to NIFTI format.
# 10/15/2017 by Minsun Park

# ===================================================================
# Hands-on fMRI workshop @VCN, Korea Univ.
# Presenter: Minsun Park, Ph.D.
# Email:  vd.mpark@gmail.com
# Distributed on 08/26/2022.
# ===================================================================


### variables ###
expID=s01
rawDir=/Volumes/M.Park/fMRI_MAE_MVPA/
moveDir=/Volumes/M.Park/fMRI_MAE_MVPA/Analyzed_Data
sbjDir=${rawDir}/${expID}


#=== To know this info, see the measurements in the pdf.
EpiVolNum=136
EpiSlices=45
EpiTR=2000
T1VolNum=1
T1Slices=192
T1TR=2300

# select data to convert to 3d
idxT1=0
idxLR=0
#### Change the for loop (for kk in {1..4})

# Check the directory
echo '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'${expID}
echo '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'${sbjDir}


###### Make a directory to move afni files ######
# cd ${moveDir}
# mkdir ${expID}
# mkdir ${expID}/LRtask


###### Start ######
cd ${sbjDir}
echo '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ current folder: '${sbjDir}


#======= LR task =======#
if [ "$idxLR" -eq 1 ]
	then
	echo '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Convert Main to 3d'
	

	for ii in 1 2
	do
		cd 1_LRtask"$ii"*
			# dicom2afni
			to3d -prefix ${expID}.LRtask"$ii" -skip_outliers \
			-assume_dicom_mosaic \
			-time:zt ${EpiSlices} ${EpiVolNum} ${EpiTR} alt+z2 \
			*.IMA

			# afni2nifti
			3dAFNItoNIFTI ${expID}.LRtask"$ii"+orig.

			# move files
			find . -name ${expID}'*'.nii -exec mv {} ${moveDir}/${expID}/LRtask \;
			# delete files
			rm ${expID}.LRtask"$ii"+orig.*
		cd ..
	done
fi

#======= T1 =======#
	if [ "$idxT1" -eq 1 ]
		then
		echo '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Convert T1 to 3d'


		cd T1*
			to3d -prefix ${expID}.T1.MT -time:zt ${T1Slices} ${T1VolNum} ${T1TR} seq+z \
			*.IMA

			# afni2nifti
			3dAFNItoNIFTI ${expID}.T1.MT+orig.

			# move files
			find . -name ${expID}'*'.nii -exec mv {} ${moveDir}/${expID}/T1 \;
			# delete files
			rm ${expID}.T1.MT+orig.*
		cd ..
	fi

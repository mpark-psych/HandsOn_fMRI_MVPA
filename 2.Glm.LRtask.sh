#!/bin/bash

# 1st level analysis. 
# Here the purpose is to extract beta estimates for each visual direction.

# ===================================================================
# Hands-on fMRI workshop @VCN, Korea Univ.
# Presenter: Minsun Park, Ph.D.
# Email:  vd.mpark@gmail.com
# Distributed on 08/26/2022.
# ===================================================================


### variables ###
expID=s01
baseDir=/Users/minsunpark/Desktop/MyWorkshop/Analyzed_data/
onsetDir=${baseDir}${expID}/regressors
sbjDir=${baseDir}${expID}
Bmask=${expID}.LRtask.BrainMask.nii
inputEPI=${expID}.LRtask.TMdeoblqAI.nii
onsetLeft=${onsetDir}/onset_left.txt
onsetRight=${onsetDir}/onset_right.txt
MotPar=${expID}.motion.1D

cd ${sbjDir}
echo '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ current folder: '${sbjDir}

3dDeconvolve \
-input ${inputEPI} \
-mask ${Bmask}	\
-polort A \
-float \
-jobs 2	\
-local_times	\
-concat '1D: 0 136' \
-num_stimts 8 \
-stim_times 1 ${onsetLeft} 'BLOCK5(18,1)' -stim_label 1 Left \
-stim_times 2 ${onsetRight} 'BLOCK5(18,1)' -stim_label 2 Right \
-stim_file 3 ${MotPar}'[1]' -stim_base 3 \
-stim_file 4 ${MotPar}'[2]' -stim_base 4 \
-stim_file 5 ${MotPar}'[3]' -stim_base 5 \
-stim_file 6 ${MotPar}'[4]' -stim_base 6 \
-stim_file 7 ${MotPar}'[5]' -stim_base 7 \
-stim_file 8 ${MotPar}'[6]' -stim_base 8 \
-gltsym "SYM: Left" 		-glt_label 1 "Left" \
-gltsym "SYM: Right"		-glt_label 2 "Right" \
-gltsym "SYM: Left -Right" 	-glt_label 3 "LeftVsRight" \
-gltsym "SYM: Right -Left" 	-glt_label 4 "RightVsLeft" \
-iresp 1 iresp_Left.nii -iresp 2 iresp_Right.nii \
-nobout \
-tout \
-x1D ${expID}.LRtask.B5.matrix.x1D \
-bucket ${expID}.LRtask.B5+orig. \
-cbucket ${expID}.LRtask.B5.betas.nii \
-fitts ${expID}.LRtask.B5.fitts.nii \
-xjpeg ${expID}.LRtask.B5.xmat.jpg \
-xsave

####################### See the *.x1D file (1dplot -sep_scl *.x1D)##########################

###### Make a directory to move afni files ######
cd ${sbjDir}
mkdir ./3dDec

find . -name '*.LRtask.B5*' -exec mv {} ${sbjDir}/3dDec \;
find . -name 'iresp*' -exec mv {} ${sbjDir}/3dDec \;


cp ${sbjDir}/${expID}.T1.LRtask.deoblq.ns.nii ${sbjDir}/3dDec


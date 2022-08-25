#!/bin/bash

# Preprocessing of LRtask data.
# LRtask data will be used in MVPA.
# This script will not include Talairaching and spatial smoothing.

# ===================================================================
# Hands-on fMRI workshop @VCN, Korea Univ.
# Presenter: Minsun Park, Ph.D.
# Email:  vd.mpark@gmail.com
# Distributed on 08/26/2022.
# ===================================================================


### variables ###
expID=s01
baseDir=/Users/minsunpark/Desktop/MyWorkshop/Analyzed_data/
sbjDir=${baseDir}${expID}
prefMain=${expID}.LRtask
t1input=${sbjDir}/${expID}.T1.LRtask

# Put 1 if want to make T1 deoblique.
# Put 1 if want skull stripping.
deoblqT1=0
noSkullT1=0

cd ${sbjDir}
echo '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ current folder: '${sbjDir}
	#============================================================#
	#===================== START PREPROCESSING ==================#
	#============================================================#


#========== T1 deoblique ==========#
#---- Make T1 deoblique (deoblq: deoblique)
if [ "$deoblqT1" -eq 1 ]
	then
	3dWarp -deoblique -prefix ${t1input}.deoblq.nii	\
	${t1input}.nii	
fi
t1input=${t1input}.deoblq


#======================================================#
#============1. Slice time correction (T) =============#
#======================================================#
for ii in 1 2
do
	3dTshift -slice 0 -tpattern alt+z2 \
	-prefix ${prefMain}"$ii".T.nii \
	${prefMain}"$ii".nii
done
3dTcat -prefix ${prefMain}.T.nii ${prefMain}1.T.nii ${prefMain}2.T.nii
rm *1.T.*
rm *2.T.*



#======================================================#
#============2. Head motion correction (M)=============#
#======================================================#
#--- rigid body (6 parameter) transformations.
3dvolreg -twopass -base 0 	\
-prefix ${prefMain}.TM.nii \
-dfile ${expID}.motion.1D	\
${prefMain}.T.nii
#--- To see head motion parameters,
## 1dplot -one ${expID}motion.1D'[4..6]'



# ======================================================#
# ================= 3. Corregistration =================#
# ======================================================#
#--- deoblique EPI data (deoblq)
3dWarp -deoblique -prefix ${prefMain}.TMdeoblq.nii \
${prefMain}.TM.nii


#--- Skull-stripping of MP (ns)
if [ "$noSkullT1" -eq 1 ]
	then
	3dSkullStrip -input ${t1input}.nii \
	-prefix ${t1input}.ns.nii -shrink_fac_bot_lim 0.6
fi

#---- Coregistration (aligning EPI to T1/ OUTPUT: *A+orig.)
if [ -e $t1input".nii" ]
then
		align_epi_anat.py -tshift off -volreg off -deoblique off -epi_strip None	\
		-anat_has_skull no -anat ${t1input}.ns.nii -epi ${prefMain}.TMdeoblq.nii \
		-epi_base 0 -epi2anat -suffix A

		3dAFNItoNIFTI -prefix ${prefMain}.TMdeoblqA.nii ${prefMain}.TMdeoblqA+orig.
		rm ${prefMain}.TMdeoblqA+orig.*
fi



#======================================================#
#============ 5. Intensity normalization ==============#
#======================================================#
#---- Break EPI for each run
3dTcat -prefix ${expID}.TMdeoblqA.run1.nii	\
${prefMain}.TMdeoblqA.nii'[0..135]'
3dTcat -prefix ${expID}.TMdeoblqA.run2.nii	\
${prefMain}.TMdeoblqA.nii'[136..271]'

#---- Calculate mean intensity
3dTstat -mean -prefix ${expID}.TMdeoblqA.run1.mean.nii	\
${expID}.TMdeoblqA.run1.nii
3dTstat -mean -prefix ${expID}.TMdeoblqA.run2.mean.nii	\
${expID}.TMdeoblqA.run2.nii

#---- Create brain mask
3dAutomask -dilate 5 -prefix ${expID}.LRtask.BrainMask.nii \
${prefMain}.TMdeoblqA.nii

#---- Intensity normalization
3dcalc -a ${expID}.TMdeoblqA.run1.nii \
-b ${expID}.TMdeoblqA.run1.mean.nii \
-c ${expID}.LRtask.BrainMask.nii \
-expr '(100*a/b) *step(c)' \
-prefix ${expID}.TMdeoblqA.run1.I.nii

3dcalc -a ${expID}.TMdeoblqA.run2.nii \
-b ${expID}.TMdeoblqA.run2.mean.nii \
-c ${expID}.LRtask.BrainMask.nii \
-expr '(100*a/b) *step(c)' \
-prefix ${expID}.TMdeoblqA.run2.I.nii

#---- Re-concatenate runs to EPIs
3dTcat -prefix ${prefMain}.TMdeoblqAI.nii \
${expID}.TMdeoblqA.run1.I.nii \
${expID}.TMdeoblqA.run2.I.nii

#---- Remove runs
rm -f *TMdeoblqA.run*



#============================================================#
#=====================Resampling (res)=======================#
#============================================================#
# 3dresample -master ${sbjDir}/AVmae.MT/${expID}.MT.TMdeoblqA.nii \
# -prefix ${prefMain}.TMdeoblqAIres.nii 	\
# -input ${prefMain}.TMdeoblqAI.nii


#!/bin/bash

# ===================================================================
# Hands-on fMRI workshop @VCN, Korea Univ.
# Presenter: Minsun Park, Ph.D.
# Email:  vd.mpark@gmail.com
# Distributed on 08/26/2022.
# ===================================================================

#============================================================#
#=====================Resampling (res)=======================#
#============================================================#

sbjDir=/Users/minsunpark/Desktop/MyWorkshop/Analyzed_data/s01/ROIs

cd ${sbjDir}

3dresample -master ${sbjDir}/../s01.LRtask.TMdeoblqAI.nii \
-prefix both.V1.res.nii 	\
-input both.V1.nii

3dresample -master ${sbjDir}/../s01.LRtask.TMdeoblqAI.nii \
-prefix both.V2.res.nii 	\
-input both.V2.nii

3dresample -master ${sbjDir}/../s01.LRtask.TMdeoblqAI.nii \
-prefix bothMT.res.nii 	\
-input bothMT.nii
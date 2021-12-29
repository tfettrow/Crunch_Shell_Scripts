# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

Code_dir=/blue/rachaelseidler/tfettrow/Crunch_Code

export MATLABPATH=${Code_dir}/Matlab_Scripts/helper

# Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/option2
# output_filename=option2_subject_normalized_intensity_variability.nii

# cd ${Study_dir}
# for file_to_compare in functTempTarget_*.nii; do
#    echo $this_file
#    ml fsl

#    this_file_header_info=$(fslhd $file_to_compare)
#    this_file_number_of_volumes=$(echo $this_file_header_info | grep -o dim4.* | tr -s ' ' | cut -d ' ' -f 2)
#    echo $this_file_number_of_volumes

#    if [[ $this_file_number_of_volumes == 1 ]]; then
         
#          fslmaths $file_to_compare -nan noNAN_$file_to_compare
#          gunzip -f *nii.gz
#          cp noNAN_$file_to_compare duplicate_$file_to_compare
#          gunzip -f *nii.gz
#          fslmerge -t merged_$file_to_compare noNAN_$file_to_compare duplicate_$file_to_compare
#          gunzip -f *nii.gz
#          fslmaths merged_$file_to_compare -Tmean Mean_$file_to_compare
#          gunzip -f *nii.gz
         
#          # rm merged_$file_to_compare
#          # rm duplicate_$file_to_compare
#          # rm noNAN_$file_to_compare

#          in_brain_mean=$(fslmeants -i Mean_$file_to_compare -m Mean_$file_to_compare)
#          echo $in_brain_mean

#          fslmaths $file_to_compare -div $in_brain_mean normalized_$file_to_compare
#          gunzip -f *nii.gz
#       # else
#       #    fslmaths $file_to_compare -Tmean Mean_$file_to_compare
         
#       #    in_brain_mean=$(fslmeants -i Mean_$file_to_compare -m Mean_$file_to_compare)
#       #    echo $in_brain_mean

#       #    fslmaths Mean_$file_to_compare -div $in_brain_mean normalized_$file_to_compare
#       fi
# done 


# # cd $Study_dir
# # ml fsl
# fslmerge -t all_subject_normalized_intensity.nii normalized_*
# gunzip -f *nii.gz
# fslmaths all_subject_normalized_intensity.nii -Tstd $output_filename
# gunzip -f *nii.gz
# rm normalized_*
# rm all_subject_normalized_intensity.nii







Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data

# subjects='2007,2012,2008,2021,2015'
# subjects='1002,1004,1010,1011,1013'
# subjects='1002,1004,1009,1010,1013,1018,1019,1020,1022,1026,1027'
# subjects='2002,2007,2008,2012,2013,2015,2017,2018,2020,2021,2023,2025,2026,2033,2034,2037,2038,2039,2042,2052,2059,2062,2027'
subjects='3004,3006,3007,3008,3010,3021,3023,3024,3025,3026,3027,3028,3029,3030,3034,3036,3039,3040,3042,3043,3046,3047,3051,3053,3056,3058,3059,3063,3066,3068'
# subjects='wu120_001,wu120_002,wu120_003,wu120_004,wu120_005'

output_filename=mim_asl_subject_normalized_intensity_variability.nii
# file_to_compare='warpedToSUITdartelNoBrainstem_coregToSUIT_CBmasked_coregToT1_unwarpedRealigned_slicetimed_fMRI_Run1.nii'
# file_to_compare='warpedToMNI_unwarpedRealigned_slicetimed_RestingState.nii'
# file_to_compare='warpedToMNI_unwarpedRealigned_slicetimed_fMRI_Run1.nii'

file_to_compare='warpedToMNI_perfusion_calib.nii'
# image_folder='05_MotorImagery'
# image_folder='06_Nback'
# image_folder='04_rsfMRI'
# image_folder='07_ASL/BasilCMD_calib_anat_scalib_pvcorr'
image_folder='07_ASL/BasilCMD_calib_anat_FM_scalib_pvcorr'

while IFS=',' read -ra subject_list; do
   for this_subject in "${subject_list[@]}"; do
		cd ${Study_dir}/$this_subject/Processed/MRI_files/${image_folder}/ANTS_Normalization
      echo collecting $this_subject variability estimates
   	ml fsl

      this_file_header_info=$(fslhd $file_to_compare)
      this_file_number_of_volumes=$(echo $this_file_header_info | grep -o dim4.* | tr -s ' ' | cut -d ' ' -f 2)
      echo $this_file_number_of_volumes
      
      if [[ -e ${this_subject}_normalized_intensity_for_subject_normalization_variability_analysis.nii ]]; then 
         rm ${this_subject}_normalized_intensity_for_subject_normalization_variability_analysis.nii
      fi

      if [[ $this_file_number_of_volumes == 1 ]]; then
         
         fslmaths $file_to_compare -nan noNAN_$file_to_compare
         gunzip -f *nii.gz
         cp noNAN_$file_to_compare duplicate_$file_to_compare
         gunzip -f *nii.gz
         fslmerge -t merged_$file_to_compare noNAN_$file_to_compare duplicate_$file_to_compare
         gunzip -f *nii.gz
         fslmaths merged_$file_to_compare -Tmean Mean_$file_to_compare
         gunzip -f *nii.gz
         
         rm merged_$file_to_compare
         rm duplicate_$file_to_compare
         rm noNAN_$file_to_compare

         in_brain_mean=$(fslmeants -i Mean_$file_to_compare -m Mean_$file_to_compare)
         echo $in_brain_mean

         fslmaths $file_to_compare -div $in_brain_mean ${this_subject}_normalized_intensity_for_subject_normalization_variability_analysis
         gunzip -f *nii.gz
      else
         fslmaths $file_to_compare -Tmean Mean_$file_to_compare
         
         in_brain_mean=$(fslmeants -i Mean_$file_to_compare -m Mean_$file_to_compare)
         echo $in_brain_mean

         fslmaths Mean_$file_to_compare -div $in_brain_mean ${this_subject}_normalized_intensity_for_subject_normalization_variability_analysis
         gunzip -f *nii.gz
      fi
	done
done <<< "$subjects"
cd $Study_dir

while IFS=',' read -ra subject_list; do
   for this_subject in "${subject_list[@]}"; do
   		cd ${Study_dir}/$this_subject/Processed/MRI_files/${image_folder}/ANTS_Normalization
   		cp ${this_subject}_normalized_intensity_for_subject_normalization_variability_analysis.nii $Study_dir
	done
done <<< "$subjects"

cd $Study_dir
ml fsl
fslmerge -t all_subject_normalized_intensity.nii *normalization_variability_analysis.nii
gunzip -f *nii.gz
fslmaths all_subject_normalized_intensity.nii -Tstd $output_filename
gunzip -f *nii.gz
rm *normalization_variability_analysis.nii
rm all_subject_normalized_intensity.nii
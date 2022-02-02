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

# this script requires arguments 

# example >> export_gmv_rois.sh '2059,3028,3029,3030,3034,3036,3039,3040,3042,3043,3046,3047,3051,3053,3058,3059,3063,3066,3068' 02_T1 ROI_settings_MiMRedcap_wfuMasked_CAT12.txt
# export_gmv_rois.sh '1002' 02_T1 ROI_settings_MiMRedcap_wfuMasked_CAT12.txt
# export_gmv_rois.sh '1002,1004,1007,1009,1010,1012,1013,1018,1019,1020,1022,1025,1026,1027,2002,2007,2008,2012,2013,2015,2017,2018,2020,2021,2022,2023,2025,2026,2033,2034,2037,2038,2039,2042,2052,2059,2027,3004,3006,3007,3008,3010,3021,3023,3024,3025,3026,3028,3029,3030,3034,3036,3039,3040,3042,3043,3046,3047,3051,3053,3058,3059,3063,3066,3068' 02_T1 ROI_settings_MiMRedcap_wfuMasked_CAT12.txt
# export_gmv_rois.sh '3028' 02_T1 ROI_settings_MiMRedcap_wfuMasked_CAT12.txt
# FYI>> This is setup to deal with CAT12 output atm


##################################################

argument_counter=0
for this_argument in "$@"; do
	if	[[ $argument_counter == 0 ]]; then
		subjects=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		this_struct_folder_name=$this_argument
	elif [[ $argument_counter == 2 ]]; then
		roi_settings_file=$this_argument
	fi
	(( argument_counter++ ))
done

Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data

ml fsl/6.0.3
ml gcc/5.2.0; ml ants
ml itksnap

while IFS=',' read -ra subject_list; do
    for this_subject in "${subject_list[@]}"; do
       	cd ${Study_dir}/$this_subject/Processed/MRI_files/${this_struct_folder_name}/CAT12_Analysis/mri
   	    mni_intensities_outfile=mni_${this_subject}_gmv_roi_intensities.csv
   	    subj_intensities_outfile=subj_${this_subject}_gmv_roi_intensities.csv
   	    mni_volumes_outfile=mni_${this_subject}_gmv_roi_volumes.csv
   	    subj_volumes_outfile=subj_${this_subject}_gmv_roi_volumes.csv

   	    rm mni_${this_subject}_gmv_roi_vols.csv
   	    rm subj_${this_subject}_gmv_roi_vols.csv
   	    rm $mni_intensities_outfile
   	    rm $subj_intensities_outfile
   	    rm $mni_volumes_outfile
   	    rm $subj_volumes_outfile
   		
       	cd "${Study_dir}"
		lines_to_ignore=$(awk '/#/{print NR}' $roi_settings_file)
		roi_line_numbers=$(awk 'END{print NR}' $roi_settings_file)

		for (( this_row=1; this_row<=${roi_line_numbers}; this_row++ )); do
			if ! [[ ${lines_to_ignore[*]} =~ $this_row ]]; then
				this_roi_file_corename=$(cat $roi_settings_file | sed -n ${this_row}p | cut -d ',' -f4)
				this_roi_file_corename_squeeze=$(echo $this_roi_file_corename | sed -r 's/( )+//g')
				this_roi_image_name=${Study_dir}/ROIs/${this_roi_file_corename_squeeze}.nii
				echo pulling vols for $this_roi_image_name on $this_subject
				cd ${Study_dir}/$this_subject/Processed/MRI_files/${this_struct_folder_name}/CAT12_Analysis/mri

				# # MNI ROI
				# var1="record_id, redcap_event_name"
				# var2="$H${this_subject}, base_v4_mri_arm_1"
				# echo -e "$var1\n$var2" >> "$mni_intensities_outfile"
				# echo -e "$var1\n$var2" >> "$mni_volumes_outfile"
	
				# fslmaths mwp1T1.nii -thr 0.1 -bin binary_mwp1T1.nii
				# gunzip -qf *nii.gz
			
				# fslmaths $this_roi_image_name -mas binary_mwp1T1.nii mwp1T1Masked_$this_roi_file_corename_squeeze.nii
				# gunzip -qf *nii.gz

				# avg_intensity=$(fslstats mwp1T1.nii -k mwp1T1Masked_$this_roi_file_corename_squeeze -m)
				# first_row_intensity=$(cat $mni_intensities_outfile | sed -n 1p)
				# second_row_intensity=$(cat $mni_intensities_outfile | sed -n 2p)
				# rm $mni_intensities_outfile
				# first_row_volumes=$(cat $mni_volumes_outfile | sed -n 1p)
				# second_row_volumes=$(cat $mni_volumes_outfile | sed -n 2p)
				# rm $mni_volumes_outfile

				# #dynamically determine number of voxels in ROI
				# volume_in_roi=$(fslstats mwp1T1Masked_$this_roi_file_corename_squeeze -V)
				# volume_in_roi="$(echo $volume_in_roi | cut -d' ' -f2)"
				# vol_ml=$(echo "$avg_intensity*$volume_in_roi" | bc )
				# # echo mni_vol= $vol_ml
				
				# echo -e "${first_row_intensity},${this_roi_file_corename_squeeze}\n${second_row_intensity},$avg_intensity" >> "$mni_intensities_outfile"
				# echo -e "${first_row_volumes},${this_roi_file_corename_squeeze}\n${second_row_volumes},$vol_ml" >> "$mni_volumes_outfile"

				# rm mni_${this_subject}_${this_roi_file_corename_squeeze}_histcount.csv
				# hist_count=$(fslstats mwp1T1.nii -k mwp1T1Masked_$this_roi_file_corename_squeeze -H 10 0 1)
				# echo -e "$hist_count" >> "mni_${this_subject}_${this_roi_file_corename_squeeze}_histcount.csv"
				
				# uncomment to check
				# itksnap -g mwp1T1.nii -o $this_roi_image_name








				# # SUBJ ROI

				# TF cant figure out where 02_T1/ANTS_Normalization was created!
				# soo...
				# 1) mkdir 02_T1/ANTS_Normalization
				# 2) cp 04_rsfMRI/ANTS_Normalization/warpToMNIParams_biascorrected_SkullStripped_T11InverseWarp.nii and warpToMNIParams_biascorrected_SkullStripped_T10GenericAffine.mat
				mkdir ${Study_dir}/$this_subject/Processed/MRI_files/${this_struct_folder_name}/ANTS_Normalization
				cp ${Study_dir}/$this_subject/Processed/MRI_files/04_rsfMRI/ANTS_Normalization/warpToMNIParams_SkullStripped_biascorrected_T11InverseWarp.nii ${Study_dir}/$this_subject/Processed/MRI_files/${this_struct_folder_name}/ANTS_Normalization/
				cp ${Study_dir}/$this_subject/Processed/MRI_files/04_rsfMRI/ANTS_Normalization/warpToMNIParams_SkullStripped_biascorrected_T10GenericAffine.mat  ${Study_dir}/$this_subject/Processed/MRI_files/${this_struct_folder_name}/ANTS_Normalization/

				antsApplyTransforms -d 3 -e 3 -i $this_roi_image_name -r p1T1.nii \
				-o warpedToP1_${this_roi_file_corename_squeeze}.nii -t [${Study_dir}/$this_subject/Processed/MRI_files/${this_struct_folder_name}/ANTS_Normalization/warpToMNIParams_SkullStripped_biascorrected_T10GenericAffine.mat,1]  \
				-t [${Study_dir}/$this_subject/Processed/MRI_files/${this_struct_folder_name}/ANTS_Normalization/warpToMNIParams_SkullStripped_biascorrected_T11InverseWarp.nii] -v


				var1="record_id, redcap_event_name"
				var2="$H${this_subject}, base_v4_mri_arm_1"
				echo -e "$var1\n$var2" >> "$subj_volumes_outfile"
				echo -e "$var1\n$var2" >> "$subj_intensities_outfile"
				# cat $subj_volumes_outfile

				fslmaths p1T1.nii -thr 0.1 -bin binary_p1T1.nii
				gunzip -qf *.nii.gz
				
				fslmaths warpedToP1_${this_roi_file_corename_squeeze}.nii -mas binary_p1T1.nii p1T1Masked_warpedToP1_${this_roi_file_corename_squeeze}.nii
				gunzip -qf *.nii.gz

				fslmaths p1T1Masked_warpedToP1_${this_roi_file_corename_squeeze}.nii -bin binary_p1T1Masked_warpedToP1_${this_roi_file_corename_squeeze}.nii
				gunzip -qf *.nii.gz

				
				# uncomment to check
				# itksnap -g p1T1.nii -o warpedToP1_${this_roi_file_corename_squeeze}.nii

				avg_intensity=$(fslstats p1T1.nii -k binary_p1T1Masked_warpedToP1_${this_roi_file_corename_squeeze}.nii -M)

				first_row_volumes=$(cat $subj_volumes_outfile | sed -n 1p)
				second_row_volumes=$(cat $subj_volumes_outfile | sed -n 2p)
				rm $subj_volumes_outfile

				first_row_intensity=$(cat $subj_intensities_outfile | sed -n 1p)
				second_row_intensity=$(cat $subj_intensities_outfile | sed -n 2p)
				rm $subj_intensities_outfile


				#dynamically determine number of voxels in ROI
				volume_in_roi=$(fslstats binary_p1T1Masked_warpedToP1_${this_roi_file_corename_squeeze}.nii -V)
				volume_in_roi="$(echo $volume_in_roi | cut -d' ' -f2)"
				vol_ml=$(echo "$avg_intensity*($volume_in_roi/1000)" | bc )

				echo subj_vol= $vol_ml

				echo -e "${first_row_volumes},${this_roi_file_corename_squeeze}\n${second_row_volumes},$vol_ml" >> "$subj_volumes_outfile"
				echo -e "${first_row_intensity},${this_roi_file_corename_squeeze}\n${second_row_intensity},$avg_intensity" >> "$subj_intensities_outfile"

				rm subj_${this_subject}_${this_roi_file_corename_squeeze}_histcount.csv
				hist_count=$(fslstats p1T1.nii -k binary_p1T1Masked_warpedToP1_${this_roi_file_corename_squeeze}.nii -H 10 0 1)
				echo -e "$hist_count" >> "subj_${this_subject}_${this_roi_file_corename_squeeze}_histcount.csv"
			fi
			cd ${Study_dir}
		done
	done
done <<< "$subjects"

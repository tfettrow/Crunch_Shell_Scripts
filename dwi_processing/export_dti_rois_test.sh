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

# example >> export_dti_rois.sh '1002,1004,1007,1009,1010,1011,1012,1013,1017,1018,1019,1020,1022,1024,1025,1026,1027,2002,2007,2008,2012,2013,2015,2017,2018,2020,2021,2022,2023,2025,2026,2033,2034,2037,2038,2039,2042,2052,2059,2027,3004,3006,3007,3008,3010,3021,3023,3024,3025,3026,3028,3029,3030,3034,3036,3039,3040,3042,3043,3046,3047,3051,3053,3058,3059,3063,3066,3068' 08_DWI TBSS_results_all ROI_settings_MiMRedcap_wfuMasked.txt
# export_dti_rois.sh '1011,1017,1024' 08_DWI TBSS_results_all ROI_settings_MiMRedcap_wfuMasked.txt
# export_dti_rois.sh '2062' 08_DWI TBSS_results_all ROI_settings_MiMRedcap_wfuMasked.txt
# export_dti_rois.sh '1011' 08_DWI TBSS_Results ROI_settings_MiMRedcap_wfuMasked.txt
# export_dti_rois.sh '3023_orig,3025_orig,3036_orig' 08_DWI TBSS_results_origCheck ROI_settings_MiMRedcap_wfuMasked.txt
# export_dti_rois.sh '1002,1002_NoFM,1004,1004_NoFM,1007,1007_NoFM,2002,2002_NoFM,2007,2007_NoFM,2012,2012_NoFM,3023,3023_NoFM,3025,3025_NoFM,3036,3036_NoFM' 08_DWI TBSS_results_NoFMcheck ROI_settings_MiMRedcap_wfuMasked.txt
# export_dti_rois.sh '3023_orig,3023_NoFM,3025_orig,3025_NoFM,3036_orig,3036_NoFM' 08_DWI TBSS_results_timeCheck ROI_settings_MiMRedcap_wfuMasked.txt


##################################################

argument_counter=0
for this_argument in "$@"; do
	if	[[ $argument_counter == 0 ]]; then
		subjects=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		this_dti_folder_name=$this_argument
	elif [[ $argument_counter == 2 ]]; then
		TBSS_dir=$this_argument
	elif [[ $argument_counter == 3 ]]; then
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
       	cd ${Study_dir}/$this_subject/Processed/MRI_files/${this_dti_folder_name}
       	pwd
   	    subj_intensities_outfile=subj_${this_subject}_dti_roi_fa.csv
   	    subjectid=$(echo ${this_subject} | egrep -o '[[:digit:]]{4}' | head -n1)
   	    rm subj_${this_subject}_dti_roi_fa.csv
   	    gunzip -qf *nii.gz
   	    # # SUBJ ROI
		# Eddy_image=se_epi_unwarped_brain.nii
		Eddy_image=eddycorrected_FAt.nii
		this_core_file_name=$(echo $Eddy_image | cut -d. -f 1)
		# go into 02_T1 and grab the c2biascorrected_T1.nii .. binary threshhold and mv to dti folder
		cd ${Study_dir}/$this_subject/Processed/MRI_files/02_T1
		
		cp c2biascorrected_T1.nii ${Study_dir}/$this_subject/Processed/MRI_files/${this_dti_folder_name}
		cp SkullStripped_biascorrected_T1.nii ${Study_dir}/$this_subject/Processed/MRI_files/${this_dti_folder_name}

   		cd ${Study_dir}/$this_subject/Processed/MRI_files/${this_dti_folder_name}
   		flirt -in SkullStripped_biascorrected_T1 -ref eddycorrected_FA.nii -out dtiMatched_SkullStripped_biascorrected_T1 -omat transf_T1_to_dti.mat
		gunzip -qf *nii.gz
		flirt -in c2biascorrected_T1.nii -ref eddycorrected_FA.nii -out dtiMatched_c2biascorrected_T1.nii -applyxfm -init transf_T1_to_dti.mat

       	cd ${Study_dir}
		lines_to_ignore=$(awk '/#/{print NR}' $roi_settings_file)
		roi_line_numbers=$(awk 'END{print NR}' $roi_settings_file)

		for (( this_row=1; this_row<=${roi_line_numbers}; this_row++ )); do
			if ! [[ ${lines_to_ignore[*]} =~ $this_row ]]; then
				this_roi_file_corename=$(cat $roi_settings_file | sed -n ${this_row}p | cut -d ',' -f4)
				this_roi_file_corename_squeeze=$(echo $this_roi_file_corename | sed -r 's/( )+//g')
				this_roi_image_name=${Study_dir}/ROIs/${this_roi_file_corename_squeeze}.nii
				echo pulling vols for $this_roi_image_name on $this_subject
				cd ${Study_dir}/$this_subject/Processed/MRI_files/${this_dti_folder_name}
                
				
				# itksnap -g dtiMatched_binary_c2biascorrected_T1.nii -o dtiMatched_$this_roi_file_corename_squeeze.nii

				applywarp --ref=$Eddy_image --in=$this_roi_image_name --warp=${Study_dir}/${this_subject}/Processed/MRI_files/${this_dti_folder_name}/${TBSS_dir}/FA/${subjectid}_eddycorrected_FA_FA_to_target_warp_inv.nii.gz \
				--out=dtiMatched_${this_roi_file_corename_squeeze}.nii --interp=nn
				gunzip -qf *nii.gz
				# itksnap -g $Eddy_image -o dtiMatched_${this_roi_file_corename_squeeze}.nii

				fslmaths dtiMatched_c2biascorrected_T1.nii -thr 0.1 -bin binary_dtiMatched_c2biascorrected_T1.nii

				fslmaths dtiMatched_$this_roi_file_corename_squeeze.nii -mas binary_dtiMatched_c2biascorrected_T1.nii c2biascorrectedT1Masked_dtiMatched_$this_roi_file_corename_squeeze.nii
				gunzip -qf *nii.gz

				# itksnap -g binary_dtiMatched_c2biascorrected_T1.nii -o c2biascorrectedT1Masked_dtiMatched_$this_roi_file_corename_squeeze.nii
				# itksnap -g eddycorrected_FAt.nii -o c2biascorrectedT1Masked_dtiMatched_$this_roi_file_corename_squeeze.nii				

				var1="record_id, redcap_event_name"
				var2="$H${this_subject}, base_v4_mri_arm_1"
				echo -e "$var1\n$var2" >> "$subj_intensities_outfile"

				avg_intensity=$(fslstats eddycorrected_FAt.nii -k c2biascorrectedT1Masked_dtiMatched_$this_roi_file_corename_squeeze.nii -M)

				first_row_intensity=$(cat $subj_intensities_outfile | sed -n 1p)
				second_row_intensity=$(cat $subj_intensities_outfile | sed -n 2p)
				rm $subj_intensities_outfile

				echo -e "${first_row_intensity},${this_roi_file_corename_squeeze}\n${second_row_intensity},$avg_intensity" >> "$subj_intensities_outfile"

				rm subj_${this_subject}_${this_roi_file_corename_squeeze}_histcount.csv
				hist_count=$(fslstats binary_dtiMatched_c2biascorrected_T1.nii -k c2biascorrectedT1Masked_dtiMatched_$this_roi_file_corename_squeeze.nii -H 10 0 1)
				echo -e "$hist_count" >> "subj_${this_subject}_${this_roi_file_corename_squeeze}_histcount.csv"
			fi
			cd ${Study_dir}
		done
	done
done <<< "$subjects"

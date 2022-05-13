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

# example >> export_asl_rois_to_redcap.sh '1002,1004,1009,1010,1011,1012,1013,1017,1018,1019,1020,1022,1024,1025,1026,1027,2002,2007,2008,2012,2013,2015,2017,2018,2020,2021,2022,2023,2025,2026,2033,2034,2037,2038,2039,2042,2052,2059,2027,3004,3006,3007,3008,3010,3021,3023,3024,3025,3026,3028,3029,3030,3036,3039,3040,3042,3043,3046,3047,3051,3053,3056,3058,3059,3063,3066,3068' ROI_settings_MiMRedcap_wfuMasked.txt
# export_asl_rois_to_redcap.sh '1012,2017,3004' ROI_settings_MiMRedcap_wfuMasked.txt
# export_asl_rois_to_redcap.sh '1011,2017,1024,1025' ROI_settings_MiMRedcap_wfuMasked.txt
#'1002,1004,1007,1009,1010,1013,1018,1019,1020,1022,1025,1026,1027,2002,2007,2012,2013,2015,2017,2018,2020,2021,2022,2023,2025,2026,2033,2034,2037,2038,2039,2042,2052,2059,2062,2027,3004,3006,3007,3008,3010,3021,3026,3028,3029,3030,3039,3040,3042,3043,3046,3047'
##################################################

argument_counter=0
for this_argument in "$@"; do
	if [[ $argument_counter == 0 ]]; then
		subjects=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		Matlab_dir=$this_argument
	elif [[ $argument_counter == 2 ]]; then
		Template_dir=$this_argument
	elif [[ $argument_counter == 3 ]]; then
		roi_settings_file=$this_argument
	fi
	(( argument_counter++ ))
done

Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data

	
#####################################################################################################################################################
ml fsl/6.0.3
ml gcc/5.2.0

while IFS=',' read -ra subject_list; do
    for this_subject in "${subject_list[@]}"; do
        Results_folder_name=BasilCMD_calib_anat_FM_scalib_pvcorr
       	cd ${Study_dir}/${this_subject}/Processed/MRI_files/07_ASL/${Results_folder_name}/ANTS_Normalization
		pwd
        cp ${Template_dir}/MNI_2mm.nii ${Study_dir}/${this_subject}/Processed/MRI_files/07_ASL/${Results_folder_name}/ANTS_Normalization
        outfile_fsl_perfusion=${this_subject}_fsl_perfusion.csv
   	    outfile_fsl_perfusion_calib=${this_subject}_fsl_perfusion_calib.csv
		if [ -e ${this_subject}_fsl_perfusion.csv ]; then
			rm ${this_subject}_fsl_perfusion.csv
		fi
		if [ -e ${this_subject}_fsl_perfusion_calib.csv ]; then
			rm ${this_subject}_fsl_perfusion_calib.csv
		fi
		ls       	
        var1="record_id,redcap_event_name"
        var2="$H${this_subject},base_v4_mri_arm_1" 
        echo -e "$var1\n$var2" >> "$outfile_fsl_perfusion"
        echo -e "$var1\n$var2" >> "$outfile_fsl_perfusion_calib"
		echo "check point 1"
        cd "${Study_dir}"
		lines_to_ignore=$(awk '/#/{print NR}' $roi_settings_file)
		roi_line_numbers=$(awk 'END{print NR}' $roi_settings_file)
		for (( this_row=1; this_row<=${roi_line_numbers}; this_row++ )); do
			if ! [[ ${lines_to_ignore[*]} =~ $this_row ]]; then
				this_roi_file_corename=$(cat $roi_settings_file | sed -n ${this_row}p | cut -d ',' -f4)
				this_roi_file_corename_squeeze=$(echo $this_roi_file_corename | sed -r 's/( )+//g')
				this_roi_image_name=${Study_dir}/ROIs/${this_roi_file_corename_squeeze}.nii
				echo "check 2"
				
				echo "pulling asl betas for $this_roi_image_name on ${this_subject}"
				cd ${Study_dir}/${this_subject}/Processed/MRI_files/07_ASL/${Results_folder_name}/ANTS_Normalization/


				beta=0
				beta=$(fslmeants -i warpedToMNI_perfusion.nii -m $this_roi_image_name)
				# echo $this_roi_file_corename_squeeze
				first_row=$(cat $outfile_fsl_perfusion | sed -n 1p)
				second_row=$(cat $outfile_fsl_perfusion | sed -n 2p) 
				rm $outfile_fsl_perfusion
				echo -e "${first_row},${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile_fsl_perfusion"
				

				beta=0
				beta=$(fslmeants -i warpedToMNI_perfusion_calib.nii -m $this_roi_image_name)
				# echo $this_roi_file_corename_squeeze
				first_row=$(cat $outfile_fsl_perfusion_calib | sed -n 1p)
				second_row=$(cat $outfile_fsl_perfusion_calib | sed -n 2p) 
				rm $outfile_fsl_perfusion_calib
				echo -e "${first_row},${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile_fsl_perfusion_calib"
 			fi
            cd ${Study_dir}			
		done
		cd ${Study_dir}
	done
done <<< "$subjects"
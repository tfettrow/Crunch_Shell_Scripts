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

# example >> check_asl_rois.sh '1002,1004,1009,1010,1013,1018,1019,1020,1022,1026,1027,2002,2007,2008,2012,2013,2015,2017,2018,2020,2021,2022,2023,2025,2026,2033,2034,2037,2038,2039,2042,2052,2059,2062,2027,3004,3006,3007,3008,3010,3021,3023,3024,3025,3026,3027,3028,3029,3030,3034,3036,3039,3040,3042,3043,3046,3047,3051,3053,3056,3058,3059,3063,3066,3068' ROI_settings_MiMRedcap_wfuMasked.txt
#'1002,1004,1007,1009,1010,1013,1018,1019,1020,1022,1025,1026,1027,2002,2007,2012,2013,2015,2017,2018,2020,2021,2022,2023,2025,2026,2033,2034,2037,2038,2039,2042,2052,2059,2062,2027,3004,3006,3007,3008,3010,3021,3026,3028,3029,3030,3039,3040,3042,3043,3046,3047'
##################################################

argument_counter=0
for this_argument in "$@"; do
	if	[[ $argument_counter == 0 ]]; then
		subjects=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		roi_settings_file=$this_argument
	fi
	(( argument_counter++ ))
done

Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data
Template_dir=/blue/rachaelseidler/tfettrow/Crunch_Code/MR_Templates
	
#####################################################################################################################################################
# ml fsl/6.0.1
ml itksnap
while IFS=',' read -ra subject_list; do
       for this_subject in "${subject_list[@]}"; do
       	# Results_folder_name=BasilCMD_calib_anat_FM_scalib_pvcorr
       	Results_folder_name=BasilCMD_calib_anat_scalib_pvcorr
       	
       	cd "${Study_dir}"
		
		lines_to_ignore=$(awk '/#/{print NR}' $roi_settings_file)
		roi_line_numbers=$(awk 'END{print NR}' $roi_settings_file)
		for (( this_row=1; this_row<=${roi_line_numbers}; this_row++ )); do
			if ! [[ ${lines_to_ignore[*]} =~ $this_row ]]; then
				this_roi_file_corename=$(cat $roi_settings_file | sed -n ${this_row}p | cut -d ',' -f4)
				this_roi_file_corename_squeeze=$(echo $this_roi_file_corename | sed -r 's/( )+//g')
				this_roi_image_name=${Study_dir}/ROIs/${this_roi_file_corename_squeeze}.nii
				
				echo checking asl rois for $this_roi_image_name on $this_subject
				cd ${Study_dir}/$this_subject/Processed/MRI_files/07_ASL/$Results_folder_name/ANTS_Normalization/
				itksnap -g warpedToMNI_perfusion.nii -o $this_roi_image_name
			
				cd ${Study_dir}
 			fi			
		done
		cd ${Study_dir}
	done
 done <<< "$subjects"

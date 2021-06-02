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


# example >> check_roi_boundaries.sh subject_id folder_name file_to_check roi_settings_file.txt
# example >> check_roi_boundaries.sh 1013 04_rsfMRI/ANTS_Normalization smoothed_warpedToMNI_unwarpedRealigned_slicetimed_RestingState.nii ROI_settings_conn_wu120_all_wb_cb.txt

argument_counter=0
for this_argument in "$@"; do
	if	[[ $argument_counter == 0 ]]; then
		this_subject=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		this_folder_name=$this_argument
	elif [[ $argument_counter == 2 ]]; then
		this_file_to_check=$this_argument
	elif [[ $argument_counter == 3 ]]; then
		roi_settings_file=$this_argument
	fi
	(( argument_counter++ ))
done

ml fsl/6.0.1
Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data
outfile=check_ROIoverlap_${this_file_to_check}.csv

cd ${Study_dir}/$this_subject/Processed/MRI_files/${this_folder_name}

if [ -e check_ROIoverlap_${this_file_to_check}.csv ]; then
	rm check_ROIoverlap_${this_file_to_check}.csv
fi

this_file_to_check_corename=$(echo $this_file_to_check | cut -d. -f 1)
this_file_to_check_info=$(fslhd $this_file_to_check)
this_file_to_check_number_of_volumes=$(echo $this_file_to_check_info | grep -o dim4.* | tr -s ' ' | cut -d ' ' -f 2)
	
echo $this_file_to_check_number_of_volumes volumes in $this_file_to_check
# if [[ $this_file_to_check_number_of_volumes == 1 ]]; then
#  	echo "need to setup 1 vol check"
#  	exit 1
# else
#  	fslsplit $this_file_to_check
# fi

# this_volume_index=0
# for this_volume_file in vol0*; do
echo -e  >> "$outfile"
	cd "${Study_dir}"
	lines_to_ignore=$(awk '/#/{print NR}' $roi_settings_file)
	roi_line_numbers=$(awk 'END{print NR}' $roi_settings_file)
	for (( this_row=1; this_row<=${roi_line_numbers}; this_row++ )); do
		if ! [[ ${lines_to_ignore[*]} =~ $this_row ]]; then
			this_roi_file_corename=$(cat $roi_settings_file | sed -n ${this_row}p | cut -d ',' -f4)
			this_roi_file_corename_squeeze=$(echo $this_roi_file_corename | sed -r 's/( )+//g')
			this_roi_image_name=${Study_dir}/ROIs/${this_roi_file_corename_squeeze}.nii
		
			cd ${Study_dir}/$this_subject/Processed/MRI_files/${this_folder_name}/

			val=$(fslmeants -i $this_file_to_check -m $this_roi_image_name)
			outfile_prev=$(cat $outfile)
			echo $this_file_to_check $this_roi_image_name $val
			echo -e "${outfile_prev}\n${this_file_to_check},${this_roi_image_name},${val}" >> "$outfile"
			# if [[ $val = NaN ]]; then
			# 	echo $this_volume_file $this_roi_image_name are problematic
			# fi
		fi
		cd ${Study_dir}
	done

	# (( this_volume_index++ ))
# done

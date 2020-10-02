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

subject=$1


Subject_dir=/ufrc/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data/${subject}
cd "${Subject_dir}"
lines_to_ignore=$(awk '/#/{print NR}' file_settings.txt)
fmri_line_numbers_in_file_info=$(awk '/functional_run/{print NR}' file_settings.txt)

fmri_line_numbers_to_process=$fmri_line_numbers_in_file_info

this_index_fmri=0
for item_to_ignore in ${lines_to_ignore[@]}; do
	for item_to_check in ${fmri_line_numbers_in_file_info[@]}; do
  		if [[ $item_to_check == $item_to_ignore ]]; then 
  			remove_this_item_fmri[$this_index_fmri]=$item_to_ignore
  			(( this_index_fmri++ ))
  		fi
  	done
done

for item_to_remove_fmri in ${remove_this_item_fmri[@]}; do
	fmri_line_numbers_to_process=$(echo ${fmri_line_numbers_to_process[@]/$item_to_remove_fmri})
done

this_index=0
for this_line_number in ${fmri_line_numbers_to_process[@]}; do
	fmri_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
	(( this_index++ ))
done

fmri_processed_folder_names=$(echo "${fmri_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	
data_folder_to_analyze=($fmri_processed_folder_names)
#cd $Subject_dir/Processed/MRI_files
for this_functional_run_folder in ${data_folder_to_analyze[@]}; do
	cd ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}

	#zip processed_files.zip *
	#wait
	
	shopt -s extglob
	#rm !(art_*|ARTscreenshot*|Condition_Onsets*|smoothed*|fMRI_Run*|*.json)
	rm !(Condition_Onsets*|slicetimed*|fMRI_Run*|*.json)
	#wait
################################################################
	cd ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization

	#zip ants_processed_files.zip *
	#wait

	# rm !(art_*|ARTscreenshot*|Condition_Onsets*|smoothed*|warpedToMNI_biascorrected*|fMRI_Run*|*.json|ANTs_*)
	rm !(Condition_Onsets*|fMRI_Run*|*.json)
	#shopt -u extglob

done
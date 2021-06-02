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

argument_counter=0
for this_argument in "$@"
do
	if	[[ $argument_counter == 0 ]]; then
		Matlab_dir=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		Template_dir=$this_argument
	elif [[ $argument_counter == 2 ]]; then
    	Subject_dir=$this_argument
	else
		preprocessing_steps[argument_counter]="$this_argument"
	fi
	(( argument_counter++ ))
done
	export MATLABPATH=${Matlab_dir}/helper
	ml matlab/2020a
	ml gcc/5.2.0; ml ants ## ml gcc/9.3.0; ml ants/2.3.4
	ml fsl/6.0.3
	
	cd $Subject_dir

	lines_to_ignore=$(awk '/#/{print NR}' file_settings.txt)

	fmri_line_numbers_in_file_info=$(awk '/functional_run/{print NR}' file_settings.txt)
	fmri_fieldmap_line_numbers_in_file_info=$(awk '/fmri_fieldmap/{print NR}' file_settings.txt)
	t1_line_numbers_in_file_info=$(awk '/t1/{print NR}' file_settings.txt)

	fmri_line_numbers_to_process=$fmri_line_numbers_in_file_info
	fieldmap_line_numbers_to_process=$fmri_fieldmap_line_numbers_in_file_info
	t1_line_numbers_to_process=$t1_line_numbers_in_file_info

	this_index_fmri=0
	this_index_fieldmap=0
	this_index_t1=0
	for item_to_ignore in ${lines_to_ignore[@]}; do
		for item_to_check in ${fmri_line_numbers_in_file_info[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_fmri[$this_index_fmri]=$item_to_ignore
  				(( this_index_fmri++ ))
  			fi
  		done
  		for item_to_check in ${fieldmap_line_numbers_to_process[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_fieldmap[$this_index_fieldmap]=$item_to_ignore
  				(( this_index_fieldmap++ ))
  			fi
  		done
  		for item_to_check in ${t1_line_numbers_to_process[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_t1[$this_index_t1]=$item_to_ignore
  				(( this_index_t1++ ))
  			fi
  		done
	done

	for item_to_remove_fmri in ${remove_this_item_fmri[@]}; do
		fmri_line_numbers_to_process=$(echo ${fmri_line_numbers_to_process[@]/$item_to_remove_fmri})
	done
	for item_to_remove_fieldmap in ${remove_this_item_fieldmap[@]}; do
		fieldmap_line_numbers_to_process=$(echo ${fieldmap_line_numbers_to_process[@]/$item_to_remove_fieldmap})
	done
	for item_to_remove_t1 in ${remove_this_item_t1[@]}; do
		t1_line_numbers_to_process=$(echo ${t1_line_numbers_to_process[@]/$item_to_remove_t1})
	done

	this_index=0
	for this_line_number in ${fmri_line_numbers_to_process[@]}; do
		fmri_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done
	
	this_index=0
	for this_line_number in ${fieldmap_line_numbers_to_process[@]}; do
		fmri_fieldmap_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done
	
	this_index=0
	for this_line_number in ${t1_line_numbers_to_process[@]}; do
		t1_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done
	
	fmri_processed_folder_names=$(echo "${fmri_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	fmri_fieldmap_processed_folder_names=$(echo "${fmri_fieldmap_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	t1_processed_folder_names=$(echo "${t1_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

for this_preprocessing_step in ${preprocessing_steps[@]}; do
	if [[ $this_preprocessing_step == "copy_fmri_for_conn" ]]; then
		data_folder_to_analyze=($fmri_processed_folder_names)
		for this_functional_run_folder in ${data_folder_to_analyze[@]}; do
			mkdir -p "${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/conn_processing"
			cp ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/Condition_Onsets*.csv ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/conn_processing
			cp ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/unwarpedRealigned* ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/conn_processing
			cp ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/rp_* ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/conn_processing
			cp ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/slicetimed_* ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/conn_processing			
		done
		echo This step took $SECONDS seconds to execute
   		cd "${Subject_dir}"
		echo "copy fmri for conn processing: $SECONDS sec" >> preprocessing_log.txt
		SECONDS=0
	fi
	if [[ $this_preprocessing_step == "copy_t1_for_vbm" ]]; then
		data_folder_to_copy_from=('04_rsfMRI') # BEWARE, this is hard coded specific to MiM
		data_folder_to_copy_to=($t1_processed_folder_names)
		mkdir -p "${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization"
		cp ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_from}/ANTS_Normalization/warpToMNIParams_biascorrected_SkullStripped_T10GenericAffine.mat ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization
		cp ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_from}/ANTS_Normalization/warpToMNIParams_biascorrected_SkullStripped_T11InverseWarp.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization
		cp ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_from}/ANTS_Normalization/warpToMNIParams_biascorrected_SkullStripped_T11Warp.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization
		cp ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_from}/ANTS_Normalization/*T1*.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization
	fi
done
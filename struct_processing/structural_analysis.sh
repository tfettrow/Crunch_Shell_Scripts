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

argument_counter=0
for this_argument in "$@"
do
	if	[[ $argument_counter == 0 ]]; then
		Matlab_dir=$this_argument
	elif [[ $argument_counter == 1 ]]; then
    	Template_dir=$this_argument
    elif [[ $argument_counter == 2 ]]; then
    	Study_dir=$this_argument
    elif [[ $argument_counter == 3 ]]; then
    	subject=$this_argument
    else
		struct_processing_steps="$this_argument"
	fi
	(( argument_counter++ ))
done
export MATLABPATH=${Matlab_dir}/helper
cd "$Study_dir"
ml matlab/2020a
matlab -nodesktop -nosplash -r "try; cat12StructuralAnalysis('subjects',$subject,'t1_folder','02_T1','t1_filename','T1.nii','steps_to_run_vector',[1 0 0 0 0],'template_dir','/blue/rachaelseidler/tfettrow/Crunch_Code/MR_Templates'); catch; end; quit"




################ legacy ########################
# ml matlab/2020a
# matlab -nodesktop -nosplash -r "try; cat12StructuralAnalysis('subjects',{$subject}','t1_folder','02_T1','t1_filename','T1.nii','steps_to_run_vector',[1 0 0 0 0],'template_dir','/blue/rachaelseidler/tfettrow/Crunch_Code/MR_Templates'); catch; end; quit"

# Subject_dir=$Study_dir/$subject

# 	export MATLABPATH=${Matlab_dir}/helper
# 	ml matlab/2020a
# 	ml gcc/5.2.0; ml ants ## ml gcc/9.3.0; ml ants/2.3.4
# 	ml fsl/6.0.1
# 	ml itksnap
# 	cd $Subject_dir

# 	lines_to_ignore=$(awk '/#/{print NR}' file_settings.txt)

# 	t1_line_numbers_in_file_info=$(awk '/t1/{print NR}' file_settings.txt)

# 	t1_line_numbers_to_process=$t1_line_numbers_in_file_info

# 	this_index_t1=0
# 	for item_to_ignore in ${lines_to_ignore[@]}; do
#   		for item_to_check in ${t1_line_numbers_to_process[@]}; do
#   			if [[ $item_to_check == $item_to_ignore ]]; then 
#   				remove_this_item_t1[$this_index_t1]=$item_to_ignore
#   				(( this_index_t1++ ))
#   			fi
#   		done
# 	done

# 	for item_to_remove_t1 in ${remove_this_item_t1[@]}; do
# 		t1_line_numbers_to_process=$(echo ${t1_line_numbers_to_process[@]/$item_to_remove_t1})
# 	done

# 	this_index=0
# 	for this_line_number in ${t1_line_numbers_to_process[@]}; do
# 		t1_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
# 		(( this_index++ ))
# 	done
	
# 	t1_processed_folder_names=$(echo "${t1_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')


# 	for this_preprocessing_step in "${struct_processing_steps[@]}"; do
# 		if [[ $this_preprocessing_step ==  "check_struct_segments" ]]; then
# 			data_folder_to_analyze=($t1_processed_folder_names)
# 			echo checking $subject
# 			itksnap -g ${Study_dir}/ROIs/MNI_2mm.nii -o ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/CAT12_Analysis/mri/mwp1T1.nii
# 		fi
# 	done

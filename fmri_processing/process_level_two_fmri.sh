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

#subjects=('1002,1004,1010,1011')
#subjects=('2002,2015,2018,2021')
# subjects=('2002,2015,2018,2012,2025,2020')

#group_name=(youngAdult)
# group_name=(oldAdult)

# fmri_processed_folder_names=('05_MotorImagery')
fmri_processed_folder_names=('06_Nback')

####### find roi locations ##############################
#roi_analysis_steps=("level_two_stats_withinGroup")
#roi_analysis_steps=("level_two_stats_betweenGroup")
roi_analysis_steps=("level_two_stats_sweNP")

# roi_analysis_steps=("convert_manually_entered_roi_to_voxel_coordinates")
#roi_analysis_steps=("create_roi_sphere")

#roi_analysis_steps=("extract_intensity_from_existing_rois")

#roi_analysis_steps=("convert_to_mni_for_significant_clusters")
#roi_analysis_steps=("extract_intensity_from_significant_clusters")
#roi_analysis_steps=("collect_roi_from_significant_clusters")

#roi_analysis_steps=("collect_roi")
##################################################

Code_dir=/blue/rachaelseidler/tfettrow/Crunch_Code
export MATLABPATH=${Code_dir}/Matlab_Scripts/helper

#for SUB in ${subjects[@]}; do
Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data/
cd "${Study_dir}"

for this_roi_analysis_step in "${roi_analysis_steps[@]}"; do
	if [[ $this_roi_analysis_step == "level_two_stats_withinGroup" ]]; then
		for this_functional_run_folder in ${fmri_processed_folder_names[@]}; do
			# task_folder = '06_Nback';
			# subject_codes = {'1002', '1004'}; % need to figure out how to pass cell from shell
			echo $this_functional_run_folder
			echo $group_name
			echo ${subjects[@]}
			mkdir -p "${Study_dir}/withinGroup_Results/MRI_files/${this_functional_run_folder}/${group_name}"
			ml matlab
   			matlab -nodesktop -nosplash -r "try; level_two_stats_withinGroup(1, '$this_functional_run_folder', '${subjects}', '$group_name'); catch; end; quit"
   		done


   		#echo This step took $SECONDS seconds to execute
   		#cd "${Subject_dir}"
		#echo "Level Two Main Effect: $SECONDS sec" >> preprocessing_log.txt
		#SECONDS=0
	fi
	if [[ $this_roi_analysis_step == "level_two_stats_sweNP" ]]; then
		for this_functional_run_folder in ${fmri_processed_folder_names[@]}; do
			# task_folder = '06_Nback';
			# subject_codes = {'1002', '1004'}; % need to figure out how to pass cell from shell
			# echo $this_functional_run_folder
			# echo $group_name
			# echo ${subjects[@]}
			# mkdir -p "${Study_dir}/withinGroup_Results/MRI_files/${this_functional_run_folder}/${group_name}"
			ml matlab/2020a
   			matlab -nodesktop -nosplash -r "try; level_two_stats_fmri_3FacSWE; catch; end; quit"
   		done

   		
   		#echo This step took $SECONDS seconds to execute
   		#cd "${Subject_dir}"
		#echo "Level Two Main Effect: $SECONDS sec" >> preprocessing_log.txt
		#SECONDS=0
	fi

# replace with twoSampTtest... 
#####################################################################################################################################################
	#if [[ $this_roi_analysis_step == "level_two_stats_betweenGroup" ]]; then
	#	for this_functional_run_folder in ${fmri_processed_folder_names[@]}; do
	#		# task_folder = '06_Nback';
	#		# subject_codes = {'1002', '1004'}; % need to figure out how to pass cell from shell
	#		echo $this_functional_run_folder
	#		echo $group_name
	#		echo ${subjects[@]}
	#		mkdir -p "${Study_dir}/betweenGroup_Results/MRI_files/${this_functional_run_folder}/${group_name}"
	#		ml matlab
   	#		matlab -nodesktop -nosplash -r "try; level_two_stats_betweenGroup(1, '$this_functional_run_folder', '${subjects}'); catch; end; quit"
   	#	done
   	#	echo This step took $SECONDS seconds to execute
   	#	#cd "${Subject_dir}"
	#	#echo "Level Two Main Effect: $SECONDS sec" >> preprocessing_log.txt
	#	#SECONDS=0
	#fi
#####################################################################################################################################################

done

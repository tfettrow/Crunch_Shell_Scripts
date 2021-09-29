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
	ml matlab/2020b
	ml gcc/5.2.0; ml ants ## ml gcc/9.3.0; ml ants/2.3.4
	ml fsl/6.0.3
	
	cd $Subject_dir
	subject_id=$(basename $Subject_dir)

	lines_to_ignore=$(awk '/#/{print NR}' file_settings.txt)

	asl_line_numbers_in_file_info=$(awk '/asl/{print NR}' file_settings.txt)
	t1_line_numbers_in_file_info=$(awk '/t1/{print NR}' file_settings.txt)

	asl_line_numbers_to_process=$asl_line_numbers_in_file_info
	t1_line_numbers_to_process=$t1_line_numbers_in_file_info

	this_index_asl=0
	this_index_t1=0
	for item_to_ignore in ${lines_to_ignore[@]}; do
		for item_to_check in ${asl_line_numbers_in_file_info[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_asl[$this_index_asl]=$item_to_ignore
  				(( this_index_asl++ ))
  			fi
  		done
  		for item_to_check in ${t1_line_numbers_to_process[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_t1[$this_index_t1]=$item_to_ignore
  				(( this_index_t1++ ))
  			fi
  		done
	done

	for item_to_remove_asl in ${remove_this_item_asl[@]}; do
		asl_line_numbers_to_process=$(echo ${asl_line_numbers_to_process[@]/$item_to_remove_asl})
	done
	for item_to_remove_t1 in ${remove_this_item_t1[@]}; do
		t1_line_numbers_to_process=$(echo ${t1_line_numbers_to_process[@]/$item_to_remove_t1})
	done

	this_index=0
	for this_line_number in ${asl_line_numbers_to_process[@]}; do
		asl_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done
		
	this_index=0
	for this_line_number in ${t1_line_numbers_to_process[@]}; do
		t1_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done
	
	asl_processed_folder_names=$(echo "${asl_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	t1_processed_folder_names=$(echo "${t1_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

for this_preprocessing_step in ${preprocessing_steps[@]}; do
	if [[ $this_preprocessing_step == "package4MRIcloud" ]]; then
		asl_folder=($asl_processed_folder_names)
		t1_folder=($t1_processed_folder_names)
			cd ${Subject_dir}/Processed/MRI_files/${asl_folder}/
			ml fsl/5.0.8
			fslchfiletype ANALYZE ASL_Run1.nii ${subject_id}_ASL
			mv ${subject_id}_ASL* /blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data/MRIcloud_upload/ASL

			cd ${Subject_dir}/Processed/MRI_files/${t1_folder}/
			fslchfiletype ANALYZE T1.nii ${subject_id}_T1
			mv ${subject_id}_T1* /blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data/MRIcloud_upload/T1
	fi

	if [[ $this_preprocessing_step == "realign_asl" ]]; then
		asl_folders=($asl_processed_folder_names)
		for this_asl_folder in ${asl_folders[@]}; do
			cd ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/
			matlab -nodesktop -nosplash -r "try; realign_asl('ASL_Run1.nii'); catch; end; quit"
			fslroi realigned_ASL_Run1.nii M0_calibration.nii 0 1
			fslroi realigned_ASL_Run1.nii noM0_realigned_ASL_Run1.nii 1 184
			gunzip -f *nii.gz
		done
	fi

	if [[ $this_preprocessing_step == "copy_skullstripped_biascorrected_t1_4_ants" ]]; then
		this_t1_folder=($t1_processed_folder_names)
		data_folder_to_analyze=($asl_processed_folder_names)
		for this_asl_folder in ${data_folder_to_analyze[@]}; do
			mkdir -p ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization
			cp ${Subject_dir}/Processed/MRI_files/${this_t1_folder}/SkullStripped_biascorrected_T1.nii ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization
		done
	fi

	if [[ $this_preprocessing_step == "asl_norm" ]]; then
		data_folder_to_analyze=($asl_processed_folder_names)
		for this_asl_folder in ${data_folder_to_analyze[@]}; do
			cd ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization
			cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/noM0_realigned_ASL_Run1.nii ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization
			cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/meanASL_Run1.nii ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization
			cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/M0_calibration.nii ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization
            cp ${Template_dir}/MNI_2mm.nii ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization

			T1_Template=SkullStripped_biascorrected_T1.nii
			Mean_ASL=meanASL_Run1.nii

			this_core_file_name=$(echo $Mean_ASL | cut -d. -f 1)
			echo 'registering' $Mean_ASL 'to' $T1_Template
			# moving low res func to high res T1
			antsRegistration --dimensionality 3 --float 0 \
			--output [warpToT1Params_${this_core_file_name},warpToT1Estimate_${this_core_file_name}.nii] \
			--interpolation Linear \
			--winsorize-image-intensities [0.005,0.995] \
			--use-histogram-matching 0 \
			--initial-moving-transform [$T1_Template,$Mean_ASL,1] \
			--transform Rigid[0.1] \
			--metric MI[$T1_Template,$Mean_ASL,1,32,Regular,0.25] \
			--convergence [1000x500x250x100,1e-6,10] \
			--shrink-factors 8x4x2x1 \
			--smoothing-sigmas 3x2x1x0vox

			gunzip -f *nii.gz 
			antsApplyTransforms -d 3 -e 3 -i ${this_core_file_name}.nii -r SkullStripped_biascorrected_T1.nii \
				-n BSpline -o warpedToT1_${this_core_file_name}.nii -t [warpToT1Params_${this_core_file_name}0GenericAffine.mat,0] -v 

			outputFolder=${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization
			T1_Template=${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization/SkullStripped_biascorrected_T1.nii
			MNI_Template=${Template_dir}/MNI_1mm.nii
			this_core_file_name=SkullStripped_biascorrected_T1
			echo 'registering' $T1_Template 'to' $MNI_Template
			antsRegistration --dimensionality 3 --float 0 \
			    --output [$outputFolder/warpToMNIParams_${this_core_file_name},$outputFolder/warpToMNIEstimate_${this_core_file_name}.nii] \
			    --interpolation Linear \
			    --winsorize-image-intensities [0.01,0.99] \
			    --use-histogram-matching 1 \
			    --initial-moving-transform [$MNI_Template,$T1_Template,1] \
			    --transform Rigid[0.1] \
			    --metric MI[$MNI_Template,$T1_Template,1,64,Regular,.5] \
			    --convergence [1000x500x250x100,1e-6,10] \
			    --shrink-factors 8x4x2x1 \
			    --smoothing-sigmas 3x2x1x0vox \
			    --transform Affine[0.1] \
			    --metric MI[$MNI_Template,$T1_Template,1,64,Regular,.5] \
			    --convergence [1000x500x250x100,1e-6,10] \
			    --shrink-factors 8x4x2x1 \
			    --smoothing-sigmas 3x2x1x0vox \
			    --transform SyN[0.1,3,0] \
			    --metric CC[$MNI_Template,$T1_Template,1,2] \
			    --convergence [100x70x50x20,1e-6,10] \
			    --shrink-factors 8x4x2x1 \
			    --smoothing-sigmas 3x2x1x0vox

			gunzip -f *nii.gz

			antsApplyTransforms -d 3 -e 3 -i ${this_core_file_name}.nii -r MNI_2mm.nii \
				-n BSpline -o warpedToMNI_${this_core_file_name}.nii -t [warpToMNIParams_${this_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_core_file_name}0GenericAffine.mat,0] -v
		
			this_file_to_warp=noM0_realigned_ASL_Run1.nii
			
			this_T1_core_file_name=SkullStripped_biascorrected_T1
		
			antsApplyTransforms -d 3 -e 3 -i $this_file_to_warp -r MNI_2mm.nii \
			-o warpedToMNI_$this_file_to_warp -t [warpToT1Params_meanASL_Run10GenericAffine.mat,0] \
			-t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v

			antsApplyTransforms -d 3 -e 3 -i M0_calibration.nii -r MNI_2mm.nii \
			-o warpedToMNI_M0_calibration.nii -t [warpToT1Params_meanASL_Run10GenericAffine.mat,0] \
			-t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v
			
			gunzip -f *nii.gz

		done
	fi

	if [[ $this_preprocessing_step == "smooth_asl" ]]; then
		data_folder_to_analyze=($asl_processed_folder_names)
		for this_asl_folder in ${data_folder_to_analyze[@]}; do
			cd ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization
			shopt -s nullglob
			prefix_to_delete=(smoothed_*.nii)
			if [ -e "$prefix_to_delete" ]; then
               	rm smoothed_*.nii
           	fi
			matlab -nodesktop -nosplash -r "try; smooth_asl_ants; catch; end; quit"
		done
	fi

done
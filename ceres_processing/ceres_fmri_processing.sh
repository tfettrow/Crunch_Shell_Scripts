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
for this_argument in "$@"; do
	if	[[ $argument_counter == 0 ]]; then
		Matlab_dir=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		Template_dir=$this_argument
	elif [[ $argument_counter == 2 ]]; then
    	Subject_dir=$this_argument
	else
		processing_steps[argument_counter]="$this_argument"
	fi
	(( argument_counter++ ))	
done
		
	export MATLABPATH=${Matlab_dir}/helper
	study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data
	subject=$(echo ${Subject_dir} | egrep -o [[:digit:]]{4} )
	echo $subject
	# cd $study_dir
	cd $Subject_dir
	pwd;
	ml matlab/2020b
	ml gcc/5.2.0; ml ants ## ml gcc/9.3.0; ml ants/2.3.4
	ml fsl/6.0.1
	ml itksnap 
########### determine which functional files you would like to ceres process (resting state and fmri) ############################
	lines_to_ignore=$(awk '/#/{print NR}' file_settings.txt) # file_settings dictates which folders are Processed

	fmri_line_numbers_in_file_info=$(awk '/functional_run/{print NR}' file_settings.txt)
	restingstate_line_numbers_in_file_info=$(awk '/restingstate/{print NR}' file_settings.txt)
	t1_line_numbers_in_file_info=$(awk '/t1/{print NR}' file_settings.txt)

	restingstate_line_numbers_to_process=$restingstate_line_numbers_in_file_info
	fmri_line_numbers_to_process=$fmri_line_numbers_in_file_info
	t1_line_numbers_to_process=$t1_line_numbers_in_file_info

	this_index_fmri=0
	this_index_restingstate=0
	this_index_t1=0
	for item_to_ignore in ${lines_to_ignore[@]}; do
		for item_to_check in ${fmri_line_numbers_in_file_info[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_fmri[$this_index_fmri]=$item_to_ignore
  				(( this_index_fmri++ ))
  			fi
  		done
  		for item_to_check in ${restingstate_line_numbers_in_file_info[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_restingstate[$this_index_restingstate]=$item_to_ignore
  				(( this_index_restingstate++ ))
  			fi
  		done
  		for item_to_check in ${t1_line_numbers_in_file_info[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_t1[$this_index_t1]=$item_to_ignore
  				(( this_index_t1++ ))
  			fi
  		done
	done

	for item_to_remove_fmri in ${remove_this_item_fmri[@]}; do
		fmri_line_numbers_to_process=$(echo ${fmri_line_numbers_to_process[@]/$item_to_remove_fmri})
	done
	for item_to_remove_restingstate in ${remove_this_item_restingstate[@]}; do
		restingstate_line_numbers_to_process=$(echo ${restingstate_line_numbers_to_process[@]/$item_to_remove_restingstate})
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
	for this_line_number in ${restingstate_line_numbers_to_process[@]}; do
		restingstate_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done
	this_index=0
	for this_line_number in ${t1_line_numbers_to_process[@]}; do
		t1_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done

	fmri_processed_folder_names=$(echo "${fmri_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	restingstate_processed_folder_names=$(echo "${restingstate_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	t1_processed_folder_names=$(echo "${t1_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

	for this_ceres_processing_step in "${processing_steps[@]}"; do
###################################################################################

########### move and unzip raw ceres files ############################
		if [[ $this_ceres_processing_step ==  "ceres_unzip" ]]; then
			
			cd $Subject_dir/Processed/MRI_files/01_Ceres

			for this_functional_run_folder in ${fmri_processed_folder_names[@]}; do
				cp $Subject_dir/Processed/MRI_files/01_Ceres/CB_mask.nii $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				cp $Subject_dir/Processed/MRI_files/01_Ceres/WM_mask.nii $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				cp $Subject_dir/Processed/MRI_files/01_Ceres/GM_mask.nii $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				cp $Subject_dir/Processed/MRI_files/01_Ceres/job* $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				cp $Subject_dir/Processed/MRI_files/01_Ceres/native_tissue_ln_crop_mmni* $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
			done
		fi
###################################################################################

########### Place Functional Run in T1 space (write) to allow for proper cb mask ############################
		if [[ $this_ceres_processing_step ==  "coreg_func_to_ceresT1" ]]; then
			for this_functional_run_folder in ${fmri_processed_folder_names[@]}; do #${restingstate_processed_folder_names[@]}; do
				cd $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				#cp ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/meanunwarped*.nii ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization

				if [[ -e coregToT1_*.nii ]]; then 
        	        rm coregToT1_*.nii
        	    fi

				for this_func_run in unwarpedRealigned_*.nii; do
					this_core_file_name=$(echo $this_func_run | cut -d. -f1)

					flirt -in SkullStripped_biascorrected_T1.nii -ref mean${this_func_run} -out dimMatch2Func_SkullStripped_biascorrected_T1.nii
					gunzip -f *nii.gz

					# TO DO: if whole brain normalization procedure changes, adjust here...
					antsApplyTransforms -d 3 -e 3 -i ${this_core_file_name}.nii --float 0 -r dimMatch2Func_SkullStripped_biascorrected_T1.nii \
					-n BSpline -o coregToT1_${this_core_file_name}.nii -t [warpToT1Params_biascorrected_mean${this_core_file_name}0GenericAffine.mat,0] -v 

					antsApplyTransforms -d 3 -e 3 -i native_tissue*.nii --float 0 -r dimMatch2Func_SkullStripped_biascorrected_T1.nii \
					-n BSpline -o coregToT1_native_tissue_CB.nii -t [warpToT1Params_biascorrected_mean${this_core_file_name}0GenericAffine.mat,0] -v

					antsApplyTransforms -d 3 -e 3 -i CB_mask.nii --float 0 -r dimMatch2Func_SkullStripped_biascorrected_T1.nii \
					-n BSpline -o coregToT1_CB_mask.nii -t [warpToT1Params_biascorrected_mean${this_core_file_name}0GenericAffine.mat,0] -v  					

					antsApplyTransforms -d 3 -e 3 -i WM_mask.nii --float 0 -r dimMatch2Func_SkullStripped_biascorrected_T1.nii \
					-n BSpline -o coregToT1_WM_mask.nii -t [warpToT1Params_biascorrected_mean${this_core_file_name}0GenericAffine.mat,0] -v  					

					antsApplyTransforms -d 3 -e 3 -i GM_mask.nii --float 0 -r dimMatch2Func_SkullStripped_biascorrected_T1.nii \
					-n BSpline -o coregToT1_GM_mask.nii -t [warpToT1Params_biascorrected_mean${this_core_file_name}0GenericAffine.mat,0] -v  					

					fslmaths coregToT1_native_tissue_CB.nii -thr 0.5 -bin binary_coregToT1_native_tissue_CB
					gunzip -f *nii.gz

					# masking vv is the reason for dimMatch2Func above
					fslmaths coregToT1_${this_func_run} -mas binary_coregToT1_native_tissue_CB.nii CBmasked_coregToT1_${this_func_run}
					gunzip -f *nii.gz

				done
			done
			echo This step took $SECONDS seconds to execute
        	cd "${Subject_dir}"
        	echo "coreg and write: $SECONDS sec" >> ceres_processing_log.txt
        	SECONDS=0
		fi
###################################################################################
########### JAMMED FULL WITH LOTS OF STEPS (Change dimensions, masking, and Ants warping) ############################
		if [[ $this_ceres_processing_step ==  "ceres_cb_mask_ants_norm" ]]; then
			for this_functional_run_folder in ${fmri_processed_folder_names[@]}; do
				cd $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				
				# TO DO: remove this for loop
				for ceres_image in native_*.nii; do
					N4BiasFieldCorrection -i $ceres_image -o biascorrected_$ceres_image
					ceres_image=biascorrected_$ceres_image
					SUIT_Template_1mm=${Template_dir}/SUIT_Nobrainstem_1mm.nii
					SUIT_Template_2mm=${Template_dir}/SUIT_Nobrainstem_2mm.nii
					echo 'registering' $ceres_image 'to' $SUIT_Template_1mm
					
					antsRegistration --dimensionality 3 --float 0 \
				   	 	--output [warpToSUITParams,warpToSUITEstimate.nii] \
				   	 	--interpolation Linear \
				   	 	--winsorize-image-intensities [0.01,0.99] \
				   	 	--use-histogram-matching 1 \
				   	 	--initial-moving-transform [$SUIT_Template_1mm,$ceres_image,1] \
				   	 	--transform Rigid[0.1] \
				   	 	--metric MI[$SUIT_Template_1mm,$ceres_image,1,64,Regular,.5] \
				   	 	--convergence [1000x500x250x100,1e-6,10] \
				   	 	--shrink-factors 8x4x2x1 \
				   	 	--smoothing-sigmas 3x2x1x0vox \
				   	 	--transform Affine[0.1] \
				   	 	--metric MI[$SUIT_Template_1mm,$ceres_image,1,64,Regular,.5] \
				   	 	--convergence [1000x500x250x100,1e-6,10] \
				   	 	--shrink-factors 8x4x2x1 \
				   	 	--smoothing-sigmas 3x2x1x0vox \
				   	 	--transform SyN[0.1,3,0] \
				   	 	--metric CC[$SUIT_Template_1mm,$ceres_image,1,2] \
				   	 	--convergence [100x70x50x20,1e-6,10] \
				   	 	--shrink-factors 8x4x2x1 \
				   	 	--smoothing-sigmas 3x2x1x0vox
				done

				gunzip -f *nii.gz

				antsApplyTransforms -d 3 -e 3 -i $ceres_image -r $SUIT_Template_1mm \
				-o warpedToSUIT_$ceres_image -t [warpToSUITParams1Warp.nii] -t [warpToSUITParams0GenericAffine.mat,0] -v

				antsApplyTransforms -d 3 -e 3 -i GM_mask.nii -r $SUIT_Template_1mm \
				-o warpedToSUIT_GM_mask.nii -t [warpToSUITParams1Warp.nii] -t [warpToSUITParams0GenericAffine.mat,0] -v

				antsApplyTransforms -d 3 -e 3 -i CB_mask.nii -r $SUIT_Template_1mm \
				-o warpedToSUIT_CB_mask.nii -t [warpToSUITParams1Warp.nii] -t [warpToSUITParams0GenericAffine.mat,0] -v

				cp $SUIT_Template_2mm ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization
				cp $SUIT_Template_1mm ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization
				for this_func_run in unwarpedRealigned*.nii; do

					# fslmaths coregToT1_${this_func_run} -mas binary_coregToT1_native_tissue_CB.nii CBmasked_coregToT1_${this_func_run}
					# gunzip -f *nii.gz

					antsApplyTransforms -d 3 -e 3 -i CBmasked_coregToT1_${this_func_run} -r $SUIT_Template_2mm \
					-o warpedToSUIT_CBmasked_coregToT1_${this_func_run} -t [warpToSUITParams1Warp.nii] -t [warpToSUITParams0GenericAffine.mat,0] -v
				done
			done
			echo This step took $SECONDS seconds to execute
        	cd "${Subject_dir}"
        	echo "Normalizing CB: $SECONDS sec" >> ceres_processing_log.txt
        	SECONDS=0
		fi
		
		if [[ $this_ceres_processing_step ==  "ceres_smooth_ants_norm"  ]]; then
			for this_functional_run_folder in ${fmri_processed_folder_names[@]}; do # ${restingstate_processed_folder_names[@]}; do
				cd $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				matlab -nodesktop -nosplash -r "try; ceres_smooth_antsnorm; catch; end; quit"
			done
			echo This step took $SECONDS seconds to execute
        	cd "${Subject_dir}"
        	echo "smoothing ceres: $SECONDS sec" >> ceres_processing_log.txt
        	SECONDS=0
		fi		

		if [[ $this_ceres_processing_step == "level_one_stats_ceres" ]]; then
			data_folder_to_analyze=($fmri_processed_folder_names)
			for this_functional_run_folder in ${fmri_processed_folder_names[@]}; do
				cd ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization
    			matlab -nodesktop -nosplash -r "try; level_one_stats_cb_fmri; catch; end; quit"
    		done
    		echo This step took $SECONDS seconds to execute
    		cd "${Subject_dir}"
			echo "Level One ANTS: $SECONDS sec" >> preprocessing_log.txt
			SECONDS=0
		fi
		
		if [[ $this_ceres_processing_step == "check_ceres_ants_func" ]]; then
			for this_functional_run_folder in ${restingstate_processed_folder_names[@]}; do #in ${fmri_processed_folder_names[@]} ${restingstate_processed_folder_names[@]}; do
				cd ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization

				# gunzip smoothed_warpedToSUIT_CBmasked_*
				# gunzip SUIT_Nobrainstem_2mm.nii.gz
				for this_functional_file in smoothed_warpedToSUIT_CBmasked_*; do
					this_core_functional_file_name=$(echo $this_functional_file | cut -d. -f 1)
					echo checking $this_core_functional_file_name for ${Subject_dir}
					
					# stat $this_functional_file
					
					itksnap -g SUIT_Nobrainstem_2mm.nii -o $this_functional_file					
				done
			done
		fi

		if [[ $this_ceres_processing_step ==  "ceres_structural_norm"  ]]; then
			struct_folder=($t1_processed_folder_names)
			rs_folder=($restingstate_processed_folder_names)

			cd ${Subject_dir}/Processed/MRI_files/${struct_folder}/
			mkdir -p ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization/

			cp ${Subject_dir}/Processed/MRI_files/${rs_folder}/ANTS_Normalization/warpToSUIT* ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization
			cp ${Subject_dir}/Processed/MRI_files/${rs_folder}/ANTS_Normalization/warpedToSUIT_GM_mask.nii ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization
			cp ${Subject_dir}/Processed/MRI_files/${rs_folder}/ANTS_Normalization/warpedToSUIT_CB_mask.nii ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization
			
			# this is kind of out of place... only cp this bc of Eriks DeepBrainNet stuff... this should be redone to be 1x1 or FSL should take care of this
			cp ${Subject_dir}/Processed/MRI_files/${rs_folder}/ANTS_Normalization/warpedToMNI_SkullStripped_biascorrected_T1.nii ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization

			SUIT_Template_1mm=${Template_dir}/SUIT_Nobrainstem_1mm.nii
			cp $SUIT_Template_1mm ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization
			cd ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization

			CreateJacobianDeterminantImage 3 warpToSUITParams1InverseWarp.nii SUIT_jacobian.nii.gz
			gunzip -f *nii.gz

			# antsApplyTransforms -d 3 -e 3 -i GM_mask.nii -r $SUIT_Template_1mm -o warpedToSUIT_GM_mask.nii -t [warpToSUITParams1Warp.nii] -t [warpToSUITParams0GenericAffine.mat,0] -v
			# gunzip -f *nii.gz

			fslmaths warpedToSUIT_GM_mask -mul SUIT_jacobian.nii modulated_warpedToSUIT_GM_mask
			gunzip -f *nii.gz

			matlab -nodesktop -nosplash -r "try; ceres_smooth_antsnorm_struct; catch; end; quit"
		fi

		if [[ $this_ceres_processing_step == "check_ceres_ants_struct" ]]; then
			struct_folder=($t1_processed_folder_names)
			echo $struct_folder
			cd ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization

			gunzip warpedToSUIT_CB_mask*
			# gunzip SUIT_Nobrainstem_1mm.nii.gz
			# for this_structural_file in warpedToSUIT_CB_mask.nii*; do
			this_core_structural_file_name=$(echo warpedToSUIT_CB_mask.nii | cut -d. -f 1)
			echo saving jpeg of $this_core_structural_file_name for $subject

			ml itksnap 
			itksnap -g SUIT_Nobrainstem_1mm.nii -o warpedToSUIT_GM_mask.nii modulated_warpedToSUIT_GM_mask
			# xvfb-run -s "-screen 0 640x480x24" fsleyes render --scene ortho --outfile ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization/check_SUIT_ants_${this_core_structural_file_name} \
			# ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization/SUIT_Nobrainstem_1mm.nii -cm red-yellow \
			# ${Subject_dir}/Processed/MRI_files/${struct_folder}/ANTS_Normalization/warpedToSUIT_CB_mask.nii  --alpha 85
			# echo "Created screenshot for": ${SUB}-${SSN};
			# display check_SUIT_ants_${this_core_structural_file_name}.png
			# done
		fi
done
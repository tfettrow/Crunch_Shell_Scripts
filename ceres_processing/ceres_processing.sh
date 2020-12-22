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
    	subject=$this_argument
	else
		ceres_processing_steps="$this_argument"
	fi
	
	# Set the path for our custom matlab functions and scripts
	Code_dir=/blue/rachaelseidler/tfettrow/Crunch_Code
		
	export MATLABPATH=${Code_dir}/Matlab_Scripts/helper
		
	study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data
	Subject_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data/$subject
	cd $Subject_dir

########### determine which functional files you would like to ceres process (resting state and fmri) ############################
	lines_to_ignore=$(awk '/#/{print NR}' file_settings.txt) # file_settings dictates which folders are Processed

	fmri_line_numbers_in_file_info=$(awk '/functional_run/{print NR}' file_settings.txt)
	restingstate_line_numbers_in_file_info=$(awk '/restingstate/{print NR}' file_settings.txt)

	restingstate_line_numbers_to_process=$restingstate_line_numbers_in_file_info
	fmri_line_numbers_to_process=$fmri_line_numbers_in_file_info

	this_index_fmri=0
	this_index_restingstate=0
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
	done

	for item_to_remove_fmri in ${remove_this_item_fmri[@]}; do
		fmri_line_numbers_to_process=$(echo ${fmri_line_numbers_to_process[@]/$item_to_remove_fmri})
	done
	for item_to_remove_restingstate in ${remove_this_item_restingstate[@]}; do
		restingstate_line_numbers_to_process=$(echo ${restingstate_line_numbers_to_process[@]/$item_to_remove_restingstate})
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
	
	fmri_processed_folder_names=$(echo "${fmri_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	restingstate_processed_folder_names=$(echo "${restingstate_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

	for this_ceres_processing_step in "${ceres_processing_steps[@]}"; do
###################################################################################

########### move and unzip raw ceres files ############################
		if [[ $this_ceres_processing_step ==  "ceres_unzip" ]]; then
			
			cd $Subject_dir/Processed/MRI_files/
			mkdir 01_Ceres
			cd 01_Ceres
			rm *
			cd $study_dir/Ceres_Output_Native
			cp native_${subject}* $Subject_dir/Processed/MRI_files/01_Ceres
			
			cd $Subject_dir/Processed/MRI_files/01_Ceres

			unzip *.zip
			
			ml matlab
			matlab -nodesktop -nosplash -r "try; ceres_create_binary; catch; end; quit"

			for this_functional_run_folder in ${fmri_processed_folder_names[@]} ${restingstate_processed_folder_names[@]}; do
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
			for this_functional_run_folder in ${fmri_processed_folder_names[@]} ${restingstate_processed_folder_names[@]}; do
				cd $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				cp ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/meanunwarped*.nii ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization

				if [[ -e coregToT1_*.nii ]]; then 
        	        rm coregToT1_*.nii
        	    fi

				for this_func_run in unwarpedRealigned_*.nii; do
					this_core_file_name=$(echo $this_func_run | cut -d. -f 1)

					ml fsl
					flirt -in biascorrected_SkullStripped_T1.nii -ref mean${this_func_run} -out dimMatch2Func_biascorrected_SkullStripped_T1.nii
					gunzip -f *nii.gz

					ml gcc; ml ants
					# TO DO: if whole brain normalization procedure changes, adjust here...
					antsApplyTransforms -d 3 -e 3 -i ${this_core_file_name}.nii --float 0 -r dimMatch2Func_biascorrected_SkullStripped_T1.nii \
					-n BSpline -o coregToT1_${this_core_file_name}.nii -t [warpToT1Params_biascorrected_mean${this_core_file_name}0GenericAffine.mat,0] -v 

					antsApplyTransforms -d 3 -e 3 -i native_tissue*.nii --float 0 -r dimMatch2Func_biascorrected_SkullStripped_T1.nii \
					-n BSpline -o coregToT1_native_tissue_CB.nii -t [warpToT1Params_biascorrected_mean${this_core_file_name}0GenericAffine.mat,0] -v

					antsApplyTransforms -d 3 -e 3 -i CB_mask.nii --float 0 -r dimMatch2Func_biascorrected_SkullStripped_T1.nii \
					-n BSpline -o coregToT1_CB_mask.nii -t [warpToT1Params_biascorrected_mean${this_core_file_name}0GenericAffine.mat,0] -v  					

					antsApplyTransforms -d 3 -e 3 -i WM_mask.nii --float 0 -r dimMatch2Func_biascorrected_SkullStripped_T1.nii \
					-n BSpline -o coregToT1_WM_mask.nii -t [warpToT1Params_biascorrected_mean${this_core_file_name}0GenericAffine.mat,0] -v  					

					antsApplyTransforms -d 3 -e 3 -i GM_mask.nii --float 0 -r dimMatch2Func_biascorrected_SkullStripped_T1.nii \
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


################## Norm Dartel #################################################################
		if [[ $this_ceres_processing_step ==  "ceres_cb_mask_spm_norm" ]]; then
			for this_functional_run_folder in ${fmri_processed_folder_names[@]} ${restingstate_processed_folder_names[@]}; do
				cd $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				cp $Code_dir/MR_Templates/SUIT_Nobrainstem_2mm.nii $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
			    
			    ml gcc/5.2.0
				ml ants
				echo 'registering' coregToT1_native_tissue_CB.nii 'to' SUIT_Nobrainstem_2mm.nii
				# moving low res func to high res T1
				antsRegistration --dimensionality 3 --float 0 \
				    --output [coregToSUITParams,coregToSUITEstimate.nii] \
				    --interpolation Linear \
				    --winsorize-image-intensities [0.005,0.995] \
				    --use-histogram-matching 0 \
				    --initial-moving-transform [ SUIT_Nobrainstem_2mm.nii,coregToT1_native_tissue_CB.nii,1] \
				    --transform Rigid[0.1] \
				    --metric MI[ SUIT_Nobrainstem_2mm.nii,coregToT1_native_tissue_CB.nii,1,32,Regular,0.25] \
				    --convergence [1000x500x250x100,1e-6,10] \
				    --shrink-factors 8x4x2x1 \
				    --smoothing-sigmas 3x2x1x0vox

				
				gunzip -f *nii.gz
				for this_func_run in CBmasked_coregToT1_*.nii; do
					antsApplyTransforms -d 3 -e 3 -i $this_func_run --float 0 -r SUIT_Nobrainstem_2mm.nii \
					-n BSpline -o coregToSUIT_${this_func_run}.nii -t [coregToSUITParams0GenericAffine.mat,0] -v 
				done

				antsApplyTransforms -d 3 -e 3 -i native_tissue*.nii --float 0 -r SUIT_Nobrainstem_2mm.nii \
				-n BSpline -o coregToSUIT_coregToT1_native_tissue_CB.nii -t [coregToSUITParams0GenericAffine.mat,0] -v

				antsApplyTransforms -d 3 -e 3 -i CB_mask.nii --float 0 -r SUIT_Nobrainstem_2mm.nii \
				-n BSpline -o coregToSUIT_coregToT1_CB_mask.nii -t [coregToSUITParams0GenericAffine.mat,0] -v  					

				antsApplyTransforms -d 3 -e 3 -i WM_mask.nii --float 0 -r SUIT_Nobrainstem_2mm.nii \
				-n BSpline -o coregToSUIT_coregToT1_WM_mask.nii -t [coregToSUITParams0GenericAffine.mat,0] -v  					

				antsApplyTransforms -d 3 -e 3 -i GM_mask.nii --float 0 -r SUIT_Nobrainstem_2mm.nii \
				-n BSpline -o coregToSUIT_coregToT1_GM_mask.nii -t [coregToSUITParams0GenericAffine.mat,0] -v  		

				if [[ -e Affine_GM_mask.mat ]]; then
        	        rm warpedToSUITdartelNoBrainstem_*.nii
        	        rm Affine_GM_mask.mat
        	        rm u_a_GM_mask.nii
        	    fi

				ml matlab
				matlab -nodesktop -nosplash -r "try; ceres_norm_suit_estimate; catch; end; quit"
				matlab -nodesktop -nosplash -r "try; ceres_norm_suit_apply; catch; end; quit"
			done
		fi
###################################################################################

		if [[ $this_ceres_processing_step ==  "ceres_smooth_ants_norm"  ]]; then
			for this_functional_run_folder in ${fmri_processed_folder_names[@]} ${restingstate_processed_folder_names[@]}; do
				cd $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				ml matlab
				matlab -nodesktop -nosplash -r "try; ceres_smooth_spmnorm; catch; end; quit"
			done	
			echo This step took $SECONDS seconds to execute
        	cd "${Subject_dir}"
        	echo "smoothing ceres: $SECONDS sec" >> ceres_processing_log.txt
        	SECONDS=0
		fi

########### JAMMED FULL WITH LOTS OF STEPS (Change dimensions, masking, and Ants warping) ############################
		if [[ $this_ceres_processing_step ==  "ceres_cb_mask_ants_norm" ]]; then
			for this_functional_run_folder in ${fmri_processed_folder_names[@]} ${restingstate_processed_folder_names[@]}; do
				cd $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				
				# TO DO: remove this for loop
				for ceres_image in native_*.nii; do
					ml gcc/5.2.0; ml ants
					N4BiasFieldCorrection -i $ceres_image -o biascorrected_$ceres_image
					ceres_image=biascorrected_$ceres_image
					SUIT_Template_1mm=$Code_dir/MR_Templates/SUIT_Nobrainstem_1mm.nii
					SUIT_Template_2mm=$Code_dir/MR_Templates/SUIT_Nobrainstem_2mm.nii
					echo 'registering' $ceres_image 'to' $SUIT_Template_1mm
					
					ml gcc/5.2.0; ml ants
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

				# ml gcc/5.2.0; ml ants
				# antsApplyTransforms -d 3 -e 3 -i $ceres_image -r $SUIT_Template_2mm \
				# -o warpedToSUIT_CBmasked_coregToT1_${this_func_run} -t [warpToSUITParams1Warp.nii] -t [warpToSUITParams0GenericAffine.mat,0] -v

				cp $SUIT_Template_2mm ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization
				for this_func_run in unwarpedRealigned*.nii; do
					ml fsl	

					# fslmaths coregToT1_${this_func_run} -mas binary_coregToT1_native_tissue_CB.nii CBmasked_coregToT1_${this_func_run}
					# gunzip -f *nii.gz

					ml gcc/5.2.0; ml ants
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
			for this_functional_run_folder in ${fmri_processed_folder_names[@]} ${restingstate_processed_folder_names[@]}; do
				cd $Subject_dir/Processed/MRI_files/$this_functional_run_folder/ANTS_Normalization
				ml matlab
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
				# grab TR from json file
				# TO DO: this is not working properly so hardcoded level_one_stats.m
				# for this_functional_run_file in *.json; do
				# 		TR_from_json=$(grep "RepetitionTime" ${this_functional_run_file} | tr -dc '0.00-9.00')
				# 		echo $TR_from_json
  				# 		done
  				ml matlab
    			# matlab -nodesktop -nosplash -r "try; level_one_stats(1, '$TR_from_json'); catch; end; quit"
    			matlab -nodesktop -nosplash -r "try; level_one_stats(1, 1.5, 'smoothed_warpedToSUIT', 'Level1_Ceres'); catch; end; quit"
    		done
    		echo This step took $SECONDS seconds to execute
    		cd "${Subject_dir}"
			echo "Level One ANTS: $SECONDS sec" >> preprocessing_log.txt
			SECONDS=0
		fi
		if [[ $this_ceres_processing_step == "check_ceres_ants" ]]; then
			for this_functional_run_folder in ${fmri_processed_folder_names[@]} ${restingstate_processed_folder_names[@]};; do
				cd ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization
				ml fsl/6.0.1
				gunzip smoothed_warpedToSUIT_CBmasked_*
				gunzip SUIT_Nobrainstem_2mm.nii.gz
				for this_functional_file in smoothed_warpedToSUIT_CBmasked_*; do
					this_core_functional_file_name=$(echo $this_functional_file | cut -d. -f 1)
					echo saving jpeg of $this_core_functional_file_name for $subject
					xvfb-run -s "-screen 0 640x480x24" fsleyes render --scene ortho --outfile ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/check_SUIT_ants_${this_core_functional_file_name} \
					${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/SUIT_Nobrainstem_2mm.nii -cm red-yellow \
					${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/$this_functional_file --alpha 85
					# echo "Created screenshot for": ${SUB}-${SSN};
					display check_SUIT_ants_${this_core_functional_file_name}.png
				done
			done
			# echo This step took $SECONDS seconds to execute
			# cd "${Subject_dir}"
			# echo "Smoothing ANTS files: $SECONDS sec" >> preprocessing_log.txt
			# SECONDS=0
		fi
		### potentially mask smoothed images ####
	done
	(( argument_counter++ ))
done
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
		preprocessing_steps["$argument_counter-3"]="$this_argument"
	fi
	(( argument_counter++ ))
done
	export MATLABPATH=${Matlab_dir}/helper
	ml matlab/2020b
	ml itksnap
	ml gcc/5.2.0; ml ants ## ml gcc/9.3.0; ml ants/2.3.4
	ml fsl/6.0.4
	
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
		echo ${asl_folders}
		for this_asl_folder in ${asl_folders[@]}; do
			cd ${Subject_dir}/Processed/MRI_files/${this_asl_folder}
			pwd
			# shopt -s extglob
			# rm -r !(ASL_Run1.*)
			# shopt -u extglob
			if [[ -e realigned_*.nii ]]; then 
       	        rm realigned_*.nii
       	    fi
			matlab -nodesktop -nosplash -r "try; realign_asl; catch; end; quit"
			fslroi realigned_ASL_Run1.nii M0_calibration.nii 0 1
			if [[ $subject_id == "3004" ]]; then
				fslroi realigned_ASL_Run1.nii noM0_realigned_ASL_Run1.nii 1 124
			else
				fslroi realigned_ASL_Run1.nii noM0_realigned_ASL_Run1.nii 1 184
			fi
			gunzip -f *nii.gz
		done
	fi

	if [[ $this_preprocessing_step == "fsl_anat" ]]; then
		cd ${Subject_dir}/Processed/MRI_files/02_T1
		rm -r T1.anat
		chmod g-s *.nii.gz
		gunzip -f *T1.nii.gz
		fsl_anat -i T1.nii
	fi

	if [[ $this_preprocessing_step == "check_fsl_anat_ran" ]]; then
		cd ${Subject_dir}/Processed/MRI_files/02_T1/T1.anat
		rm log.txt
		if [ "$(ls -A)" ]; then
     		echo "FULL:" $Subject_dir
		else
    		echo "EMPTY:" $Subject_dir
		fi
	fi

	if [[ $this_preprocessing_step == "basil_cbf" ]]; then
		asl_folder=($asl_processed_folder_names)
		this_t1_folder=($t1_processed_folder_names)
	
		subject=$(echo ${Subject_dir} | egrep -o '[[:digit:]]{4}' | head -n1)
   		subject_level=$(echo $subject | cut -c1-1)
   		# echo $subject_level
   		# This logic says if MiM subject id starts with 3 (harmonized) then go ahead and process fieldmaps..
   		# if not, then copy fieldmaps for restingstate from task fmri folder
   		if [[ $subject_level == 3 ]]; then
   			cd ${Subject_dir}/Processed/MRI_files/03_Fieldmaps
			if [[ -d Fieldmap_nback ]]; then
				cd ${Subject_dir}/Processed/MRI_files/03_Fieldmaps/Fieldmap_nback/
   				fslmaths my_fieldmap_nifti -mul 6.28 my_fieldmap_nifti_rads
   				bet2 my_fieldmap_mag my_fieldmap_mag_brain
				gunzip -f *nii.gz
   				fieldmap_rads=${Subject_dir}/Processed/MRI_files/03_Fieldmaps/Fieldmap_nback/my_fieldmap_nifti_rads.nii
   				fieldmap_mag=${Subject_dir}/Processed/MRI_files/03_Fieldmaps/Fieldmap_nback/my_fieldmap_mag.nii
   				fieldmap_mag_brain=${Subject_dir}/Processed/MRI_files/03_Fieldmaps/Fieldmap_nback/my_fieldmap_mag_brain.nii
			else
   				cd ${Subject_dir}/Processed/MRI_files/03_Fieldmaps/
   				fslmaths my_fieldmap_nifti -mul 6.28 my_fieldmap_nifti_rads
   				bet2 my_fieldmap_mag my_fieldmap_mag_brain
   				gunzip -f *nii.gz 
   				# this was a mistake
   				rm my_fieldmap_nifti_rads1.nii
   				fieldmap_rads=${Subject_dir}/Processed/MRI_files/03_Fieldmaps/my_fieldmap_nifti_rads.nii
   				fieldmap_mag=${Subject_dir}/Processed/MRI_files/03_Fieldmaps/my_fieldmap_mag.nii
   				fieldmap_mag_brain=${Subject_dir}/Processed/MRI_files/03_Fieldmaps/my_fieldmap_mag_brain.nii
   			fi
   		else
   			# taking nback bc it is closest in time to ASL data
   			cd ${Subject_dir}/Processed/MRI_files/03_Fieldmaps/Fieldmap_nback/
   			fslmaths my_fieldmap_nifti -mul 6.28 my_fieldmap_nifti_rads
   			bet2 my_fieldmap_mag my_fieldmap_mag_brain
			gunzip -f *nii.gz
			# this was a mistake
   			rm my_fieldmap_nifti_rads1.nii
   			fieldmap_rads=${Subject_dir}/Processed/MRI_files/03_Fieldmaps/Fieldmap_nback/my_fieldmap_nifti_rads.nii
   			fieldmap_mag=${Subject_dir}/Processed/MRI_files/03_Fieldmaps/Fieldmap_nback/my_fieldmap_mag.nii
   			fieldmap_mag_brain=${Subject_dir}/Processed/MRI_files/03_Fieldmaps/Fieldmap_nback/my_fieldmap_mag_brain.nii
   		fi

		cp ${Subject_dir}/Processed/MRI_files/${this_t1_folder}/SkullStripped_biascorrected_T1.nii ${Subject_dir}/Processed/MRI_files/${asl_folder}
		cd ${Subject_dir}/Processed/MRI_files/${asl_folder}/
		# rm -r BasilCMD_calib_anat_FM

		# rm -r BasilCMD_calib_anat_scalib_pvcorr
		rm -r BasilCMD_calib_anat_FM_scalib_pvcorr
		# 		Parameters for CBF software:
		#		 labeling time (bolus duration) = 700 ms, 
		# 		post labeling delay (inversion time) = 1.8 s, 
		# 		slice time = 6.25 (slicetime=(minTR-labelingtime-delaytime)/#slices)
		# 		TR = 2600 msec
		# 		TE = 12 msec

		
		# oxford_asl -i noM0_realigned_ASL_Run1.nii --iaf tc --ibf rpt --casl --bolus 1.8 --rpts 92 --slicedt 0.00625 --tis 2.5 --fslanat ${Subject_dir}/Processed/MRI_files/02_T1/T1.anat -c M0_calibration.nii --cmethod voxel --tr 6 --cgain 1 -o ${Subject_dir}/Processed/MRI_files/07_ASL/BasilCMD_calib_anat_FM --bat 0 --t1 1.65 --t1b 1.65 --alpha 0.85 --spatial --fixbolus --pvcorr --artoff --wp

		# oxford_asl -i noM0_realigned_ASL_Run1.nii --iaf tc --ibf rpt --casl --bolus 0.7 --rpts 92 --slicedt 0.00625 --tis 2.5 -s SkullStripped_biascorrected_T1.nii -c M0_calibration.nii --cmethod voxel --tr 2.6 --cgain 1 -o ${Subject_dir}/Processed/MRI_files/07_ASL/BasilCMD_calib_pvcorr --bat 0 --t1 1.65 --t1b 1.65 --alpha 0.85 --spatial --fixbolus --pvcorr --artoff --wp

		# # #  SC 40+ perfusion vv # # # 
		# apps/fsl/6.0.4/fsl/bin/oxford_asl -i noM0_realigned_ASL_Run1.nii --iaf tc --ibf rpt --casl --bolus 0.7 --rpts 92 --slicedt 0.00625 --tis 2.5 -s SkullStripped_biascorrected_T1.nii -c M0_calibration.nii --cmethod voxel --tr 2.6 --cgain 1 -o BASIL_GUI_STRUC_11-22-21 --bat 0 --t1 1.65 --t1b 1.65 --alpha 0.85 --spatial --fixbolus --pvcorr --artoff --wp

		# oxford_asl -i noM0_realigned_ASL_Run1.nii --iaf tc --ibf rpt --casl --bolus 0.7 --rpts 92 --slicedt 0.00625 --tis 2.5 --fslanat ${Subject_dir}/Processed/MRI_files/02_T1/T1.anat -c M0_calibration.nii --cmethod single --tr 2.6 --cgain 1 -o ${Subject_dir}/Processed/MRI_files/07_ASL/BasilCMD_calib_anat_scalib_pvcorr --bat 0 --t1 1.65 --t1b 1.65 --alpha 0.85 --spatial --fixbolus --pvcorr --artoff --wp

		oxford_asl -i noM0_realigned_ASL_Run1.nii --iaf tc --ibf rpt --casl --bolus 0.7 --rpts 92 --slicedt 0.00625 --tis 2.5 --fslanat ${Subject_dir}/Processed/MRI_files/02_T1/T1.anat -c M0_calibration.nii --cmethod single --tr 2.6 --cgain 1 --echospacing 2.1e-07 --pedir y --fmap $fieldmap_rads --fmapmag $fieldmap_mag --fmapmagbrain $fieldmap_mag_brain -o ${Subject_dir}/Processed/MRI_files/07_ASL/BasilCMD_calib_anat_FM_scalib_pvcorr --bat 0 --t1 1.65 --t1b 1.65 --alpha 0.85 --spatial --fixbolus --pvcorr --artoff --wp

		# oxford_asl -i noM0_realigned_ASL_Run1.nii --iaf tc --ibf rpt --casl --bolus 1.8 --rpts 92 --slicedt 0.00625 --tis 2.5 --fslanat ${Subject_dir}/Processed/MRI_files/02_T1/T1.anat -c M0_calibration.nii --cmethod voxel --tr 6 --cgain 1 --echospacing 2.1e-07 --pedir y --fmap $fieldmap_rads --fmapmag $fieldmap_mag --fmapmagbrain $fieldmap_mag_brain -o ${Subject_dir}/Processed/MRI_files/07_ASL/BasilCMD_calib_anat_FM --bat 0 --t1 1.65 --t1b 1.65 --alpha 0.85 --spatial --fixbolus --pvcorr --artoff --wp

		# oxford_asl -i noM0_realigned_ASL_Run1.nii --iaf tc --ibf rpt --casl --bolus 1.8 --rpts 92 --slicedt 0.00625 --tis 2.5 --fslanat ${Subject_dir}/Processed/MRI_files/02_T1/T1.anat -c M0_calibration.nii --cmethod voxel --tr 6 --cgain 1 --echospacing 2.1e-07 --pedir y --fmap $fieldmap_rads --fmapmag $fieldmap_mag --fmapmagbrain $fieldmap_mag_brain -o ${Subject_dir}/Processed/MRI_files/07_ASL/BasilCMD_calib_anat_FM --bat 0 --t1 1.65 --t1b 1.65 --alpha 0.85 --spatial --fixbolus --pvcorr --artoff --wp
	fi

	if [[ $this_preprocessing_step == "check_fsl_basil_native_ran" ]]; then
		cd ${Subject_dir}/Processed/MRI_files/07_ASL/BasilCMD_calib_anat_FM_scalib_pvcorr/native_space/pvcorr
		# rm log.txt
		if [ "$(ls *.nii.gz)" ]; then
     		echo "FULL:" $Subject_dir
		else
    		echo "EMPTY:" $Subject_dir
		fi
	fi

	if [[ $this_preprocessing_step == "check_fsl_basil_std_ran" ]]; then
		cd ${Subject_dir}/Processed/MRI_files/07_ASL/BasilCMD_calib_anat_FM_scalib_pvcorr/std_space/pvcorr
		# rm log.txt
		if [ "$(ls *.nii.gz)" ]; then
     		echo "FULL:" $Subject_dir
		else
    		echo "EMPTY:" $Subject_dir
		fi
	fi

	if [[ $this_preprocessing_step == "asl_norm_ants" ]]; then
		data_folder_to_analyze=($asl_processed_folder_names)
		this_t1_folder=($t1_processed_folder_names)
		for this_asl_folder in ${data_folder_to_analyze[@]}; do
			# Results_folder_name=BasilCMD_calib_anat_scalib_pvcorr
			Results_folder_name=BasilCMD_calib_anat_FM_scalib_pvcorr

			mkdir -p ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization
			cp ${Subject_dir}/Processed/MRI_files/${this_t1_folder}/SkullStripped_biascorrected_T1.nii ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization
			cd ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization
			cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/meanASL_Run1.nii ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization
            cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/native_space/perfusion.nii.gz ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization
            cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/native_space/perfusion_calib.nii.gz ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization
            # cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/native_space/perfusion_wm.nii.gz ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization
            # cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/native_space/perfusion_wm_calib.nii.gz ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization
            cp ${Template_dir}/MNI_2mm.nii ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization
          
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

			# cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/BasilCMD_calib_anat_FM/ANTS_Normalization/pvcorr/warpToT1Params_meanASL_Run10GenericAffine.mat ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/BasilCMD_calib/native_space/

			outputFolder=${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization/
			T1_Template=${Subject_dir}/Processed/MRI_files/${this_asl_folder}/${Results_folder_name}/ANTS_Normalization/SkullStripped_biascorrected_T1.nii
			MNI_Template=${Template_dir}/MNI_1mm.nii
			this_file_to_warp=noM0_realigned_ASL_Run1.nii
			this_T1_core_file_name=SkullStripped_biascorrected_T1
			echo 'registering' $T1_Template 'to' $MNI_Template
			antsRegistration --dimensionality 3 --float 0 \
			    --output [$outputFolder/warpToMNIParams_${this_T1_core_file_name},$outputFolder/warpToMNIEstimate_${this_T1_core_file_name}.nii] \
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

			# cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization/warpToMNIParams_* ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/BasilCMD_calib/native_space/

			# cd ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/BasilCMD_calib/native_space/
			# gunzip -f *nii.gz
			
			antsApplyTransforms -d 3 -e 3 -i perfusion.nii -r MNI_2mm.nii \
			-o warpedToMNI_perfusion.nii -t [warpToT1Params_meanASL_Run10GenericAffine.mat,0] \
			-t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v

			antsApplyTransforms -d 3 -e 3 -i perfusion_calib.nii -r MNI_2mm.nii \
			-o warpedToMNI_perfusion_calib.nii -t [warpToT1Params_meanASL_Run10GenericAffine.mat,0] \
			-t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v

			# antsApplyTransforms -d 3 -e 3 -i perfusion_wm.nii -r MNI_2mm.nii \
			# -o warpedToMNI_perfusion_wm.nii -t [warpToT1Params_meanASL_Run10GenericAffine.mat,0] \
			# -t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v
			
			# antsApplyTransforms -d 3 -e 3 -i perfusion_wm_calib.nii -r MNI_2mm.nii \
			# -o warpedToMNI_perfusion_wm_calib.nii -t [warpToT1Params_meanASL_Run10GenericAffine.mat,0] \
			# -t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v
			
			gunzip -f *nii.gz


			# cp ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/ANTS_Normalization/warpToMNIParams_* ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/BasilGUI_calib/native_space/

			# cd ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/BasilGUI_calib/native_space/

			# gunzip -f *nii.gz
			# antsApplyTransforms -d 3 -e 3 -i perfusion.nii -r MNI_3mm.nii \
			# -o warpedToMNI_perfusion.nii -t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v

			# antsApplyTransforms -d 3 -e 3 -i perfusion_calib.nii -r MNI_3mm.nii \
			# -o warpedToMNI_perfusion_calib.nii -t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v

			# antsApplyTransforms -d 3 -e 3 -i perfusion_wm.nii -r MNI_3mm.nii \
			# -o warpedToMNI_perfusion_wm.nii -t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v

			# antsApplyTransforms -d 3 -e 3 -i perfusion_var.nii -r MNI_3mm.nii \
			# -o warpedToMNI_perfusion_var.nii -t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v

			# antsApplyTransforms -d 3 -e 3 -i perfusion_var_calib.nii -r MNI_3mm.nii \
			# -o warpedToMNI_perfusion_var_calib.nii -t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v

			# antsApplyTransforms -d 3 -e 3 -i perfusion_calib.nii -r MNI_3mm.nii \
			# -o warpedToMNI_perfusion_calib.nii -t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v
			
			# gunzip -f *nii.gz

		done
	fi

	if [[ $this_preprocessing_step == "check_ants_norm" ]]; then
		cd ${Subject_dir}/Processed/MRI_files/07_ASL/BasilCMD_calib_anat_FM_scalib_pvcorr/ANTS_Normalization
		# cd ${Subject_dir}/Processed/MRI_files/07_ASL/BasilCMD_calib_anat_FM_scalib_pvcorr/std_space
		# rm log.txt
		echo checking $Subject_dir
		itksnap -g MNI_2mm.nii -o warpedToMNI_perfusion_calib.nii
	fi

	if [[ $this_preprocessing_step == "smooth_asl_ants" ]]; then
		data_folder_to_analyze=($asl_processed_folder_names)
		for this_asl_folder in ${data_folder_to_analyze[@]}; do
			Results_folder_name=BasilCMD_calib_anat_FM_scalib_pvcorr
			cd ${Subject_dir}/Processed/MRI_files/${this_asl_folder}/$Results_folder_name/ANTS_Normalization/pvcorr
			shopt -s nullglob
			prefix_to_delete=(smoothed_*.nii)
			if [ -e "$prefix_to_delete" ]; then
               	rm smoothed_*.nii
           	fi
			matlab -nodesktop -nosplash -r "try; smooth_asl_ants; catch; end; quit"
		done
	fi
	
	if [[ $this_preprocessing_step == "whole_brain" ]]; then
		this_subject=$(echo ${Subject_dir} | egrep -o '[[:digit:]]{4}' | head -n1)
		Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data

	    Results_folder_name=BasilCMD_calib_anat_FM_scalib_pvcorr
       	cd ${Subject_dir}/Processed/MRI_files/07_ASL/${Results_folder_name}/ANTS_Normalization
		pwd
        outfile_fsl_perfusion=${this_subject}_fsl_perfusion_temporal.csv
   	    outfile_fsl_perfusion_calib=${this_subject}_fsl_perfusion_calib_whole.csv
		this_roi_image_name=${Study_dir}/rwwtemp.nii
		if [ -e ${this_subject}_fsl_perfusion_temporal.csv ]; then
			rm ${this_subject}_fsl_perfusion_temporal.csv
		fi
		if [ -e ${this_subject}_fsl_perfusion_calib_whole.csv ]; then
			rm ${this_subject}_fsl_perfusion_calib_whole.csv
		fi
		      	
        var1="record_id,redcap_event_name"
        var2="$H${this_subject},base_v4_mri_arm_1" 
		echo -e "$var1\n$var2" >> "$outfile_fsl_perfusion"
        echo -e "$var1\n$var2" >> "$outfile_fsl_perfusion_calib"
		echo "check point 1"
		beta=0
		beta=$(fslmeants -i warpedToMNI_perfusion_calib.nii)
		# echo $this_roi_file_corename_squeeze
		first_row=$(cat $outfile_fsl_perfusion_calib | sed -n 1p)
		second_row=$(cat $outfile_fsl_perfusion_calib | sed -n 2p) 
		rm $outfile_fsl_perfusion_calib
		echo -e "${first_row},${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile_fsl_perfusion_calib"
		beta=0
		beta=$(fslmeants -i warpedToMNI_perfusion_calib.nii -m $this_roi_image_name)
		# echo $this_roi_file_corename_squeeze
		first_row=$(cat $outfile_fsl_perfusion | sed -n 1p)
		second_row=$(cat $outfile_fsl_perfusion | sed -n 2p) 
		rm $outfile_fsl_perfusion
		echo -e "${first_row},${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile_fsl_perfusion"
	fi	
done
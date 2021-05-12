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
	echo $preprocessing_steps
	
	export MATLABPATH=${Matlab_dir}/helper
	ml matlab/2020a
	ml gcc/5.2.0
	ml ants ## ml gcc/9.3.0; ml ants/2.3.4
	ml fsl/6.0.3
	
	cd $Subject_dir

	lines_to_ignore=$(awk '/#/{print NR}' file_settings.txt)

	dwi_line_numbers_in_file_info=$(awk '/dwi/{print NR}' file_settings.txt)
	dwi_fieldmap_line_numbers_in_file_info=$(awk '/dti_fieldmap/{print NR}' file_settings.txt)
	t1_line_numbers_in_file_info=$(awk '/t1/{print NR}' file_settings.txt)

	dwi_line_numbers_to_process=$dwi_line_numbers_in_file_info
	fieldmap_line_numbers_to_process=$dwi_fieldmap_line_numbers_in_file_info
	t1_line_numbers_to_process=$t1_line_numbers_in_file_info

	this_index_dwi=0
	this_index_fieldmap=0
	this_index_t1=0
	for item_to_ignore in ${lines_to_ignore[@]}; do
		for item_to_check in ${dwi_line_numbers_in_file_info[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_fmri[$this_index_fmri]=$item_to_ignore
  				(( this_index_dwi++ ))
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
		dwi_line_numbers_to_process=$(echo ${dwi_line_numbers_to_process[@]/$item_to_remove_fmri})
	done
	for item_to_remove_fieldmap in ${remove_this_item_fieldmap[@]}; do
		fieldmap_line_numbers_to_process=$(echo ${fieldmap_line_numbers_to_process[@]/$item_to_remove_fieldmap})
	done
	for item_to_remove_t1 in ${remove_this_item_t1[@]}; do
		t1_line_numbers_to_process=$(echo ${t1_line_numbers_to_process[@]/$item_to_remove_t1})
	done

	this_index=0
	for this_line_number in ${dwi_line_numbers_to_process[@]}; do
		dwi_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done
	
	this_index=0
	for this_line_number in ${fieldmap_line_numbers_to_process[@]}; do
		dwi_fieldmap_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done
	
	this_index=0
	for this_line_number in ${t1_line_numbers_to_process[@]}; do
		t1_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done
	
	dwi_processed_folder_name=$(echo "${dwi_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	dwi_fieldmap_processed_folder_name=$(echo "${dwi_fieldmap_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	t1_processed_folder_name=$(echo "${t1_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

for this_preprocessing_step in ${preprocessing_steps[@]};do
	if [[ $this_preprocessing_step == "drift_correction" ]]; then
		dwi_folder_name=($dwi_processed_folder_name)
        cd ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
        matlab -nodesktop -nosplash -r "try; create_bmat_text; catch; end; quit"
		matlab -nodesktop -nosplash -r "try; flip_or_permute; catch; end; quit"
		matlab -nodesktop -nosplash -r "try; driftcorrect; catch; end; quit"
	fi

   	if [[ $this_preprocessing_step == "fieldmap_dti" ]]; then
   		fieldmap_folder_name=($dwi_fieldmap_processed_folder_name)
   		dwi_folder_name=($dwi_processed_folder_name)
   		cd ${Subject_dir}/Processed/MRI_files/${fieldmap_folder_name}

		if [ -e AP_PA_merged.nii ]; then 
			rm AP_PA_merged.nii
		fi
		if [ -e se_epi_unwarped.nii ]; then 
			rm se_epi_unwarped.nii
		fi 
		if [ -e topup_results_fieldcoef.nii ]; then 
			rm topup_results_fieldcoef.nii
		fi
		if [ -e topup_results_movpar.txt ]; then 
			rm topup_results_movpar.txt
		fi
		if [ -e my_fieldmap_nifti.nii ]; then
	   		rm my_fieldmap_nifti.nii
	   	fi
	   	if [ -e acqParams.txt ]; then
	   		rm acqParams.txt
	   	fi
	   	if [ -e my_fieldmap_mask.nii ]; then
			rm my_fieldmap_mask.nii
			rm my_fieldmap_rads.nii
		fi

		fslroi DistMap_AP DistMap_AP1 0 1
		fslroi DistMap_PA DistMap_PA1 0 1
		fslroi ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}/driftcorrected_DWI.nii DistMap_AP1 0 1

		flirt -in DistMap_PA1.nii -ref DistMap_AP1.nii -out DistMap_PA1_reg.nii
		gunzip -qf *nii.gz
		fslmerge -t AP_PA_merged.nii DistMap_AP1.nii DistMap_PA1_reg.nii
		gunzip -qf *nii.gz
		
		this_file_header_info=$(fslhd AP_PA_merged.nii)
		
		gunzip -qf *nii.gz

		# just a dummy value to check whether ecoding direction is same between distmaps
		previous_encoding_direction=k
		# assuming only the DistMaps have .jsons in this folder
		for this_json_file in *.json*; do
								
			total_readout=$(grep "TotalReadoutTime" ${this_json_file} | tr -dc '0.00-9.00')
			encoding_direction=$(grep "PhaseEncodingDirection" ${this_json_file} | cut -d: -f 2 | head -1 | tr -d '"' |  tr -d ',')
			this_file_name=$(echo $this_json_file | cut -d. -f 1)
			
			this_file_header_info=$(fslhd ${this_file_name}1.nii)
			this_file_number_of_volumes=$(echo $this_file_header_info | grep -o dim4.* | tr -s ' ' | cut -d ' ' -f 2)
			for (( this_volume=1; this_volume<=$this_file_number_of_volumes; this_volume++ )); do
				if [[ $encoding_direction =~ j- ]]; then
					echo 0 -1 0 ${total_readout} >> acqParams.txt
				else
					echo 0 1 0 ${total_readout} >> acqParams.txt
				fi
				if [[ $encoding_direction == $previous_encoding_direction ]]; then
					echo WARNING: the phase encoding directions appear to be the same between distmaps!!!
				fi
			done
			previous_encoding_direction=$encoding_direction
		done

		topup --imain=AP_PA_merged.nii --datain=acqParams.txt --fout=my_fieldmap --config=b02b0_1.cnf --iout=se_epi_unwarped --out=topup_results
		gunzip -qf *nii.gz
		fslmaths se_epi_unwarped -Tmean se_epi_unwarped_mean
		gunzip -qf *nii.gz
		bet se_epi_unwarped_mean se_epi_unwarped_brain -m
		gunzip -qf *nii.gz

		echo topup finished for $Subject_dir
   	fi

   	if [[ $this_preprocessing_step ==  "eddy_correction" ]]; then
   		fieldmap_folder_name=($dwi_fieldmap_processed_folder_name)
   		dwi_folder_name=($dwi_processed_folder_name)

   		cd ${Subject_dir}/Processed/MRI_files/${fieldmap_folder_name}
   		cp se_epi_unwarped_brain_mask.nii ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
		cp my_fieldmap.nii ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
		cp acqParams.txt ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
        cp topup_results* ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
        cd ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
        
		NVOL=`fslnvols driftcorrected_DWI.nii`
		for ((i=1; i<=${NVOL}; i+=1)); do indx="$indx 1"; done; echo $indx > index.txt

		rm eddycorrected_driftcorrected_DWI.*
		
		flirt -in se_epi_unwarped_brain_mask.nii -ref driftcorrected_DWI.nii -out se_epi_unwarped_brain_mask_pixelAdjusted.nii
		gunzip -f *nii.gz
	 	eddy_cuda9.1 --imain=driftcorrected_DWI.nii --mask=se_epi_unwarped_brain_mask_pixelAdjusted.nii --topup=topup_results --acqp=acqParams.txt --index=index.txt --bvecs=DWI.bvec --bvals=DWI.bval --niter=8 --fwhm=10,8,4,2,0,0,0,0 --repol --out=eddycorrected_driftcorrected_DWI --mporder=16 --json=DWI.json --s2v_niter=8 --s2v_lambda=1 --s2v_interp=trilinear --cnr_maps

		rm -r eddycorrected_driftcorrected_DWI.qc
		eddy_quad ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}/eddycorrected_driftcorrected_DWI --eddyIdx index.txt --eddyParams acqParams.txt --mask se_epi_unwarped_brain_mask_pixelAdjusted --bvals DWI.bval --output-dir=eddycorrected_driftcorrected_DWI.qc
		
		gunzip -f *nii.gz
	fi

	if [[ $this_preprocessing_step ==  "fit_tensors" ]]; then
		dwi_folder_name=($dwi_processed_folder_name)
		cd ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}

		dtifit -k eddycorrected_driftcorrected_DWI.nii -o tensorfit_eddycorrected_driftcorrected_DWI -m se_epi_unwarped_brain_mask_pixelAdjusted.nii -r DWI.bvec -b DWI.bval
		gunzip -f *nii.gz
	fi
# fsl_motion_outliers 



	# fsl FA TBSS .. 4 different normalization procedures


	# if [[ $this_preprocessing_step == "skull_strip" ]]; then
	# 	cd /ufrc/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/Pilot_Study_Data/${SUB}/Processed/MRI_files/08_DWI
	# 	ml fsl
	# 	bet2 eddy_corrected_data.nii eddy_corrected_Skullstripped.nii
	# files

	# if [[ $this_preprocessing_step == "check_dwi_ants" ]]; then
	# 	data_folder_to_analyze=($restingstate_processed_folder_names)
	# 	for this_functional_run_folder in ${data_folder_to_analyze[@]}; do
	# 		cd ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization
	# 		ml fsl/6.0.1
	# 		for this_functional_file in smoothed_warpedToMNI_unwarpedRealigned*.nii; do
	# 			this_core_functional_file_name=$(echo $this_functional_file | cut -d. -f 1)
	# 			echo saving jpeg of $this_core_functional_file_name for ${subject}
				

	# 			# xvfb-run -s "-screen 0 640x480x24" fsleyes render --scene ortho --outfile ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/check_MNI_ants_${this_core_functional_file_name} \
	# 			# ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/MNI_2mm.nii -cm red-yellow \
	# 			# ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/$this_functional_file --alpha 85
	# 			# # echo "Created screenshot for": ${SUB}-${SSN};
	# 			# display check_MNI_ants_${this_core_functional_file_name}.png
	# 		done
	# 	done
	# 	# echo This step took $SECONDS seconds to execute
	# 	# cd "${Subject_dir}"
	# 	# echo "Smoothing ANTS files: $SECONDS sec" >> preprocessing_log.txt
	# 	# SECONDS=0
	# fi

	## TO DO: eddy_quad or motion correction

	#

	## TO DO: dti_fit or motion correction
		# should give you differet images
	#

	# XYZ == RGB
	# 	Red = medial-lateral tracts
	# green = anterior-posterior, you can see major tracts
	#	 blue= up-down, you can see corticospinal tract in middle ish of the brain	

done
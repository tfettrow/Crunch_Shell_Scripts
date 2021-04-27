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
	ml gcc/5.2.0; ml ants ## ml gcc/9.3.0; ml ants/2.3.4
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

	if [[ $this_preprocessing_step == "check_dwi_raw" ]]; then
		fieldmap_folder_name=($dwi_fieldmap_processed_folder_name)
   		dwi_folder_name=($dwi_processed_folder_name)

   	    # replace with itksnap

		# cd ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
		# xvfb-run -s "-screen 0 640x480x24" fsleyes render --scene ortho --outfile ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}/check_dwi_raw \
		# ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}/DWI.nii --alpha 100
		# display check_dwi_raw.png
	fi


   	# TO DO:
	#if [[ dedrift/detrend mean signal intensity over time]]; then
		# 1) create b_mat text file (create_bmat_text.m)
		# 2) convert nii to mat file (nii_to_mat.m) # this is not necessary
		# 3) signal drift correction?
	#


	# used for nasa but not KH UF data
   	#if [[ ${preprocessing_steps[*]} =~ "rician_filter" ]]; then
   		# MainDWIDenoising # # 
   		# # arguments  to automate ?? X X
   	#fi

	# this is not necessary ?? 
   	# TO DO: 
   	#if [[  gibbs via MRtrix?? .. there is also gibbs correction in exploreDTI ]]; then
   		# wtf is gibbs.. TF missed it
   	#
   	

   	# TO DO: make sure dwi and fieldmap are registered
   	if [[ $this_preprocessing_step == "fieldmap_dti" ]]; then
   		fieldmap_folder_name=($dwi_fieldmap_processed_folder_name)
   		cd ${Subject_dir}/Processed/MRI_files/${fieldmap_folder_name}

		if [ -e AP_PA_merged.nii ]; then 
			rm AP_PA_merged.nii
		fi
		if [ -e Mean_AP_PA_merged.nii ]; then 
			rm Mean_AP_PA_merged.nii
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
			rm my_fieldmap_mask_brain.nii
		fi

		# removing a slice
		fslroi DistMap_AP DistMap_AP1 0 1
		fslroi DistMap_PA DistMap_PA1 0 1
		
		fslmerge -t AP_PA_merged.nii DistMap_AP1.nii DistMap_PA1.nii
		gunzip -f *nii.gz
		
		this_file_header_info=$(fslhd AP_PA_merged.nii )
		# this_file_number_of_slices=$(echo $this_file_header_info | grep -o dim3.* | tr -s ' ' | cut -d ' ' -f 2)
		# if [ $((this_file_number_of_slices%2)) -ne 0 ]; then
		# 	# removing a slice
		# 	fslroi AP_PA_merged AP_PA_merged 0 -1 0 -1 0 68 0 -1

		# 	# fslsplit AP_PA_merged.nii slice -z
		# 	# gunzip -f *nii.gz
		# 	# rm slice0000.nii
		# 	# fslmerge -z AP_PA_merged slice0*
		# 	# rm slice00*.nii
		# fi
		gunzip -f *nii.gz

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


		fslmaths se_epi_unwarped -Tmean my_fieldmap_mask
		bet2 my_fieldmap_mask my_fieldmap_mask_brain
		gunzip -f *nii.gz
   	fi

   	# TO DO:  [[ $this_preprocessing_step ==  "check_bet" ]]; then
   		#It may be a good idea to check this stage to ensure bet has done a good job of extracting the brain.



   	# TO DO: where does motion correction occur?? do we need to code this? according to KH, HM made her own function? that doesnt seem right, this should be a standard step.
   	# this happens in eddy below.. where does eddy_quad come in? look into different eddy checks
   	# 1mm total movement threshold
   	# run on gpu (eddy_cuda).. need to replace this..
   	# where does the slice-to-volume step come in to play? 
   	# read in the json file for the slice acq order

   	if [[ $this_preprocessing_step ==  "eddy_correction" ]]; then
   		fieldmap_folder_name=($dwi_fieldmap_processed_folder_name)
   		dwi_folder_name=($dwi_processed_folder_name)

   		cd ${Subject_dir}/Processed/MRI_files/${fieldmap_folder_name}
   		cp my_fieldmap_mask_brain.nii ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
		cp my_fieldmap.nii ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
		cp acqParams.txt ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
        cp topup_results* ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
        cd ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}
        

		NVOL=`fslnvols driftcorrected_DWI.nii`
		for ((i=1; i<=${NVOL}; i+=1)); do indx="$indx 1"; done; echo $indx > index.txt

		# need this?? only if fieldmap slice_removed!!	
		rm eddycorrected_driftcorrected_DWI.*
		rm my_fieldmap_mask_brain_pixAdjust.nii
		rm Mean_driftcorrected_DWI.nii
		
		fslmaths driftcorrected_DWI -Tmean Mean_driftcorrected_DWI

		flirt -in my_fieldmap_mask_brain.nii -ref Mean_driftcorrected_DWI.nii -out my_fieldmap_mask_brain_pixAdjust.nii
		# flirt -in my_fieldmap_mask_brain.nii -ref Mean_driftcorrected_DWI.nii -out my_fieldmap_pixAdjust.nii

	 	eddy_cuda9.1 --imain=driftcorrected_DWI.nii --mask=my_fieldmap_mask_brain_pixAdjust.nii --acqp=acqParams.txt --index=index.txt --bvecs=DWI.bvec --bvals=DWI.bval --niter=8 --fwhm=10,8,4,2,0,0,0,0 --repol --out=eddycorrected_driftcorrected_DWI --mporder=6 --json=DWI.json --s2v_niter=5 --s2v_lambda=1 --s2v_interp=trilinear --cnr_maps

		rm -r eddycorrected_driftcorrected_DWI.qc
		eddy_quad ${Subject_dir}/Processed/MRI_files/${dwi_folder_name}/eddycorrected_driftcorrected_DWI --eddyIdx index.txt --eddyParams acqParams.txt --mask my_fieldmap_mask_brain --bvals DWI.bval --output-dir=eddycorrected_driftcorrected_DWI.qc
		
		gunzip -f *nii.gz
	fi


	# if [[ $this_preprocessing_step == "skull_strip" ]]; then
	# 	cd /ufrc/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/Pilot_Study_Data/${SUB}/Processed/MRI_files/08_DWI
	# 	ml fsl
	# 	bet2 eddy_corrected_data.nii eddy_corrected_Skullstripped.nii
	# fi

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
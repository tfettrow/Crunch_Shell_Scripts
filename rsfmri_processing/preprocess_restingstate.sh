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
	ml itksnap
	
	cd $Subject_dir

	lines_to_ignore=$(awk '/#/{print NR}' file_settings.txt)

	restingstate_line_numbers_in_file_info=$(awk '/restingstate/{print NR}' file_settings.txt)
	t1_line_numbers_in_file_info=$(awk '/t1/{print NR}' file_settings.txt)

	restingstate_line_numbers_to_process=$restingstate_line_numbers_in_file_info
	t1_line_numbers_to_process=$t1_line_numbers_in_file_info

	this_index_restingstate=0
	this_index_t1=0
	for item_to_ignore in ${lines_to_ignore[@]}; do
		for item_to_check in ${restingstate_line_numbers_in_file_info[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_restingstate[$this_index_restingstate]=$item_to_ignore
  				(( this_index_restingstate++ ))
  			fi
  		done
  		for item_to_check in ${t1_line_numbers_to_process[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_t1[$this_index_t1]=$item_to_ignore
  				(( this_index_t1++ ))
  			fi
  		done
	done

	for item_to_remove_restingstate in ${remove_this_item_restingstate[@]}; do
		restingstate_line_numbers_to_process=$(echo ${restingstate_line_numbers_to_process[@]/$item_to_remove_restingstate})
	done
	for item_to_remove_t1 in ${remove_this_item_t1[@]}; do
		t1_line_numbers_to_process=$(echo ${t1_line_numbers_to_process[@]/$item_to_remove_t1})
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
	
	restingstate_processed_folder_names=$(echo "${restingstate_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	t1_processed_folder_names=$(echo "${t1_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

for this_preprocessing_step in ${preprocessing_steps[@]}; do
		if [[ $this_preprocessing_step == "slicetime_restingstate" ]]; then
		    data_folder_to_analyze=($restingstate_processed_folder_names)
        	#cd $Subject_dir/Processed/MRI_files
            cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/
            
            if [ -e slicetimed_*.nii ]; then 
                rm slicetimed_*.nii
            fi
			gunzip *.gz
            matlab -nodesktop -nosplash -r "try; slicetime_restingstate; catch; end; quit"

        	echo This step took $SECONDS seconds to execute
        	cd ${Subject_dir}
        	echo "slicetime_restingstate: $SECONDS sec" >> preprocessing_log.txt
        	SECONDS=0
		fi
##########
		if [[ $this_preprocessing_step == "create_fieldmap_restingstate" ]]; then

			data_folder_to_copy_to=($restingstate_processed_folder_names)
			
   			# WARNING: this logic is specific to MiM until decide on better method
			subject=$(echo ${Subject_dir} | egrep -o '[[:digit:]]{4}' | head -n1)
   			subject_level=$(echo $subject | cut -c1-1)
   			echo $subject_level

   			# This logic says if MiM subject id starts with 3 (harmonized) then go ahead and process fieldmaps..
   			# if not, then copy fieldmaps for restingstate from task fmri folder
   			if [[ $subject_level == 3 ]]; then
			   
   				cd ${Subject_dir}/Processed/MRI_files/03_Fieldmaps
				if [[ -d Fieldmap_imagery ]]; then
				cd Fieldmap_imagery
				
    	    	cp fpm_my_fieldmap.hdr ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
    	    	cp fpm_my_fieldmap.img ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
    	    	cp ${Matlab_dir}/helper/vdm_defaults.m ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
				cp se_epi_unwarped.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
				else
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

					fslmerge -t AP_PA_merged.nii DistMap_AP.nii DistMap_PA.nii
			
					this_file_header_info=$(fslhd AP_PA_merged.nii )
					this_file_number_of_slices=$(echo $this_file_header_info | grep -o dim3.* | tr -s ' ' | cut -d ' ' -f 2)
		
					if [ $((this_file_number_of_slices%2)) -ne 0 ]; then
						fslsplit AP_PA_merged.nii slice -z
						gunzip -f *nii.gz
						rm slice0000.nii
						fslmerge -z AP_PA_merged slice0*
						rm slice00*.nii
					fi
		
					fslmaths AP_PA_merged.nii -Tmean Mean_AP_PA_merged.nii
					gunzip -f *nii.gz
		
					cp Mean_AP_PA_merged.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
				
					echo creating fieldmap...
					cd ${Subject_dir}/Processed/MRI_files/03_Fieldmaps
					# just cleaning up in case this is being rerun
					if [ -e my_fieldmap_nifti.nii ]; then
						rm my_fieldmap_nifti.nii
					fi
					if [ -e acqParams.txt ]; then
						rm acqParams.txt
					fi
					if [ -e my_fieldmap_mag.nii ]; then
						rm my_fieldmap_mag.nii
					fi
						
					# just a dummy value to check whether ecoding direction is same between distmaps
					previous_encoding_direction=k
					# assuming only the DistMaps have .jsons in this folder
					for this_json_file in *.json*; do
												
						total_readout=$(grep "TotalReadoutTime" ${this_json_file} | tr -dc '0.00-9.00')
						encoding_direction=$(grep "PhaseEncodingDirection" ${this_json_file} | cut -d: -f 2 | head -1 | tr -d '"' |  tr -d ',')

						this_file_name=$(echo $this_json_file | cut -d. -f 1)
						this_file_header_info=$(fslhd $this_file_name.nii)
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
					topup --imain=AP_PA_merged.nii --datain=acqParams.txt --fout=my_fieldmap_nifti --config=b02b0.cnf --iout=se_epi_unwarped --out=topup_results

					fslmaths se_epi_unwarped -Tmean my_fieldmap_mag
					
					ml fsl/5.0.8
					fslchfiletype ANALYZE my_fieldmap_nifti.nii fpm_my_fieldmap
		
					gunzip -f *nii.gz
					cp fpm_my_fieldmap.hdr ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
    	    		cp fpm_my_fieldmap.img ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
    	    		cp ${Matlab_dir}/helper/vdm_defaults.m ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
					cp se_epi_unwarped.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
				fi
   			else
   				# WARNING: hard coded to imagery since this is closest in time to restingstate (assuming preprocess_fmri has already been run)				
				cd ${Subject_dir}/Processed/MRI_files/03_Fieldmaps/Fieldmap_imagery
				
    	    	cp fpm_my_fieldmap.hdr ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
    	    	cp fpm_my_fieldmap.img ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
    	    	cp ${Matlab_dir}/helper/vdm_defaults.m ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
				cp se_epi_unwarped.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
		
			fi
			echo This step took $SECONDS seconds to execute
			cd ${Subject_dir}
			echo "create_fieldmap_restingstate : $SECONDS sec" >> preprocessing_log.txt
			SECONDS=0
		fi
###########
   		if [[ $this_preprocessing_step == "realign_unwarp_restingstate" ]]; then
   			data_folder_to_copy_to=($restingstate_processed_folder_names)
   			cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}
				
			for this_rsfMRI_file in RestingState*.nii; do
				this_core_functional_file_name=$(echo $this_rsfMRI_file | cut -d. -f 1)
				read_out=$(cat vdm_defaults.m)
				array[0]=$(echo $read_out | awk -F";" '{print $1}')
				array[1]=$(echo $read_out | awk -F";" '{print $2}')
				array[2]=$(echo $read_out | awk -F";" '{print $3}')
				array[3]=$(echo $read_out | awk -F";" '{print $4}')
				array[4]=$(echo $read_out | awk -F";" '{print $5}')
	
   				total_readout_sec=$(grep "TotalReadoutTime" ${this_core_functional_file_name}.json | tr -dc '0.00-9.00')
				encoding_direction=$(grep "PhaseEncodingDirection" ${this_core_functional_file_name}.json | cut -d: -f 2 | head -1 | tr -d '"' |  tr -d ',')
				if [[ $encoding_direction =~ LR ]]; then
					array[2]="pm_def.K_SPACE_TRAVERSAL_BLIP_DIR = -1;"
				else
					array[2]="pm_def.K_SPACE_TRAVERSAL_BLIP_DIR = 1;"
				fi
				total_readout_ms=$(echo "1000 * $total_readout_sec" | bc )
	  				
	  			echo $total_readout_ms
				array[1]="pm_def.EPI_BASED_FIELDMAPS = 0;"
	  			array[3]="pm_def.TOTAL_EPI_READOUT_TIME = $total_readout_ms;"
	  			array[4]="pm_def.DO_JACOBIAN_MODULATION = 0;"
				
				rm vdm_defaults.m
	  			rm vdm5_fpm_my_fieldmap.img
	  			rm vdm5_fpm_my_fieldmap.hdr
	  			echo ${array[0]} >> vdm_defaults.m
	  			echo ${array[1]} >> vdm_defaults.m
	  			echo ${array[2]} >> vdm_defaults.m
	  			echo ${array[3]} >> vdm_defaults.m
	  			echo ${array[4]} >> vdm_defaults.m
	
	    		matlab -nodesktop -nosplash -r "try; create_vdm_img('slicetimed_${this_core_functional_file_name}.nii'); catch; end; quit"
	   			matlab -nodesktop -nosplash -r "try; realign_unwarp_single('slicetimed_${this_core_functional_file_name}.nii'); catch; end; quit"
				
				for this_rp_file in rp_*.txt; do
					if ! [[ $this_rp_file =~ "unwarpedRealigned" ]]; then
						this_filename_1=$(echo $this_rp_file | cut -d'_' -f1)
						this_filename_2=$(echo $this_rp_file | cut -d'_' -f2)
						this_filename_3=$(echo $this_rp_file | cut -d'_' -f3)
						# this_filename_4=$(echo $this_rp_file | cut -d'_' -f4)
						mv -v $this_rp_file ${this_filename_1}_unwarpedRealigned_${this_filename_2}_${this_filename_3} #_${this_filename_4}
					fi
				done
			done
			echo This step took $SECONDS seconds to execute
			cd ${Subject_dir}
			echo "create_fieldmap_restingstate : $SECONDS sec" >> preprocessing_log.txt
			SECONDS=0
		fi
##########
		if [[ $this_preprocessing_step == "art_restingstate" ]]; then
			data_folder_to_analyze=($restingstate_processed_folder_names)
			data_folder_to_copy_from=($t1_processed_folder_names)
	
			cp ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_from}/T1.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/
			cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/
		
			for this_rp_file in rp_*.txt; do
				if ! [[ $this_rp_file =~ "unwarpedRealigned" ]]; then
					this_filename_1=$(echo $this_rp_file | cut -d'_' -f1)
					this_filename_2=$(echo $this_rp_file | cut -d'_' -f2)
					this_filename_3=$(echo $this_rp_file | cut -d'_' -f3)
					this_filename_4=$(echo $this_rp_file | cut -d'_' -f4)
					mv -v $this_rp_file ${this_filename_1}_unwarpedRealigned_${this_filename_2}_${this_filename_3}
				fi
			done

			for this_functional_file in unwarpedRealigned*.nii; do
				matlab -nodesktop -nosplash -r "try; art_restingstate('$this_functional_file'); catch; end; quit"
	
				rm T1.nii
				rm -rf Conn_Art_Folder_Stuff
    			rm Conn_Art_Folder_Stuff.mat
    			#rm art_mask.hdr
    			#rm art_mask.img
			done
			echo This step took $SECONDS seconds to execute
			cd ${Subject_dir}
			echo "Artifact Regression Tool: $SECONDS sec" >> preprocessing_log.txt
			SECONDS=0
		fi
	
		if [[ $this_preprocessing_step == "remove_outlier_volumes" ]]; then
			lines_to_ignore=$(awk '/#/{print NR}' outlier_removal_settings.txt)
			line_numbers_to_process=$(awk 'END{print NR}' outlier_removal_settings.txt)
			
			#this_index=0
			for (( this_line_number=1; this_line_number<=${line_numbers_to_process}; this_line_number++ )); do
				if ! [[ ${lines_to_ignore[*]} =~ $this_line_number ]]; then
					processed_folder_name_array=$(cat outlier_removal_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f1)
					run_number_array=$(cat outlier_removal_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
					first_index_array=$(cat outlier_removal_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f3)
					last_index_array=$(cat outlier_removal_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f4)
					processed_folder_names=$(echo "${processed_folder_name_array[@]}" | tr '' '\n' )

					for this_processed_folder in $processed_folder_names; do
						cd ${Subject_dir}/Processed/MRI_files/${this_processed_folder}
		
						this_slicetimed_file=slicetimed_RestingState.nii						
						ml fsl/6.0.1
						## need to check the length of slicetimed run with respect to raw.. if already changed throw an error
						this_slicetimed_file_corename=$(echo $this_slicetimed_file | cut -d. -f 1)
						this_raw_file_name=$(echo $this_slicetimed_file | cut -d_ -f2-)

						this_slicetimed_file_info=$(fslhd $this_slicetimed_file)
						this_slicetimed_file_number_of_volumes=$(echo $this_slicetimed_file_info | grep -o dim4.* | tr -s ' ' | cut -d ' ' -f 2)
						this_raw_file_info=$(fslhd $this_raw_file_name)
						this_raw_file_number_of_volumes=$(echo $this_raw_file_info | grep -o dim4.* | tr -s ' ' | cut -d ' ' -f 2)
						if ! [[ $this_slicetimed_file_number_of_volumes = $this_raw_file_number_of_volumes ]]; then
							echo "Warning:" $this_slicetimed_file_corename "in" $processed_folder_names "WAS ALREADY ADJUSTED!!!"
							#exit 1
						else
							fslsplit $this_slicetimed_file
							this_volume_index=0
							for this_volume_file in vol*; do
								if ! [[ ${first_index_array} =~ NA ]]; then 
									if [[ $this_volume_index -lt ${first_index_array} ]]; then
										rm $this_volume_file
										#echo $this_volume_file
									fi
								fi
								if ! [[ ${last_index_array} =~ NA ]]; then 
									if [[ ${last_index_array} -lt ${this_volume_index} ]]; then
										rm $this_volume_file
										#echo $this_volume_file
									fi
								fi
								(( this_volume_index++ ))
							done
	
							rm ${this_slicetimed_file_corename}.nii
							rm unwarpedRealigned_${this_slicetimed_file_corename}.nii
							rm rp_unwarpedRealigned_${this_slicetimed_file_corename}.txt
			
							fslmerge -a $this_slicetimed_file vol*
							rm vol*
							gunzip -f *nii.gz		
			
							matlab -nodesktop -nosplash -r "try; realign_unwarp_single('$this_slicetimed_file'); catch; end; quit"
						
							for this_rp_file in rp_*.txt; do
								if ! [[ $this_rp_file =~ "unwarpedRealigned" ]]; then
									this_filename_1=$(echo $this_rp_file | cut -d'_' -f1)
									this_filename_2=$(echo $this_rp_file | cut -d'_' -f2)
									this_filename_3=$(echo $this_rp_file | cut -d'_' -f3)
									this_filename_4=$(echo $this_rp_file | cut -d'_' -f4)
									mv -v $this_rp_file ${this_filename_1}_unwarpedRealigned_${this_filename_2}_${this_filename_3}_${this_filename_4}
								fi
							done
				
							matlab -nodesktop -nosplash -r "try; art_fmri('unwarpedRealigned_${this_slicetimed_file}'); catch; end; quit"
							rm T1.nii
							rm -rf Conn_Art_Folder_Stuff
    						rm Conn_Art_Folder_Stuff.mat
    						rm art_mask.hdr
    						rm art_mask.img
    					fi
					done
				fi
				cd ${Subject_dir}
			done
			echo This step took $SECONDS seconds to execute
			cd ${Subject_dir}
			echo "Outlier Removal: $SECONDS sec" >> preprocessing_log.txt
			SECONDS=0
		fi
###########
		if [[ $this_preprocessing_step == "n4_bias_correct" ]]; then
			data_folder_to_analyze=($restingstate_processed_folder_names)
			cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}
			cp ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/meanunwarpedRealigned*.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
	        cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			# for each run in this functional folder, bias correct and place in ANTS folder
			for this_func_file in meanunwarpedRealigned*.nii; do 
				N4BiasFieldCorrection -i $this_func_file -o biascorrected_$this_func_file
			done

			echo This step took $SECONDS seconds to execute
			cd "${Subject_dir}"
			echo "Bias Corrected: $SECONDS sec" >> preprocessing_log.txt
			SECONDS=0
		fi
###########		
		if [[ $this_preprocessing_step == "copy_skullstripped_biascorrected_t1_4_ants" ]]; then
			this_t1_folder=($t1_processed_folder_names)
			data_folder_to_copy_to=($restingstate_processed_folder_names)
			cd ${Subject_dir}/Processed/MRI_files/${this_t1_folder}
			mkdir -p ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization


			pwd
			# echo ${this_t1_folder}
			# echo ${data_folder_to_copy_to}
			cp SkullStripped_biascorrected_T1.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization/
			cp c1biascorrected_T1.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization/
			cp c2biascorrected_T1.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization/
			cp c3biascorrected_T1.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization/
			cp c4biascorrected_T1.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization/
			cp c5biascorrected_T1.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_copy_to}/ANTS_Normalization/
		fi
############
		if [[ $this_preprocessing_step == "ants_norm_restingstate" ]]; then
			data_folder_to_analyze=($restingstate_processed_folder_names)
	
			cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			
			if [ -e warpToT1Params_*.nii ]; then 
                rm warpToT1Params_*.nii
                rm warpToT1Params_*.mat
                rm warpToT1Estimate_*.nii
            fi
			
			for this_mean_file in biascorrected_mean*.nii; do
				T1_Template=SkullStripped_biascorrected_T1.nii
				Mean_Func=$this_mean_file
				this_core_file_name=$(echo $this_mean_file | cut -d. -f 1)
				echo 'registering' $Mean_Func 'to' $T1_Template
				#moving low res func to high res T1
				antsRegistration --dimensionality 3 --float 0 \
				    --output [warpToT1Params_${this_core_file_name},warpToT1Estimate_${this_core_file_name}.nii] \
				    --interpolation Linear \
				    --winsorize-image-intensities [0.005,0.995] \
				    --use-histogram-matching 0 \
				    --initial-moving-transform [$T1_Template,$Mean_Func,1] \
				    --transform Rigid[0.1] \
				    --metric MI[$T1_Template,$Mean_Func,1,32,Regular,0.25] \
				    --convergence [1000x500x250x100,1e-6,10] \
				    --shrink-factors 8x4x2x1 \
				    --smoothing-sigmas 3x2x1x0vox
			done

			if [ -e warpedToT1_*.nii ]; then 
        	    rm warpedToT1_*.nii
        	fi

        	gunzip -f *nii.gz

			for this_mean_file in biascorrected_mean*.nii; do
				this_core_file_name=$(echo $this_mean_file | cut -d. -f 1)
				antsApplyTransforms -d 3 -e 3 -i ${this_core_file_name}.nii -r SkullStripped_biascorrected_T1.nii \
				-n BSpline -o warpedToT1_${this_core_file_name}.nii -t [warpToT1Params_${this_core_file_name}0GenericAffine.mat,0] -v 
			done
		
			if [ -e warpToMNIParams_*.nii ]; then 
        	    rm warpToMNIParams_*.nii
        	    rm warpToMNIParams_*.mat
        	    rm warpToMNIEstimate_*.nii
        	    rm warpedToMNI_*.nii
        	fi
			gunzip -f *nii.gz
			#outputFolder=${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			T1_Template=SkullStripped_biascorrected_T1.nii
			# T1_Template=${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization/SkullStripped_biascorrected_T1.nii
			MNI_Template=${Template_dir}/MNI_1mm.nii
			this_core_file_name=SkullStripped_biascorrected_T1
			echo 'registering' $T1_Template 'to' $MNI_Template

			antsRegistration --dimensionality 3 --float 0 \
        	--output [warpToMNIParams_${this_core_file_name},warpToMNIEstimate_${this_core_file_name}.nii] \
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

			# #--output [$outputFolder/warpToMNIParams_${this_core_file_name},$outputFolder/warpToMNIEstimate_${this_core_file_name}.nii] \
			gunzip -f *nii.gz

			cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			cp ${Template_dir}/MNI_2mm.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			
			this_core_file_name=SkullStripped_biascorrected_T1

			antsApplyTransforms -d 3 -e 3 -i ${this_core_file_name}.nii -r MNI_2mm.nii \
			-n BSpline -o warpedToMNI_${this_core_file_name}.nii -t [warpToMNIParams_${this_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_core_file_name}0GenericAffine.mat,0] -v

			antsApplyTransforms -d 3 -e 3 -i c1biascorrected_T1.nii -r MNI_2mm.nii \
			-n BSpline -o warpedToMNI_c1T1.nii -t [warpToMNIParams_${this_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_core_file_name}0GenericAffine.mat,0] -v
			
			antsApplyTransforms -d 3 -e 3 -i c2biascorrected_T1.nii -r MNI_2mm.nii \
			-n BSpline -o warpedToMNI_c2T1.nii -t [warpToMNIParams_${this_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_core_file_name}0GenericAffine.mat,0] -v
			
			antsApplyTransforms -d 3 -e 3 -i c3biascorrected_T1.nii -r MNI_2mm.nii \
			-n BSpline -o warpedToMNI_c3T1.nii -t [warpToMNIParams_${this_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_core_file_name}0GenericAffine.mat,0] -v
			
			gunzip -f *nii.gz

			cp ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/unwarpedRealigned*.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			
			for this_file_to_warp in unwarpedRealigned*.nii; do 
				echo $this_file_to_warp
				ml fsl
				this_file_header_info=$(fslhd $this_file_to_warp)
				this_file_number_of_volumes=$(echo $this_file_header_info | grep -o dim4.* | tr -s ' ' | cut -d ' ' -f 2)

				this_func_core_file_name=$(echo $this_file_to_warp | cut -d. -f 1)
				this_T1_core_file_name=SkullStripped_biascorrected_T1
			
				antsApplyTransforms -d 3 -e 3 -i $this_file_to_warp -r MNI_2mm.nii \
				-o warpedToMNI_$this_file_to_warp -t [warpToT1Params_biascorrected_mean${this_func_core_file_name}0GenericAffine.mat,0] \
				-t [warpToMNIParams_${this_T1_core_file_name}1Warp.nii] -t [warpToMNIParams_${this_T1_core_file_name}0GenericAffine.mat,0] -v
			done
			
			gunzip -f *nii.gz
			echo This step took $SECONDS seconds to execute
			cd "${Subject_dir}"
			echo "ANTS Normalization: $SECONDS sec" >> preprocessing_log.txt
			SECONDS=0
		fi
	
		if [[ $this_preprocessing_step == "smooth_restingstate_ants" ]]; then
			data_folder_to_analyze=($restingstate_processed_folder_names)
			cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			if [[ -e smoothed_*.nii ]]; then
               	rm smoothed_*.nii
            fi
			matlab -nodesktop -nosplash -r "try; smooth_restingstate_ants; catch; end; quit"
			echo This step took $SECONDS seconds to execute
			cd "${Subject_dir}"
			echo "Smoothing ANTS files: $SECONDS sec" >> preprocessing_log.txt
			SECONDS=0
		fi

		if [[ $this_preprocessing_step == "check_restingstate_ants" ]]; then
			data_folder_to_analyze=($restingstate_processed_folder_names)
			for this_functional_run_folder in ${data_folder_to_analyze[@]}; do
				cd ${Subject_dir}/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization
				ml fsl/6.0.1
				for this_functional_file in smoothed_warpedToMNI_unwarpedRealigned*.nii; do
					this_core_functional_file_name=$(echo $this_functional_file | cut -d. -f 1)
					echo checking $this_core_functional_file_name for ${Subject_dir}
					
					stat $this_functional_file
					# itksnap -g MNI_2mm.nii  -o $this_functional_file
					# fslview_deprecated MNI_2mm.nii $this_functional_file
				done
			done
		fi
		if [[ $this_preprocessing_step == "copy_files_restingstate" ]]; then
			data_folder_to_analyze=($restingstate_processed_folder_names)
			echo copying files ${Subject_dir}
			cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			pwd
			gunzip *.gz
			Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data
			subject=$(echo ${Subject_dir} | egrep -o '[[:digit:]]{4}' | head -n1)
			cp ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/rp_* ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			cp ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/art_regression_outliers_and_movement*.mat ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			# cp ${Subject_dir}/Processed/MRI_files/05_MotorImagery/ANTS_Normalization/warpedToMNI_biascorrected*.nii ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}/ANTS_Normalization
			echo "copying done: check CONN_test folder"
		fi
done

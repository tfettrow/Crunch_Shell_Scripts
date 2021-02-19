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

# example >> export_fmri_wholebrain.sh '1002,1004,1007,1009,1010,1011,1013,1020,1022,1024,1027,2002,2007,2008,2012,2013,2015,2017,2018,2020,2021,2022,2023,2025,2026,2033,2034,2037,2042,2052' 05_MotorImagery ROI_settings_MiMRedcap.txt

##################################################

argument_counter=0
for this_argument in "$@"; do
	if	[[ $argument_counter == 0 ]]; then
		subjects=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		this_functional_run_folder=$this_argument
	elif [[ $argument_counter == 2 ]]; then
		roi_settings_file=$this_argument
	fi
	(( argument_counter++ ))
done

Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data
	
#####################################################################################################################################################
ml fsl/6.0.1
while IFS=',' read -ra subject_list; do
    for this_subject in "${subject_list[@]}"; do
       	cd ${Study_dir}/$this_subject/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/Level1_WholeBrain	     					
   	    outfile=${this_subject}_fmri_wholebrain_betas.csv
   	    if [ -e ${this_subject}_fmri_redcap.csv ]; then
   	    	rm ${this_subject}_fmri_redcap.csv
   	    fi
		if [ -e ${this_subject}_fmri_wholebrain_betas.csv ]; then
			rm ${this_subject}_fmri_wholebrain_betas.csv
		fi
		var1="record_id, redcap_event_name"
		var2="$H${this_subject}, base_v4_mri_arm_1" 
		echo -e "$var1\n$var2" >> "$outfile"
       	cd "${Study_dir}"
		lines_to_ignore=$(awk '/#/{print NR}' $roi_settings_file)
		roi_line_numbers=$(awk 'END{print NR}' $roi_settings_file)
		for (( this_row=1; this_row<=${roi_line_numbers}; this_row++ )); do
			if ! [[ ${lines_to_ignore[*]} =~ $this_row ]]; then
				this_roi_file_corename=$(cat $roi_settings_file | sed -n ${this_row}p | cut -d ',' -f4)
				this_roi_file_corename_squeeze=$(echo $this_roi_file_corename | sed -r 's/( )+//g')
				this_roi_image_name=${Study_dir}/ROIs/${this_roi_file_corename_squeeze}.nii
				echo pulling betas for $this_roi_image_name on $this_subject
				cd ${Study_dir}/$this_subject/Processed/MRI_files/${this_functional_run_folder}/ANTS_Normalization/Level1_WholeBrain
   				if [[ $this_functional_run_folder == "05_MotorImagery" ]]; then
		 	
		 			if ! [ -e noNANcon_0001.nii ]; then
    						fslmaths con_0001.nii -nan noNANcon_0001
    						fslmaths con_0002.nii -nan noNANcon_0002
    						fslmaths con_0003.nii -nan noNANcon_0003
    						fslmaths con_0004.nii -nan noNANcon_0004
    						gunzip -f *nii.gz
    					fi
					beta=0
					beta=$(fslmeants -i noNANcon_0001.nii -m $this_roi_image_name)
					# echo $this_roi_file_corename_squeeze
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},flat_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					beta=$(fslmeants -i noNANcon_0003.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},low_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					beta=$(fslmeants -i noNANcon_0004.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},med_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					beta=$(fslmeants -i noNANcon_0002.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},high_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"		​
					# beta=0
					# beta=$(fslmeants -i con_0001.nii -m $this_roi_image_name)
					# # echo $this_roi_file_corename_squeeze
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},flat_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					# beta=$(fslmeants -i con_0003.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},low_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					# beta=$(fslmeants -i con_0004.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},med_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					# beta=$(fslmeants -i con_0002.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},high_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"		​								
				fi	
				if [[ $this_functional_run_folder == "06_Nback" ]]; then
		 	
		 			if ! [ -e noNANcon_0001.nii ]; then
    						fslmaths con_0001.nii -nan noNANcon_0001
    						fslmaths con_0002.nii -nan noNANcon_0002
    						fslmaths con_0003.nii -nan noNANcon_0003
    						fslmaths con_0004.nii -nan noNANcon_0004
    						fslmaths con_0005.nii -nan noNANcon_0005
    						fslmaths con_0006.nii -nan noNANcon_0006
    						fslmaths con_0007.nii -nan noNANcon_0007
    						fslmaths con_0008.nii -nan noNANcon_0008
    						gunzip -f *nii.gz
    					fi
					beta=0
					beta=$(fslmeants -i noNANcon_0004.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},zero_long_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					beta=$(fslmeants -i noNANcon_0001.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},one_long_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					beta=$(fslmeants -i noNANcon_0003.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},two_long_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					beta=$(fslmeants -i noNANcon_0002.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},three_long_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					beta=$(fslmeants -i noNANcon_0008.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},zero_short_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					beta=$(fslmeants -i noNANcon_0005.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},one_short_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					beta=$(fslmeants -i noNANcon_0007.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},two_short_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					beta=$(fslmeants -i noNANcon_0006.nii -m $this_roi_image_name)
					first_row=$(cat $outfile | sed -n 1p)
					second_row=$(cat $outfile | sed -n 2p) 
					rm $outfile
					echo -e "${first_row},three_short_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"		
					# beta=0
					# beta=$(fslmeants -i con_0004.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},zero_long_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					# beta=$(fslmeants -i con_0001.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},one_long_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					# beta=$(fslmeants -i con_0003.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},two_long_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					# beta=$(fslmeants -i con_0002.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},three_long_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					# beta=$(fslmeants -i con_0008.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},zero_short_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					# beta=$(fslmeants -i con_0005.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},one_short_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					# beta=$(fslmeants -i con_0007.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},two_short_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"
					# beta=$(fslmeants -i con_0006.nii -m $this_roi_image_name)
					# first_row=$(cat $outfile | sed -n 1p)
					# second_row=$(cat $outfile | sed -n 2p) 
					# rm $outfile
					# echo -e "${first_row},three_short_${this_roi_file_corename_squeeze}\n${second_row},$beta" >> "$outfile"				
				fi	
 				cd ${Study_dir}
 			fi			
		done
		cd ${Study_dir}
	done
 done <<< "$subjects"
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


# this script requires arguments... use the batch_fmri.batch to call this shell script
# example >> combine_asl_redcap.sh '1002,1004,1007,1009,1010,1011,1012,1013,1017,1018,1019,1020,1022,1024,1025,1026,1027,2002,2007,2008,2012,2013,2015,2017,2018,2020,2021,2022,2023,2025,2026,2033,2034,2037,2038,2039,2042,2052,2059,2027,3004,3006,3007,3008,3010,3021,3023,3024,3025,3026,3028,3029,3030,3034,3036,3039,3040,3042,3043,3046,3047,3051,3053,3058,3059,3063,3066,3068' 07_ASL 

argument_counter=0
for this_argument in "$@"; do
	if [[ $argument_counter == 0 ]]; then
		subjects=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		asl_processed_folder_name=$this_argument
	fi
	(( argument_counter++ ))
done

Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data

#####################################################################################################################################################
ml fsl/6.0.3

subject_index=0
outfile=${asl_processed_folder_name}_asl_redcap.csv
if [ -e ${asl_processed_folder_name}_asl_redcap.csv ]; then
	rm ${asl_processed_folder_name}_asl_redcap.csv
fi
while IFS=',' read -ra subject_list; do
   	for this_subject in "${subject_list[@]}"; do
   		Results_folder_name=BasilCMD_calib_anat_FM_scalib_pvcorr
   	   	cd ${Study_dir}/$this_subject/Processed/MRI_files/07_ASL/$Results_folder_name/ANTS_Normalization
   	   	this_subject_header=$(cat ${this_subject}_fsl_perfusion_calib.txt | sed -n 1p)
   	   	this_subject_data=$(cat ${this_subject}_fsl_perfusion_calib.txt | sed -n 2p)
		
		cd ${Study_dir}
   	   	this_subject_header_outfile=$(cat $outfile | sed 1d)
   		row1=$this_subject_header
		existing_section=$this_subject_header_outfile
		new_row=$this_subject_data
		if [[ subject_index == 0 ]]; then
			echo -e "$row1\n$new_row" >> "$outfile"
		else
			rm $outfile
			echo -e "$row1\n$existing_section\n$new_row" >> "$outfile"
		fi
		(( subject_index++ ))
	done
 done <<< "$subjects"
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

subject=$1


Subject_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data/${subject}
cd "${Subject_dir}"

lines_to_ignore=$(awk '/#/{print NR}' file_settings.txt)

	asl_line_numbers_in_file_info=$(awk '/asl/{print NR}' file_settings.txt)
# echo $asl_line_numbers_in_file_info
	asl_line_numbers_to_process=$asl_line_numbers_in_file_info

	this_index_asl=0
	for item_to_ignore in ${lines_to_ignore[@]}; do
		for item_to_check in ${asl_line_numbers_in_file_info[@]}; do
  			if [[ $item_to_check == $item_to_ignore ]]; then 
  				remove_this_item_asl[$this_index_asl]=$item_to_ignore
  				(( this_index_asl++ ))
  			fi
  		done
	done

	for item_to_remove_asl in ${remove_this_item_asl[@]}; do
		asl_line_numbers_to_process=$(echo ${asl_line_numbers_to_process[@]/$item_to_remove_asl})
	done

	this_index=0
	for this_line_number in ${asl_line_numbers_to_process[@]}; do
		asl_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
		(( this_index++ ))
	done

	asl_processed_folder_name=$(echo "${asl_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

data_folder_to_analyze=($asl_processed_folder_name)
#cd $Subject_dir/Processed/MRI_files

cd ${Subject_dir}/
rm core*


cd ${Subject_dir}/Processed/MRI_files/${asl_processed_folder_name}
chmod g-s *.nii.gz
chmod g-s *.nii
GLOBIGNORE=BasilCMD_calib_anat_FM_scalib_pvcorr:ASL_Run1*.nii
rm -r ANTS_Normalization
rm -r BasilCMD_calib
rm -r BasilCMD_calib_anat
rm -r BasilCMD_calib_anat_FM
rm -r BasilCMD_calib_anat_scalib
rm -r BasilCMD_calib_anat_scalib_pvcorr
rm -r BasilCMD_calib_pvcorr
rm -fv *
unset GLOBIGNORE
gzip *.nii

################################################################
cd BasilCMD_calib_anat_FM_scalib_pvcorr
pwd
rm -r std_space
rm -r struct_space
rm -r calib
	
################################################################
cd ANTS_Normalization
chmod g-s *.nii.gz
chmod g-s *.nii
GLOBIGNORE=warpedToMNI*.nii:perfusion.nii:perfusion_calib.nii:MNI_2mm.nii:*fsl_perfusion.txt:*fsl_perfusion_calib.txt
rm -fv *
unset GLOBIGNORE
gzip *.nii
	

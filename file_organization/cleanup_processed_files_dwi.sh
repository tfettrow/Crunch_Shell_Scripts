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


dwi_line_numbers_in_file_info=$(awk '/dwi/{print NR}' file_settings.txt)

dwi_line_numbers_to_process=$dwi_line_numbers_in_file_info

this_index_dwi=0
for item_to_ignore in ${lines_to_ignore[@]}; do
	for item_to_check in ${dwi_line_numbers_in_file_info[@]}; do
  		if [[ $item_to_check == $item_to_ignore ]]; then 
  			remove_this_item_fmri[$this_index_fmri]=$item_to_ignore
  			(( this_index_dwi++ ))
  		fi
  	done
done

for item_to_remove_fmri in ${remove_this_item_fmri[@]}; do
	dwi_line_numbers_to_process=$(echo ${dwi_line_numbers_to_process[@]/$item_to_remove_fmri})
done

this_index=0
for this_line_number in ${dwi_line_numbers_to_process[@]}; do
	dwi_processed_folder_name_array[$this_index]=$(cat file_settings.txt | sed -n ${this_line_number}p | cut -d ',' -f2)
	(( this_index++ ))
done
	
dwi_processed_folder_name=$(echo "${dwi_processed_folder_name_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

data_folder_to_analyze=($dwi_processed_folder_name)
#cd $Subject_dir/Processed/MRI_files

cd ${Subject_dir}/Processed/MRI_files/${data_folder_to_analyze}
GLOBIGNORE=*.json:*.bval:driftcorrected_DWI.png:*.bvec:DWI.nii:eddycorrected_driftcorrected_DWI*:acqParams.txt:index.txt:SkullStripped_biascorrected_T1.nii:c2biascorrected_T1.nii:eddycorrected_*
rm -v *
unset GLOBIGNORE
gzip *.nii
	

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

# example >> export_fmri_wholebrain.sh '1002,1004,1007,1009,1010,1011,1013,1020,1022,1024,1027,2002,2007,2008,2012,2013,2015,2017,2018,2020,2021,2022,2023,2025,2026,2033,2034,2037,2042,2052' this_rsfmri_folder

##################################################

argument_counter=0
for this_argument in "$@"; do
	if	[[ $argument_counter == 0 ]]; then
		subjects=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		this_rsfmri_folder=$this_argument
	elif [[ $argument_counter == 2 ]]; then
		roi_settings_file=$this_argument
	fi
	(( argument_counter++ ))
done

Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data
	$this_subject
#####################################################################################################################################################
ml fsl/6.0.1
while IFS=',' read -ra subject_list; do
	for this_subject in "${subject_list[@]}"; do
		cd ${Study_dir}/$this_subject/Processed/MRI_files/${this_rsfmri_folder}/ANTS_Normalization/Level1_WholeBrain			
   	    outfile=${this_subject}_fmri_wholebrain_betas.csv
   	    if [ -e ${this_subject}_fmri_redcap.csv ]; then
   	    	rm ${this_subject}_fmri_redcap.csv
   	    fi	
	cd ${Study_dir}
	done
 done <<< "$subjects"
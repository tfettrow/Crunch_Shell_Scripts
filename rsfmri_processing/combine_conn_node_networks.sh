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

# this script requires arguments .... call from the batch_fmri.batch

# example >> combine_conn_node_networks.sh conn_wu120_test 'left_dlpfc,medial_prefrontal_cortex,post_cingulate'
# combine_conn_node_networks.sh conn_wu120_all_wb 'left_dlpfc,right_dlpfc,left_acc,right_acc,medial_prefrontal_cortex,post_cingulate,left_aud_cortex,left_post_ips,right_post_ips,left_insular,right_insular,visual_cortex,left_ips,right_ips,right_thalamus,left_hand,right_hand,left_mouth,right_mouth,left_rsc,right_rsc,dACC'
# combine_conn_node_networks.sh  conn_wu120_all_wb 'left_hand,right_mouth,medial_prefrontal_cortex_post_cingulate,right_post_ips,left_insular,visual_cortex,right_thalamus,left_aud_cortex,right_mouth,left_dlpfc,right_dlpfc,left_acc,right_acc,dACC'

argument_counter=0
for this_argument in "$@"; do
	if [[ $argument_counter == 0 ]]; then
		conn_project=$this_argument
	elif [[ $argument_counter == 1 ]]; then
		nodes=$this_argument
	fi
	(( argument_counter++ ))
done


#for SUB in ${subjects[@]}; do
Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data
cd $Study_dir


# for this_functional_run_folder in ${fmri_processed_folder_names[@]}; do # only doing one task folder at a time so this for loop not necessary
	ml fsl
	node_index=0

	outfile=ROI_settings_${conn_project}_GT.txt
	if  [ -e $outfile ]; then
		rm $outfile
	fi

	while IFS=',' read -ra nodes; do
   	    for this_node in "${nodes[@]}"; do
   	    	cd ${Study_dir}/${conn_project}/results/secondlevel/SBC_01/AllSubjects/rest/${this_node}

   	    	this_node_data=$(cat ROI_settings_connNodeID_${this_node}.txt)
			
			cd ${Study_dir}
   	    	outfile_data=$(cat $outfile)

			new_row=$this_node_data
			existing_section=$outfile_data
			
			if [[ node_index == 0 ]]; then
				echo -e "$new_row" >> "$outfile"
			else
				rm $outfile
				echo -e "$existing_section\n$new_row" >> "$outfile"
			fi
			(( node_index++ ))
		done
 	done <<< "$nodes"
# done
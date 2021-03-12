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

argument_counter=0
for this_argument in "$@"
do
	if	[[ $argument_counter == 0 ]]; then
		Matlab_dir=$this_argument
	elif [[ $argument_counter == 1 ]]; then
    	Template_dir=$this_argument
    elif [[ $argument_counter == 2 ]]; then
    	Study_dir=$this_argument
    elif [[ $argument_counter == 3 ]]; then
    	subject=$this_argument
    else
		struct_processing_steps="$this_argument"
	fi
	(( argument_counter++ ))
done
export MATLABPATH=${Matlab_dir}/helper
cd "$Study_dir"
ml matlab/2020a
matlab -nodesktop -nosplash -r "try; cat12StructuralAnalysis('subjects',$subject,'t1_folder','02_T1','t1_filename','T1.nii','steps_to_run_vector',[1 0 1 0 1 1 1 1 1 1],'template_dir','/blue/rachaelseidler/tfettrow/Crunch_Code/MR_Templates'); catch; end; quit"
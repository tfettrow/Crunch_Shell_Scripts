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

ml fsl/6.0.3
Study_dir=/blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data/
cd "${Study_dir}/TBSS_results"

###### Running TBSS preprocessing Steps ###########
tbss_1_preproc *.nii
tbss_2_reg -T
# if you wish to use the FMRIB58_FA mean FA image and its derived skeleton, instead of the mean of your subjects in the study, use the -T option:
tbss_3_postreg -T
tbss_4_prestats 0.2   # do we have to run this here?? or is this a part of "stats"
tbss_non_FA FW
##################################################################

###### Warping MiM MNI ROIs in to Subject Space ###########
cd "${Study_dir}/TBSS_results/FA"
for this_warp in *tensorfit_eddycorrected_driftcorrected_DWI_FA_FA_to_target_warp.nii.gz; do
	echo $this_warp
	this_warp_file_name=$(echo $this_warp | cut -d. -f 1)
	invwarp --ref=target --warp=${this_warp_file_name} --out=${this_warp_file_name}_inv
done

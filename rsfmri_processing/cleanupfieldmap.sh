argument_counter=0
for this_argument in "$@"; do
	if	[[ $argument_counter == 0 ]]; then
		Subject_dir=$this_argument
    fi
done
cd ${Subject_dir}/Processed/MRI_files/03_Fieldmaps
# cd ${Subject_dir}/Processed/MRI_files/04_rsfMRI

# for files in *; do
#     if [[ $files != RestingState* ]]; then
# 	echo "test"
#         rm -rf $files
#     fi
# done

for files in *; do
   if [[ $files != DistMap_* ]]; then
	echo "test"
       rm -f $files
   fi
done

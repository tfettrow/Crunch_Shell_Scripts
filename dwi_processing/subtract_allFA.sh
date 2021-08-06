
cd /blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data/TBSS_results_NoFMcheck/stats

fslroi all_FA.nii.gz 1002_FA.nii.gz 0 1
fslroi all_FA.nii.gz 1002_noFM_FA.nii.gz 1 1
fslroi all_FA.nii.gz 1004_FA.nii.gz 2 1
fslroi all_FA.nii.gz 1004_noFM_FA.nii.gz 3 1
fslroi all_FA.nii.gz 1007_FA.nii.gz 4 1
fslroi all_FA.nii.gz 1007_noFM_FA.nii.gz 5 1
fslroi all_FA.nii.gz 2002_FA.nii.gz 6 1
fslroi all_FA.nii.gz 2002_noFM_FA.nii.gz 7 1
fslroi all_FA.nii.gz 2007_FA.nii.gz 8 1
fslroi all_FA.nii.gz 2007_noFM_FA.nii.gz 9 1
fslroi all_FA.nii.gz 2012_FA.nii.gz 10 1
fslroi all_FA.nii.gz 2012_noFM_FA.nii.gz 11 1
fslroi all_FA.nii.gz 3023_FA.nii.gz 12 1
fslroi all_FA.nii.gz 3023_noFM_FA.nii.gz 13 1
fslroi all_FA.nii.gz 3025_FA.nii.gz 14 1
fslroi all_FA.nii.gz 3025_noFM_FA.nii.gz 15 1
fslroi all_FA.nii.gz 3036_FA.nii.gz 16 1
fslroi all_FA.nii.gz 3036_noFM_FA.nii.gz 17 1

fslmaths 1002_FA.nii.gz -sub 1002_noFM_FA.nii.gz 1002_subtract
fslmaths 1004_FA.nii.gz -sub 1004_noFM_FA.nii.gz 1004subtract
fslmaths 1007_FA.nii.gz -sub 1007_noFM_FA.nii.gz 1007_subtract
fslmaths 2002_FA.nii.gz -sub 2002_noFM_FA.nii.gz 2002_subtract
fslmaths 2007_FA.nii.gz -sub 2007_noFM_FA.nii.gz 2007_subtract
fslmaths 2012_FA.nii.gz -sub 2012_noFM_FA.nii.gz 2012_subtract
fslmaths 3023_FA.nii.gz -sub 3023_noFM_FA.nii.gz 3023_subtract
fslmaths 3025_FA.nii.gz -sub 3025_noFM_FA.nii.gz 3025_subtract
fslmaths 3036_FA.nii.gz -sub 3036_noFM_FA.nii.gz 3036_subtract
gunzip -f *nii.gz



# cd /blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data/TBSS_results_timeCheck/stats

# fslroi all_FA.nii.gz 3023_orig_FA.nii.gz 0 1
# fslroi all_FA.nii.gz 3023_noFM_FA.nii.gz 1 1
# fslroi all_FA.nii.gz 3025_orig_FA.nii.gz 2 1
# fslroi all_FA.nii.gz 3025_noFM_FA.nii.gz 3 1
# fslroi all_FA.nii.gz 3036_orig_FA.nii.gz 4 1
# fslroi all_FA.nii.gz 3036_noFM_FA.nii.gz 5 1


# fslmaths 3023_orig_FA.nii.gz -sub 3023_noFM_FA.nii.gz 3023_subtract
# fslmaths 3025_orig_FA.nii.gz -sub 3025_noFM_FA.nii.gz 3025_subtract
# fslmaths 3036_orig_FA.nii.gz -sub 3036_noFM_FA.nii.gz 3036_subtract
# gunzip -f *nii.gz
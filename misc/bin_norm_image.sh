

minmax=$(fslstats r3023orig_Distmap_AP1.nii -R)
min=`echo "$minmax" | cut -d ' ' -f 1`
max=`echo "$minmax" | cut -d ' ' -f 2`
fslmaths r3023orig_Distmap_AP1.nii -sub $min -div $(echo $max - $min | /usr/bin/bc) r3023orig_Distmap_AP1_BINnormed.nii
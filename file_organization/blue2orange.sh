subject=$1

cd /orange/rachaelseidler/MiM_Backup

if [[ ! -d ${subject} ]]; then
    mkdir ${subject}
fi

mv -t ${subject}/ /blue/rachaelseidler/share/FromExternal/Research_Projects_UF/CRUNCH/MiM_Data/${subject}/Raw/MRI_files/*.zip

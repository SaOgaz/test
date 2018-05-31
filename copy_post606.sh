
dir="/grp/hst/acs/verap/DISTORION_new/F606W/flt/"

image[0]=$dir"jce502hoq_flc.fits"
image[1]=$dir"jbbf01hxq_flc.fits"
image[2]=$dir"jbn503rbq_flc.fits"
image[3]=$dir"jbms03olq_flc.fits"
image[4]=$dir"jc6101hjq_flc.fits"

echo "images to copy: "
echo ${image[@]}

for img in ${image[@]}
do
   echo " Copying... " #$img" to ."
   cp -v $img .
#   cp -v $img notdd/
#   cp -v $img orig/
#   cp -v $img orig_notdd/
#   cp -v $img tdd/
done

echo "copy_pre.sh Finished!"

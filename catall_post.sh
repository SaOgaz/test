prefix=$1
#prefix="022714_post"
#dir="/grp/hst/acs/dborncamp/"
#file="/grp/hst/acs/dborncamp/post_sm04/all/"$prefix"_all_idc.txt"
dir="/Users/slhoffmann/acs/geodist/testing/"
file="/Users/slhoffmann/acs/geodist/testing/post_sm04/all/"$prefix"_all_idc.txt"

FILTER[0]=$dir"post_sm04/f606w/"$prefix"_wfc_idc.txt"
FILTER[1]=$dir"post_sm04/f435w/"$prefix"_wfc_idc.txt"
FILTER[2]=$dir"post_sm04/f814w/"$prefix"_wfc_idc.txt"
FILTER[3]=$dir"post_sm04/f775w/"$prefix"_wfc_idc.txt"
FILTER[4]=$dir"post_sm04/f475w/"$prefix"_wfc_idc.txt"
FILTER[5]=$dir"post_sm04/f625w/"$prefix"_wfc_idc.txt"
FILTER[6]=$dir"post_sm04/f658n/"$prefix"_wfc_idc.txt"
FILTER[7]=$dir"post_sm04/f555w/"$prefix"_wfc_idc.txt"
FILTER[8]=$dir"post_sm04/f502n/"$prefix"_wfc_idc.txt"
FILTER[9]=$dir"post_sm04/f850lp/"$prefix"_wfc_idc.txt"


counter=0
for i in "${FILTER[@]}"
do   
   if [ $counter == 0 ]
   then
      echo "creating file $file"
      echo $i " added to file"
      cat $i > $file
      counter=`expr $counter + 1`
      continue
   fi
   echo $i " added to file"
   cat $i >> $file
   counter=`expr $counter + 1`
done   


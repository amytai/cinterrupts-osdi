#!/bin/bash
# vim: set shiftwidth=4


input="fig6.csv"
output="fig6.txt"
arr_csv=()
declare -A arr
names=('' 'default' 'cint' 'adaptive')
k=16
n="-"

#print header
cat <<EOF > $output
#-------------------------------------------------------------------------------
# Experiment 3 (Fig 6) -- increase coalescing threashold in mixed workload
#
#
# FIELD     WHAT
# -----     --------------------
# k	    requests in-flight (iodepth)
# thr       threshold
# total     sync + async
# tput      throughout [IOPS]
# lat       latency [usec]
# inter     interrupts/second
# idle      idle cpu [%]
#-------------------------------------------------------------------------------
#                      total   sync   sync         idle
#  ischeme   k   thr    tput   tput    lat  inter   cpu
#-------------------------------------------------------------------------------
EOF

tmp=()
# load all csv line into an array
while IFS= read -r line 
do
    [[ $line = \#* ]] && continue
    #arr_csv+=("$line")
    IFS=',' read -a tmp <<< "$line"
    arr["${tmp[0]}"]="${tmp[@]:1}"
done < $input

#---------------------------------------------------------------------------
# csv fields:
# name,thr,aioIops,syncIops,syncLat,cpuIdle,ints,subm,compla
#
# txt fileds:
#-------------------------------------------------------------------------------
#                      total   sync   sync         idle
#  ischeme   k   thr    tput   tput    lat  inter   cpu
#-------------------------------------------------------------------------------

fmt="%-1d %-9s %3d %5d %6d %6d %6.1f %6d %3.0f\n"

echo >> $output
echo "# idx.adaptive" >> $output
entry=()
# thr,aioIops,syncIops,syncLat,cpuIdle,ints,subm,compla
# 0   1       2        3       4       5    6    7  
time=1000000
i=1
for thr in 4 8 16 32 64 128; do
    entry=(${arr["alpha-$time-$thr"]})
    total=$(echo ${entry[1]} + ${entry[2]} | bc)
    printf "$fmt" $i "adaptive" 512 ${entry[0]} $total  \
        ${entry[2]} ${entry[3]} ${entry[5]} ${entry[4]} >> $output

   ((i+=1))
done

echo >> $output
echo >> $output
echo "# idx.cint" >> $output
thr=65535
i=1
entry=(${arr["cint-$time-$thr"]})
total=$(echo ${entry[1]} + ${entry[2]} | bc)
printf "$fmt" $i "cint" 512 ${entry[0]} $total            \
       ${entry[2]} ${entry[3]} ${entry[5]} ${entry[4]} >> $output



echo >> $output
echo >> $output
echo "# idx.cintooo" >> $output
thr=32
i=1
entry=(${arr["cint-ooo-$time-$thr"]})
total=$(echo ${entry[1]} + ${entry[2]} | bc)
printf "$fmt" $i "cint" 512 ${entry[0]} $total            \
       ${entry[2]} ${entry[3]} ${entry[5]} ${entry[4]} >> $output


echo >> $output
echo "# idx.default" >> $output
thr=0
i=1
entry=(${arr["alpha-0-0"]})
total=$(echo ${entry[1]} + ${entry[2]} | bc)
printf "$fmt" $i "baseline" 512 ${entry[0]} $total            \
       ${entry[2]} ${entry[3]} ${entry[5]} ${entry[4]} >> $output

exit 

echo "${arr_csv[@]}"
    #IFS=',' read -a tmp <<< "$line"
    #arr_csv+=("${tmp[@]}")
    #echo "${tmp[@]}"

#for i in $(seq 0 ${#arr_csv[@]}); do
for i in "${arr_csv[@]}"; do
    #${arr_csv[$i]}
    #IFS=',' read -a tmp <<< "${arr_csv[$i]}"
    IFS=',' read -a tmp <<< "$i"
    #echo key: "${tmp[0]}"
    #echo val: "${tmp[@]:1}" 
    arr["${tmp[0]}"]="${tmp[@]:1}"
done


for name in "${!arr[@]}"; do
    echo key: "$name"
    echo vals: "${arr[$name]}"
done



exit




# we want only first line
IFS="," read -a arr <<< ${arr_csv[0]}

j=1
for i in 2 1 3; do
    total=$(echo ${arr[i]} + ${arr[i+3]} | bc)
    sync_iops=${arr[i+3]}
    sync_lat=${arr[i+6]}
    inter=${arr[i+12]}
    idle=${arr[i+9]}
    name=${names[$i]}

    printf "%-1d %-8s %2d %2s %8d %6d %6.2f %6d %6.2f\n"  \
	$j $name $k $n $total $sync_iops $sync_lat $inter $idle >> $output
    (( j += 1 )) 
done





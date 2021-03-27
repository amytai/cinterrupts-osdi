#!/bin/bash

input="fig5.csv"
output="fig5.txt"
arr_csv=()
arr=()
names=('' 'default' 'cint' 'adaptive')
k=16
n="-"

#print header
cat <<EOF > $output
#-------------------------------------------------------------------------------
# Fig 5 -- mix of one sync and one async(k) that sustains k
#   outstaning requests. cint is 'urgent'.
#
# FIELD     WHAT
# -----     --------------------
# tput      throughout [IOPS]
# lat       latency [usec]
# idle      idle cpu [%]
# inter     interrupts/second
#-------------------------------------------------------------------------------
#                  total   sync   sync          idle
#  ischeme  k  n    tput   tput    lat   inter   cpu
#-------------------------------------------------------------------------------

# idx.1
EOF


# load all csv line into an array
while IFS= read -r line 
do
    [[ $line = \#* ]] && continue
    arr_csv+=("$line")
done < $input

#------------------------------------------------------------------------------------------------------------
# baseIopsA,cintIopsA,adaptIopsA,
# baseIopsS,cintIopsS,adaptIopsS,
# baseLat,cintLat,adaptLat,
# baseIdle,cintIdle,adaptIdle,
# baseInts,cintInts,adaptInts,
# baseSubm,cintSubm,adaptSubm,
# baseCompl,cintCompl,adaptComple
#
# Example:
#1 cint     16  -  246086  75040	 12.77	 75043	 0.2
#2 default  16  -  205272  69666  	 13.48  205477   0.0
#3 adaptive 16  -  283840  17636	 56.09	 18416	21.0




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





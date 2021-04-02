#!/bin/bash

input="fig7.csv"
output="fig7.txt"
arr_csv=()
arr=()
names=('' '' '' 'default' 'cint' 'adaptive')
k=16
n="-"

#print header
cat <<EOF > $output
#-------------------------------------------------------------------------------
# Experiment 1 -- file-read-like workload, issuing k requests and then
#     synchronously waiting for them to complete before issuing the 
#     subsequent k requests.
#
# k = number of requests submitted ("the file")
# n = number of such fio processes (each submitting k requests at a time)
#
# FIELD     WHAT
# -----     --------------------
# tput      throughout [IOPS]
# lat       latency [usec]
# idle      idle cpu [%]
# inter     interrupts/second
#-------------------------------------------------------------------------------
#  ischeme  k n   tput    lat  util   inter
#-------------------------------------------------------------------------------
EOF


# load all csv line into an array
while IFS= read -r line 
do
    [[ $line = \#* ]] && continue
    arr_csv+=("$line")
done < $input

#--------------------------------------------------------------------------------------------
# batch,iodepth,threads, 
# baseIops,cintIops,adaptIops,  (IOPS)
# baseLat,cintLat,adaptLat,     (Latency)
# baseIdle,cintIdle,adaptIdle,  (Idle)
# baseInts,cintInts,adaptInts   (Inter)
#--------------------------------------------------------------------------------------------
# example:
# idx.1
# 1 cint      4 1 169968  22.14  52.9   42498
# 2 default   4 1 186701  20.02  69.8  186850
# 3 adaptive  4 1 135225  28.91  42.9   33943


# idx.2
# 1     cint  4 2 280497  27.00   98.3   70151
# 2 default   4 2 239643  31.95   99.6  239805
# 3 adaptive  4 2 197790  39.04  64.1   31211


# idx.3
# 1 cint      4 4 263597  58.76   99.5   66014
# 2 default   4 4 231649  67.24   100.0  231802
# 3 adaptive  4 4 266092  57.95  99.5   65577
#--------------------------------------------------------------------------------------------


for l in 0 1 2; do
    IFS="," read -a arr <<< ${arr_csv[$l]}

    ((idx=l + 1))
    printf "\n\n# idx.$idx\n" $idx >> $output
    
    batch=${arr[0]}
    threads=${arr[2]}
    
    j=1
    for i in 4 3 5; do
       name=${names[$i]}
       iops=${arr[$i]}
       lat=${arr[$i+3]}
       idle=${arr[$i+6]}
       util=$(echo 100 - $idle | bc -l)
       intr=${arr[$i+9]}

       printf "%-1d %-8s %2d %2s %8d %6.2f %6.2f %6d\n"  \
	$j $name $batch $threads $iops $lat $util $intr >> $output
    (( j += 1 )) 
    done 
done





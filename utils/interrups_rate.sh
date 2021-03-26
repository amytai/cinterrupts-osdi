#!/bin/bash


if [ $# -ne 2 ]; then
	
	echo "$0 requires two args: <device_in_proc_interrupts>, <interval>
	output, e.g., $0 nvme0 30"
	exit 1
fi


device=$1
file="/proc/interrupts"


tmp1=$(grep "$device" "$file" | while read line ; 
	do
		cur=$(echo $line | 
			awk 'BEGIN { sum=0} {for (i=2; i<=NF; i++) if ($i ~ /^[0-9]+$/) sum+=$i } END {print sum}')
		echo $cur +
	done)

sleep $2
    
tmp2=$(grep "$device" "$file" | while read line ; 
	do
		cur=$(echo $line | 
			awk 'BEGIN { sum=0} {for (i=2; i<=NF; i++) if ($i ~ /^[0-9]+$/) sum+=$i } END {print sum}')
		echo $cur +
	done)
    
after=$(echo $tmp2 0  | bc)
before=$(echo $tmp1 0  | bc)

diff=$(($after - $before))
rate=$(echo $diff/$2 | bc)
echo $rate


#before=$(calc_int $file_before)
#after=$(calc_int $file_after)
#diff=$(($after - $before))
#rate=$(echo $diff/60 | bc)
#echo $before $after $rate

#!/bin/bash


if [ $# -ne 2 ]; then
	echo "$0 requires two args: device name, or reg. expr for grep, and the file with interrupt
	output, e.g., $0 nvme0  results/interrupts_read_seq_1k_2"
	exit 1
fi


device=$1
file=$2


tmp=$(grep -G "$device" "$file" | while read line ;
	do
		cur=$(echo $line |
			awk 'BEGIN { sum=0} {for (i=2; i<=NF; i++) if ($i ~ /^[0-9]+$/) sum+=$i } END {print sum}')
		echo $cur +
	done)
total=$(echo $tmp 0 | bc)
echo $total


#before=$(calc_int $file_before)
#after=$(calc_int $file_after)
#diff=$(($after - $before))
#rate=$(echo $diff/60 | bc)
#echo $before $after $rate

#!/bin/bash
# vim: set shiftwidth=4


# adaptive (ex alpha) scheme delay
delay=6
# cint delay and thr are set to very max to enable only urgent requests interrupts
cint_delay=1000000
thr=65535
model="p4800"

#dir="../../../data/exp2_mixed_sync_driven/p4800-no-mitigations-delay1M-run4"
dir="results"
bs="4K"
systems="alpha-0-0 cint-$cint_delay-$thr alpha-$delay-32"
load="rand_mix"

# libaio iodepths
#ks="$(seq 0 16) 24 32 48 64"
ks="16"

#output=$model-$cint_delay-$thr.csv
output="fig5.csv"

cat <<EOF > $output
#-------------------------------------------------------------------------------
# base*     measurment done using alpha-0-0 interrupt scheme
# cint*     measurment done using cint-$cint_delay-$thr interrupt scheme
# adapt*    measurment done using alpha-$delay-32 interrupt scheme
#
# FIELD     UNIT
# IopsA     IOPS of libaio
# IopsS     IOPS of sync
# Lat       usec, average latency of sync
# Idle      %, idle cpu time
# Ints      interrupt/s
# Subm      requests/submited syscall, libaio
# Compl     requests/completed syscall, libaio
#
# Fields are:
#------------------------------------------------------------------------------------------------------------
# baseIopsA,cintIopsA,adaptIopsA,baseIopsS,cintIopsS,adaptIopsS,\
baseLat,cintLat,adaptLat,baseIdle,cintIdle,adaptIdle,\
baseInts,cintInts,adaptInts,\
baseSubm,cintSubm,adaptSubm,baseCompl,cintCompl,adaptComple
#-------------------------------------------------------------------------------------------------------------
EOF

for k in $ks; do

    printf "%d" $k | tee -a $output

    sys1="alpha-0-0"
    sys2="cint-$cint_delay-$thr"
    sys3="alpha-$delay-32"
    file1="$dir"/"$sys1"-"$load"-"$bs"-k"$k"
    file2="$dir"/"$sys2"-"$load"-"$bs"-k"$k"
    file3="$dir"/"$sys3"-"$load"-"$bs"-k"$k"
    files="$file1 $file2 $file3"
    schemes=$(seq 1 3)

    # libaio iops
    if [ $k -eq 0 ]; then
	printf ",%d,%d,%d" 0 0 0 | tee -a $output
    else
	for file in $files; do
	    printf ",%d" \
	    $(grep libaio $file-*.out | awk -F";" '{sum+=$8} END {printf "%d", sum/NR}') | \
	    tee -a $output
	done
    fi

    # psync iops
    for file in $files; do
	printf ",%d" \
	$(grep psync $file-*.out | awk -F";" '{sum+=$8} END {printf "%d", sum/NR}') | \
	tee -a $output
    done

    # psync avg latency
    for file in $files; do
	printf ",%.2f" \
	$(grep psync $file-*.out | awk -F";" '{sum+=$40} END {printf "%f", sum/NR}') | \
	tee -a $output
    done

    # idle cpu
    for file in $files; do
	printf ",%.1f" \
	$(grep Average $file-*.mpstat | awk '{sum+=$6+$12} END {printf "%f", sum/NR}') | \
	tee -a $output
    done

    # interrupts
    for file in $files; do
	printf ",%d" \
	$(awk '{sum+=$1} END {printf "%d", sum/NR}' $file-*.ints) | \
	tee -a $output
    done


    if [ $k -eq 0 ]; then
	printf ",%d,%d,%d,%d,%d,%d\n" 0 0 0 0 0 0 | tee -a $output
	continue
    fi

    # total libaio requests
    declare -a total
    for i in $schemes; do
	file="file$i"
	total[$i]=$(grep libaio ${!file}-*.out | awk -F";" '{sum+=$123} END {printf "%d", sum/NR}')
    done

    # requests per submition
    for i in $schemes; do
	file="file$i"
	submit=$(grep libaio ${!file}-*.out | awk -F";" '{sum+=$125} END {printf "%d", sum/NR}')
	printf ",%.2f" $(echo ${total[$i]} / $submit | bc -l) | tee -a $output
    done

    # requests per completion
    for i in $schemes; do
	file="file$i"
	compl=$(grep libaio ${!file}-*.out | awk -F";" '{sum+=$126} END {printf "%d", sum/NR}')
	printf ",%.2f" $(echo ${total[$i]} / $compl| bc -l) | tee -a $output
    done

    printf "\n"	| tee -a $output

done # iodepth


exit 0


# field  8 -- iops
# field 24 -- 50th percentile
# field 28 -- 90th percentile
# field 30 -- 99th percentile
# field 40 -- average
# filed 88 -- cpu_usr
# field 89 -- cpu_sys
#
# in modiefied fio following fields were added:
# field 131  "foo" string
# field 132  total read IOs
# field 133  total write IOs
# field 134  total submition calls (io_submit for libaio)
# field 135  total completion calls (io_getevents for libaio)
# field 136  "boo" string

# if disk bw/t-p stats are disabled in an fio file then
# field are moved down by 9 :
# field 122  "foo" string
# field 123  total read IOs
# field 124  total write IOs
# field 125  total submition calls (io_submit for libaio)
# field 126  total completion calls (io_getevents for libaio)
# field 127  "boo" string
#
#
#
# mpstat fields:
# 08:40:08 AM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
# Average:       1   22.95    0.00   54.69    0.00   22.36    0.00    0.00    0.00    0.00    0.00

# pcm fields for core 1:
# Core1 (Socket 1)
#  #54  #55      #56      #57      #58
# EXEC	IPC	FREQ	AFREQ	L3MISS	L2MISS	L3HIT	L2HIT	L3MPI	L2MPI	L3OCC	LMB	RMB ...


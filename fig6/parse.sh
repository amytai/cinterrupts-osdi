#!/bin/bash
# vim: set shiftwidth=4


delay=1000000
model="p4800"
max_thr=65535

dir="results"
bs="4K"
load="rand_mix"

# baseline thresholds, $max_thr is used for cint scheme
thrs="0 4 8 16 32 64 128 256 $max_thr -1"

output="fig6.csv"

cat <<EOF > $output
#-------------------------------------------------------------------------------
# aio*      measurment for libaio job
# sync*	    measurment for psync job
#
# FIELD     UNIT
# name	    str, name of the interrupt scheme, e.g., cint-1000000-65535
# thr	    requests, interrupt colaescing threshold
# Iops      IOPS
# Lat       usec, average latency
# idle      %, idle cpu time
# ints      interrupt/s
# subm      requests submitted per io_submit() syscall, libaio
# compl     requests completed per io_getevents() syscall, libaio
#------------------------------------------------------------------------------------------------------------
# name,thr,aioIops,syncIops,syncLat,cpuIdle,ints,subm,compl
#-------------------------------------------------------------------------------------------------------------
EOF

for thr in $thrs; do

    if [ $thr -eq $max_thr ]; then
	sys="cint-$delay-$thr"
    elif [ $thr -eq 0 ]; then
	sys="alpha-0-0"
    elif [ $thr -lt 0 ]; then
	sys="cint-ooo-$delay-32"
	thr=32
    else
	sys="alpha-$delay-$thr"
    fi

    # name
    printf "%s" $sys | tee -a $output

    #thr
    printf ",%d" $thr | tee -a $output

    file="$dir"/"$sys"-"$load"-"$bs"

    # libaio iops
    printf ",%d" \
	$(grep libaio $file-*.out | awk -F";" '{sum+=$8} END {printf "%d", sum/NR}') | \
	tee -a $output

    # psync iops
    printf ",%d" \
	$(grep psync $file-*.out | awk -F";" '{sum+=$8} END {printf "%d", sum/NR}') | \
	tee -a $output

    # psync avg latency
    printf ",%.1f" \
	$(grep psync $file-*.out | awk -F";" '{sum+=$40} END {print sum/NR}') | \
	tee -a $output

    # idle cpu
    printf ",%.1f" \
	$(grep Average $file-*.mpstat | awk '{sum+=$6+$12} END {print sum/NR}' ) | \
	tee -a $output

    # interrupts
    printf ",%d" \
	$(awk '{sum+=$1} END {printf "%d", sum/NR}' $file-*.ints) | \
	tee -a $output

    # total libaio requests
    total=$(grep libaio $file-*.out | awk -F";" '{sum+=$123} END {printf "%d", sum/NR}')

    # requests per submition
    submit=$(grep libaio $file-*.out | awk -F";" '{sum+=$125} END {printf "%d", sum/NR}')
    printf ",%.2f" $(echo $total / $submit | bc -l) | tee -a $output

    # requests per completion
    compl=$(grep libaio $file-*.out | awk -F";" '{sum+=$126} END {printf "%d", sum/NR}')
    printf ",%.2f" $(echo $total / $compl | bc -l) | tee -a $output

    printf "\n"	| tee -a $output

done


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


#!/bin/bash
# vim: set shiftwidth=4


model="p4800"
delay=6
cint_delay=$delay
cint_thr=65535

#dir="../../../data/exp1_libaio_barrier/p4800-no-mitigations-delay6-run2"
dir="results"
bs="4K"
systems="alpha-0-0 cint-$cint_delay-$cint_thr alpha-$delay-32"
load="rand_read_libaio"

threads="1 2 4"
batch_szs="4"
declare -A iodepths=(
    [1]="1 2"
    [2]="2 4"
    #[4]="4 8"
    [4]="4"
    [8]="8 16"
   [16]="16 32"
   [32]="32 64"
   [64]="64 128"
  [128]="128 256"
)

# testing
#dir="results-test"
#threads="1"
#batch_szs="8"

#output=$model-$cint_delay-$cint_thr.csv
output="fig7.csv"

cat <<EOF > $output
#-------------------------------------------------------------------------------
# base*     measurment done using alpha-0-0 interrupt scheme
# cint*     measurment done using cint-$cint_delay-$cint_thr interrupt scheme
# adapt*    measurment done using alpha-$delay-32 interrupt scheme
#
# FIELD     UNIT
# batch	    requests, libaio iodepth_submit/complete
# iodepth   requests, libaio iodepth
# Iops      IOPS
# Lat       usec, average latency
# Idle      %, idle cpu time
# Ints      interrupt/s
#--------------------------------------------------------------------------------------------
# batch,iodepth,threads,\
baseIops,cintIops,adaptIops,\
baseLat,cintLat,adaptLat,\
baseIdle,cintIdle,adaptIdle,\
baseInts,cintInts,adaptInts
#--------------------------------------------------------------------------------------------
EOF

for bsz in $batch_szs; do

    for iod in ${iodepths[$bsz]}; do

	for t in $threads; do

	    printf "%d,%d,%d" $bsz $iod $t | tee -a $output

	    sys1="alpha-0-0"
	    sys2="cint-$cint_delay-$cint_thr"
	    sys3="alpha-$delay-32"
	    file1="$dir"/"$sys1"-"$load"-"$bs"-j"$t"-btsz"$bsz"-iod"$iod"
	    file2="$dir"/"$sys2"-"$load"-"$bs"-j"$t"-btsz"$bsz"-iod"$iod"
	    file3="$dir"/"$sys3"-"$load"-"$bs"-j"$t"-btsz"$bsz"-iod"$iod"
	    files="$file1 $file2 $file3"

	    # iops
	    for file in $files; do
		printf ",%d" $(awk -F";" '{sum+=$8} END {printf "%d", sum/NR}' $file-*.out) | tee -a $output
	    done

	    # lat
	    for file in $files; do
		printf ",%.2f" $(awk -F";" '{sum+=$40} END {printf "%f", sum/NR}' $file-*.out) | tee -a $output
	    done

	    # idle cpu
	    for file in $files; do
		printf ",%.1f" $(grep Average $file-*.mpstat | awk '{sum+=$6+$12} END {printf "%f", sum/NR}' ) | tee -a $output
	    done

	    # interrupts
	    for file in $files; do
		printf ",%d" $(awk '{sum+=$1} END {printf "%d", sum/NR}' $file-*.ints) | tee -a $output
	    done

	    printf "\n"	| tee -a $output

	done # threads

    done # iodepth

done # batch size


exit 0


# field  8 -- iops
# field 24 -- 50th percentile
# field 28 -- 90th percentile
# field 30 -- 99th percentile
# field 40 -- average
# filed 88 -- cpu_usr
# field 89 -- cpu_sys
#
# mpstat fields:
# 08:40:08 AM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
# Average:       1   22.95    0.00   54.69    0.00   22.36    0.00    0.00    0.00    0.00    0.00

# pcm fields for core 1:
# Core1 (Socket 1)
#  #54  #55      #56      #57      #58
# EXEC	IPC	FREQ	AFREQ	L3MISS	L2MISS	L3HIT	L2HIT	L3MPI	L2MPI	L3OCC	LMB	RMB ...


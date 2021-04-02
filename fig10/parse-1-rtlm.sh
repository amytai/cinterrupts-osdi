#!/bin/bash

delay=6
model="p4800"

#dir="../../../../data/mixed_workload/p4800-no-mitigations-psync-512-async-throttled-max-irq-acct"
#sizes="512 4K 16K 64K 1M"
dir="results_raw_rtlm"
sizes="4K"
systems="baseline-0-0 baseline-100-32 alpha-0-0 alpha-$delay-32 cint-$delay-32 cint-$delay-32-ooo"
load="rand_mix_batched"

fmt="%-4s %11s %11s %11s %11s %11s %11s\n"
head=$(printf "$fmt" "#msg" "b-0-0" "b-100-32" "alpha-0-0" "alpha-$delay-32" "cint-$delay-32" "cint-$delay-32-ooo")


function print_field() {
    field="$1"
    out="$2"
    job="$3"
    echo "$head" > "$out"
    for size in $sizes; do
	    printf "%-4s" $size >> $out
	    for sys in $systems; do
	       file="$dir"/"$sys"-"$load"-"$size"-*.out
	       data=$(grep "$job" $file | awk -v var="$field" -F";" \
		       '{sum += $(var)} END {print sum/NR}')
	       printf " %11.1f" $data >> $out
           done
           printf "\n" >> $out
    done
}


function print_lat_p() {
    field="$1"
    out="$2"
    echo "$head" > "$out"
    for size in $sizes; do
	    printf "%-4s" $size >> $out
	    for sys in $systems; do
	       file="$dir"/"$sys"-"$load"-"$size"-*.out
	       lat=$(grep psync $file | awk -v var="$field" -F";" \
		       '{ split($(var), str, "="); sum += str[2]} END {print sum/NR}')
	       printf " %11.1f" $lat >> $out
           done
           printf "\n" >> $out
    done
}

function print_file() {
    out="$1"
    ext="$2"
    echo "$head" > "$out"
    for size in $sizes; do
	    printf "%-4s" $size >> $out
	    for sys in $systems; do
	       file="$dir"/"$sys"-"$load"-"$size"-*."$ext"
	       data=$(awk '{sum += $1} END {print sum/NR}' $file)
	       printf " %11.1f" $data >> $out
           done
           printf "\n" >> $out
    done
}

function print_cpu() {
    out="$1"
    job="$2"
    echo "$head" > "$out"
    for size in $sizes; do
	    printf "%-4s" $size >> $out
	    for sys in $systems; do
	       file="$dir"/"$sys"-"$load"-"$size"-*.out
	       data=$(grep "$job" $file | awk -F";" \
		       '{sum += $88 + $89} END {print sum/NR}')
	       printf " %11.1f" $data >> $out
           done
           printf "\n" >> $out
    done
}

function print_mpstat() {
    field="$1"
    out="$2"
    echo "$head" > "$out"
    for size in $sizes; do
	    printf "%-4s" $size >> $out
	    for sys in $systems; do
	       file="$dir"/"$sys"-"$load"-"$size"-*.mpstat
	       data=$(grep Average $file | awk  \
		       '{sum += '"$field"'} END {print sum/NR}')
	       printf " %11.1f" $data >> $out
           done
           printf "\n" >> $out
    done
}

function print_pcm() {
    field="$1"
    out="$2"
    echo "$head" > "$out"
    for size in $sizes; do
	    printf "%-4s" $size >> $out
	    for sys in $systems; do
	       file="$dir"/"$sys"-"$load"-"$size"-*.pcm
	       # skip first two lines with headers
	       data=$(tail -q -n+3 $file | awk  -F";" \
		       '{sum += '"$field"'} END {print sum/NR}')
	       printf " %11.2f" $data >> $out
           done
           printf "\n" >> $out
    done
}

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

outdir="results_rtlm"
mkdir -p "$outdir"

print_field  8 "$outdir/$model-async-iops.data" libaio
print_field  8 "$outdir/$model-psync-iops.data" psync
print_field 40 "$outdir/$model-psync-lat-avg.data" psync

print_lat_p 24 "$outdir/$model-psync-lat-p50.data"
print_lat_p 28 "$outdir/$model-psync-lat-p90.data"
print_lat_p 30 "$outdir/$model-psync-lat-p99.data"

print_file "$outdir/$model-total-ints.data" "ints"

print_cpu  "$outdir/$model-async-cpu.data" libaio
print_cpu  "$outdir/$model-psync-cpu.data" psync

print_mpstat  '$7' "$outdir/$model-cpu-irq.data"
print_mpstat  '$6 + $12' "$outdir/$model-cpu-idle.data"

#print_pcm  '$55' "$model-cpu-ipc.data"

exit 0





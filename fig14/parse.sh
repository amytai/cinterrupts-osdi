#!/bin/bash

delay=6
model="p4800"

#dir="../../../../data/pure_workload_p4800/p4800-no-mitigations-alpha0"
dir="results"
#sizes="512 4K 16K 64K 1M"
sizes="4K"
systems="baseline-0-0 baseline-100-32 alpha-0-0 alpha-$delay-32 cint-$delay-32 cint-$delay-32-ooo"
load="rand_read"

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
	       file="$dir"/"$sys"-"$load"_"$job"-"$size"-*.out
	       data=$(awk -v var="$field" -F";" \
		       '{sum += $(var)} END {print sum/NR}' $file)
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
	       file="$dir"/"$sys"-"$load"_psync-"$size"-*.out
	       lat=$(awk -v var="$field" -F";" \
		       '{ split($(var), str, "="); sum += str[2]} END {print sum/NR}' $file)
	       printf " %11.1f" $lat >> $out
           done
           printf "\n" >> $out
    done
}

function print_file() {
    out="$1"
    ext="$2"
    job="$3"
    echo "$head" > "$out"
    for size in $sizes; do
	    printf "%-4s" $size >> $out
	    for sys in $systems; do
	       file="$dir"/"$sys"-"$load"_"$job"-"$size"-*."$ext"
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
	       file="$dir"/"$sys"-"$load"_"$job"-"$size"-*.out
	       data=$(awk -F";" '{sum += $88 + $89} END {print sum/NR}' $file)
	       printf " %11.1f" $data >> $out
           done
           printf "\n" >> $out
    done
}

function print_mpstat() {
    field="$1"
    out="$2"
    job="$3"
    echo "$head" > "$out"
    for size in $sizes; do
            printf "%-4s" $size >> $out
            for sys in $systems; do
               file="$dir"/"$sys"-"$load"_"$job"-"$size"-*.mpstat
               data=$(grep Average $file | awk  \
                       '{sum += '"$field"'} END {print sum/NR}')
               printf " %11.1f" $data >> $out
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

# mpstat fields:
# 08:40:08 AM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
# Average:       1   22.95    0.00   54.69    0.00   22.36    0.00    0.00    0.00    0.00    0.00



print_field  8 "$model-async-iops.data" libaio
print_field  8 "$model-psync-iops.data" psync
print_field 40 "$model-psync-lat-avg.data" psync
print_field 40 "$model-async-lat-avg.data" libaio

print_lat_p 24 "$model-psync-lat-p50.data"
print_lat_p 28 "$model-psync-lat-p90.data"
print_lat_p 30 "$model-psync-lat-p99.data"

print_file "$model-async-total-ints.data" "ints" libaio
print_file "$model-psync-total-ints.data" "ints" psync

print_cpu  "$model-async-cpu.data" libaio
print_cpu  "$model-psync-cpu.data" psync

print_mpstat  '$7' "$model-async-cpu-irq.data" libaio
print_mpstat  '$7' "$model-psync-cpu-irq.data" psync
print_mpstat  '$6 + $12' "$model-async-cpu-idle.data" libaio
print_mpstat  '$6 + $12' "$model-psync-cpu-idle.data" psync






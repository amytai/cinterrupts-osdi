#!/bin/bash
env_file="env-$(hostname)"

[ -f "$env_file" ] || { echo "missing $env_file"; exit 1; }

source "$env_file"
source common.sh

echo "Reading test environemnt from $env_file"
echo "Scripts dir: $ipts_dir"
echo "Driver dir: $drv_dir"
#echo "Delay: $delay"

logdir="results"
logdir_bkup="results-$release-$(date +%d_%m_%Y-%H:%M)"

dev_str="CAL"
count_script="$scripts_dir/utils/interrups_count.sh"
int_file="/proc/interrupts"
fio="$fio_dir"/fio
mpstat="/usr/bin/mpstat"

if [ -d $logdir ] ; then
	mv $logdir $logdir_bkup
fi

mkdir $logdir


runtime=60
runs=$(seq 1 10)
sizes="4K"

threads="1 2 4"
#batch_szs="1 2 4 8 16 32 64 128"
batch_szs="4"
# for each batch size test different iodepths
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

# for testing
#runtime=10
#runs="1"
#sizes="4K"
#threads=1
#batch_szs="1 2"


load="rand_read_libaio"
core=1

function run_load {

    local name="$1"
    local driver="$2"
    local params="$3"

    for bs in $sizes; do
	for batch_sz in $batch_szs; do
	    for iodepth in ${iodepths[$batch_sz]}; do
		for thr in $threads; do
		    echo
		    echo "Running $load, bs=$bs, name=$name, jobs=$thr, " \
		          "batch_sz=$batch_sz, iodepth=$iodepth"

		    for run in $runs; do
	    		unload_driver
	    		check_and_tryagain
	    		load_driver "$driver" "$params"

			    # output file format:
			    # $name-$load-bs-jobs-batch-iodepth-run
			    log="$logdir"/"$name"-"$load"-"$bs"-j"$thr"-btsz"$batch_sz"-iod"$iodepth"-"$run"
			    before=$($count_script $dev_str $int_file)

			    sudo $fio --blocksize=$bs --runtime=$runtime \
				    --numjobs=$thr --iodepth=$iodepth	 \
			    	    --iodepth_batch_submit=$batch_sz	 \
			 	    --iodepth_batch_complete=$batch_sz   \
				    --output-format=terse  --output="$log".out \
				    "$load".fio >/dev/null &

			    sleep 2
			    $mpstat -P $core $(expr $runtime - 5) 1 > "$log".mpstat  2>&1 &

			    wait

			   after=$($count_script $dev_str $int_file)
			   diff=$(($after - $before))
			   rate=$(echo $diff/$runtime | bc)
			   echo $rate > "$log".ints

		    done # done $runs
		done # done $threads
	    done # done $iodepth
	done # done batch_szs
    done # done $sizes
   echo "Done"
}

# alpha0 baseline
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=0 irq_poller_delay=0 \
	urgent_ooo=0"
run_load "alpha-0-0" "$driver" "$params"

# adaptive (alpha-$delay-32)
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=32 irq_poller_delay=$delay \
	urgent_ooo=0"
run_load "alpha-"$delay"-32" "$driver" "$params"


# In this test, in cint mode, only barrier fires interrupt:
# delay 6 usec, thr 64K
# Recall, we set a delay of 6 (or 15) in cint because occasionally we have
# an out of order completion (request with the BARRIER flag is not the
# last requests in the completion batch) and requests are stuck in the
#  CQ. So we use a delay to "clean up" stacked requests.
cint_delay=$delay
cint_thr=65535
# cint-$cint_delay-$cint_thr
driver="nvme.ko"
params="empathetic=1 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=$cint_thr irq_poller_delay=$cint_delay \
	urgent_ooo=0"
run_load "cint-$cint_delay-$cint_thr" "$driver" "$params"

exit 0


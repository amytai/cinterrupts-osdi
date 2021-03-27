#!/bin/bash

env_file="env-$(hostname)"

[ -f "$env_file" ] || { echo "missing $env_file"; exit 1; }

source "$env_file"
source common.sh

thr=65535
cint_delay=1000000
delay=6

echo "Reading test environemnt from $env_file"
echo "Scripts dir: $scripts_dir"
echo "Driver dir: $drv_dir"
echo "Delay: $delay"
echo "Threshold: $thr"
echo "Block device: $bdev"


dev_str="CAL"
count_script="$scripts_dir/utils/interrups_count.sh"
int_file="/proc/interrupts"
mpstat="/usr/bin/mpstat"
pcm="$pcm_dir/pcm.x"
enable_pcm=0

logdir="results"
logdir_bkup="results-$release-$(date +%d_%m_%Y-%H:%M)"

if [ -d $logdir ] ; then
	mv $logdir $logdir_bkup
fi

mkdir $logdir

load="rand_mix"
runtime=60
runs=$(seq 1 10)
#ks="$(seq 0 16) 24 32 48 64"
ks="16"
sizes="4K"

# testing test.sh
#runtime=15
#runs="1 2 3"
#sizes="4K"
#ks="16"

core=1
other_core=7

fio="rand_mix.fio"

function run_load {

    local name="$1"
    local driver="$2"
    local params="$3"

    for bs in $sizes; do

	for k in $ks; do
	    echo
	    echo "Running $load, bs=$bs, k=$k name $name"

	    for run in $runs; do

		unload_driver
		check_and_tryagain
		load_driver "$driver" "$params"

		log="$logdir"/"$name"-"$load"-"$bs"-k"$k"-"$run"
		before=$($count_script $dev_str $int_file)

		if [ $k -eq 0 ]; then # run only pure sync
		    sudo $fio_dir/fio --section=psync --blocksize=$bs 		\
		       	--runtime=$runtime --output-format=terse 	\
		 	--output="$log".out "$fio" >/dev/null &
		else
		    sudo $fio_dir/fio --blocksize=$bs --runtime=$runtime 	\
			--iodepth=$k --iodepth_batch_submit=1		\
			--iodepth_batch_complete_min=1			\
			--iodepth_batch_complete_max=$k			\
			--output-format=terse --output="$log".out 	\
			"$fio" >/dev/null &
		fi

		sleep 2
		$mpstat -P $core $(expr $runtime - 5) 1 > "$log".mpstat  2>&1 &

		if [ "$enable_pcm" -eq 1 ]; then
		    sudo numactl -C $other_core \
			$pcm 1 -i=15 -yc $core -nsys -ns -csv="$log".pcm   2>/dev/null &
		fi

		wait

		after=$($count_script $dev_str $int_file)
		diff=$(($after - $before))
		rate=$(echo $diff/$runtime | bc)
		echo $rate > "$log".ints

		#cat "$log".tmp_job1 "$log".tmp_job2 > "$log".out
		#rm -f "$log".tmp_job2 "$log".tmp_job1

	    done #runs
	done # ks
    done # bs

    echo "Done"
    echo
}

#load msr module for pcm
sudo /sbin/modprobe msr 2>/dev/null

# alpha0 (baseline)
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1	\
	irq_poller_target_queue_id=15 irq_poller_max_thr=0	\
	irq_poller_delay=0"
run_load "alpha-0-0" "$driver" "$params"

# alpha-6-32 (adaptive)
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1	\
	irq_poller_target_queue_id=15 irq_poller_max_thr=32	\
	irq_poller_delay=$delay"
run_load "alpha-$delay-32" "$driver" "$params"

# cint-$cint_delay-$thr
driver="nvme.ko"
params="empathetic=1 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=$thr \
	irq_poller_delay=$cint_delay urgent_ooo=0"
run_load "cint-$cint_delay-$thr" "$driver" "$params"

exit 0


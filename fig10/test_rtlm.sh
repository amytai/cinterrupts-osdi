#!/bin/bash

env_file="env-$(hostname)"

[ -f "$env_file" ] || { echo "missing $env_file"; exit 1; }

source "$env_file"
source common.sh

echo "Reading test environemnt from $env_file"
echo "Scripts dir: $scripts_dir"
echo "Driver dir: $drv_dir"
echo "Delay: $delay"
echo "Block device: $bdev"


dev_str="CAL"
count_script="$scripts_dir/utils/interrups_count.sh"
int_file="/proc/interrupts"
mpstat="/usr/bin/mpstat"
pcm="$pcm_dir/pcm.x"
enable_pcm=0

logdir="results_raw_rtlm"
logdir_bkup="$logdir-$release-$(date +%d_%m_%Y-%H:%M)"

if [ -d $logdir ] ; then
	mv $logdir $logdir_bkup
fi

mkdir $logdir

async=async
psync=psync

sudo cgdelete  -g cpu:$psync 2>/dev/null
sudo cgdelete  -g cpu:$async 2>/dev/null
sudo cgdelete  -g blkio:$async 2>/dev/null

sudo cgcreate -g blkio:$async

very_high_iops=10000000

function set_cgroup_blk() {
	local max_iops="$1"
	local blkio=(blkio.throttle.read_iops_device=\"$bdev $max_iops\" $async)
	echo "cgset blkio params: "${blkio[@]}" "

	#eval sudo cgset -r blkio.throttle.read_iops_device=\"$bdev $max_iops\" $async
	eval sudo cgset -r "${blkio[@]}"

	echo -n "Cgroup blkio controller read_iops: "
	sudo cgget -g blkio:$async | grep blkio.throttle.read_iops_device
	echo
}

load="rand_mix_batched"
runtime=60
runs=$(seq 1 10)
sizes="4K"

#testing
#runtime=15
#runs="1 2 3"
#sizes="4K"

core=1
other_core=7

#fio="rand_mix_batched_sync_fixed_sz.fio"
fio="rand_mix_batched.fio"

function run_load {

	local name="$1"
    	local driver="$2"
    	local params="$3"

	for bs in $sizes; do
	   echo
	   echo "Running $load, bs=$bs, name $1"
	   for run in $runs; do

	       unload_driver
	       check_and_tryagain
	       load_driver "$driver" "$params"

	       if [ "$name" = "baseline-0-0" ] || [ "$name" = "alpha-0-0" ]; then
		   # cgoups has its cpu overhead, so configure very high rate
		   # not to throttle baseline0 and alpha0 loads but
		   # make a fair comparison with throttled loads.
                   iops=$very_high_iops
		   set_cgroup_blk $iops
	       else
		   # alpha0 is true baseline
	           iops=$(grep libaio "$logdir"/alpha-0-0-"$load"-"$bs"-*.out | \
			       awk -F";" '{ sum += $8 } END {print sum/NR}')
		   set_cgroup_blk $iops
	       fi

	       cg_str="cgexec -g blkio:$async"
	       echo "load: $name, cg prefix: \"$cg_str\""

	       log="$logdir"/"$name"-"$load"-"$bs"-"$run"
               before=$($count_script $dev_str $int_file)

	       sudo $cg_str "$fio_dir"/fio --section=job1 --blocksize=$bs 		\
		       	--runtime=$runtime --output-format=terse 	\
		 	--output="$log".tmp_job1 "$fio" >/dev/null &

	       sudo "$fio_dir"/fio --section=job2 --blocksize=$bs 			\
		       	--runtime=$runtime --output-format=terse 	\
		 	--output="$log".tmp_job2 "$fio" >/dev/null &

	       $mpstat -P $core $runtime 1 > "$log".mpstat  2>&1 &

	       if [ "$enable_pcm" -eq 1 ]; then
	           sudo numactl -C $other_core \
			$pcm 1 -i=15 -yc $core -nsys -ns -csv="$log".pcm   2>/dev/null &
	       fi

	       wait

               after=$($count_script $dev_str $int_file)
               diff=$(($after - $before))
	       rate=$(echo $diff/$runtime | bc)
	       echo $rate > "$log".ints

	       cat "$log".tmp_job1 "$log".tmp_job2 > "$log".out
	       rm -f "$log".tmp_job2 "$log".tmp_job1

	    done
	done
   echo "Done"
   echo
}

#load msr module for pcm
sudo /sbin/modprobe msr 2>/dev/null

# baseline0 and alpha0 have to run first, we throttle other based on
# their libaio results (currently based on alpha0)

# baseline0
driver="nvme-emul.ko"
params="irq_poller_cpu=3 irq_poller_target_cpu=1 irq_poller_target_queue_id=15 \
	irq_poller_thr=0 irq_poller_time=0"
run_load "baseline-0-0" "$driver" "$params"

# alpha0 (baseline)
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1	\
	irq_poller_target_queue_id=15 irq_poller_max_thr=0	\
	irq_poller_delay=0"
run_load "alpha-0-0" "$driver" "$params"

# cint-$delay-32-ooo (cint-ooo)
driver="nvme.ko"
params="empathetic=1 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=32 irq_poller_delay=$delay \
	urgent_ooo=1"
run_load "cint-"$delay"-32-ooo" "$driver" "$params"

## baseline-100-32
driver="nvme-emul.ko"
params="irq_poller_cpu=3 irq_poller_target_cpu=1 irq_poller_target_queue_id=15 \
	irq_poller_thr=32 irq_poller_time=1"
run_load "baseline-100-32" "$driver" "$params"

# alpha-$delay-32 (adaptive)
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=32 irq_poller_delay=$delay \
	urgent_ooo=0"
run_load "alpha-"$delay"-32" "$driver" "$params"

# cint-$delay-32 (cint)
driver="nvme.ko"
params="empathetic=1 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=32 irq_poller_delay=$delay \
	urgent_ooo=0"
run_load "cint-"$delay"-32" "$driver" "$params"


sudo cgdelete  -g cpu:$psync 2>/dev/null
sudo cgdelete  -g cpu:$async 2>/dev/null
sudo cgdelete  -g blkio:$async 2>/dev/null

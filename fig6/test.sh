#!/bin/bash

env_file="env-$(hostname)"

[ -f "$env_file" ] || { echo "missing $env_file"; exit 1; }

source "$env_file"
source common.sh

delay=1000000
cint_thr=65535

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
sizes="4K"
thrs="4 8 16 32 64 128 256"

#runtime=15
#runs="1 2 3"
#sizes="4K"
#ks="12 13 14 15 16"

core=1
other_core=7
#iodepth=512

fio="rand_mix.fio"

function run_load {

    local name=$(printf "$1" "$4")
    local driver="$2"
    local params=$(printf "$3" "$4")
    local thr="$4"

    if [ $thr -eq 256 ]; then
	iodepth=1024
    else
	iodepth=512
    fi

    for bs in $sizes; do

	echo
	echo "Running $load, bs=$bs, thr=$thr, name $name"

	for run in $runs; do

	    unload_driver
	    check_and_tryagain
	    load_driver "$driver" "$params"

	    log="$logdir"/"$name"-"$load"-"$bs"-"$run"
	    before=$($count_script $dev_str $int_file)

	    sudo $fio_dir/fio --blocksize=$bs --runtime=$runtime 	\
		--iodepth=$iodepth --iodepth_batch_submit=$iodepth \
		--iodepth_batch_complete_min=1 			\
		--iodepth_batch_complete_max=$iodepth		\
		--output-format=terse --output="$log".out 	\
		"$fio" >/dev/null &

	    # start sampling after the test begins
	    sleep 2
	    # and stop sampling just before the test finishes
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

	done #runs
    done # bs

    echo "Done"
    echo
}

#load msr module for pcm
sudo /sbin/modprobe msr 2>/dev/null


# cint-ooo-$delay-32
driver="nvme.ko"
params="empathetic=1 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=%d   \
	irq_poller_delay=$delay urgent_ooo=1"
run_load "cint-ooo-$delay-%d" "$driver" "$params" 32

# alpha-0-0 (baseline)
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1 \
    irq_poller_target_queue_id=15 irq_poller_max_thr=0	  \
    irq_poller_delay=0"
run_load "alpha-0-0" "$driver" "$params" 0

# now run alpha with different thr
# delay is huge, no interrupts on delay expiration
for thr in $thrs; do

    # alpha-$delay-$thr (baseline)
    driver="nvme.ko"
    params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	    irq_poller_target_queue_id=15 irq_poller_max_thr=%d	  \
	    irq_poller_delay=$delay"
    run_load "alpha-$delay-%d" "$driver" "$params" $thr

done

# cint-$delay-$cint_thr
driver="nvme.ko"
params="empathetic=1 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=%d   \
	irq_poller_delay=$delay urgent_ooo=0"
run_load "cint-$delay-%d" "$driver" "$params" $cint_thr

exit 0


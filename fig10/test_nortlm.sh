#!/bin/bash

env_file="env-$(hostname)"

[ -f "$env_file" ] || { echo "missing $env_file"; exit 1; }

source "$env_file"

echo "Reading test environemnt from $env_file"
echo "Scripts dir: $scripts_dir"
echo "Driver dir: $drv_dir"
echo "Delay: $delay"

logdir="results_raw_nortlm"
logdir_bkup="$logdir"-"$release-$(date +%d_%m_%Y-%H:%M)"
#drv_dir="/homes/xrevolver/src/kernel/nvme-kernel/drivers/nvme/host"

dev_str="CAL"
count_script="$scripts_dir/utils/interrups_count.sh"
int_file="/proc/interrupts"
mpstat="/usr/bin/mpstat"

# for Optane delay is 6, for P3700 delay is 15
#delay=6
#delay=15

if [ -d $logdir ] ; then
	mv $logdir $logdir_bkup
fi

mkdir $logdir


function unload_driver {
    echo
    echo "Unloading nvme driver"
    sudo umount /dev/nvme0n1p1
    sudo rmmod nvme
    sudo rmmod nvme-emul
    sudo rmmod nvme-clean
    sudo rm /dev/nvme* 2>/dev/null
    sleep 5
    lsmod | grep nvme
    echo "Unloaded"
}

function load_driver {
    driver="$drv_dir"/"$1"
    params="$2"
    echo "Loading nvme driver $driver"
    echo "Params: $params"
    sudo insmod $driver $params || lsmod | grep nvme
    sleep 3
    echo "Loaded"
}

core=1
loads="rand_mix_batched"
runtime=60
runs=$(seq 1 10)
sizes="4K"

# testing
#runtime=20
#runs="1 2 3"

function run_load {
    for load in $loads; do
        for bs in $sizes; do
	   echo "Running $load, bs=$bs, name $1"
	   for run in $runs; do

	       log="$logdir"/"$1"-"$load"-"$bs"-"$run"
               before=$($count_script $dev_str $int_file)

	       sudo "$fio_dir"/fio --blocksize=$bs --runtime=$runtime --output-format=terse \
		 --output="$log".out "$load".fio >/dev/null
	       
	       $mpstat -P $core $runtime 1 > "$log".mpstat  2>&1 &
               after=$($count_script $dev_str $int_file)
               diff=$(($after - $before))
	       rate=$(echo $diff/$runtime | bc)
	       echo $rate > "$log".ints

	    done
	done
   done
   echo "Done"
   echo
}


# baseline-0-0
driver="nvme-emul.ko"
params="irq_poller_cpu=3 irq_poller_target_cpu=1 irq_poller_target_queue_id=15 \
	irq_poller_thr=0 irq_poller_time=0"
unload_driver
load_driver "$driver" "$params"
run_load "baseline-0-0"


# baseline-100-32
driver="nvme-emul.ko"
params="irq_poller_cpu=3 irq_poller_target_cpu=1 irq_poller_target_queue_id=15 \
	irq_poller_thr=32 irq_poller_time=1"
unload_driver
load_driver "$driver" "$params"
run_load "baseline-100-32"


# alpha0 (baseline)
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1	\
	irq_poller_target_queue_id=15 irq_poller_max_thr=0	\
	irq_poller_delay=0"
unload_driver
load_driver "$driver" "$params"
run_load "alpha-0-0"


# adaptive
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=32 irq_poller_delay=$delay \
	urgent_ooo=0"
unload_driver
load_driver "$driver" "$params"
run_load "alpha-"$delay"-32"


# cint
driver="nvme.ko"
params="empathetic=1 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=32 irq_poller_delay=$delay \
	urgent_ooo=0"
unload_driver
load_driver "$driver" "$params"
run_load "cint-"$delay"-32"


# cint-ooo
driver="nvme.ko"
params="empathetic=1 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=32 irq_poller_delay=$delay \
	urgent_ooo=1"
unload_driver
load_driver "$driver" "$params"
run_load "cint-"$delay"-32-ooo"



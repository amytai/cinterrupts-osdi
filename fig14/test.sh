#!/bin/bash

env_file="env-$(hostname)"

[ -f "$env_file" ] || { echo "missing $env_file"; exit 1; }

source "$env_file"

echo "Reading test environment from $env_file"
echo "Scripts dir: $scripts_dir"
echo "Driver dir: $drv_dir"
echo "Delay: $delay"

logdir="results"
logdir_bkup="results-$release-$(date +%d_%m_%Y-%H:%M)"
#drv_dir="/homes/xrevolver/src/kernel/nvme-kernel/drivers/nvme/host"

dev_str="CAL"
count_script="$scripts_dir/utils/interrups_count.sh"
int_file="/proc/interrupts"
mpstat="/usr/bin/mpstat"
insmod="/sbin/insmod"
rmmod="/sbin/rmmod"

if [ -d $logdir ] ; then
	mv $logdir $logdir_bkup
fi

mkdir $logdir


function unload_driver {
    echo
    echo "Unloading nvme driver"
    sudo pkill fio
    sleep 3
    sudo umount /dev/nvme0n1p1
    sudo $rmmod nvme
    sudo $rmmod nvme-emul
    sudo $rmmod nvme-clean
    sudo rm -f /dev/nvme*
}

function check_and_tryagain {
    lsmod | grep nvme | grep -q -v core && {
        # It is possible for a request to arrive after the poller was shutdown.
	# In this case request will be completed by the timer after 30 seconds.
        echo "Can't unload driver, wait and try again"
    	sleep 35
	unload_driver
	lsmod | grep nvme | grep -q -v core && { echo "Can't unload driver"; exit 1; }
    }
    echo "Unloaded"
}

function load_driver {
    local driver="$drv_dir"/"$1"
    local params="$2"
    echo "Loading nvme driver $driver"
    echo "Params: $params"
    sudo $insmod $driver $params || { echo "Can't load driver"; lsmod | grep nvme; exit 1; }
    sleep 5
    echo "Loaded"
}

runs=$(seq 1 10)

runtime=60
#sizes="512 4K 16K 64K 1M"
sizes="4K"
loads="rand_read_libaio rand_read_psync"

# for testing
#runs="1 2 3"
#runtime=30
#sizes="4K"
#loads="rand_read_libaio"

core=1

function run_load {
    local name="$1"
    local driver="$2"
    local params="$3"

    for load in $loads; do
        for bs in $sizes; do
	   echo "Running $load, bs=$bs, name $name"
	   for run in $runs; do

	       unload_driver
	       check_and_tryagain
	       load_driver "$driver" "$params"

	       log="$logdir"/"$name"-"$load"-"$bs"-"$run"
               before=$($count_script $dev_str $int_file)


	       sudo "$fio_dir"/fio --blocksize=$bs --runtime=$runtime --output-format=terse \
		 --output="$log".out "$load".fio >/dev/null &

	       sleep 2
	       $mpstat -P $core $(expr $runtime - 5) 1 > "$log".mpstat  2>&1 &

	       wait

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
run_load "baseline-0-0" "$driver" "$params"

# baseline-100-32
driver="nvme-emul.ko"
params="irq_poller_cpu=3 irq_poller_target_cpu=1 irq_poller_target_queue_id=15 \
	irq_poller_thr=32 irq_poller_time=1"
run_load "baseline-100-32"  "$driver" "$params"

# alpha-0-0 (new baseline)
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1	\
	irq_poller_target_queue_id=15 irq_poller_max_thr=0	\
	irq_poller_delay=0"
run_load "alpha-0-0" "$driver" "$params"

# alpha-$delay-32 (adaptive)
driver="nvme.ko"
params="empathetic=0 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=32 irq_poller_delay=$delay \
	urgent_ooo=0"
run_load "alpha-"$delay"-32" "$driver" "$params"

# cint-$delay-32
driver="nvme.ko"
params="empathetic=1 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=32 irq_poller_delay=$delay \
	urgent_ooo=0"
run_load "cint-"$delay"-32" "$driver" "$params"

# cint-$delay-32-ooo
driver="nvme.ko"
params="empathetic=1 irq_poller_cpu=3 irq_poller_target_cpu=1 \
	irq_poller_target_queue_id=15 irq_poller_max_thr=32 irq_poller_delay=$delay \
	urgent_ooo=1"
run_load "cint-"$delay"-32-ooo" "$driver" "$params"



#!/bin/bash
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu9/cpufreq/scaling_min_freq"
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu5/cpufreq/scaling_min_freq"
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq"
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq"

dir=results$1

rm -rf results$1/
mkdir results$1/

sudo umount /dev/nvme0n1p3
sudo modprobe -r nvme nvme_emul nvme_core
sleep 3
ls -al /dev/nvme*

# Now load the correct NVMe configuration
sudo modprobe nvme irq_poller_cpu=9,11,13,15 irq_poller_target_cpu=1,3,5,19 irq_poller_target_queue_id=15,16,17,24 irq_poller_delay=0 irq_poller_max_thr=0 empathetic=N
sleep 2

sudo mount /dev/nvme0n1p3 /scratch0

for run in 0 1 2 3 4
do
	filename=results$1/scan_raw_N_0_0_${run}.out
	sudo ../kvell/main 0 2 4 s $1 > ${filename} 2>&1
done

sudo umount /dev/nvme0n1p3
sudo modprobe -r nvme nvme_emul nvme_core
sleep 3
ls -al /dev/nvme*

sudo modprobe nvme irq_poller_cpu=9,11,13,15 irq_poller_target_cpu=1,3,5,19 irq_poller_target_queue_id=15,16,17,24 irq_poller_delay=15 irq_poller_max_thr=32 empathetic=Y
sleep 2
sudo mount /dev/nvme0n1p3 /scratch0

for run in 0 1 2 3 4
do
	filename=results$1/scan_raw_Y_32_15_${run}.out
	sudo ../kvell/main 0 2 4 s $1 > ${filename} 2>&1
done

sudo umount /dev/nvme0n1p3
sudo modprobe -r nvme nvme_emul nvme_core
sleep 3
ls -al /dev/nvme*

sudo modprobe nvme irq_poller_cpu=9,11,13,15 irq_poller_target_cpu=1,3,5,19 irq_poller_target_queue_id=15,16,17,24 irq_poller_delay=15 irq_poller_max_thr=32 empathetic=N
sleep 2
sudo mount /dev/nvme0n1p3 /scratch0

for run in 0 1 2 3 4
do
	filename=results$1/scan_raw_N_32_15_${run}.out
	sudo ../kvell/main 0 2 4 s $1 > ${filename} 2>&1
done

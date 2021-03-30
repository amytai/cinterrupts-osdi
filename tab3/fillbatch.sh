#!/bin/bash

rocksdbdir=rocksdb-6.4.6

rm -rf results
mkdir results/

sudo umount /dev/nvme0n1p1
sudo umount /dev/nvme0n1p2
sudo umount /dev/nvme0n1p3
sudo modprobe -r nvme

sleep 5

# Now run default
sudo modprobe nvme irq_poller_cpu=9,11,13,15 irq_poller_target_cpu=1,3,5,19 irq_poller_target_queue_id=15,16,17,24 irq_poller_delay=0
sleep 20
sudo mount /dev/nvme0n1p1 /scratch2

for i in {1..5}
do
sudo rm -rf /scratch2/*; sync; sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"; sudo numactl -C 1 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=fillbatch --threads=1  --key_size=16 --value_size=1024 --num=10000000  --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -batch_size=4000 -compression_type=none -statistics > results/fillbatch_default_${i}

sleep 10
done

# Now run unmodified app, IRQ for every request
sudo umount /scratch2
sudo umount /rocks-scratch
sudo modprobe -r nvme

sleep 5

sudo modprobe nvme irq_poller_cpu=9,11,13,15 irq_poller_target_cpu=1,3,5,19 irq_poller_target_queue_id=15,16,17,24 irq_poller_delay=0 empathetic=Y irq_poller_max_thr=0
sleep 20
sudo mount /dev/nvme0n1p1 /scratch2

for i in {1..5}
do
sudo rm -rf /scratch2/*; sync; sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"; sudo numactl -C 1 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=fillbatch --threads=1  --key_size=16 --value_size=1024 --num=10000000  --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -batch_size=4000 -compression_type=none -statistics > results/fillbatch_unmodified_app_cint_${i}

sleep 10
done

#Now run adaptive
sudo umount /scratch2
sudo umount /rocks-scratch
sudo modprobe -r nvme

sleep 5

sudo modprobe nvme irq_poller_cpu=9,11,13,15 irq_poller_target_cpu=1,3,5,19 irq_poller_target_queue_id=15,16,17,24 irq_poller_delay=6 empathetic=N irq_poller_max_thr=32
sleep 20
sudo mount /dev/nvme0n1p1 /scratch2

for i in {1..5}
do
sudo rm -rf /scratch2/*; sync; sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"; sudo numactl -C 1 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=fillbatch --threads=1  --key_size=16 --value_size=1024 --num=10000000  --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -batch_size=4000 -compression_type=none -statistics > results/fillbatch_adaptive_${i}

sleep 10
done

# Now run cint
sudo umount /scratch2
sudo umount /rocks-scratch
sudo modprobe -r nvme

sleep 5

sudo modprobe nvme irq_poller_cpu=9,11,13,15 irq_poller_target_cpu=1,3,5,19 irq_poller_target_queue_id=15,16,17,24 irq_poller_delay=15 empathetic=Y irq_poller_max_thr=32
sleep 20
sudo mount /dev/nvme0n1p1 /scratch2

for i in {1..5}
do
sudo rm -rf /scratch2/*; sync; sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"; sudo numactl -C 1 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=fillbatch --threads=1  --key_size=16 --value_size=1024 --num=10000000  --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -batch_size=4000 -compression_type=none -statistics > results/fillbatch_cint_${i}

sleep 10
done

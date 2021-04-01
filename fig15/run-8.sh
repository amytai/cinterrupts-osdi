#!/bin/bash
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu9/cpufreq/scaling_min_freq"
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu5/cpufreq/scaling_min_freq"
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq"
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq"

rocksdbdir=../rocksdb/rocksdb-6.4.6

rm -rf results8
mkdir results8/

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
#first fill
sudo rm -rf /scratch2/*; sync; sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"; sudo numactl -C 1 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=fillbatch --threads=1  --key_size=16 --value_size=1024 --num=20000000  --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -batch_size=4000 -compression_type=none

echo ""
echo "Done with fill, starting readwhilewriting"
echo ""

sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
sleep 3
sudo numactl -C 1,5 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=readwhilewriting --threads=7 -duration=30  --key_size=16 --value_size=1024 -use_existing_db=true --disable_auto_compactions=true --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -compression_type=none -statistics > results8/readwhilewriting_default_${i}

df -h
sleep 10
done

echo ""
echo "Done will readwhilewriting, starting readrandom"
echo ""

sudo rm -rf /scratch2/*; sync; sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"; sudo numactl -C 1 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=fillbatch --threads=1  --key_size=16 --value_size=1024 --num=20000000  --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -batch_size=4000 -compression_type=none

for i in {1..5}
do

sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
sudo numactl -C 1,5 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=readrandom --threads=8  --key_size=16 --value_size=1024  --reads=100000 -use_existing_db=true --disable_auto_compactions=true --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -compression_type=none -statistics > results8/readrandom_default_${i}

df -h
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
sudo rm -rf /scratch2/*; sync; sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"; sudo numactl -C 1 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=fillbatch --threads=1  --key_size=16 --value_size=1024 --num=20000000  --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -batch_size=4000 -compression_type=none

sudo numactl -C 1,5 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=readwhilewriting --threads=7 -duration=30  --key_size=16 --value_size=1024 -use_existing_db=true --disable_auto_compactions=true --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -compression_type=none -statistics > results8/readwhilewriting_adaptive_${i}

sleep 10
done

echo ""
echo "Done will readwhilewriting, starting readrandom"
echo ""

sudo rm -rf /scratch2/*; sync; sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"; sudo numactl -C 1 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=fillbatch --threads=1  --key_size=16 --value_size=1024 --num=20000000  --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -batch_size=4000 -compression_type=none

for i in {1..5}
do

sudo numactl -C 1,5 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=readrandom --threads=8  --key_size=16 --value_size=1024 --num=20000000 --reads=100000 -use_existing_db=true --disable_auto_compactions=true --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -compression_type=none -statistics > results8/readrandom_adaptive_${i}

df -h
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
sudo rm -rf /scratch2/*; sync; sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"; sudo numactl -C 1 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=fillbatch --threads=1  --key_size=16 --value_size=1024 --num=20000000  --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -batch_size=4000 -compression_type=none

sudo numactl -C 1,5 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=readwhilewriting --threads=7 -duration=30  --key_size=16 --value_size=1024 -use_existing_db=true --disable_auto_compactions=true --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -compression_type=none -statistics > results8/readwhilewriting_cint_${i}

df -h
sleep 10
done

echo ""
echo "Done will readwhilewriting, starting readrandom"
echo ""

sudo rm -rf /scratch2/*; sync; sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"; sudo numactl -C 1 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=fillbatch --threads=1  --key_size=16 --value_size=1024 --num=20000000  --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -batch_size=4000 -compression_type=none

for i in {1..5}
do

sudo numactl -C 1,5 ./${rocksdbdir}/db_bench --db=/scratch2/ --benchmarks=readrandom --threads=8  --key_size=16 --value_size=1024 --num=20000000 --reads=100000 -use_existing_db=true --disable_auto_compactions=true --use_direct_io_for_flush_and_compaction=true --use_direct_reads=true -compression_type=none -statistics > results8/readrandom_cint_${i}

df -h
sleep 10
done

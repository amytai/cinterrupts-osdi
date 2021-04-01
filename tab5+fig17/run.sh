#!/bin/bash
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu9/cpufreq/scaling_min_freq"
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu5/cpufreq/scaling_min_freq"
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq"
sudo sh -c "echo 2000000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq"
./load.sh 2 4
./scan.sh 16

sleep 10

./scan.sh 256

echo "Done with scan benchmark, both length=16 and length=256. Now run ./cdf.sh and ./throughput.sh to get results"

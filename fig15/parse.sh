#!/bin/bash

./parse_readwhilewriting.sh 4
./parse_readrandom.sh 4

./parse_readwhilewriting.sh 8
./parse_readrandom.sh 8

echo "1.25 cint" > labels.dat
echo "2.5 default0" >> labels.dat
echo "3.75 default32" >> labels.dat

paste labels.dat readrandom.out.latency readrandom8.out.latency readwhilewriting.out.latency readwhilewriting8.out.latency | column -s $'\t' -t > latency.dat

paste labels.dat readrandom.out.thru readrandom8.out.thru readwhilewriting.out.thru readwhilewriting8.out.thru | column -s $'\t' -t > iops.dat

gnuplot iops.gp
gnuplot latency.gp

epstopdf fig15-iops.eps
epstopdf fig15-latency.eps

#!/bin/bash
./throughput.sh 16
./throughput.sh 256

./cdf.sh 16
./cdf.sh 256

gnuplot fig17.gp

epstopdf fig17.eps

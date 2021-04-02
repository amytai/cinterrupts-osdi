#!/bin/bash
echo "n wl cint default adaptive" > gp.dat
echo "" >> gp.dat
echo "#idx.avg" >> gp.dat
./parse_latency.sh
echo "" >> gp.dat
echo "" >> gp.dat

echo "# idx.p99" >> gp.dat
./parse_99.sh
echo "" >> gp.dat
echo "" >> gp.dat

echo "# idx.iops" >> gp.dat
./parse_throughput.sh

gnuplot fig16.gp
ps2pdf fig16.eps

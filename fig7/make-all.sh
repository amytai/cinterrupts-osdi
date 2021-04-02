#!/bin/bash

fig="fig7"

./test.sh
./parse.sh
./parse-csv.sh
gnuplot ./$fig.gp
ps2pdf $fig.eps

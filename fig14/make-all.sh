#!/bin/bash

fig="fig14"

./test.sh
./parse.sh
./parse-mix.sh
gnuplot $fig.gp
ps2pdf $fig.eps

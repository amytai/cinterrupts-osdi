#!/bin/bash

fig="fig10"

./test_nortlm.sh
./test_rtlm.sh
./parse-1-nortlm.sh
./parse-1-rtlm.sh
./parse-2.sh

gnuplot "$fig".gp
ps2pdf "$fig".eps


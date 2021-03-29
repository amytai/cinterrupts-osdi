#!/bin/bash

fig="fig6"

./test.sh
./parse.sh
./parse-csv.sh
./$fig.gp
ps2pdf $fig.eps

#!/bin/bash

./test.sh
./parse.sh
./parse-csv.sh
./fig5.gp
ps2pdf fig5.eps

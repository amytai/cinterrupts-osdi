#!/bin/bash
dir=results$1

javac Cdf.java
rm *.tmp

grep "id:" ${dir}/scan_raw_N_0_0_4.out | awk '{print int($4/1000)}' | awk -F',' '{print $1}' | tail -n 3000 | head -n 1000 > default.in.tmp

grep "id:" ${dir}/scan_raw_Y_32_15_4.out | awk '{print int($4/1000)}' | awk -F',' '{print $1}' | tail -n 3000 | head -n 1000 > cint.in.tmp

grep "id:" ${dir}/scan_raw_N_32_15_4.out | awk '{print int($4/1000)}' | awk -F',' '{print $1}' | tail -n 3000 | head -n 1000 > adaptive.in.tmp

# Now get the minimum
cat default.in.tmp >> min.tmp
cat cint.in.tmp >> min.tmp
cat adaptive.in.tmp >> min.tmp

min=`cat min.tmp | awk 'BEGIN {min=10000000} {if ($1 < min) min=$1} END {print min}'`
min=$(($min/100))
min=$(($min*100))

#Manually change the following line if the buckets don't look right
if [ $1 -eq 16 ] 
then
	bucket=15
else
	bucket=200
fi

java Cdf default.in.tmp ${min} ${bucket} > default_cdf_$1.dat
java Cdf cint.in.tmp ${min} ${bucket} > cint_cdf_$1.dat
java Cdf adaptive.in.tmp ${min} ${bucket} > adaptive_cdf_$1.dat

rm *.tmp

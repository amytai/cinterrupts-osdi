#!/bin/bash
dir=results$1

javac Cdf.java
rm *.tmp

echo "Scan Latency Histograms:"
echo "-------------------" >> default.cdf.out.tmp
echo "default            " >> default.cdf.out.tmp
echo "-------------------" >> default.cdf.out.tmp
grep "id:" ${dir}/scan_raw_N_0_0_4.out | awk '{print int($4/1000)}' | awk -F',' '{print $1}' | tail -n 3000 | head -n 1000 > default.in.tmp

echo "-------------------" >> cint.cdf.out.tmp
echo "cint" >> cint.cdf.out.tmp
echo "-------------------" >> cint.cdf.out.tmp
grep "id:" ${dir}/scan_raw_Y_32_15_4.out | awk '{print int($4/1000)}' | awk -F',' '{print $1}' | tail -n 3000 | head -n 1000 > cint.in.tmp


echo "-------------------" >> adaptive.cdf.out.tmp
echo "adaptive" >> adaptive.cdf.out.tmp
echo "-------------------" >> adaptive.cdf.out.tmp
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

java Cdf default.in.tmp ${min} ${bucket} >> default.cdf.out.tmp
java Cdf cint.in.tmp ${min} ${bucket} >> cint.cdf.out.tmp
java Cdf adaptive.in.tmp ${min} ${bucket} >> adaptive.cdf.out.tmp

paste default.cdf.out.tmp cint.cdf.out.tmp adaptive.cdf.out.tmp | column -s $'\t' -t > cdf$1.out
cat cdf.out
echo "Output also written to cdf$1.out"
rm *.tmp

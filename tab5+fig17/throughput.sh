#!/bin/bash
rm *.tmp

dir=results$1

echo "Scan Throughput:"
echo "-------------------" >> default.thru.out.tmp
echo "default:" >> default.thru.out.tmp
echo "-------------------" >> default.thru.out.tmp
mean=`grep "req/s" ${dir}/*_raw_N_0_0_*.out | awk -F'requests' '{print $2}' | awk -F'(' '{print $2}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "req/s" ${dir}/*_raw_N_0_0_*.out | awk -F'requests' '{print $2}' | awk -F'(' '{print $2}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`

echo $mean "+/-" $stdev >> default.thru.out.tmp

echo "-------------------" >> cint.thru.out.tmp
echo "cint:" >> cint.thru.out.tmp
echo "-------------------" >> cint.thru.out.tmp
mean=`grep "req/s" ${dir}/*_raw_Y*.out | awk -F'requests' '{print $2}' | awk -F'(' '{print $2}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "req/s" ${dir}/*_raw_Y*.out | awk -F'requests' '{print $2}' | awk -F'(' '{print $2}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`

echo $mean "+/-" $stdev >> cint.thru.out.tmp

echo "-------------------" >> adaptive.thru.out.tmp
echo "adaptive:" >> adaptive.thru.out.tmp
echo "-------------------" >> adaptive.thru.out.tmp
mean=`grep "req/s" ${dir}/*_raw_N_32_15*.out | awk -F'requests' '{print $2}' | awk -F'(' '{print $2}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "req/s" ${dir}/*_raw_N_32_15*.out | awk -F'requests' '{print $2}' | awk -F'(' '{print $2}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`

echo $mean "+/-" $stdev >> adaptive.thru.out.tmp

paste default.thru.out.tmp cint.thru.out.tmp adaptive.thru.out.tmp | column -s $'\t' -t > thru$1.out
cat thru$1.out
echo "Output also written to thru$1.out"
rm *.tmp

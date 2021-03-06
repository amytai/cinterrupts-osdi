#!/bin/bash

rm *.tmp

echo " " >> labels.tmp
echo " " >> labels.tmp
echo " " >> labels.tmp
echo "cint" >> labels.tmp
echo "default" >> labels.tmp
echo "adaptive" >> labels.tmp
echo "app-cint" >> labels.tmp

echo "------------" >> 99.out.tmp
echo "99% latency" >> 99.out.tmp
echo "------------" >> 99.out.tmp
for name in unmodified_app_cint default adaptive cint
do
mean=`grep "rocksdb.db.write.micros" results/fillbatch_${name}_* | awk '{print $10}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "rocksdb.db.write.micros" results/fillbatch_${name}_* | awk '{print $10}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`
echo $mean "+/-" $stdev >> 99.out.tmp
done

echo "------------" >> avg.out.tmp
echo "avg latency" >> avg.out.tmp
echo "------------" >> avg.out.tmp
for name in unmodified_app_cint default adaptive cint
do
mean=`grep "rocksdb.db.write.micros" results/fillbatch_${name}_* | awk '{print $4}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "rocksdb.db.write.micros" results/fillbatch_${name}_* | awk '{print $4}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`
echo $mean "+/-" $stdev >> avg.out.tmp
done


echo "------------" >> thru.out.tmp
echo "throughput" >> thru.out.tmp
echo "------------" >> thru.out.tmp
for name in unmodified_app_cint default adaptive cint
do
mean=`grep "ops/sec;" results/fillbatch_${name}_* | awk '{print $5}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "ops/sec;" results/fillbatch_${name}_* | awk '{print $5}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`
echo $mean "+/-" $stdev >> thru.out.tmp
done

paste labels.tmp thru.out.tmp avg.out.tmp 99.out.tmp  | column -s $'\t' -t > all.out
cat all.out
echo ""
echo "Results also written to all.out"
rm *.tmp

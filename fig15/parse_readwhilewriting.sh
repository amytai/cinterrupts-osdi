#!/bin/bash

rm *.tmp

echo " " >> labels.tmp
echo " " >> labels.tmp
echo " " >> labels.tmp
echo "cint" >> labels.tmp
echo "default" >> labels.tmp
echo "adaptive" >> labels.tmp

echo "------------" >> 99.out.tmp
echo "99% latency" >> 99.out.tmp
echo "------------" >> 99.out.tmp
for name in cint default adaptive
do
mean=`grep "rocksdb.db.get.micros" results/readwhilewriting_${name}_* | awk '{print $10}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "rocksdb.db.get.micros" results/readwhilewriting_${name}_* | awk '{print $10}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`
echo $mean "+/-" $stdev >> 99.out.tmp
done

echo "------------" >> avg.out.tmp
echo "avg latency" >> avg.out.tmp
echo "------------" >> avg.out.tmp
for name in cint default adaptive
do
mean=`grep "rocksdb.db.get.micros" results/readwhilewriting_${name}_* | awk '{print $4}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "rocksdb.db.get.micros" results/readwhilewriting_${name}_* | awk '{print $4}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`
echo $mean "+/-" $stdev >> avg.out.tmp
done


echo "------------" >> thru.out.tmp
echo "throughput" >> thru.out.tmp
echo "------------" >> thru.out.tmp
for name in cint default adaptive
do
mean=`grep "ops/sec;" results/readwhilewriting_${name}_* | awk '{print $5}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "ops/sec;" results/readwhilewriting_${name}_* | awk '{print $5}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`
echo $mean "+/-" $stdev >> thru.out.tmp
done

#cint=`tail -n 3 thru.out.tmp | head -n 1`

#echo "------------" >> thru.deg.out.tmp
#echo "throughput degradation" >> thru.deg.out.tmp
#echo "------------" >> thru.deg.out.tmp
#for name in cint default adaptive
#do
#grep "ops/sec;" results/readwhilewriting_${name}_* | awk '{print $5}' | awk '{sum += $1} END {print sum/5}' | awk -v norm=$cint '{print $1/norm}' >> thru.deg.out.tmp
#done

paste labels.tmp thru.out.tmp avg.out.tmp 99.out.tmp  | column -s $'\t' -t > readwhilewriting.out
echo "readwhilewriting results:"
cat readwhilewriting.out
echo ""
echo "Results also written to readwhilewriting.out"
rm *.tmp

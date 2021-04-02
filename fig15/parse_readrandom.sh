#!/bin/bash

dir=results
output=readrandom.out

if [ $1 -eq 8 ]
then
	dir=results8
	output=readrandom8.out
fi

rm ${output}*
rm *.tmp

cintnorm=0
for name in cint default adaptive
do
mean=`grep "rocksdb.db.get.micros" ${dir}/readrandom_${name}_* | awk '{print $4}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "rocksdb.db.get.micros" ${dir}/readrandom_${name}_* | awk '{print $4}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`

stdev=`echo $stdev $mean | awk '{printf "%0.2f", $1/$2}'`
mean=`echo $mean | awk '{printf "%d", $1}'`

if [[ $name == "cint" ]]
then
	cintnorm=$mean
fi
norm=`echo $mean $cintnorm | awk '{printf "%0.2f", $1/$2}'`
echo $norm $stdev $mean >> ${output}.latency
done

for name in cint default adaptive
do
mean=`grep "ops/sec;" ${dir}/readrandom_${name}_* | awk '{print $5}' | awk '{sum += $1} END {print sum/5}'`
stdev=`grep "ops/sec;" ${dir}/readrandom_${name}_* | awk '{print $5}' | awk -v mean=$mean '{sum += ($1-mean)*($1-mean)} END {print sqrt(sum/5)}'`

stdev=`echo $stdev $mean | awk '{printf "%0.2f", $1/$2}'`
mean=`echo $mean | awk '{printf "%d", $1}'`

if [[ $name == "cint" ]]
then
	cintnorm=$mean
fi
norm=`echo $mean $cintnorm | awk '{printf "%0.2f", $1/$2}'`
echo $norm $stdev $mean >> ${output}.thru
done

rm *.tmp

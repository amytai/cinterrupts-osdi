#!/bin/bash
rm *.tmp

echo " " >> labels.tmp
echo " " >> labels.tmp
echo " " >> labels.tmp
echo "A" >> labels.tmp
echo "B" >> labels.tmp
echo "C" >> labels.tmp
echo "F" >> labels.tmp
echo "D" >> labels.tmp

echo "-------------------" >> default.out.tmp
echo "default:" >> default.out.tmp
echo "-------------------" >> default.out.tmp

for run in 0 1 2 3 4
do
	grep "AVG" results/*_raw_N_0_0_${run}.out | awk '{print $4}' >> default.out.${run}.tmp
done

paste default.out.0.tmp default.out.1.tmp default.out.2.tmp default.out.3.tmp default.out.4.tmp | awk '{print ($1+$2+$4+$4+$5)/5}' >> default.out.tmp

echo "-------------------" >> cint.out.tmp
echo "cint:" >> cint.out.tmp
echo "-------------------" >> cint.out.tmp
for run in 0 1 2 3 4
do
	grep "AVG" results/*_raw_Y_32_15_${run}.out | awk '{print $4}' >> cint.out.${run}.tmp
done

paste cint.out.0.tmp cint.out.1.tmp cint.out.2.tmp cint.out.3.tmp cint.out.4.tmp | awk '{print ($1+$2+$4+$4+$5)/5}' >> cint.out.tmp

echo "-------------------" >> adaptive.out.tmp
echo "adaptive:" >> adaptive.out.tmp
echo "-------------------" >> adaptive.out.tmp
for run in 0 1 2 3 4
do
	grep "AVG" results/*_raw_N_32_15_${run}.out | awk '{print $4}' >> adaptive.out.${run}.tmp
done

paste adaptive.out.0.tmp adaptive.out.1.tmp adaptive.out.2.tmp adaptive.out.3.tmp adaptive.out.4.tmp | awk '{print ($1+$2+$4+$4+$5)/5}' >> adaptive.out.tmp

paste labels.tmp default.out.tmp cint.out.tmp adaptive.out.tmp | column -s $'\t' -t > avglat.out
echo "Average latency:"
cat avglat.out
echo "Output also written to avglat.out"
rm *.tmp

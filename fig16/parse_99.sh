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
	grep "99p" results/*_raw_N_0_0_${run}.out | awk '{print $4}' >> default.out.${run}.tmp
done

paste default.out.0.tmp default.out.1.tmp default.out.2.tmp default.out.3.tmp default.out.4.tmp | awk '{print ($1+$2+$4+$4+$5)/5}' >> default.out.tmp

echo "-------------------" >> cint.out.tmp
echo "cint:" >> cint.out.tmp
echo "-------------------" >> cint.out.tmp
for run in 0 1 2 3 4
do
	grep "99p" results/*_raw_Y_32_15_${run}.out | awk '{print $4}' >> cint.out.${run}.tmp
done

paste cint.out.0.tmp cint.out.1.tmp cint.out.2.tmp cint.out.3.tmp cint.out.4.tmp | awk '{print ($1+$2+$4+$4+$5)/5}' >> cint.out.tmp

echo "-------------------" >> adaptive.out.tmp
echo "adaptive:" >> adaptive.out.tmp
echo "-------------------" >> adaptive.out.tmp
for run in 0 1 2 3 4
do
	grep "99p" results/*_raw_N_32_15_${run}.out | awk '{print $4}' >> adaptive.out.${run}.tmp
done

paste adaptive.out.0.tmp adaptive.out.1.tmp adaptive.out.2.tmp adaptive.out.3.tmp adaptive.out.4.tmp | awk '{print ($1+$2+$4+$4+$5)/5}' >> adaptive.out.tmp

paste labels.tmp default.out.tmp cint.out.tmp adaptive.out.tmp | column -s $'\t' -t > 99lat.out
echo "99p latency:"
cat 99lat.out
echo "Output also written to 99lat.out"
rm *.tmp

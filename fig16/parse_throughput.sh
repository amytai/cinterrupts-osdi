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

echo "-------------------" >> default.thru.out.tmp
echo "default:" >> default.thru.out.tmp
echo "-------------------" >> default.thru.out.tmp

for run in 0 1 2 3 4
do
	grep "req/s" results/*_raw_N_0_0_${run}.out | awk '{print $10}' | awk -F'(' '{print $2}' >> default.thru.out.${run}.tmp
done

paste default.thru.out.0.tmp default.thru.out.1.tmp default.thru.out.2.tmp default.thru.out.3.tmp default.thru.out.4.tmp | awk '{print ($1+$2+$3+$4+$5)/5}' > mean.tmp
paste default.thru.out.0.tmp default.thru.out.1.tmp default.thru.out.2.tmp default.thru.out.3.tmp default.thru.out.4.tmp mean.tmp | awk '{print "+/-",  sqrt((($1-$6)*($1-$6)+($2-$6)*($2-$6)+($3-$6)*($3-$6)+($4-$6)*($4-$6)+($5-$6)*($5-$6))/5)}' > stdev.tmp

paste -d ' ' mean.tmp stdev.tmp >> default.thru.out.tmp

#cint file
echo "-------------------" >> cint.thru.out.tmp
echo "cint:" >> cint.thru.out.tmp
echo "-------------------" >> cint.thru.out.tmp
for run in 0 1 2 3 4
do
	grep "req/s" results/*_raw_Y_32_15_${run}.out | awk '{print $10}' | awk -F'(' '{print $2}' >> cint.thru.out.${run}.tmp
done

paste cint.thru.out.0.tmp cint.thru.out.1.tmp cint.thru.out.2.tmp cint.thru.out.3.tmp cint.thru.out.4.tmp | awk '{print ($1+$2+$3+$4+$5)/5}' > mean.tmp
paste cint.thru.out.0.tmp cint.thru.out.1.tmp cint.thru.out.2.tmp cint.thru.out.3.tmp cint.thru.out.4.tmp mean.tmp | awk '{print "+/-",  sqrt((($1-$6)*($1-$6)+($2-$6)*($2-$6)+($3-$6)*($3-$6)+($4-$6)*($4-$6)+($5-$6)*($5-$6))/5)}' > stdev.tmp

paste -d ' ' mean.tmp stdev.tmp >> cint.thru.out.tmp

echo "-------------------" >> adaptive.thru.out.tmp
echo "adaptive:" >> adaptive.thru.out.tmp
echo "-------------------" >> adaptive.thru.out.tmp
for run in 0 1 2 3 4
do
	grep "req/s" results/*_raw_N_32_15_${run}.out | awk '{print $10}' | awk -F'(' '{print $2}' >> adaptive.thru.out.${run}.tmp
done

paste adaptive.thru.out.0.tmp adaptive.thru.out.1.tmp adaptive.thru.out.2.tmp adaptive.thru.out.3.tmp adaptive.thru.out.4.tmp | awk '{print ($1+$2+$3+$4+$5)/5}' > mean.tmp
paste adaptive.thru.out.0.tmp adaptive.thru.out.1.tmp adaptive.thru.out.2.tmp adaptive.thru.out.3.tmp adaptive.thru.out.4.tmp mean.tmp | awk '{print "+/-",  sqrt((($1-$6)*($1-$6)+($2-$6)*($2-$6)+($3-$6)*($3-$6)+($4-$6)*($4-$6)+($5-$6)*($5-$6))/5)}' > stdev.tmp

paste -d ' ' mean.tmp stdev.tmp >> adaptive.thru.out.tmp

paste labels.tmp default.thru.out.tmp cint.thru.out.tmp adaptive.thru.out.tmp | column -s $'\t' -t > thru.out
echo "Throughput:"
cat thru.out
echo "Output also written to thru.out"
rm *.tmp

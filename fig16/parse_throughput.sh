#!/bin/bash
rm *.tmp

echo "1 A" >> labels.tmp
echo "2 B" >> labels.tmp
echo "3 C" >> labels.tmp
echo "4 F" >> labels.tmp
echo "5 D" >> labels.tmp

for run in 0 1 2 3 4
do
	grep "req/s" results/*_raw_N_0_0_${run}.out | awk -F'requests' '{print $2}' | awk -F'(' '{print $2}' | awk '{print $1}' >> default.thru.out.${run}.tmp
done

paste default.thru.out.0.tmp default.thru.out.1.tmp default.thru.out.2.tmp default.thru.out.3.tmp default.thru.out.4.tmp | awk '{print ($1+$2+$3+$4+$5)/5}' > default.thru.mean.out.tmp
paste default.thru.out.0.tmp default.thru.out.1.tmp default.thru.out.2.tmp default.thru.out.3.tmp default.thru.out.4.tmp default.thru.mean.out.tmp | awk '{print sqrt((($1-$6)*($1-$6)+($2-$6)*($2-$6)+($3-$6)*($3-$6)+($4-$6)*($4-$6)+($5-$6)*($5-$6))/5)}' > default.thru.stdev.out.tmp

#cint file
for run in 0 1 2 3 4
do
	grep "req/s" results/*_raw_Y_32_15_${run}.out | awk -F'requests' '{print $2}' | awk -F'(' '{print $2}' | awk '{print $1}' >> cint.thru.out.${run}.tmp
done

paste cint.thru.out.0.tmp cint.thru.out.1.tmp cint.thru.out.2.tmp cint.thru.out.3.tmp cint.thru.out.4.tmp | awk '{print ($1+$2+$3+$4+$5)/5}' > cint.thru.mean.out.tmp
paste cint.thru.out.0.tmp cint.thru.out.1.tmp cint.thru.out.2.tmp cint.thru.out.3.tmp cint.thru.out.4.tmp cint.thru.mean.out.tmp | awk '{print sqrt((($1-$6)*($1-$6)+($2-$6)*($2-$6)+($3-$6)*($3-$6)+($4-$6)*($4-$6)+($5-$6)*($5-$6))/5)}' > cint.thru.stdev.out.tmp

for run in 0 1 2 3 4
do
	grep "req/s" results/*_raw_N_32_15_${run}.out | awk -F'requests' '{print $2}' | awk -F'(' '{print $2}' | awk '{print $1}' >> adaptive.thru.out.${run}.tmp
done

paste adaptive.thru.out.0.tmp adaptive.thru.out.1.tmp adaptive.thru.out.2.tmp adaptive.thru.out.3.tmp adaptive.thru.out.4.tmp | awk '{print ($1+$2+$3+$4+$5)/5}' > adaptive.thru.mean.out.tmp
paste adaptive.thru.out.0.tmp adaptive.thru.out.1.tmp adaptive.thru.out.2.tmp adaptive.thru.out.3.tmp adaptive.thru.out.4.tmp adaptive.thru.mean.out.tmp | awk '{print sqrt((($1-$6)*($1-$6)+($2-$6)*($2-$6)+($3-$6)*($3-$6)+($4-$6)*($4-$6)+($5-$6)*($5-$6))/5)}' > adaptive.thru.stdev.out.tmp

paste labels.tmp cint.thru.mean.out.tmp default.thru.mean.out.tmp adaptive.thru.mean.out.tmp cint.thru.stdev.out.tmp default.thru.stdev.out.tmp adaptive.thru.stdev.out.tmp | column -s $'\t' -t >> gp.dat
rm *.tmp

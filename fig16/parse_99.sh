#!/bin/bash
rm *.tmp

echo "1 A" >> labels.tmp
echo "2 B" >> labels.tmp
echo "3 C" >> labels.tmp
echo "4 F" >> labels.tmp
echo "5 D" >> labels.tmp

for run in 0 1 2 3 4
do
	grep "99p" results/*_raw_N_0_0_${run}.out | awk '{print $4}' >> default.out.${run}.tmp
done

paste default.out.0.tmp default.out.1.tmp default.out.2.tmp default.out.3.tmp default.out.4.tmp | awk '{print ($1+$2+$3+$4+$5)/5}' > default.mean.tmp
paste default.out.0.tmp default.out.1.tmp default.out.2.tmp default.out.3.tmp default.out.4.tmp default.mean.tmp | awk '{print sqrt((($1-$6)*($1-$6)+($2-$6)*($2-$6)+($3-$6)*($3-$6)+($4-$6)*($4-$6)+($5-$6)*($5-$6))/5)}' > default.stdev.tmp

for run in 0 1 2 3 4
do
	grep "99p" results/*_raw_Y_32_15_${run}.out | awk '{print $4}' >> cint.out.${run}.tmp
done

paste cint.out.0.tmp cint.out.1.tmp cint.out.2.tmp cint.out.3.tmp cint.out.4.tmp | awk '{print ($1+$2+$3+$4+$5)/5}' > cint.mean.tmp
paste cint.out.0.tmp cint.out.1.tmp cint.out.2.tmp cint.out.3.tmp cint.out.4.tmp cint.mean.tmp | awk '{print sqrt((($1-$6)*($1-$6)+($2-$6)*($2-$6)+($3-$6)*($3-$6)+($4-$6)*($4-$6)+($5-$6)*($5-$6))/5)}' > cint.stdev.tmp

for run in 0 1 2 3 4
do
	grep "99p" results/*_raw_N_32_15_${run}.out | awk '{print $4}' >> adaptive.out.${run}.tmp
done

paste adaptive.out.0.tmp adaptive.out.1.tmp adaptive.out.2.tmp adaptive.out.3.tmp adaptive.out.4.tmp | awk '{print ($1+$2+$3+$4+$5)/5}' > adaptive.mean.tmp
paste adaptive.out.0.tmp adaptive.out.1.tmp adaptive.out.2.tmp adaptive.out.3.tmp adaptive.out.4.tmp adaptive.mean.tmp | awk '{print  sqrt((($1-$6)*($1-$6)+($2-$6)*($2-$6)+($3-$6)*($3-$6)+($4-$6)*($4-$6)+($5-$6)*($5-$6))/5)}' > adaptive.stdev.tmp

paste labels.tmp cint.mean.tmp default.mean.tmp adaptive.mean.tmp cint.stdev.tmp default.stdev.tmp adaptive.stdev.tmp | column -s $'\t' -t >> gp.dat
rm *.tmp

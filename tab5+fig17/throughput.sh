#!/bin/bash
rm *.tmp

echo "Scan Latency Histograms:"
echo "-------------------" >> default.thru.out.tmp
echo "default:" >> default.thru.out.tmp
echo "-------------------" >> default.thru.out.tmp
grep "req/s" results/*_raw_N_0_0_*.out | awk '{print $10}' | awk -F'(' '{sum += $2} END {print sum/5}' >> default.thru.out.tmp

echo "-------------------" >> cint.thru.out.tmp
echo "cint:" >> cint.thru.out.tmp
echo "-------------------" >> cint.thru.out.tmp
grep "req/s" results/*_raw_Y*.out | awk '{print $10}' | awk -F'(' '{sum += $2} END {print sum/5}' >> cint.thru.out.tmp

echo "-------------------" >> adaptive.thru.out.tmp
echo "adaptive:" >> adaptive.thru.out.tmp
echo "-------------------" >> adaptive.thru.out.tmp
grep "req/s" results/*_raw_N_32_15_*.out | awk '{print $10}' | awk -F'(' '{sum += $2} END {print sum/5}' >> adaptive.thru.out.tmp

paste default.thru.out.tmp cint.thru.out.tmp adaptive.thru.out.tmp | column -s $'\t' -t > thru.out
cat thru.out
echo "Output also written to thru.out"
rm *.tmp

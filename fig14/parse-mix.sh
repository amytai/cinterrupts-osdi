#!/bin/bash

#delay=6
bs=4K 	# for async, for sync it is 512
#k=256 	# iodepth
#n=16  	# size of submit/receive batch for async
cpucycles=2000000000
#out=pure-mix.txt
out="fig14.txt"


declare -A data_files=(
         [aio]="async-iops.data"
     [synclat]="psync-lat-avg.data"
      [cpuaio]="async-cpu.data"
      [cpuirq]="async-cpu-irq.data"
      [cpuidl]="async-cpu-idle.data"
      [numint]="async-total-ints.data"
)

declare -A precs=(
         [aio]="9.0f"
        [sync]="9.0f"
     [synclat]="8.1f"
      [aiolat]="8.1f"
      [cpuaio]="7.1f"
     [cpusync]="8.1f"
      [cpuirq]="7.1f"
      [cpuidl]="7.1f"
      [numint]="8.0f"
         [ipc]="6.2f"
)

declare -A res=(
         [aio]=""
     [synclat]=""
      [cpuaio]=""
      [cpuirq]=""
      [cpuidl]=""
      [numint]=""
)


names="cint default adaptive ooocint"
datas="aio synclat cpuaio cpuirq cpuidl numint"

function do_parsing() {

    local out="$1"
    local dir="$2"
    local model="$3"
    local delay="$4"
    local i=1
    local total
    local reqcycles

    declare -A ischeme_names=(
	 [default]="alpha-0-0"
	[adaptive]="alpha-$delay-32"
	    [cint]="cint-$delay-32"
	 [ooocint]="cint-$delay-32-ooo"
    )

    for name in $names; do

	for data in $datas; do
	    field=$(
		awk 'NR==1 {for (i=1;i<=NF;i++) 			\
		    if ($i == "'${ischeme_names["$name"]}'") print i }' \
			"$dir/$model-"${data_files[$data]}""
	    )
	    res[$data]=$( awk '{ if ($1 == "'$bs'") print $'"$field"'}' \
		    "$dir/$model-${data_files[$data]}" )
	done

	# cpuidl = 100-(cpuaio+cpusync+cpuirq)
	cpu=$(echo ${res[cpuaio]} + ${res[cpuirq]} |bc -l)
	#[ $(echo "${res[cpuidl]} < 0" | bc -l) -eq 1 ] && res[cpuidl]=0


	#total=$(echo ${res[aio]} + ${res[sync]} | bc)
	#reqcycles=$(echo "( $cpucycles / $total ) * ( 100 - ${res[cpuidl]} ) / 100"  | bc -l)

	# print sync iops, sync lat, inter/sec, idle cpu
	#for data in sync synclat numint cpuidl; do
	#    printf "%"${precs[$data]}"" ${res[$data]} | tee -a $out
	#done

	# print cycles per-IO
	#printf "%9.0f" $reqcycles | tee -a $out

	printf "%-d %9s %8.1f %9.0f %9.0f %8.0f" 	\
		$i $name ${res[synclat]} 		\
		${res[aio]} ${res[numint]} 		\
		$(echo $cpucycles / ${res[aio]} | bc ) 	\
			| tee -a $out

	let "i+=1"
	printf "\n" | tee -a $out
    done
}

cat <<EOF > $out
#-------------------------------------------------------------------------------
# Experiment   -- pure workload. read() or libaio, 4KB
#
#  		  Adaptive, cint and cintooo schemes use
#  		  delay of 6 in P4800 and 15 for P3700,
#  		  threshold of 32.
#
# idx.disk0 for P3700
# idx.disk1 for P4800
#
# FIELD     WHAT
# -----     --------------------
# t-p       async throughout [IOPS]
# lat       sync latency [usec]
# cycles/io [cycles/io]
# inter     interrupts/second
#-------------------------------------------------------------------------------
# i ischeme       t-p       inter    cycles/io   lat
#-------------------------------------------------------------------------------
EOF

printf "\n\n# disk0\n" | tee -a $out

# pure p3700
#data_dir="../workload_bars/p3700/no-mitigations-alpha0"
data_dir="./"
#do_parsing "$out" "$data_dir" p3700 15
printf "For now only generate for Optane, as we don't have  Intel 3700 on dante733.\n"
printf "1      cint 0 0 0 0\n" | tee -a  $out
printf "2   default 0 0 0 0\n" | tee -a $out
printf "3  adaptive 0 0 0 0\n" | tee -a $out
printf "4   ooocint 0 0 0 0\n" | tee -a $out


printf "\n\n# disk1\n" | tee -a $out

# pure p4800
#data_dir="../workload_bars/p4800/no-mitigations-alpha0"
data_dir="./"
do_parsing "$out" "$data_dir" p4800 6


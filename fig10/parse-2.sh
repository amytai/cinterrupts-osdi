#!/bin/bash

model=p4800
delay=6
bs=4K

declare -A data_files=(
         [aio]="$model-async-iops.data"
        [sync]="$model-psync-iops.data"
     [synclat]="$model-psync-lat-avg.data"
      [cpuaio]="$model-async-cpu.data"
     [cpusync]="$model-psync-cpu.data"
      [cpuirq]="$model-cpu-irq.data"
      [cpuidl]="$model-cpu-idle.data"
      [numint]="$model-total-ints.data"
         [ipc]="$model-cpu-ipc.data"
)

declare -A precs=(
         [aio]="9.0f"
        [sync]="9.0f"
     [synclat]="8.1f"
      [cpuaio]="7.1f"
     [cpusync]="8.1f"
      [cpuirq]="7.1f"
      [cpuidl]="7.1f"
      [numint]="8.0f"
         [ipc]="6.2f"
)

declare -A res=(
         [aio]=""
        [sync]=""
     [synclat]=""
      [cpuaio]=""
     [cpusync]=""
      [cpuirq]=""
      [cpuidl]=""
      [numint]=""
         [ipc]=""
)

declare -A ischeme_names=(
    [default]="alpha-0-0"
    [adaptive]="alpha-$delay-32"
        [cint]="cint-$delay-32"
     [ooocint]="cint-$delay-32-ooo"
)

#names="default adaptive cint ooocint"
#datas="aio sync synclat cpuaio cpusync cpuirq cpuidl numint ipc"
names="cint default adaptive ooocint"
datas="sync aio synclat numint cpuidl cpuaio cpusync cpuirq"

function do_parsing() {

    local out="$1"
    local dir="$2"
    local i=1

    for name in $names; do

	printf "%d" $i >> $out
	printf "%9s" $name >> $out

	for data in $datas; do
	    field=$(
		awk 'NR==1 {for (i=1;i<=NF;i++) 			\
		    if ($i == "'${ischeme_names["$name"]}'") print i }' \
			"$dir/${data_files[$data]}"
	    )
	    res[$data]=$( awk '{ if ($1 == "'$bs'") print $'"$field"'}' "$dir/${data_files[$data]}" )
	done

	# cpuidl = 100-(cpuaio+cpusync+cpuirq)
	#res[cpuidl]=$(echo 100 - ${res[cpuaio]} - ${res[cpusync]} - ${res[cpuirq]} |bc -l)
	res[cpuidl]=$(echo ${res[cpuaio]} + ${res[cpusync]} + ${res[cpuirq]} |bc -l)
	#[ $(echo "${res[cpuidl]} > 100" | bc -l) -eq 1 ] && res[cpuidl]=100

	for data in $datas; do
	    printf "%"${precs[$data]}"" ${res[$data]} >> $out
	done

	let "i+=1"
	printf "\n" >> $out
    done
}

out="fig10.txt"

cat <<EOF > $out
#-------------------------------------------------------------------------------
# FIELD     UNIT
# aio,sync  iops
# synclat   usec
# cpu*      percents (sum to 100%; cpuidl = 100-(cpuaio+cpusync+cpuirq))
# numint    interrupt/s
# ipc       instructions/cycle
#-------------------------------------------------------------------------------
#  ischeme   sync   async   lat    numint  cpuidl cpuaio cpusync cpuirq 
#-------------------------------------------------------------------------------


# idx.ratelimit0
EOF

# mixed, no throttling
#data_dir="../mixed_bars/p4800/mitigations_off_psync_512_sz_irq_acct_run2"
data_dir="results_nortlm"
#out="$model-4k.dat"
do_parsing "$out" "$data_dir"

cat <<EOF >> $out


# idx.ratelimit1
EOF

# mixed, with throttling async
#data_dir="../mixed_bars/p4800/mitigations_off_psync_512_sz_io_throttled_alpha0_irq_acct"
data_dir="results_rtlm"
#out="$model-4k-rlmt.dat"
do_parsing "$out" "$data_dir"

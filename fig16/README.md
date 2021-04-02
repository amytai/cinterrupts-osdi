### Experiment description
Run the YCSB suite (except for YCSB-E) on KVell.
Each experiment is run 5 times.

Interrupt schemes under comparison: cint, default, and adaptive

**Make sure you run `build-kvell.sh` in the top-level directory before starting this experiment!**

### Description of scripts in this directory
* all.sh	 	-- run the benchmark
* parse.sh 	-- parse the results and generate fig16.pdf
* make-all.sh	-- run the 2 preceding scripts
* fig16.gp	-- gnuplot script that generates fig16.gp. This is called from parse.sh.
		   You should not need to call it manually.

### Output files
* fig16.pdf	-- Figure 16 in the paper

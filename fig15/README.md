### Experiment description
readwhilewriting and readrandom experiments in RocksDB, for 4 and 8 RocksDB threads.
Both experiments are run on a RocksDB instance that is loaded with 20M 1KiB key-value pairs,
for a RocksDB instance size of ~20GiB.
Each experiment is run 5 times.

Interrupt schemes under comparison: cint, default, adaptive.

**Make sure you have run the `build-rocksdb.sh` script in the top-level directory!**

### Description of scripts in this directory
* run-4.sh		-- script to run the readwhilewriting and readrandom experiments for RocksDB, 4 threads
* run-8.sh		-- script to run the readwhilewriting and readrandom experiments for RocksDB, 8 threads
* parse.sh		-- script to parse the results
* make-all.sh		-- run all 3 preceding scripts

### Output files
* fig15-latency.pdf	-- top half of Figure 15 in the paper
* fig15-iops.pdf	-- bottom half of Figure 15 in the paper

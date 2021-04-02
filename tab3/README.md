### Experiment description
Run the fillbatch workload from RocksDB's db_bench benchmarking suite.
Fill the RocksDB instance with 10M 1KiB key-value pairs.
Each experiment is run 5 times.

Interrupt schemes under comparison: cint (app unmodified), default, adaptive, app-cint (modified app).

**Make sure you have run the `build-rocksdb.sh` script in the top-level directory!**

### Description of scripts in this directory
* fillbatch.sh		-- script to run the fillbatch experiment
* parse_fillbatch.sh	-- script to parse the results
* make-all.sh		-- run the two preceding scripts

### Output files
* all.out			-- contains data for Table 3 in the paper

#include "headers.h"
 
static bench_t LOAD_WORKLOAD[] = {};
static bench_t SCAN_WORKLOAD[] = {
      ycsb_e_uniform, 
};
static bench_t READ_WORKLOAD[] = {
      ycsb_c_uniform, 
};
static bench_t YCSB_ALL_WORKLOAD[] = {
      ycsb_a_uniform, 
      ycsb_b_uniform, 
      ycsb_c_uniform, 
      ycsb_b_uniform, 
      ycsb_a_uniform, 
};

int main(int argc, char **argv) {
   int disk_nb, nb_workers_per_disk, nb_load_injectors = 0;
   /* 
    * Default workload is 'l' for 'load'.
    * If the user wants read, use 'r' on the commandline.
    * If the user wants scan, use 's' on the commandline.
    * If the user wants all YCSB workloads, use 'a' on the commandline.
    */
   char workload_char = 'l';
   int num_workloads = sizeof(LOAD_WORKLOAD)/sizeof(bench_t);
   declare_timer;

   /* Definition of the workload, if changed you need to erase the DB before relaunching */
   struct workload w = {
      .api = &YCSB,
      .nb_items_in_db = 80000000LU,
      .nb_load_injectors = 4,
      .scan_length=16,
      //.nb_load_injectors = 12, // For scans (see scripts/run-aws.sh and OVERVIEW.md)
   };


   /* Parsing of the options */
   if(argc < 3)
      die("Usage: ./main <disk #> <nb workers per disk> <nb load-injectors> <char of workload type> <scan length> \n\tData is stored in %s\n", PATH);
   disk_nb = atoi(argv[1]);
   nb_workers_per_disk = atoi(argv[2]);
   if (argc >= 4) {
    nb_load_injectors = atoi(argv[3]);
    w.nb_load_injectors = nb_load_injectors;
    }
   if (argc >= 5) {
    workload_char = argv[4][0];
    }
   if (argc >= 6) {
    w.scan_length = atoi(argv[5]);
    }

   /* Pretty printing useful info */
   printf("# Configuration:\n");
   printf("# \tPage cache size: %lu GB\n", PAGE_CACHE_SIZE/1024/1024/1024);
   //printf("# \tWorkers: %d working on %d disks\n", disk_nb*nb_workers_per_disk, disk_nb);
   printf("# \tIO configuration: %d queue depth (capped: %s, extra waiting: %s)\n", QUEUE_DEPTH, NEVER_EXCEED_QUEUE_DEPTH?"yes":"no", WAIT_A_BIT_FOR_MORE_IOS?"yes":"no");
   printf("# \tQueue configuration: %d maximum pending callbaks per worker\n", MAX_NB_PENDING_CALLBACKS_PER_WORKER);
   printf("# \tDatastructures: %d (memory index) %d (pagecache)\n", MEMORY_INDEX, PAGECACHE_INDEX);
   printf("# \tThread pinning: %s\n", PINNING?"yes":"no");
   printf("# \tBench: %s (%lu elements)\n", w.api->api_name(), w.nb_items_in_db);

   /* Initialization of random library */
   start_timer {
      printf("Initializing random number generator (Zipf) -- this might take a while for large databases...\n");
      init_zipf_generator(0, w.nb_items_in_db - 1); /* This takes about 3s... not sure why, but this is legacy code :/ */
   } stop_timer("Initializing random number generator (Zipf)");

   /* Recover database */
   start_timer {
      slab_workers_init(disk_nb, nb_workers_per_disk);
   } stop_timer("Init found %lu elements", get_database_size());

   /* Add missing items if any */
   repopulate_db(&w);

   /* Launch benchs */
   bench_t workload;
   bench_t *workloads;

    if (workload_char == 'r') {
	printf("hi, using c as the workload\n");
        workloads = READ_WORKLOAD;
	num_workloads = sizeof(READ_WORKLOAD)/sizeof(bench_t);
    } else if (workload_char == 's') {
	workloads = SCAN_WORKLOAD;
	num_workloads = sizeof(SCAN_WORKLOAD)/sizeof(bench_t);
    } else if (workload_char == 'a') {
	workloads = YCSB_ALL_WORKLOAD;
	num_workloads = sizeof(YCSB_ALL_WORKLOAD)/sizeof(bench_t);
    } else if (workload_char == 'l') {
	workloads = LOAD_WORKLOAD;
	num_workloads = sizeof(LOAD_WORKLOAD)/sizeof(bench_t);
    }
    printf("number of workloads: %d\n", num_workloads);

    /* YCSB experiment config: ABCBA, 10M requests each. 50K for E */

   for (int i = 0; i < num_workloads; i++) {
      workload = workloads[i];
      if(workload == ycsb_e_uniform || workload == ycsb_e_zipfian) {
         w.nb_requests = 10000LU; // requests for YCSB E are longer (scans) so we do less
      } else {
         w.nb_requests = 10000000LU;
      }
      run_workload(&w, workload);
   }
   return 0;
}

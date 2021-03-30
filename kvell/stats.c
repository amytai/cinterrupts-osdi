#include "headers.h"
#include "utils.h"
#include "slab.h"

#define MAX_STATS 100000000LU

cache_hit = 0;
cache_miss = 0;

struct stats {
   uint64_t *timing_time;
   uint64_t *timing_value;
   size_t timing_idx;
   size_t max_timing_idx;
} stats;

void add_timing_stat(uint64_t elapsed) {
   if(!stats.timing_value) {
      stats.timing_time = malloc(MAX_STATS * sizeof(*stats.timing_time));
      stats.timing_value = malloc(MAX_STATS * sizeof(*stats.timing_value));
      stats.timing_idx = 0;
      stats.max_timing_idx = MAX_STATS;
   }
   if(stats.timing_idx >= stats.max_timing_idx)
      return;
      //die("Cannot collect all stats, buffer is full!\n");
   rdtscll(stats.timing_time[stats.timing_idx]);
   stats.timing_value[stats.timing_idx] = elapsed;
   stats.timing_idx++;
}

int cmp_uint(const void *_a, const void *_b) {
   uint64_t a = *(uint64_t*)_a;
   uint64_t b = *(uint64_t*)_b;
   if(a > b)
      return 1;
   else if(a < b)
      return -1;
   else
      return 0;
}

/* Calculate and print scan latency */
void print_scan_latency_stats(void) {
   size_t i;
   int stat_array_size = 50000;

   if(stats.timing_idx == 0) {
      printf("#No stat has been collected\n");
      return;
   }

   size_t last = stats.timing_idx;
   fprintf(stderr, "%lu stats have been collected\n", last);

   uint64_t *time_of_first = calloc(stat_array_size, sizeof(uint64_t));
   uint64_t *time_of_last = calloc(stat_array_size, sizeof(uint64_t));
   uint64_t *value_of_first = calloc(stat_array_size, sizeof(uint64_t));
   uint64_t *max_elapsed = calloc(stat_array_size, sizeof(uint64_t));

   /*
    * Do 1 pass over the stats, and find 1) first time for each ID, 2) last
    * time for each ID, 3) timing_value for first time for each ID
    */
   for (i = 1; i < last; i ++) {
       if (stats.timing_time[i] == 0)
           continue;
       uint64_t id = stats.timing_value[i] & ID_MASK;
       if ((id >> ID_OFFSET) >= stat_array_size)
           continue;

       if ((max_elapsed[id >> ID_OFFSET] ==0) || ((stats.timing_value[i] & NON_ID_MASK) > max_elapsed[id >> ID_OFFSET]))
           max_elapsed[id >> ID_OFFSET] = stats.timing_value[i] & NON_ID_MASK;

       if ((time_of_first[id >> ID_OFFSET] == 0) || ((stats.timing_time[i] & NON_ID_MASK) < time_of_first[id >> ID_OFFSET])) {
           time_of_first[id >> ID_OFFSET] = stats.timing_time[i] & NON_ID_MASK;
           value_of_first[id >> ID_OFFSET] = stats.timing_value[i] & NON_ID_MASK;
       }

       if ((time_of_last[id >> ID_OFFSET] == 0) || ((stats.timing_time[i] & NON_ID_MASK) > time_of_last[id >> ID_OFFSET]))
           time_of_last[id >> ID_OFFSET] = stats.timing_time[i] & NON_ID_MASK;
   }
   // Now print..
   for (i = 0; i < stat_array_size; i ++) {
       if (time_of_first[i] == 0)
           continue;

       uint64_t latency = cycles_to_us(time_of_last[i]) -
           cycles_to_us(time_of_first[i]) +
           cycles_to_us(value_of_first[i]);
       fprintf(stderr, "id: %lu, %lu, %lu, time of first: %lu, time of last: %lu, value of first: %lu\n", i, cycles_to_us(max_elapsed[i]), latency, cycles_to_us(time_of_first[i]), cycles_to_us(time_of_last[i]), cycles_to_us(value_of_first[i]));
   }
}

void print_latency_timeseries_stats(void) {
    uint64_t *sec_idxs;
    int num_secs;
    size_t i,j = 1;
    size_t last = stats.timing_idx;

    if(stats.timing_idx == 0) {
        printf("#No stat has been collected\n");
        return;
    }

    /*
     * The following is to create a timeseries of latency. We create an array of INDICES into the actual timestamp array.
     * sec_idxs[i] will contain the index in the timestamp array that is the start of second i in the stats
     */
    num_secs = (cycles_to_us(stats.timing_time[last - 1]) - cycles_to_us(stats.timing_time[0])) / 1000 / 1000 + 2;
    sec_idxs = malloc(sizeof(uint64_t) * num_secs);
    sec_idxs[0] = 0;

    uint64_t most_recent_time = stats.timing_time[0];
    for (i = 1; i < last; i++) {
        if (cycles_to_us(stats.timing_time[i]) - cycles_to_us(most_recent_time) > 1000000LU &&
                cycles_to_us(stats.timing_time[i]) - cycles_to_us(most_recent_time) < 2000000LU) {
            sec_idxs[j] = i;
            most_recent_time = stats.timing_time[i];
            // Sort each second
            qsort(stats.timing_value + (sec_idxs[j-1]), sec_idxs[j] - sec_idxs[j-1], sizeof(*stats.timing_value), cmp_uint);
            int diff = sec_idxs[j] - sec_idxs[j-1];
            printf("50th percentile: %lu, 90th percentile: %lu, 99th percentile: %lu\n",
                    cycles_to_us(stats.timing_value[diff * 50/100 + sec_idxs[j-1]]),
                    cycles_to_us(stats.timing_value[diff * 90/100 + sec_idxs[j-1]]), 
                    cycles_to_us(stats.timing_value[diff * 99/100 + sec_idxs[j-1]]));
            j++;
        }
    }

    /* Don't 0 out timing_idx because that will be done in print_stats() below */
    //printf("Cache miss: %d, cache hit: %d\n", cache_miss, cache_hit);
}

void print_stats(void) {
    uint64_t avg = 0;

    if(stats.timing_idx == 0) {
        printf("#No stat has been collected\n");
        return;
    }

    size_t last = stats.timing_idx;
    qsort(stats.timing_value, last, sizeof(*stats.timing_value), cmp_uint);
    for(size_t i = 0; i < last; i++)
        avg += stats.timing_value[i];

    printf("#Latency:\n#\tAVG - %lu us\n#\t99p - %lu us\n#\tmax - %lu us\n", cycles_to_us(avg/last), cycles_to_us(stats.timing_value[last*99/100]), cycles_to_us(stats.timing_value[last-1]));

    stats.timing_idx = 0;
}

struct timing_s {
    size_t origin;
   size_t time;
};

void *allocate_payload(void) {
#if DEBUG
   return calloc(20, sizeof(struct timing_s));
#else
   return NULL;
#endif
}

void add_time_in_payload(struct slab_callback *c, size_t origin) {
#if DEBUG
   struct timing_s *payload = c->payload;
   if(!payload)
      return;

   uint64_t t, pos = 0;
   rdtscll(t);
   while(pos < 20 && payload[pos].time)
      pos++;
   if(pos == 20)
      die("Too many times added!\n");
   payload[pos].time = t;
   payload[pos].origin = origin;
#else
   if(origin != 0)
      return;
   uint64_t t;
   rdtscll(t);
   c->payload = (void*)t;
#endif
}

uint64_t get_origin_from_payload(struct slab_callback *c, size_t pos) {
#if DEBUG
   struct timing_s *payload = c->payload;
   if(!payload)
      return 0;
   return payload[pos].origin;
#else
   return 0;
#endif
}

uint64_t get_time_from_payload(struct slab_callback *c, size_t pos) {
#if DEBUG
   struct timing_s *payload = c->payload;
   if(!payload)
      return 0;
   return payload[pos].time;
#else
   return (uint64_t)c->payload;
#endif
}

void free_payload(struct slab_callback *c) {
#if DEBUG
   free(c->payload);
#endif
}

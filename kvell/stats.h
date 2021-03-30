#ifndef STATS_H
#define STATS_H 1

#define ID_OFFSET   52
#define NON_ID_MASK    ((((uint64_t) 0x1) << (ID_OFFSET)) - 1)
#define ID_MASK (~NON_ID_MASK)

struct slab_callback;
void add_timing_stat(uint64_t elapsed);
void print_stats(void);
void print_scan_latency_stats(void);
void print_latency_timeseries_stats(void);

uint64_t cycles_to_us(uint64_t cycles);

void *allocate_payload(void);
void free_payload(struct slab_callback *c);
void add_time_in_payload(struct slab_callback *c, size_t origin);
uint64_t get_time_from_payload(struct slab_callback *c, size_t pos);
uint64_t get_origin_from_payload(struct slab_callback *c, size_t pos);

int cache_hit;
int cache_miss;
#endif

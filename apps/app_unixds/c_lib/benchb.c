#include <csunixds.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <sys/time.h>
#include <stdbool.h>

#define DEBUG(...) fprintf(stderr, "DEBUG: " __VA_ARGS__)
#define POINTS 100000
//#define POINTS 3
#define CHANNELS 1

typedef struct {
	int write_block;
	int read_block;
	int write_callback;
} csv_row_t;

static void stamp(struct timeval *val);
static int stamp_diff(const struct timeval *a, const struct timeval *b);

int main() {
	DEBUG("Benchmark \"BenchB\" with %d points.\n", POINTS);
	assert(cs_initialize(NULL) == CS_OK);

	csv_row_t *results = (csv_row_t*) malloc(sizeof(csv_row_t)*POINTS);

	// Constants to send
	const char *names[] = { "vcan4:BenchB", "vcan4:BenchB_2" };
	//const double write_values[] = { 10.0f, 11.0f };
	const cs_value_t write_values[] = {
		{CS_TYPE_F64, .value_f64=10.0},
		{CS_TYPE_F64, .value_f64=11.0},
	};

	struct timeval start, end;


	// Measure blocking ops
	for (int i=0; i<POINTS; i++) {

		// Write
		stamp(&start);
		assert(cs_write(CHANNELS, names, write_values) == CS_OK);
		stamp(&end);
		results[i].write_block = stamp_diff(&start, &end);

		cs_value_t read_value[CHANNELS];

		// Read
		stamp(&start);
		assert(cs_read(CHANNELS, names, read_value) == CS_OK);
		stamp(&end);
		results[i].read_block = stamp_diff(&start, &end);

		assert(read_value[0].value_f64 == 10.0);
		assert(read_value[0].type == CS_TYPE_F64);
		//assert(read_value[1] == 11.0f);
	}

	assert(cs_subscribe(CHANNELS, names) == CS_OK);

	// Measure subscribe callback response
	bool waiting = true;
	int callbacks = 0;

	cs_wait_mode_t event(
			int signal_count, const char *const names[],
			const cs_value_t values[]) {

		stamp(&end);

		if (waiting) {
			DEBUG("Writing initial value.\n");
			waiting = false;
		} else {
			assert(signal_count == CHANNELS);
			int timediff = stamp_diff(&start, &end);
			//DEBUG("Got result (%d).\n", timediff);
			results[callbacks++].write_callback = timediff;
		}

		if (callbacks >= POINTS) {
			DEBUG("Stop loop.\n");
			return CS_BLOCK_STOP;
		} else {
			stamp(&start);
			assert(cs_write(CHANNELS, names, write_values) == CS_OK);
			//DEBUG("Written.\n");
			return CS_BLOCK_CONTINUE;
		}
	}

	// Run subscription loop
	DEBUG("Waiting for signal... run: `Special.benchb_echo` in iex\n");
	cs_event_loop(event);

	// Write CSV
	printf("write_block;read_block;write_callback\n");
	for (int i=0; i<POINTS; i++) {
		printf("%d;%d;%d\n",
				results[i].write_block,
				results[i].read_block,
				results[i].write_callback);
	}

	// Close
	assert(cs_shutdown() == CS_OK);

	free(results);

	DEBUG("Done...\n");
	return 0;
}

static void stamp(struct timeval *val) {
	gettimeofday(val, NULL);
}

static int stamp_diff(const struct timeval *a, const struct timeval *b) {
	return b->tv_usec - a->tv_usec;
}

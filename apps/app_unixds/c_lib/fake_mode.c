#define FAKE_COS_ELEMS 40

static char tmp_block_latest[40];

const double fake_cos[FAKE_COS_ELEMS] = {
	1.0, 0.9876883405951378, 0.9510565162951535, 0.8910065241883679,
	0.8090169943749475, 0.7071067811865476, 0.5877852522924731,
	0.4539904997395468, 0.30901699437494745, 0.15643446504023092,
	0.000000995736766, -0.1564344650402306, -0.30901699437494734,
	-0.4539904997395467, -0.587785252292473, -0.7071067811865475,
	-0.8090169943749473, -0.8910065241883678, -0.9510565162951535,
	-0.9876883405951377, -1.0, -0.9876883405951378, -0.9510565162951538,
	-0.8910065241883679, -0.8090169943749476, -0.7071067811865477,
	-0.5877852522924732, -0.4539904997395469, -0.30901699437494756,
	-0.15643446504023104, -0.0000000087210297, 0.15643446504023067,
	0.30901699437494723, 0.45399049973954664, 0.5877852522924729,
	0.7071067811865474, 0.8090169943749473, 0.8910065241883678,
	0.9510565162951535, 0.9876883405951377,
};

cs_status_t cs_initialize(const char *source) {
	return CS_OK;
}

cs_status_t cs_shutdown(void) {
	return CS_OK;
}


cs_status_t cs_read(int signal_count, const char *const names[], double values[]) {

	static unsigned tick = 0;

	double value = fake_cos[(tick++) % FAKE_COS_ELEMS];

	fprintf(stderr, "Reading signals");
	for (int i=0; i<signal_count; i++) {
		fprintf(stderr, " \"%s\"", names[i]);
		values[i] = value + 0.5 * (double) i;
	}
	fprintf(stderr, "\n");

	return CS_OK;
}

cs_status_t cs_write(int signal_count, const char *const names[], const double values[]) {

	fprintf(stderr, "Writing signals");
	for (int i=0; i<signal_count; i++) {
		fprintf(stderr, " \"%s\":%f", names[i], values[i]);
	}
	fprintf(stderr, "\n");

	return CS_OK;
}

cs_status_t cs_subscribe(int signal_count, const char *const names[]) {

	CS_ERROR_NO_CONNECTION;
}

cs_status_t cs_block_signals(cs_wait_callback_t cb) {
	CS_ERROR_NO_CONNECTION;
}


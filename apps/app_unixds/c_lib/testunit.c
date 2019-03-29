#include <csunixds.h>
#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>

#define _STR(x) #x
#define STR(x) _STR(x)
#define DEBUG(...) fprintf(stderr, " {TEST UNIT} (" STR(__LINE__) "): " __VA_ARGS__)

#define ASSERT_OK(cmd) assert(require_ok(cmd, __LINE__))

#define LIST_UNITS \
	X(1, test_init, "Initialize and terminate") \
	X(2, test_write_simple, "Write simple") \
	X(3, test_handshake_null, "Handshake with null source") \
	X(4, test_send_by_namespace, "Send to multiple namespaces") \
	X(5, test_read_send_namespace, "Read and send from and to multiple namespaces") \
	X(6, test_subscribe_response, "Subscribe and respond on events") \
	X(7, test_read_unknown, "Read signal that doesn't exist") \
	X(8, test_timeout_set, "Set timeout") \
	X(9, test_timeout_trigger, "Trigger timeout") \
	X(10, test_read_several_namespaces, "Read from several namespaces in one call") \
	X(11, test_init_3sync, "Initialize, sync and terminate") \
	X(12, test_maybe_namespace, "Read and write with and without namespace") \
	X(13, test_lin_list_buses, "List empty 0 LIN buses") \
	X(14, test_lin_get_schedules, "Get LIN schedules for bus") \
	X(15, test_lin_set_scheduler, "Set LIN schedules for bus") \
	X(16, test_lin_start, "Start LIN bus") \
	X(17, test_lin_stop, "Stop LIN bus") \
	X(18, test_lin_wakeup, "Wakeup LIN bus") \

static bool wait_sync(void);
static bool require_ok(cs_status_t status, int line_number);


//=============================================================================
// Testing units
//=============================================================================

static int test_init(void) {
	ASSERT_OK(cs_initialize(NULL));
	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_write_simple(void) {
	ASSERT_OK(cs_initialize("testspace"));

	const char *sig_name[] = {"simple"};
	const cs_value_t sig_value[] = {{CS_TYPE_I64, .value_i64=-5}};

	ASSERT_OK(cs_write(1, sig_name, sig_value));
	ASSERT_OK(cs_shutdown());
	return 0;
}


static int test_lin_wakeup(void) {
	ASSERT_OK(cs_initialize("testspace"));

	const char *sig_name[] = {"HusLin18Fr01"};

	ASSERT_OK(cs_wakeup(sig_name));
	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_handshake_null(void) {
	ASSERT_OK(cs_initialize(NULL));

	const char *sig_name[] = {"simple"};
	const cs_value_t sig_value[] = {{CS_TYPE_F64, .value_f64=1.0}};

	ASSERT_OK(cs_write(1, sig_name, sig_value));
	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_send_by_namespace(void) {
	ASSERT_OK(cs_initialize(NULL));

	const char *sig_name[] = {
		"broker0:simple0",
		"broker1:simple1",
		"broker2:simple2",
	};
	const cs_value_t sig_value[] = {
		{ CS_TYPE_F64, .value_f64=0.0 },
		{ CS_TYPE_F64, .value_f64=1.0 },
		{ CS_TYPE_F64, .value_f64=2.0 },
	};

	ASSERT_OK(cs_write(3, sig_name, sig_value));
	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_read_send_namespace(void) {
	ASSERT_OK(cs_initialize(NULL));

	wait_sync();

	const char *sig_name[] = {
		"broker0:simple0",
		"broker1:simple1",
		"broker2:simple2",
	};
	cs_value_t sig_value[3];

	ASSERT_OK(cs_read(3, sig_name, sig_value));
	assert(sig_value[0].value_f64 == 0.0);
	assert(sig_value[0].type == CS_TYPE_F64);
	assert(sig_value[1].value_f64 == 1.0);
	assert(sig_value[1].type == CS_TYPE_F64);
	assert(sig_value[2].value_f64 == 2.0);
	assert(sig_value[2].type == CS_TYPE_F64);

	sig_value[0] = (cs_value_t) { .type = CS_TYPE_F64, .value_f64 = 1.0 };
	sig_value[1] = (cs_value_t) { .type = CS_TYPE_F64, .value_f64 = 2.0 };
	sig_value[2] = (cs_value_t) { .type = CS_TYPE_F64, .value_f64 = 3.0 };
	ASSERT_OK(cs_write(3, sig_name, sig_value));
	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_subscribe_response(void) {
	ASSERT_OK(cs_initialize(NULL));

	const char *sig_name[] = {
		"broker0:simple",
		"broker1:simple",
		"broker2:simple",
	};


	wait_sync();
	ASSERT_OK(cs_subscribe(3, sig_name));

	int event_count = 0;

	cs_wait_mode_t event(
			int signal_count, const char *const names[],
			const cs_value_t values[]) {

		char predict_name[30];
		sprintf(predict_name, "broker%d:simple", event_count);

		assert(signal_count == 1);
		assert(strcmp(names[0], predict_name) == 0);
		assert(cs_write(1, names, values) == CS_OK);

		// Stop after 3 events
		return ++event_count >= 3 ? CS_BLOCK_STOP : CS_BLOCK_CONTINUE;
	}

	ASSERT_OK(cs_event_loop(event));

	wait_sync();
	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_read_unknown(void) {
	ASSERT_OK(cs_initialize(NULL));

	const char *sig_names[] = {
		"broker0:simple",
		"broker0:this does not exist",
		"this does not exist",
		"this does not exist:neither does this",
		"unknown:hello",
	};

	for (int i=0; i<4; i++) {
		cs_value_t sig_value;

		ASSERT_OK(cs_read(1, sig_names+i, &sig_value));
		assert(sig_value.type == CS_TYPE_EMPTY);
	}

	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_timeout_set(void) {
	ASSERT_OK(cs_initialize(NULL));
	ASSERT_OK(cs_set_timeout(100));
	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_timeout_trigger(void) {
	ASSERT_OK(cs_initialize(NULL));

	ASSERT_OK(cs_set_timeout(30)); // Set timeout after 30 milliseconds

	for (int i=0; i<4; i++) {
		const char *sub_sig_name[] = {"Anything"};
		ASSERT_OK(cs_subscribe(1, sub_sig_name));
		assert(cs_event_loop(NULL) == CS_ERROR_TIMEOUT);
	}

	{
		const char *write_sig_name[] = {"OK"};
		const cs_value_t sig_value[] = {{ CS_TYPE_I64, .value_i64=0 }};
		assert(cs_write(1, write_sig_name, sig_value) == CS_OK);
	}

	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_read_several_namespaces(void) {
	ASSERT_OK(cs_initialize(NULL));

	const char *sig_name[] = {
		"broker2:e",
		"broker0:b",
		"broker2:a",
		"broker1:d",
		"broker1:c",
		"broker0:f",
	};

#define COUNT sizeof(sig_name) / sizeof(sig_name[0])
	cs_value_t sig_value[COUNT];

	// Test reading
	ASSERT_OK(cs_read(COUNT, sig_name, sig_value));

	assert(sig_value[0].value_f64 == 5.0);
	assert(sig_value[1].value_f64 == 2.0);
	assert(sig_value[2].value_f64 == 1.0);
	assert(sig_value[3].value_f64 == 4.0);
	assert(sig_value[4].value_f64 == 3.0);
	assert(sig_value[5].value_f64 == 6.0);

	// Test reading
	ASSERT_OK(cs_read(COUNT, sig_name, sig_value));

	assert(sig_value[0].value_f64 == 5.0);
	assert(sig_value[1].value_f64 == 2.0);
	assert(sig_value[2].value_f64 == 1.0);
	assert(sig_value[3].value_f64 == 4.0);
	assert(sig_value[4].value_f64 == 3.0);
	assert(sig_value[5].value_f64 == 6.0);

	// Test writing
	for (int i=0; i<COUNT; i++) {
		sig_value[i].value_f64 = (double) i;
	}
	ASSERT_OK(cs_write(COUNT, sig_name, sig_value));

	ASSERT_OK(cs_read(COUNT, sig_name, sig_value));
	for (int i=0; i<COUNT; i++) {
		assert(sig_value[i].type == CS_TYPE_F64);
		assert(sig_value[i].value_f64 == (double) i);
	}

	ASSERT_OK(cs_shutdown());
	return 0;
#undef COUNT
}

static int test_init_3sync(void) {
	ASSERT_OK(cs_initialize(NULL));
	assert(wait_sync());
	assert(wait_sync());
	assert(wait_sync());
	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_maybe_namespace(void) {
	ASSERT_OK(cs_initialize(NULL));

	const char *sig_name[] = {
		"a", // This should be counted as "broker0:a"
		"broker1:b",
		"broker2:c",
	};

	const cs_value_t sig_value_write[] = {
		{ .type = CS_TYPE_I64, .value_i64 = 1 },
		{ .type = CS_TYPE_I64, .value_i64 = 2 },
		{ .type = CS_TYPE_I64, .value_i64 = 3 },
	};

	// Write some values
	ASSERT_OK(cs_write(3, sig_name, sig_value_write));
	assert(wait_sync());

	// Read the same values
	cs_value_t sig_value_read[3];
	ASSERT_OK(cs_read(3, sig_name, sig_value_read));

	assert(sig_value_read[0].type == CS_TYPE_I64);
	assert(sig_value_read[0].value_i64 == 1);
	assert(sig_value_read[1].type == CS_TYPE_I64);
	assert(sig_value_read[1].value_i64 == 2);
	assert(sig_value_read[2].type == CS_TYPE_I64);
	assert(sig_value_read[2].value_i64 == 3);

	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_lin_list_buses(void) {
	ASSERT_OK(cs_initialize(NULL));
	cs_string_t buses[3];

	int count = 3; // Receive max 3 names
	ASSERT_OK(cs_lin_buses_list(buses, &count));
	assert(count == 2);
	assert(strcmp(buses[0], "Lin1") == 0);
	assert(strcmp(buses[1], "Lin2") == 0);

	count = 1; // Receive max 1
	ASSERT_OK(cs_lin_buses_list(buses, &count));
	assert(count == 1);
	assert(strcmp(buses[0], "Lin1") == 0);

	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_lin_get_schedules(void) {
	ASSERT_OK(cs_initialize(NULL));

	int count = 3;
	cs_string_t schedules[3];
	ASSERT_OK(cs_lin_schedules_list("Lin1", schedules, &count));

	assert(count == 1);
	assert(strcmp(schedules[0], "CcmLin18ScheduleTable1") == 0);

	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_lin_set_scheduler(void) {
	ASSERT_OK(cs_initialize(NULL));
	ASSERT_OK(cs_lin_schedules_set("Lin1", "CcmLin18ScheduleTable1", 2));
	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_lin_start(void) {
	ASSERT_OK(cs_initialize(NULL));
	ASSERT_OK(cs_lin_start("Lin1"));
	ASSERT_OK(cs_shutdown());
	return 0;
}

static int test_lin_stop(void) {
	ASSERT_OK(cs_initialize(NULL));
	ASSERT_OK(cs_lin_stop("Lin1"));
	ASSERT_OK(cs_shutdown());
	return 0;
}

//=============================================================================
// Synchonization
//=============================================================================

static bool wait_sync(void) {
	const char *sig_name[] = { "broker2:sig_sync" };
	const cs_value_t sig_value[] = {{CS_TYPE_I64, .value_i64=-2}};

	ASSERT_OK(cs_subscribe(1, sig_name));
	ASSERT_OK(cs_write(1, sig_name, sig_value));

	cs_wait_mode_t event(
			int signal_count,
			const char *const names[],
			const cs_value_t values[]) {

		if (signal_count != 1) return CS_ERROR_BAD_WRITE;
		if (strncmp(names[0], "broker2:sig_sync", 10) != 0) return CS_ERROR_BAD_WRITE;
		if (values[0].type != CS_TYPE_I64) return CS_ERROR_BAD_WRITE;
		if (values[0].value_i64 != -3) return CS_ERROR_BAD_WRITE;

		return CS_BLOCK_STOP;
	}

	return cs_event_loop(event) == CS_OK;
}

static bool require_ok_print_error(const char *desc, int line_number) {
	fprintf(stderr, "Assert error, line %d: %s.\n", line_number, desc);
	return false;
}

static bool require_ok(cs_status_t status, int line_number) {

	switch (status) {
		case CS_OK : return true;

		case CS_ERROR_TIMEOUT : return require_ok_print_error(
										"CS_ERROR_TIMEOUT",
										line_number);

		case CS_ERROR_BAD_WRITE : return require_ok_print_error(
										  "CS_ERROR_BAD_WRITE",
										  line_number);

		case CS_ERROR_BAD_RESPONSE : return require_ok_print_error(
											 "CS_ERROR_BAD_RESPONSE",
											 line_number);

		case CS_ERROR_NO_CONNECTION : return require_ok_print_error(
											  "CS_ERROR_NO_CONNECTION",
											  line_number);
	}
}


//=============================================================================
// Main entry point
//=============================================================================

static int exit_help(const char *argv0);
static int test_init(void);

int main(int argc, char *argv[]) {

	bool opt_fork = false;
	bool opt_unit = false;
	int opt_unit_num = -1;

	for (int i=1; i<argc; i++) {
		if (strncmp(argv[i], "-f", 20) == 0) {
			opt_fork = true;
		} else if (strncmp(argv[i], "-u", 2) == 0) {
			opt_unit = true;
			opt_unit_num = atoi(argv[i]+2);
		} else {
		}
	}

	if (!opt_unit) {
		return exit_help(argv[0]);
	}

	if (opt_fork) {
		if (fork() == 0) {
			sleep(4);
			printf("CHILD\n");
		}
	}

	switch (opt_unit_num) {
#define X(N, FUNC, DESC) case N: \
		FUNC(); \
		break;
	LIST_UNITS
#undef X
		default: return exit_help(argv[0]);
	}

	return 0;
}

static int exit_help(const char *argv0) {
	fprintf(stderr, "Usage: %s [-f] [-u<1-n>]\n", argv0);
	fprintf(stderr, "  -f, fork at startup.\n  -u<0-n>, run test unit.\n");
	return 1;
}


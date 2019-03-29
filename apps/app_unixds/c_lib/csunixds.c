#include <csunixds.h>
#include <stdbool.h>
#include <stdio.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>

#define CS_SOCK_PATH (CS_SOCK_DIR "/" CS_SOCK_NAME)
#ifdef CS_DEBUG
#define _STR(x) #x
#define STR(x) _STR(x)
#define DEBUG(...) fprintf(stderr, "(" STR(__LINE__) "): " __VA_ARGS__)
#else
#define DEBUG(...)
#endif

#define PACKED __attribute__((packed))

// Command byte
// Note, the character doesn't have any deeper meaning. Just make sure its the
// same at the receiving end in the Elixir code.
typedef enum {
	CS_CMD_WRITE = 'w',
	CS_CMD_READ = 'r',
	CS_CMD_HANDSHAKE = 'h',
	CS_CMD_OK = 'o',
	CS_CMD_SUBSCRIBE = 's',
	CS_CMD_SUBSCRIBE_START = 'S',
	CS_CMD_SUBSCRIBE_STOP = 'E',
	CS_CMD_SUBSCRIBE_CONTINUE = 'C',
	CS_CMD_SUBSCRIBE_ABORT = 'A',
	CS_CMD_SUBSCRIBE_TIMEOUT = 'T',
	CS_CMD_TIMEOUT_SET = 't',
	CS_CMD_EVENT = 'e',
	CS_CMD_LIN_BUSES_LIST = 'b',
	CS_CMD_LIN_SCHEDULS_LIST = 'u',
	CS_CMD_LIN_SCHEDULS_SET = 'v',
	CS_CMD_LIN_START = 'l',
	CS_CMD_LIN_STOP = 'L',
	CS_CMD_NAMES = 'n',
} command_t;

typedef struct PACKED {
	uint8_t name_len;
} signal_name_t;

typedef struct PACKED {
	uint8_t name_len;
	cs_value_t value;
} signal_name_value_t;

typedef struct PACKED {
	uint8_t version;
	uint8_t command;
	uint8_t signal_count;
} packet_header_t;

typedef struct PACKED {
	int32_t millis;
} fields_timeout_set_t;

typedef int (*read_socket_async_t) (
		packet_header_t *header,
		uint8_t *payload, size_t payload_size);

// Functions
static cs_status_t write_socket(const uint8_t *data, size_t size);
cs_wait_mode_t send_event_response(
		packet_header_t *header, uint8_t *payload, size_t payload_size,
		cs_wait_callback_t cb);
static int read_socket_async(read_socket_async_t cb);
static cs_status_t wait_for_ok(void);
static size_t size_of_name_signals(int signal_count,
		const char *const names[]);
static size_t size_of_name_value_signals(int signal_count,
		const char *const names[]);
static uint8_t *fill_header(command_t cmd, uint8_t signal_count, uint8_t *dst);
static uint8_t * fill_name_signal(
		command_t cmd, int signal_count,
		const char *const names[], uint8_t *ptr);
static cs_status_t request_ok(command_t cmd);
static packet_header_t make_command(command_t cmd);
static cs_status_t receive_names(cs_string_t *names, int *max_names);
static cs_status_t send_names(cs_string_t *names, int *max_names);
static cs_status_t send_names_get_values(command_t cmd, int signal_count,
		const char *const names[], cs_value_t values[]);
static cs_status_t send_names_values(command_t cmd, int signal_count,
		const char *const names[], const cs_value_t values[]);

// Variables
static int sock; // Unix domain socket
static struct sockaddr_un addr; // Socket destination

// Real mode, scroll to bottom for fake mode
#ifndef CS_FAKE_IO

//=============================================================================
// Public
//=============================================================================

cs_status_t cs_initialize(const char *source) {

	// Create socket and addres
	sock = socket(PF_LOCAL, SOCK_STREAM, 0);
	addr.sun_family = AF_LOCAL;
	strcpy(addr.sun_path, CS_SOCK_PATH);

	// Connect to server
	if (connect(sock, (struct sockaddr*) &addr, SUN_LEN(&addr)) != 0) {
		return CS_ERROR_NO_CONNECTION;
	}

	// Write handshake
	const char *names[] = {source ? source : ""};
	size_t size = size_of_name_signals(1, names);

	// Pack data
	uint8_t packed[size];
	fill_name_signal(CS_CMD_HANDSHAKE, 1, names, packed);

	// Write
	cs_status_t status = write_socket(packed, size);
	if (status != CS_OK) {
		return status;
	}

	return CS_OK;
}

cs_status_t cs_shutdown(void) {
	DEBUG("Closing socket.\n");
	close(sock);
	return CS_OK;
}

cs_status_t cs_set_timeout(int32_t ms) {
	size_t size =
		size_of_name_signals(0, NULL) +
		sizeof(fields_timeout_set_t);

	uint8_t packed[size];
	fields_timeout_set_t *payload = (fields_timeout_set_t*) fill_name_signal(
			CS_CMD_TIMEOUT_SET, 0, NULL, packed);

	// Set payload
	payload->millis = ms;

	DEBUG("Set timeout to %d milliseconds.\n", ms);
	cs_status_t status = write_socket(packed, size);
	if (status != CS_OK) {
		return status;
	}

	return wait_for_ok();
}

cs_status_t cs_read(int signal_count,
		const char *const names[],
		cs_value_t values[]) {

	return send_names_get_values(CS_CMD_READ, signal_count, names, values);
}

cs_status_t cs_write(int signal_count,
		const char *const names[],
		const cs_value_t values[]) {

	cs_status_t status = send_names_values(CS_CMD_WRITE, signal_count, names, values);

	if (status != CS_OK) {
		return status;
	}

	return wait_for_ok();
}


cs_status_t cs_wakeup(const char *const names[]) {
	const cs_value_t value = {CS_TYPE_F64, .arbitration=":arbitration"};
	cs_status_t status = send_names_values(CS_CMD_WRITE, 1, names, &value);

	if (status != CS_OK) {
		return status;
	}

	return wait_for_ok();
}



cs_status_t cs_subscribe(int signal_count, const char *const names[]) {
	size_t size = size_of_name_signals(signal_count, names);

	// Pack data
	uint8_t packed[size];
	fill_name_signal(CS_CMD_SUBSCRIBE, signal_count, names, packed);

	// Write
	cs_status_t status = write_socket(packed, size);
	if (status != CS_OK) {
		return status;
	}

	return wait_for_ok();
}

cs_status_t cs_event_loop(cs_wait_callback_t cb) {
	DEBUG("Starting event loop.\n");

	// Start
	if (request_ok(CS_CMD_SUBSCRIBE_START) != CS_OK) {
		DEBUG("ERROR: Subscription block bad start request.\n");
		return CS_ERROR_BAD_RESPONSE;
	}

	bool loop = true;
	cs_status_t err = CS_OK;
	while (loop) {
		DEBUG("START LOOP.\n");
		if (request_ok(CS_CMD_SUBSCRIBE_CONTINUE) != CS_OK) {
			DEBUG("ERROR: Subscription block bad continue request.\n");
			return CS_ERROR_BAD_RESPONSE;
		}

		// Recieve response
		int read_cb(
				packet_header_t *header,
				uint8_t *payload, size_t payload_size) {

			DEBUG("Received response (%c)! (%d b).\n",
					(char) header->command,
					(int) payload_size);

			switch (header->command) {
				case CS_CMD_SUBSCRIBE_ABORT :
					DEBUG("ERROR: Subscription block closed.\n");
					return CS_ERROR_BAD_RESPONSE;

				case CS_CMD_EVENT :
					DEBUG("Event with %d signals.\n", header->signal_count);
					return (int) send_event_response(header, payload, payload_size, cb);

				case CS_CMD_SUBSCRIBE_TIMEOUT :
					DEBUG("ERROR: Got timeout!\n");
					return CS_ERROR_TIMEOUT;
			}

			DEBUG("ERROR: Not matching subscription response (%c/%d).\n",
					header->command, header->command);

			return CS_ERROR_BAD_RESPONSE;
		}

		DEBUG("Waiting...\n");

		int read_err = read_socket_async(read_cb);
		switch (read_err) {

			// Loop control responses
			case CS_BLOCK_CONTINUE : break; // Continue loop

			case CS_BLOCK_STOP : // Graceful stop
				DEBUG("Closing loop!\n");
				loop = false;
				break;

			// All other error codes, return error
			default :
				DEBUG("Passing error %d.\n", read_err);
				loop = false;
				err = read_err;
				break;
		}
	}

	// Stop
	if (err == CS_OK) {
		if (request_ok(CS_CMD_SUBSCRIBE_STOP) != CS_OK) {
			return CS_ERROR_BAD_RESPONSE;
		}
	}

	return err;
}


//=============================================================================
// LIN bus
//=============================================================================

cs_status_t cs_lin_buses_list(cs_string_t  *names, int *max_name_count) {
	packet_header_t p = make_command(CS_CMD_LIN_BUSES_LIST);

	cs_status_t err = write_socket((const uint8_t*) &p, sizeof(p));
	if (err != CS_OK) {
		return err;
	}

	return receive_names(names, max_name_count);
}

cs_status_t cs_lin_schedules_list(const char *bus, cs_string_t *names, int *max_schedules_count) {

	// Send request
	const char *send_names[*max_schedules_count];
	cs_value_t values[*max_schedules_count];

	send_names[0] = bus;
	size_t size = size_of_name_signals(1, send_names);
	uint8_t packed[size];
	fill_name_signal(CS_CMD_LIN_SCHEDULS_LIST, 1, send_names, packed);
	cs_status_t status = write_socket(packed, size);
	if (status != CS_OK) {
		return status;
	}

	return receive_names(names, max_schedules_count);
}

cs_status_t cs_lin_schedules_set(const char *bus, const char *schedule, int repeat) {

	const cs_value_t values[] = {
		{CS_TYPE_EMPTY},
		{CS_TYPE_I64, .value_i64=repeat},
	};

	const char *names[] = { bus, schedule };

	cs_status_t status = send_names_values(CS_CMD_LIN_SCHEDULS_SET, 2, names, values);
	if (status != CS_OK) {
		return status;
	}

	return wait_for_ok();
}

static cs_status_t lin_start_or_stop(command_t cmd, const char *bus) {
	const char *const arr[] = { bus };
	size_t size = size_of_name_signals(1, arr);

	uint8_t packed[size];
	fill_name_signal(cmd, 1, arr, packed);

	cs_status_t status = write_socket(packed, size);
	if (status != CS_OK) {
		return status;
	}

	return wait_for_ok();
}

cs_status_t cs_lin_start(const char *bus) {
	return lin_start_or_stop(CS_CMD_LIN_START, bus);
}

cs_status_t cs_lin_stop(const char *bus) {
	return lin_start_or_stop(CS_CMD_LIN_STOP, bus);
}



//=============================================================================
// Internal
//=============================================================================

static cs_status_t write_socket(const uint8_t *data, size_t size) {

	// Write data packet size
	uint16_t write_size = htons(size); // Swap byte order for elixir
	if (write(sock, &write_size, 2) != 2) {
		DEBUG("Couldn't write packet size.\n");
		return CS_ERROR_BAD_WRITE;
	}

	// Write packet payload
	if (write(sock, data, size) < size) {
		DEBUG("Couldn't write payload.\n");
		return CS_ERROR_BAD_WRITE;
	}

	fsync(sock);

	return CS_OK;
}

cs_wait_mode_t send_event_response(
		packet_header_t *header, uint8_t *payload, size_t payload_size,
		cs_wait_callback_t cb) {

	const char *names[header->signal_count];
	cs_value_t values[header->signal_count];

	const uint8_t *readptr = payload;
	for (int i=0; i<header->signal_count; i++) {
		signal_name_value_t *head = (signal_name_value_t*) readptr;

		readptr += sizeof(signal_name_value_t);
		const char *name = (const char*) readptr;
		readptr += head->name_len;

		// Write response
		names[i] = name;
		values[i] = head->value;
	}

	return cb(header->signal_count, names, values);
}

/** Async is to keep dynamic stack allocation for reader. */
static int read_socket_async(read_socket_async_t cb) {

	int ret;
	uint16_t packet_size;

	ret = read(sock, &packet_size, 2);
	if (ret <= 0) {
		DEBUG("ERROR: Bad async size read (%d) %d:\"%s\".\n",
				ret, errno, strerror(errno));
		return CS_ERROR_BAD_RESPONSE;
	}

	packet_size = htons(packet_size);

	uint8_t buf[packet_size];
	ret = read(sock, buf, packet_size);
	if (ret <= 0) {
		DEBUG("ERROR: Bad async buffer read (%d).\n", ret);
		return CS_ERROR_BAD_RESPONSE;
	}

	packet_header_t *header = (packet_header_t*) buf;
	uint8_t *payload = (uint8_t*) (header+1);
	size_t payload_size = packet_size - sizeof(packet_header_t);

	return cb(header, payload, payload_size);
}

static cs_status_t wait_for_ok(void) {
	int read_cb(
			packet_header_t *header,
			uint8_t *payload, size_t payload_size) {

#ifdef CS_DEBUG
		if (header->command != CS_CMD_OK) {
			DEBUG("ERROR: Not an OK ('%c' / %.2x) (%d b).\n", 
					(int) header->command,
					(int) header->command,
					(int) payload_size);
			return CS_ERROR_BAD_RESPONSE;
		}
#endif

		return header->command == CS_CMD_OK ? CS_OK : CS_ERROR_BAD_RESPONSE;
	}

	return (cs_status_t) read_socket_async(read_cb);
}

static size_t size_of_name_signals(int signal_count,
		const char *const names[]) {

	size_t size = sizeof(packet_header_t);

	for (int i=0; i<signal_count; i++) {
		size += sizeof(signal_name_t);
		size += strlen(names[i]) + 1; // Length + 0-termination
	}

	return size;
}

static size_t size_of_name_value_signals(int signal_count,
		const char *const names[]) {

	size_t size = sizeof(packet_header_t);

	for (int i=0; i<signal_count; i++) {
		size += sizeof(signal_name_value_t);
		size += strlen(names[i]) + 1; // Length + 0-termination
	}

	return size;
}

static uint8_t *fill_name_signal(
		command_t cmd, int signal_count,
		const char *const names[], uint8_t *ptr) {

	// Pack header
	packet_header_t *header = (packet_header_t*) ptr;
	header->version = CS_PROTOCOL_VERSION;
	header->command = cmd;
	header->signal_count = signal_count;
	ptr += sizeof(packet_header_t);

	// Pack signals
	for (int i=0; i<signal_count; i++) {
		size_t name_len = strlen(names[i]) + 1; // Length + 0-termination

		signal_name_t *sig_header = (signal_name_t*) ptr;
		sig_header->name_len = name_len;
		ptr += sizeof(signal_name_t);

		memcpy(ptr, names[i], name_len);
		ptr += name_len;
	}

	return ptr;
}

static uint8_t *fill_header(command_t cmd, uint8_t signal_count, uint8_t *dst) {
	packet_header_t *header = (packet_header_t*) dst;
	header->version = CS_PROTOCOL_VERSION;
	header->command = cmd;
	header->signal_count = signal_count;

	return dst + sizeof(packet_header_t);
}

static cs_status_t request_ok(command_t cmd) {
	packet_header_t packet = make_command(cmd);
	write_socket((const uint8_t*) &packet, sizeof(packet));

	return wait_for_ok();
}

static packet_header_t make_command(command_t cmd) {
	return (packet_header_t) {
		.version = CS_PROTOCOL_VERSION,
		.command = (uint8_t) cmd,
		.signal_count = 0,
	};
}

static cs_status_t receive_names(cs_string_t *names, int *max_names) {

	int read_cb(
			packet_header_t *header,
			uint8_t *payload, size_t payload_size) {

		if (header->command != CS_CMD_NAMES) {
			return CS_ERROR_BAD_RESPONSE;
		}

		//DEBUG("GET NAMES x [%d, %d].\n", header->signal_count, payload_size);
		const uint8_t *readptr = payload;
		if (header->signal_count < *max_names) {
			*max_names = header->signal_count;
		}

		for (int i=0; i<*max_names; i++) {
			int len = *readptr++;
			strncpy(names[i], readptr, len);
			readptr += len;

			DEBUG("NAME %d \"%s\".\n", i, names[i]);
		}

		DEBUG("GET NAMES 3 [%d].\n", *max_names);
		return CS_OK;
	}

	return read_socket_async(read_cb);
}

static cs_status_t send_names(cs_string_t *names, int *max_names) {
}

static cs_status_t send_names_get_values(command_t cmd, int signal_count,
		const char *const names[], cs_value_t values[]) {

	size_t size = size_of_name_signals(signal_count, names);

	// Pack data
	uint8_t packed[size];
	fill_name_signal(CS_CMD_READ, signal_count, names, packed);

	// Write
	cs_status_t status = write_socket(packed, size);
	if (status != CS_OK) {
		return status;
	}

	// Get response
	int read_cb(
			packet_header_t *header,
			uint8_t *payload, size_t payload_size) {

		if (
				header->command != CS_CMD_WRITE ||
				header->signal_count != signal_count) {
			DEBUG("Not matching response.\n");
			return CS_ERROR_BAD_RESPONSE;
		}

		const uint8_t *readptr = payload;
		for (int i=0; i<header->signal_count; i++) {
			signal_name_value_t *head = (signal_name_value_t*) readptr;

			readptr += sizeof(signal_name_value_t);
			//const char *name = (const char*) readptr;
			readptr += head->name_len;

			// Check name matching
			//if (strncmp(name, names[i], 200) != 0) {
			//	DEBUG("Name not matching [%d].\n", i);
			//	return CS_ERROR_BAD_RESPONSE;
			//}

			// Write response
			values[i] = head->value;
		}

		return CS_OK;
	}

	return read_socket_async(read_cb);
}

static cs_status_t send_names_values(
		command_t cmd, int signal_count,
		const char *const names[], const cs_value_t values[])
{
	size_t size = size_of_name_value_signals(signal_count, names);

	// Pack data
	uint8_t packed[size];
	//uint8_t *ptr = packed;
	uint8_t *ptr = fill_header(cmd, signal_count, packed);

	// Pack signals
	for (int i=0; i<signal_count; i++) {
		size_t name_len = strlen(names[i]) + 1; // Length + 0-termination

		signal_name_value_t *sig_header = (signal_name_value_t*) ptr;
		sig_header->name_len = name_len;
		sig_header->value = values[i];
		ptr += sizeof(signal_name_value_t);

		memcpy(ptr, names[i], name_len);
		ptr[name_len] = '\0';
		ptr += name_len;
	}

	// Write
	return write_socket(packed, size);
}


#else
#include "fake_mode.c"
#endif


/*!
 * @file csunixds.in.h
 * @breif Core system unix domain socket C-API.
 *
 * \section section_namespace_format Name space formating
 * When specifying names of signals, it's possible to provide name space
 * information in the name. If no name space is given, the default name space
 * will be assumed to be used. For the purpose of being able to send or read
 * signals across multiple name spaces in a single call. Functions that use
 * name space formating is listed in the See also part of this section.
 *
 * Formating signal names are done with the following syntax:
 * ```
 * namespace:signal
 * ```
 *
 * For example, lets say we want to specify a signal named \c sig on the name
 * space \c ns:
 * ```
 * ns:sig
 * ```
 *
 * Lets see this in action with an example using \ref cs_write.
 * ```c
 * const char *sig_name[] = {
 * 	"broker0:signal0",
 * 	"broker1:signal1",
 * 	"broker2:signal2",
 * };
 * const cs_value_t sig_value[] = {
 * 	{ CS_TYPE_F64, .value_f64=0.0 },
 * 	{ CS_TYPE_F64, .value_f64=1.0 },
 * 	{ CS_TYPE_F64, .value_f64=2.0 },
 * };
 *
 * assert(cs_write(3, sig_name, sig_value) == CS_OK);
 * ```
 * The \ref cs_write call will write the following values on different signals
 * and name spaces:
 * | Name space   | Signal name   | Value      |
 * |--------------|---------------|------------|
 * | broker0      | signal0       | \c 0.0     |
 * | broker1      | signal1       | \c 1.0     |
 * | broker2      | signal2       | \c 2.0     |
 * \sa cs_read cs_write cs_subscribe
 */
#pragma once
#include <stdint.h>

/*! \defgroup group_error_codes General information
 * \brief Version, status and error codes.
 * @{
 */

/// Build flag for fake I/O.
#cmakedefine CS_FAKE_IO
/// Build flag for debug mode with extra verbosity
#cmakedefine CS_DEBUG
/// Expands to protocol version used to communicate with server.
#define CS_PROTOCOL_VERSION @CS_PROTOCOL_VERSION@
/*!
 * Expands to current library version as string.
 * Based on the current git build.
 * For example: "v0.2-19-gee65627".
 */
#define CS_VERSION_STR "@CS_VERSION_STR@"
/// Expands to directory to store Unix domain socket.
#define CS_SOCK_DIR "@CS_SOCK_DIR@"
/// Expands to name of Unix domain socket file in directory CS_SOCK_DIR.
#define CS_SOCK_NAME "@CS_SOCK_NAME@"

/// Type for fixed size strings
typedef char cs_string_t[20];

/*!
 * Command status responses. All API-commands will return one of these.
 */
typedef enum {
	CS_OK,					/**< Success. */
	CS_ERROR_NO_CONNECTION,	/**< No Unix Domain Socket connection. */
	CS_ERROR_BAD_WRITE,		/**< Invalid data packaging. */
	CS_ERROR_BAD_RESPONSE,	/**< Unexpected response. */
	CS_ERROR_TIMEOUT,		/**< Command timed out. */
} cs_status_t;

/// Event callback blocking command.
typedef enum {
	CS_BLOCK_CONTINUE,		/**< Continue blocking for another iteration. */
	CS_BLOCK_STOP,			/**< Stop blocking after this iteration. */
} cs_wait_mode_t;

/*!
 * Value types identifier.
 */
typedef enum {
	CS_TYPE_EMPTY = 0,		/**< No value has been written yet. */
	CS_TYPE_F64 = 1,		/**< C type double. */
	CS_TYPE_I64 = 2,		/**< C type int64_t. */
} cs_type_t;

/*! @} */

/*! \defgroup group_init_terminate Initialize and terminate
 * \brief Must be executed before any other operations.
 * @{
 */

/*!
 * Start connection to server.
 * @param[in] source Name space to be used for library user. \c NULL is
 * accepted and will mean that a random namespace is to be generated.
 * @return \ref CS_OK on successful connection, \ref CS_ERROR_NO_CONNECTION
 * when no connection.
 */
cs_status_t cs_initialize(const char *source);
/*!
 * Shutdown active connection.
 * @return Always CS_OK.
 */
cs_status_t cs_shutdown(void);

/*! @} */

/*! \defgroup group_timeout Timeout
 * \brief Set timeout on blocking functions.
 * @{
 */

/*!
 * Specify timeout for cs_event_loop calls. If no signals have been collected
 * before \p ms milliseconds, cs_event_loop will return CS_ERROR_TIMEOUT.
 * @param ms Timeout in milliseconds. 0 means disabled.
 */
cs_status_t cs_set_timeout(int32_t ms);

/*! @} */

/*! \defgroup group_read_write Read and write
 * \brief Access signals and their values.
 * @{
 */

typedef struct __attribute__((packed)) {
	uint8_t type;			/**< Is an identifier from cs_type_t */
	union {
		double value_f64;	/**< Value used when type is CS_TYPE_F64 */
		int64_t value_i64;	/**< Value used when type is CS_TYPE_I64 */
		const char * arbitration;
	};
} cs_value_t;
///< Value storage type for all types.

/*!
 * Callback for cs_event_loop. Triggers when changes have occured on subscribed
 * signals.
 * @param signal_count Amount of values being reported in this iteration.
 * @param names List of names of reported signals.
 * @param values List of values of reported signals.
 * @return CS_BLOCK_CONTINUE to remain listening for changes, CS_BLOCK_STOP to
 * return cs_event_loop.
 */
typedef cs_wait_mode_t (*cs_wait_callback_t) (
		int signal_count, const char *const names[], const cs_value_t values[]);

/*!
 * Synchronous read operation. Will read \p signal_count signals with names
 * from \p names. Upon successful read, values will be stored in values. Signal
 * naming follows \ref section_namespace_format.
 * @param signal_count Amount of signals to be read.
 * @param[out] names Array with \p signal_count elements, containing signal names.
 * @param[in] values Array with \p signal_count elements. Results will be stored here.
 */
cs_status_t cs_read(int signal_count, const char *const names[], cs_value_t values[]);
/*!
 * Synchronous write operation. Writes \p signal_count signals with names \p
 * names and values \p values. Signal naming follows \ref
 * section_namespace_format.
 * @param signal_count Amount of signals to be written.
 * @param[out] names Array with \p signal_count elements, containing signal
 * names.
 * @param[out] values Array with \p signal_count elements. These values are to
 * be written.
 */
cs_status_t cs_write(int signal_count, const char *const names[],
		const cs_value_t values[]);


cs_status_t cs_wakeup(const char *const names[]);

/*!
 * Tells the system what signals are to be subscribed to. Executing this will
 * clear all previous subscriptions. This function doesn't actually start any
 * subscription. To start a subscription, execute \ref cs_event_loop. Signal
 * naming follows \ref section_namespace_format.
 * @param signal_count Amount of signals to subscribed to.
 * @param[out] names Array with \p signal_count elements. Name of signals to be
 * subscribed to.
 * @sa cs_event_loop
 */
cs_status_t cs_subscribe(int signal_count, const char *const names[]);
/*!
 * Starts a blocking operation that listens for changes on subscribed signals.
 * Before this function runs. Make sure \ref cs_subscribe is called. To enable
 * timeout on this call, run \ref cs_set_timeout.
 */
cs_status_t cs_event_loop(cs_wait_callback_t cb);

/*! @} */


/*! \defgroup group_lin LIN bus
 *
 * \brief Local Interconnect Network, functions.
 *
 * \subsection lin_string_len String limitations
 * There are limitations of using LIN functions with string arrays as
 * parameters. The expected maximum size of of string in the array is \c
 * CS_LIN_STRING_MAX_LEN. Which means, if a function is suppose to write data
 * into an string array, each string in that array must have at least that \c
 * CS_LIN_STRING_MAX_LEN allocated.
 * @{
 */

#define CS_LIN_STRING_MAX_LEN (20)

/*!
 * Get names of all available LIN buses.
 * @param[out] names Array of strings to write result in. Read \ref
 * lin_string_len for requirements.
 * @param[in,out] max_name_count Maximum allowed elements to write in \p names.
 */
cs_status_t cs_lin_buses_list(cs_string_t *names, int *max_name_count);
/*!
 * List available schedules of bus \p bus.
 * @param[out] bus Name of bus to query.
 * @param[in,out] names Array to write result in. Read \ref lin_string_len for
 * requirements.
 * @param max_schedules_count Max elements in \p names.
 */
cs_status_t cs_lin_schedules_list(const char *bus, cs_string_t *names,
		int *max_schedules_count);
/*!
 * Set current scheduler.
 * @param[out] bus Name of bus to query.
 * @param[out] schedule Name of scheduler to activate.
 * @param repeat Amount of times the scheduler should run. 0 means repeat
 * forever.
 */
cs_status_t cs_lin_schedules_set(const char *bus, const char *schedule, int repeat);
/*!
 * Activate I/O operations of bus.
 * @param[out] bus Name of bus to activate.
 */
cs_status_t cs_lin_start(const char *bus);
/*!
 * Deactivate I/O operations of bus.
 * @param[out] bus Name of bus to deactivate.
 */
cs_status_t cs_lin_stop(const char *bus);

/*! @} */

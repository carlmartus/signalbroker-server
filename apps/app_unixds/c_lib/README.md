**Copyright 2017-2018 Volvo Car Corporation**.

This library is a C-API interface to the *PE* (Prototype Environment).
**Version: $(PROJECT_NUMBER)**.
Formerly known as *CSP* (Core System PoC).
Primarily the library is meant as a interface for exported [Matlab Simulink](https://www.mathworks.com/products/simulink.html) models.

The library contains functionality for reading and writing signals.
As well as listening for changes on signals and retrieving the updated values.
Furthermore a timeout operation is available to prevent listening from blocking indefinitely.

# Getting started
Binaries for this library are compiled as part of the PE project pipeline.
And can be found on the following links in a few variations:

 * [Intel](https://ci2.artifactory.cm.volvocars.biz/artifactory/ARTCSP/csp/signalbroker/intel/signal_server_c_api/) - Desktop x64 computers.
 * [ARM](https://ci2.artifactory.cm.volvocars.biz/artifactory/ARTCSP/csp/signalbroker/arm/signal_server_c_api/) - Raspberry PI 2/3.

The binaries consists of a version stamped header file *csunixds.h*.
And a static library *libcsunixds.a*.

## Development prerequisites
[CMake](https://cmake.org/) is used to setup an compilation environment.
To compile the library locally, make sure you have CMake installed:
```
apt-get install cmake
```

## Installing
Put the header file *csunixds.h* and the static library *libcsunixds.a* somewhere where your compilation environment can find it.

For example:
 * `/usr/local/include/csunixds.h`
 * `/usr/local/lib/libcsunixds.a`

# Documentation
Use the menus in *Doxygen* to navigate the documentation.
Or click here: @ref `csunixds.in.h` to go to documentation.

The functions available in `csunixds.h` are grouped into sub sections.
Click the button *Modules* on the navigation bar to view them.

Make sure to understand the name space formating of signal names in this section: \ref section_namespace_format.

To get proper troubleshooting during development.
Make sure to print out the version string for the library @ref CS_VERSION_STR.
Additionally check the return code for all function calls.
All functions return a @ref cs_status_t.

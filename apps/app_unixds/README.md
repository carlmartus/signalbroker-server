# UnixDS
C-API using a Unix domain socket to communicate with the signal broker.

Documentation for the C-API is compilable with [Doxygen](http://doxygen.org/).
To generate the documentation make sure you have doxygen installed.
Then run the script:
```
cd c_lib
./doxygen.sh
```

## Native library
The source is found in the sub directory `c_lib`.
By default the project is set to compile a static library.

To explicitly compile a static library:
```
cmake -D CS_LIBRARY_TYPE:STRING=STATIC <source path>
```
Outputs a `.a` archive.

Explicitly compile a shared library:
```
cmake -D CS_LIBRARY_TYPE:STRING=SHARED <source path>
```
Outputs a `.so` library.

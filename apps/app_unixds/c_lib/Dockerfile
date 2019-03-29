FROM sdthirlwall/raspberry-pi-cross-compiler:jessie

RUN apt-get update && apt-get install -y cmake && mkdir -p /tmp/libcsunixds/build/
WORKDIR /tmp/libcsunixds/build/
COPY *.* /tmp/libcsunixds/
RUN cmake -D CMAKE_C_FLAGS="-Wall -std=gnu11" .. && make && make install
WORKDIR /build/

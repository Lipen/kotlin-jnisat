ARG PROJECT_DIR=/kotlin-jnisat
ARG MINISAT_DIR=/minisat
ARG CADICAL_DIR=/cadical

FROM openjdk:8 as builder
ARG PROJECT_DIR
ARG MINISAT_DIR
ARG CADICAL_DIR

ENV PROJECT_DIR=${PROJECT_DIR}
ENV MINISAT_DIR=${MINISAT_DIR}
ENV CADICAL_DIR=${CADICAL_DIR}

RUN apt-get update &&\
    apt-get install --no-install-recommends -y \
        build-essential \
        gcc \
        git \
        zlib1g-dev \
    &&\
    rm -rf /var/lib/apt/lists/*

## Build libminisat
WORKDIR ${MINISAT_DIR}
RUN git clone https://github.com/niklasso/minisat .
RUN make lsh MINISAT_REL='-O3 -DNDEBUG -fpermissive'
RUN make install

## Build libcadical
WORKDIR ${CADICAL_DIR}
RUN git clone https://github.com/arminbiere/cadical .
COPY cadical-shared-lib.patch .
RUN git apply cadical-shared-lib.patch
RUN ./configure -j8 -fPIC CXXFLAGS="-s"
RUN make lsh
RUN install -d /usr/local/include/cadical
RUN install -m 644 src/cadical.hpp /usr/local/include/cadical
RUN install -d /usr/local/lib
RUN install -m 644 build/libcadical.so /usr/local/lib

## Build libs
WORKDIR ${PROJECT_DIR}
COPY . .
# Note: 'make headers' must be executed outside
RUN make libs

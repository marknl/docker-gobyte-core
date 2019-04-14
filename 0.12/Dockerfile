# Build stage for BerkeleyDB
FROM alpine as berkeleydb

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
  autoconf automake build-base libressl

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j4
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

# Build stage for GoByte Core
FROM alpine as gobyte-core

COPY --from=berkeleydb /opt /opt

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
  autoconf automake boost-dev build-base chrpath \
  file gnupg libevent-dev libressl libressl-dev \
  libtool linux-headers protobuf-dev zeromq-dev

ENV GOBYTE_VERSION=0.12.2.4
ENV GOBYTE_PREFIX=/opt/gobyte-${GOBYTE_VERSION}

RUN wget https://github.com/gobytecoin/gobyte/archive/v${GOBYTE_VERSION}.tar.gz
RUN tar -xzf *.tar.gz

WORKDIR /gobyte-${GOBYTE_VERSION}

RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
RUN sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1/configure.ac
RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h
RUN ./autogen.sh
RUN ./configure LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
    --prefix=${GOBYTE_PREFIX} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
    --with-libs \
    --with-daemon
RUN make -j4
RUN make install
RUN strip ${GOBYTE_PREFIX}/bin/gobyte-cli
RUN strip ${GOBYTE_PREFIX}/bin/gobyte-tx
RUN strip ${GOBYTE_PREFIX}/bin/gobyted
RUN strip ${GOBYTE_PREFIX}/lib/libgobyteconsensus.a
RUN strip ${GOBYTE_PREFIX}/lib/libgobyteconsensus.so.0.0.0

# Build stage for compiled artifacts
FROM alpine

LABEL maintainer="Mark Stunnenberg (mark.stunnenberg@gmail.com)" \
      version="1.0"

RUN adduser -S gobyte
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
  boost boost-program_options \
  libevent libressl libzmq su-exec

ENV GOBYTE_DATA=/home/gobyte/.gobytecore
ENV GOBYTE_VERSION=0.12.2.4
ENV GOBYTE_PREFIX=/opt/gobyte-${GOBYTE_VERSION}
ENV PATH=${GOBYTE_PREFIX}/bin:$PATH

COPY --from=gobyte-core /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/gobyte/.gobytecore"]

EXPOSE 12454 12455 13454 13455

ENTRYPOINT ["/entrypoint.sh"]

CMD ["gobyted"]

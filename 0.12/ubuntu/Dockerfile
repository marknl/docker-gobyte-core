FROM ubuntu:bionic as berkeleydb

RUN apt-get -y update \
 && apt-get -y install \
    build-essential \
    autotools-dev \
    automake \
    libssl-dev \
    wget

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -zxf *.tar.gz
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j4
RUN make install
RUN rm -rf ${BERKEYLEYDB_PREFIX}/docs

FROM ubuntu:bionic as gobyte-core

COPY --from=berkeleydb /opt /opt

RUN apt-get -y update \
 && apt-get -y install \
    build-essential libtool autotools-dev automake pkg-config \
    libboost-all-dev libssl-dev libevent-dev bsdmainutils libzmq3-dev wget 

ENV GOBYTE_VERSION=0.12.2.4
ENV GOBYTE_PREFIX=/opt/gobyte-${GOBYTE_VERSION}

RUN wget https://github.com/gobytecoin/gobyte/archive/v${GOBYTE_VERSION}.tar.gz
RUN tar -zxf *.tar.gz

WORKDIR /gobyte-${GOBYTE_VERSION}

RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
RUN sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1/configure.ac
RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h
RUN ./autogen.sh
RUN ./configure LDFLAGS=-L`ls -d /opt/db*`/lib CPPFLAGS=-I`ls -d /opt/db*`/include/ \
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

FROM ubuntu:bionic

LABEL maintainer="Mark Stunnenberg (mark.stunnenberg@gmail.com)" \
      version="1.0"

RUN useradd -r gobyte \
 && apt-get -y update \
 && apt-get -y install gosu openssl libzmq5 \
    libboost-system1.65.1 libboost-thread1.65.1 \
    libboost-chrono1.65.1 libboost-filesystem1.65.1 \
    libboost-program-options1.65.1 libevent-pthreads-2.1-6 \
    libevent-2.1-6 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV GOBYTE_DATA=/home/gobyte/.gobytecore
ENV GOBYTE_VERSION=0.12.2.4
ENV GOBYTE_PREFIX=/opt/gobyte-${GOBYTE_VERSION}
ENV PATH=${GOBYTE_PREFIX}/bin:$PATH

COPY --from=gobyte-core /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/gobyte/.gobytecoin"]

EXPOSE 12455 12454 13455 13454

ENTRYPOINT ["/entrypoint.sh"]

CMD ["gobyted"]

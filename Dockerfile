FROM ubuntu:18.04

################################################################################
# Ubuntu install dependencies
RUN apt-get update && apt-get upgrade -y

# To build redis
RUN apt-get install wget gcc libc6-dev make vim -y

################################################################################
# Install Redis
RUN mkdir -p /tmp/redis-stable

COPY build-files/redis-stable.tar.gz /tmp/redis-stable/

RUN cd /tmp/redis-stable && \
    tar xzvf redis-stable.tar.gz --strip 1 && \
    make && \
    make install

RUN mkdir /etc/redis && \
    cp /tmp/redis-stable/redis.conf /etc/redis

# Clean up
RUN rm -rf /tmp/*

################################################################################
# Copy Redis setup

COPY build-files/redis /redis
COPY build-files/generate_redis_data.sh /redis/generate_redis_data.sh

RUN chmod a+x /redis/master-slave/run-master-slave.sh && \
    chmod a+x /redis/cluster/run-cluster.sh && \
    chmod a+x /redis/generate_redis_data.sh

COPY build-files/redis.sh /etc/init.d/redis.sh

RUN chmod a+x /etc/init.d/redis.sh

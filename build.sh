#!/bin/sh

if [ ! -f "build-files/redis-stable.tar.gz" ]; then
  wget -O build-files/redis-stable.tar.gz http://download.redis.io/releases/redis-5.0.0.tar.gz
fi

docker build . -t redis:5.0.0

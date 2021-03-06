#!/bin/sh

docker run \
       --rm \
       -it \
       -v $PWD/export:/export \
       -p 8600:6000 \
       -p 8601:6001 \
       -p 8700:7000 \
       -p 8701:7001 \
       -p 8702:7002 \
       -p 8703:7003 \
       -p 8704:7004 \
       -p 8705:7005 \
       -p 8706:7006 \
       -p 8707:7007 \
       redis:5.0.0 /bin/bash

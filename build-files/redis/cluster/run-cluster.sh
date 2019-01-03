#!/bin/sh
REALPATH="$(realpath $0)"
BASEDIR="$(dirname ${REALPATH})"

OLD_PWD="$(pwd)"

cd "${BASEDIR}"

for node in $(ls -d */); do
  cd $node
  redis-server redis.conf > /dev/null &
  cd ..
done

cd "${OLD_PWD}"

echo "Wait 5 secondes to all cluster instances start"

count=1
while [ $count -lt 5 ]
do
  sleep 1
  echo -n "."
  count=`expr $count + 1`
done

redis-cli --cluster create 127.0.0.1:7000 127.0.0.1:7001 \
  127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 \
  --cluster-replicas 1

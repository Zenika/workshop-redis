#!/bin/sh

echo "Starting redis master..."
redis-server /redis/master-slave/master/redis_master.cfg &
echo "Starting redis slave..."
redis-server /redis/master-slave/slave/redis_slave.cfg &

echo "Starting redis sentinels..."
redis-sentinel /redis/master-slave/sentinel/redis_sentinel_1.cfg &
redis-sentinel /redis/master-slave/sentinel/redis_sentinel_2.cfg &
redis-sentinel /redis/master-slave/sentinel/redis_sentinel_3.cfg &

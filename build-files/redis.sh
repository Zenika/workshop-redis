#!/bin/sh -e

REDIS_MODE="master-slave | cluster"
REDIS_MASTER_SLAVE_SCRIPT="/redis/master-slave/run-master-slave.sh"
REDIS_MASTER_CLUSTER_SCRIPT="/redis/cluster/run-cluster.sh"

log_error() {
  echo "[ERROR] $@" >&2
}

start_redis() {
  if [ $# -eq 1 ]; then
    case "$1" in
      master-slave)
        ${REDIS_MASTER_SLAVE_SCRIPT};;
      cluster)
        ${REDIS_MASTER_CLUSTER_SCRIPT};;
      *)
        log_error "'$1' unknow mode, must be in: ${REDIS_MODE}"
        exit 1;;
    esac
  else
    log_error "Usage: $0 start [ ${REDIS_MODE} ]"
  fi
}

stop_redis() {
  echo "Shutdown all Redis instance..."

  for node_pid_file in $(find /redis/ -name '*.pid'); do
    node_pid=$(cat $node_pid_file)

    echo "Stop pid: ${node_pid}"

    kill -s stop $node_pid_file
  done
}

case "$1" in
  start)
    shift
    start_redis $@;;

  stop)
    stop_redis;;

  *)
    log_error "Usage: $0 start | stop"
    exit 1;;
esac

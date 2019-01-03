#!/bin/sh

random() {
  # bash generate random 32 character alphanumeric string (lowercase only)
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
}

log_error() {
  echo "[ERROR] $@" >&2
}

REDIS_MODE="master-slave | cluster"
REDIS_PATAMETERS=""

if [ $# -eq 1 ]; then
  case "$1" in
    master-slave) REDIS_PATAMETERS="-p 6000";;
    cluster) REDIS_PATAMETERS="-p 7000 -c";;
    *)
      log_error "'$1' unknow mode, must be in: ${REDIS_MODE}"
      exit 1;;
  esac
else
  log_error "Usage: $0 [ ${REDIS_MODE} ]"
  exit 1
fi

counter=0
max=100

while [ $counter -lt ${max} ]; do
  redis-cli ${REDIS_PATAMETERS} set $(random) $counter > /dev/null
  counter=$(expr ${counter} + 1)

  echo ${counter}/${max}
done

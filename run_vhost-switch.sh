#!/bin/bash

ROOT_DIR=$(dirname $0)
DPDK_BIN_PATH=/home/haizhi/downland/dpdk.org/dpdk/build/examples
VHOST_USER_PATH=/var/run/vhost-user-sock0
PCIEID=0000:0b:00.0
#PCIEID=0000:03:00.0

#${DPDK_BIN_PATH}/dpdk-vhost -l 4-7 --log-level 8 -a ${PCIEID} --no-telemetry --file-prefix vhost -- --socket-file ${VHOST_USER_PATH} --client -p 0x1 --stats 20	
${DPDK_BIN_PATH}/dpdk-vhost -l 4-7 --socket-mem 256 --log-level 8 -a ${PCIEID} --no-telemetry -- --socket-file ${VHOST_USER_PATH} --client -p 0x1 --stats 2000	

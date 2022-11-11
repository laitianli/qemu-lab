#!/bin/bash
NIC_NAME=ens192
PCIEID=0000:0b:00.0
echo 512 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
modprobe uio

insmod /home/haizhi/downland/dpdk.org/dpdk-kmods/linux/igb_uio/igb_uio.ko

ip link set dev ${NIC_NAME} down
dpdk-devbind.py -b igb_uio ${PCIEID}

#ip link set dev ens160 down
#dpdk-devbind.py -b igb_uio 0000:03:00.0


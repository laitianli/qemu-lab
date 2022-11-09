#!/bin/bash
INDEX=$1
ROOT_DIR=$(dirname $0)
ROOT_DIR=/home/haizhi/qemu-lab
#KERNEL_IMG=${ROOT_DIR}/bin_kernel/initramfs_bzImage
KERNEL_IMG=${ROOT_DIR}/bin_kernel/bzImage
#QEME_BIN=qemu-system-x86_64
#QEME_BIN=${ROOT_DIR}/qemu-2.11.0/x86_64-softmmu/qemu-system-x86_64
QEME_BIN=/usr/libexec/qemu-kvm
#QEME_BIN=gdb --args ${ROOT_DIR}/qemu-2.11.0/x86_64-softmmu/qemu-system-x86_64
init()
{
	ifconfig -a | grep -w br0
	if [ $? -eq 1 ];then
		echo "brctl addbr br0"	
		brctl addbr br0;
		ifconfig br0 up;
	fi
#	echo "ip tuntap add tap01 mode tap"
}
#
#	${QEME_BIN} -m 1024 \
#		-smp 4	\
#		-enable-kvm \
#		-netdev type=tap,script=${SCRIPT_PATH},downscript=no,id=net0 \
#		-device virtio-net-pci,netdev=net0,mac=${MAC} \
#		-drive file=${QCOW2_IMG_PATH},if=none,id=drive-virtio-disk0,format=qcow2,cache=writeback \
#		-device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x6,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 \
#		-kernel ${KERNEL_IMG} -append "console=ttyS0,115200 index=${index}" \
#		-nographic  -vnc :1 

run_qemu()
{
	index=$1
	MAC=00:11:22:33:44:A${index}
	QCOW2_IMG_PATH=${ROOT_DIR}/disk_img/qcow2.x86_${index}.img
	RAW_IMG_PATH=${ROOT_DIR}/disk_img/raw.x86_${index}.img
	SCRIPT_PATH=${ROOT_DIR}/script/qemu-ifup

	${QEME_BIN} -m 1024 \
		-smp 4	\
		-enable-kvm \
		-netdev type=tap,script=${SCRIPT_PATH},downscript=no,id=net0 \
		-device virtio-net-pci,netdev=net0,mac=${MAC} \
		-drive file=${QCOW2_IMG_PATH},if=none,id=drive-virtio-disk0,format=qcow2,cache=writeback \
		-device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x6,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 \
		-kernel ${KERNEL_IMG} -append "root=/dev/vda rootfstype=ext4 rw init=/bin/bash console=ttyS0,115200 index=${index}" \
		-nographic  -vnc :1 
}

check_argument()
{
	if [ "${INDEX}" == "" ];then
		echo "argument: INDEX is NULL!!!"
		exit -1
	else
		echo "argument: INDEX = ${INDEX}"
	fi
}

main()
{
	check_argument;
	init;
	run_qemu ${INDEX};
}

main;

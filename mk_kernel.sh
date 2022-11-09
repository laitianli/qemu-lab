#!/bin/bash
ROOT_DIR=`pwd`
KERNEL_DIR=$1
KERNEL=$2
KERNEL_OBJ=obj_${KERNEL}
#INITRAMFS=initramfs_
CONFIG=x86_64_${INITRAMFS}defconfig
KERNEL_PATH=/${KERNEL_DIR}/${KERNEL}
KERNEL_OBJ_PATH=${ROOT_DIR}/${KERNEL}/obj_${KERNEL}
BIN_PATH=${ROOT_DIR}/bin_kernel/

check_argument()
{
	if [ "$1" == "" ];then
		echo "[Error]argument is null!"
		return 0;
	fi

	return 1;
}

check_dir()
{
	DIR=$1
	if [ -d ${KERNEL_DIR}/${DIR} ];then
		echo "directory: "${KERNEaL_DIR}/${DIR}" exist."
		return 1;
	else
		echo "directory: "${KERNEL_DIR}/${DIR}" dones not exist.";
		return 0;
	fi	
}


build_kernel()
{
	echo "begin build kernel,config:${CONFIG}..."	
	cd ${KERNEL_PATH} && make distclean && make ${CONFIG} O=${KERNEL_OBJ_PATH};
	cd ${KERNEL_OBJ_PATH} && make bzImage -j3 ;
	cd ${ROOT_DIR}
}

install_kernel()
{
	if [ ! -d ${BIN_PATH} ];then
		echo "[Warning] ${BIN_PATH} does not exist, so mkdir it!"
		mkdir -p ${BIN_PATH}
	fi
	cp ${KERNEL_OBJ_PATH}/arch/x86/boot/bzImage ${BIN_PATH}/${INITRAMFS}bzImage

	echo "[Note] install [ ${BIN_PATH}/${INITRAMFS}bzImage ] success." 
}

main()
{
	check_argument ${KERNEL};
	if [ $? -eq 0 ];then
		echo "[Error] check_argument failed!"
		exit -1;
	fi

	check_dir ${KERNEL};
	if [ $? -eq 0 ];then
		echo "[Error] check directory failed!"
		exit -1;
	fi

	check_dir ${KERNEL_OBJ};
	if [ $? -eq 0 ];then
		echo "[Warning] ${KERNEL_OBJ} does not exist, so mkdir it!"
		mkdir -p ${ROOT_DIR}/${KERNEL}/${KERNEL_OBJ}
	fi

	build_kernel;	

	install_kernel;
}

main;

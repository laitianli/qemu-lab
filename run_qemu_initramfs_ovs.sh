#!/bin/bash
INDEX=$1
ROOT_DIR=`pwd`
KERNEL_IMG=${ROOT_DIR}/kernel/bin_kernel/initramfs_bzImage
OVS_BR=ovs-br0
OVS_IP="2.2.2.1"
CONF_DB="/usr/local/etc/openvswitch/conf.db"
ovs_var_run=/usr/local/var/run/openvswitch
ovs_var_log=/usr/local/var/log/openvswitch

init_ovs()
{
	if [ ! -d ${ovs_var_run} ];then
		mkdir -p ${ovs_var_run}
	fi
	if [ ! -d ${ovs_var_log} ];then
		mkdir -p ${ovs_var_log}
	fi
	if [ ! -f ${CONF_DB} ];then
		ovsdb-tool create
	fi
}

init_mod()
{
	mod_file=/lib/modules/`uname -r`/kernel/net/openvswitch/openvswitch.ko;
	openvswitch=`lsmod | awk '{if($1~/openvswitch/)print $1}'`;
	if [ "${openvswitch}" == "" ];then
		if [ -f ${mod_file} ];then
			echo "[Note]==insmod ${mod_file}==="
		#	insmod ${mod_file};
			modprobe openvswitch
		else
			echo "[Error] please build openvswitch.ko modules!!(${mod_file})";
			exit -1;
		fi
	else
		echo "[Note] ${mod_file} has insmod at os."
	fi
}

run_ovsdb-server()
{	
	ovsdb-server ${CONF_DB} \
		--remote=punix:${ovs_var_run}/db.sock  \
		--private-key=db:Open_vSwitch,SSL,private_key  \
		--certificate=db:Open_vSwitch,SSL,certificate   \
		--bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert  \
		--no-chdir  \
		--log-file=${ovs_var_log}/ovsdb-server.log  \
		--pidfile=${ovs_var_run}/ovsdb-server.pid  \
		--unixctl=${ovs_var_run}/ovsdb-server.ctl  \
		--detach  \
		--monitor
}

run_ovs-vswitchd()
{
	ovs-vswitchd unix:${ovs_var_run}/db.sock \
	     --no-chdir \
	     --log-file=${ovs_var_log}/ovs-vswitchd.log  \
	     --pidfile=${ovs_var_run}/ovsdb-vswitchd.pid \
	     --unixctl=${ovs_var_run}/ovsdb-vswitchd.ctl \
	     --detach \
	     --monitor
}

run_ovs()
{
	process=`ps -aux | awk -F " " '{if($11~/ovsdb-server/) print $11}'`
	if [ "${process}" == "" ];then
		echo "[SHELL] run ovsdb-server process..."
		run_ovsdb-server;
	fi
	
	process=`ps -aux | awk -F " " '{if($11~/ovs-vswitchd/) print $11}'`
	if [ "${process}" == "" ];then
		echo "[SHELL] run ovs-vswitchd process..."
		run_ovs-vswitchd;
	fi
} 

init_qemu()
{
	ovs_br=`ifconfig -a | awk -F ":" -v var=${OVS_BR} '{if($1==var)print $1}'`
	if [ "${ovs_br}" == "" ];then
		echo "SHELL run cmd: ovs-vsctrl add-br ${OVS_BR}"	
		ovs-vsctl add-br ${OVS_BR}
	fi
	ifconfig ${OVS_BR} ${OVS_IP};
#	echo "ip tuntap add tap01 mode tap"
}

run_qemu()
{
	index=$1
	MAC=00:11:22:33:44:A${index}
	IMG_PATH=${ROOT_DIR}/disk_img/qcow2.x86_${index}.img
	OVS_IFUP=${ROOT_DIR}/script/qemu-ovs-ifup
	OVS_IFDOWN=${ROOT_DIR}/script/qemu-ovs-ifdown

	qemu-system-x86_64 -m 512 \
		-smp 2	\
		-enable-kvm \
		-netdev type=tap,script=${OVS_IFUP},downscript=${OVS_IFDOWN},id=net0 \
		-device virtio-net-pci,netdev=net0,mac=${MAC} \
		-drive file=${IMG_PATH},if=none,id=drive-virtio-disk0,format=qcow2,cache=writeback \
		-device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x6,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 \
		-kernel ${KERNEL_IMG} -append "console=ttyS0,115200 index=${index}" \
		-nographic
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
	init_mod;
	init_ovs;
	run_ovs;
	init_qemu;
	run_qemu ${INDEX};
}

main;

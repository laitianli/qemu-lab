#!/bin/bash
INDEX=$1
ROOT_DIR=$(dirname $0)
ROOT_DIR=/home/haizhi/qemu-lab
KERNEL_IMG=${ROOT_DIR}/bin_kernel/bzImage
QEME_BIN=/usr/libexec/qemu-kvm

OVS_BR=ovs-br0
OVS_IP="2.2.2.1"
CONF_DB="/usr/local/etc/openvswitch/conf.db"
ovs_var_run=/usr/local/var/run/openvswitch
ovs_var_log=/usr/local/var/log/openvswitch

OVS_PATH=/home/haizhi/qemu-lab/ovs-bin/
OVS_SBIN_PATH=${OVS_PATH}/sbin/
OVS_BIN_PATH=${OVS_PATH}/bin/

export LD_LIBRARY_PATH=/home/haizhi/downland/dpdk.org/dpdk/install_dir/lib

init_ovs()
{
	if [ ! -d ${ovs_var_run} ];then
		mkdir -p ${ovs_var_run}
	fi
	if [ ! -d ${ovs_var_log} ];then
		mkdir -p ${ovs_var_log}
	fi
	if [ ! -f ${CONF_DB} ];then
		${OVS_BIN_PATH}/ovsdb-tool create ${CONF_DB}
	fi
}

init_mod()
{
	modprobe vhost_net
	mod_file=/lib/modules/`uname -r`/kernel/net/openvswitch/openvswitch.ko;
	if [ ! -f ${mod_file} ];then
		modprobe openvswitch
		return ;
	fi
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
	${OVS_SBIN_PATH}/ovsdb-server ${CONF_DB} \
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
	${OVS_SBIN_PATH}/ovs-vswitchd unix:${ovs_var_run}/db.sock \
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
		${OVS_BIN_PATH}/ovs-vsctl --db=unix:${ovs_var_run}/db.sock add-br ${OVS_BR}
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

	QCOW2_IMG_PATH=${ROOT_DIR}/disk_img/qcow2.x86_${index}.img
	RAW_IMG_PATH=${ROOT_DIR}/disk_img/raw.x86_${index}.img

	${QEME_BIN} -m 512 \
		-smp 2	\
		-enable-kvm \
		-spice port=6915,addr=0.0.0.0,disable-ticketing,seamless-migration=on \
		-netdev type=tap,script=${OVS_IFUP},downscript=${OVS_IFDOWN},id=net0,vhost=on,queues=4 \
		-device virtio-net-pci,netdev=net0,mac=${MAC} \
        -chardev socket,id=char1,path=/tmp/sock0,server \
        -netdev vhost-user,id=user0,chardev=char1 \
        -device virtio-net-pci,id=net1,netdev=user0,mac=52:54:00:00:00:14 \
		-drive file=${QCOW2_IMG_PATH},if=none,id=drive-virtio-disk0,format=qcow2,cache=writeback \
		-device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x6,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 \
		-kernel ${KERNEL_IMG} -append "root=/dev/vda rootfstype=ext4 init=/usr/sbin/init rw console=ttyS0,115200 index=${index}" \
		-rtc base=localtime,clock=host	\
		-nographic -vnc :1
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


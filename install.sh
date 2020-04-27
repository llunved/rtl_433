#!/bin/bash


set -x

SERVICE=$IMAGE

env

# Make sure the host is mounted
if [ ! -d /host/etc -o ! -d /host/proc -o ! -d /host/var/run ]; then
	    echo "cockpit-run: host file system is not mounted at /host" >&2
	        exit 1
fi

# Make sure that we have required directories in the host
for CUR_DIR in /host/${LOGDIR}/${NAME} /host/${DATADIR}/${NAME} /host/${CONFDIR}/${NAME}  ; do
    if [ -n $CUR_DIR ]; then
        mkdir -p $CUR_DIR
	if [ "$CUR_DIR" == "/host/${CONFDIR}/${NAME}" ] ; then
	    cp -Rv /etc/rtl_433.default /host/${CONFDIR}/${NAME}
	fi
        chmod -R 775 $CUR_DIR
	chgrp -R 0 $CUR_DIR
    fi
done    


chroot /host /usr/bin/podman create --name ${NAME} --net=host --device /dev/dvb:rwZ --entrypoint /sbin/entrypoint.sh -v ${DATADIR}/${NAME}:/var/lib/rtl_433:rwZ -v ${CONFDIR}/${NAME}:/etc/rtl_433:rwZ -v ${LOGDIR}/${NAME}:/var/log/rtl_433:rwZ ${IMAGE} /bin/start.sh
chroot /host sh -c "/usr/bin/podman generate systemd --restart-policy=always -t 1 ${NAME} > /etc/systemd/system/zwave2mqtt.service"


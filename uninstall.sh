#!/bin/bash


set -x

SERVICE=$IMAGE

env

# Make sure the host is mounted
if [ ! -d /host/etc -o ! -d /host/proc -o ! -d /host/var/run ]; then
	    echo "cockpit-run: host file system is not mounted at /host" >&2
	        exit 1
fi

# Remove the container and unit file

chroot /host /usr/bin/systemctl stop ${NAME}
chroot /host /usr/bin/systemctl disable ${NAME}
chroot /host rm -fv /etc/systemd/system/${NAME}.service
chroot /host /usr/bin/podman rm ${NAME}


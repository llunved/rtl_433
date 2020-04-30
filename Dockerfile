ARG OS_RELEASE=32
ARG OS_IMG=fedora:$OS_RELEASE

FROM $OS_IMG as build

ARG OS_RELEASE
ARG OS_IMG
ARG HTTP_PROXY=""
ARG USER="rtl_433"

LABEL MAINTAINER riek@llunved.net

ENV LANG=en_US.UTF-8

RUN mkdir -p /build
WORKDIR /build

RUN rpm -ivh  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$OS_RELEASE.noarch.rpm \
    && rpm -ivh  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$OS_RELEASE.noarch.rpm \
    && dnf install -y dnf-plugins-core \
    && dnf copr enable -y llunved/rtl-sdr-nozc \
    && dnf -y upgrade 

ADD ./rpmreqs-rt.txt ./rpmreqs-dev.txt /build/
RUN dnf -y install $(cat rpmreqs-rt.txt) $(cat rpmreqs-dev.txt) 

# Create the minimal target environment
RUN mkdir /sysimg \
    && dnf copr -y --installroot /sysimg enable llunved/rtl-sdr-nozc \
    && dnf install --installroot /sysimg --releasever $OS_RELEASE --setopt install_weak_deps=false --nodocs -y coreutils-single glibc-minimal-langpack $(cat rpmreqs-rt.txt) \
    && rm -rf /sysimg/var/cache/* \
    && ls -alh /sysimg/var/cache

RUN adduser -R /sysimg -u 1010 -r -g root -G video -d /var/lib/rtl_433 -s /sbin/nologin -c "rtl_433 user" $USER 

# Doing this here and only rpmreqs above should reduce the amount of building? 
# FIXME - should be more selective
ADD . /build

RUN mkdir build_cmake && cd build_cmake \
    && cmake -DCMAKE_INSTALL_PREFIX:PATH=/sysimg .. \
    && make \
    && make install


FROM scratch AS runtime

LABEL MAINTAINER riek@llunved.net

ENV LANG=en_US.UTF-8
ENV USER=$USER

COPY --from=build /sysimg /

RUN mv -fv /etc/rtl_433 /etc/rtl_433.default

ENV CHOWN=true 
ENV CHOWN_DIRS="/var/log/rtl_433 /etc/rtl_433 /var/lib/rtl_433"
RUN for CUR_DIR in ${CHOWN_DIRS}; do mkdir -p $CUR_DIR; done
RUN if [ ! -z "$DEVBUILD" ] ; then chown -R 1010:0 /var/lib/rtl_433 ; fi
  
ADD ./entrypoint.sh \
    ./install.sh \
    ./upgrade.sh \
    ./uninstall.sh \
    ./start.sh /bin/ 
RUN chmod +x /sbin/entrypoint.sh \
     && chmod +x /sbin/install.sh \
     && chmod +x /sbin/upgrade.sh \
     && chmod +x /sbin/uninstall.sh \
     && chmod +x /bin/start.sh

EXPOSE 8091
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/bin/start.sh"]

LABEL RUN="podman run --rm -t -i --name \$NAME --privileged --net=host --device /dev/dvb:/dev/dvb:rw --entrypoint /sbin/entrypoint.sh -v /etc/rtl_433:/etc/etl_433:rwZ -v /var/lib/rtl_433/rtl_433:/var/lib/rtl_433:rwZ -v /var/log/rtl_433:/var/log/rtl_433:rwZ \$IMAGE /bin/start.sh"
LABEL INSTALL="podman run --rm -t -i --privileged --rm --net=host --ipc=host --pid=host -v /:/host -v /run:/run -e HOST=/host -e IMAGE=\$IMAGE -e NAME=\$NAME -e CONFDIR=/etc -e LOGDIR=/var/log -e DATADIR=/var/lib --entrypoint /bin/sh  \$IMAGE /sbin/install.sh"
LABEL UPGRADE="podman run --rm -t -i --privileged --rm --net=host --ipc=host --pid=host -v /:/host -v /run:/run -e HOST=/host -e IMAGE=\$IMAGE -e NAME=\$NAME -e CONFDIR=/etc -e LOGDIR=/var/log -e DATADIR=/var/lib --entrypoint /bin/sh  \$IMAGE /sbin/upgrade.sh"
LABEL UNINSTALL="podman run --rm -t -i --privileged --rm --net=host --ipc=host --pid=host -v /:/host -v /run:/run -e HOST=/host -e IMAGE=\$IMAGE -e NAME=\$NAME -e CONFDIR=/etc -e LOGDIR=/var/log -e DATADIR=/var/lib --entrypoint /bin/sh  \$IMAGE /sbin/uninstall.sh"



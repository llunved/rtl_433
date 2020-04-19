ARG FEDORA_IMAGE_BUILD=fedora
ARG FEDORA_IMAGE_RT=fedora-minimal
ARG FEDORA_RELEASE=31
ARG HTTP_PROXY=""

FROM $FEDORA_IMAGE_BUILD:$FEDORA_RELEASE as build

LABEL MAINTAINER riek@llunved.net

RUN mkdir -p /build
WORKDIR /build

ADD ./rpmreqs-rt.txt ./rpmreqs-dev.txt /build/

RUN rpm -ivh  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_RELEASE.noarch.rpm \
    && dnf -y upgrade \
    && dnf -y install $(cat /build/rpmreqs-rt.txt) $(cat /build/rpmreqs-dev.txt) \
    && dnf -y clean all

ENV LANG=en_US.UTF-8
       
# Doing this here and only rpmreqs above should reduce the amount of building?
ADD . /build

RUN mkdir build_cmake && cd build_cmake \
    && cmake .. \
    && make \
    && make install


FROM $FEDORA_IMAGE_RT:$FEDORA_RELEASE

LABEL MAINTAINER riek@llunved.net

ADD ./rpmreqs-rt.txt /build/

RUN microdnf -y update \
    && microdnf -y install $(cat /build/rpmreqs-rt.txt) \
    && microdnf -y clean all \
    && rm -fv rpmreqs-rt.txt
 
COPY --from=build /usr/local/ /usr/local/

RUN mv -fv /usr/local/etc/rtl_433 /usr/local/etc/rtl_433.default

ENV USER=rtl_433
ENV CHOWN=true 
ENV CHOWN_DIRS="/var/log/rtl_433 /etc/rtl_433 /var/lib/rtl_433"

RUN for CUR_DIR in ${CHOWN_DIRS}; do mkdir -p $CUR_DIR; done
  
RUN adduser -u 1010 -r -g root -G video -d /var/lib/rtl_433 -s /sbin/nologin -c "rtl_433 user" ${USER} \
    && if [ ! -z "$DEVBUILD" ] ; then chown -R ${USER}:root /var/lib/rtl_433 ; fi

ADD ./entrypoint.sh /sbin/ 
ADD ./install.sh /sbin/ 
ADD ./uninstall.sh /sbin/ 
ADD ./start.sh /bin/ 
RUN chmod +x /sbin/entrypoint.sh 
RUN chmod +x /sbin/install.sh 
RUN chmod +x /sbin/uninstall.sh 
RUN chmod +x /bin/start.sh

EXPOSE 8091
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["/bin/start.sh"]

LABEL RUN="podman run --rm -t -i --name \$NAME -p 8091:8091 --net=host --device /dev/ttyACM0 --entrypoint /sbin/entrypoint.sh -v /var/lib/rtl_433/rtl_433:/rtl_433/store -v /var/lib/rtl_433/openzwave:/etc/openzwave -v /var/log/rtl_433:/var/log/rtl_433 \$IMAGE /bin/start.sh"
LABEL INSTALL="podman run --rm -t -i --privileged --rm --net=host --ipc=host --pid=host -v /:/host -v /run:/run -e HOST=/host -e IMAGE=\$IMAGE -e NAME=\$NAME -e LOGDIR=/var/log -e DATADIR=/var/lib --entrypoint /bin/sh  \$IMAGE /sbin/install.sh"
LABEL UNINSTALL="podman run --rm -t -i --privileged --rm --net=host --ipc=host --pid=host -v /:/host -v /run:/run -e HOST=/host -e IMAGE=\$IMAGE -e NAME=\$NAME -e LOGDIR=/var/log -e DATADIR=/var/lib --entrypoint /bin/sh  \$IMAGE /sbin/uninstall.sh"



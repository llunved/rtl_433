ARG FEDORA_IMAGE_BUILD=fedora
ARG FEDORA_IMAGE_RT=fedora-minimal
ARG FEDORA_RELEASE=31
ARG HTTP_PROXY=""

FROM $FEDORA_IMAGE_BUILD:$FEDORA_RELEASE as build

WORKDIR /build

ENV http_proxy=$HTTP_PROXY

RUN mkdir -p /build

ADD ./rpmreqs-rt.txt ./rpmreqs-dev.txt /build/

RUN rpm -ivh  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_RELEASE.noarch.rpm \
    && dnf -y upgrade \
    && dnf -y install $(cat /build/rpmreqs-rt.txt) $(cat /build/rpmreqs-dev.txt) \
    && dnf -y clean all

ENV LANG=en_US.UTF-8
       
ADD . /build

RUN mkdir build_cmake && cd build_cmake \
    && cmake .. \
    && make \
    && make install


FROM $FEDORA_IMAGE_RT:$FEDORA_RELEASE

ADD ./rpmreqs-rt.txt /build/

RUN microdnf -y update \
    && microdnf -y install $(cat /build/rpmreqs-rt.txt) \
    && microdnf -y clean all \
    && rm -fv rpmreqs-rt.txt
 
COPY --from=build /usr/local/ /usr/local/

ENTRYPOINT ["/usr/local/bin/rtl_433"]


ARG FEDORA_RELEASE=31
ARG HTTP_PROXY=""

FROM fedora:$FEDORA_RELEASE as build

WORKDIR /build

ENV RPM_REQS_RUNTIME="  \
       libusb \
       openssl \
       pipenv \
       rtl-sdr \
    " 

ENV RPM_REQS_BUILD=" \
       automake \
       bzip2 \
       cmake \
       doxygen \
       gcc \
       gcc-c++ \
       gnupg  \
       libusb-devel \
       make \
       openssl-devel \
       rtl-sdr-devel \
       tar \
       xz \
    "

ENV http_proxy=$HTTP_PROXY

RUN mkdir -p /build

RUN rpm -ivh  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_RELEASE.noarch.rpm \
    && dnf -y upgrade \
    && dnf -y install $RPM_REQS_RUNTIME \ 
    && dnf -y install $RPM_REQS_BUILD \
    && dnf -y clean all

ENV LANG=en_US.UTF-8
       
ADD .

RUN mkdir build_cmake && cd build_cmake \
    && cmake .. \
    && make \
    && make install


FROM fedora-minimal:$FEDORA_RELEASE

RUN dnf -y upgrade \
    && dnf -y install $RPM_REQS_RUNTIME  \
    && dnf -y clean all
 
COPY --from build /build/build_cmake/ /build/



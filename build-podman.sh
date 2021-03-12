#!/bin/bash

set +x

OS_RELEASE=${OS_RELEASE:-$(grep VERSION_ID /etc/os-release | cut -d '=' -f 2)}
OS_IMG=${OS_IMG:-"registry.fedoraproject.org/fedora:${OS_RELEASE}"}
HTTP_PROXY=${HTTP_PROXY:-""}
BUILD_ID=${BUILD_ID:-`date +%s`}
BUILD_ARCH=$(uname -m)
PUSHREG=${PUSHREG:-""}

echo sudo podman build --build-arg OS_RELEASE=${OS_RELEASE} --build-arg OS_IMG=${OS_IMG} -t ${BUILD_ARCH}/rtl_433:${BUILD_ID} -f Containerfile
sudo podman build --build-arg OS_RELEASE=${OS_RELEASE} --build-arg OS_IMG=${OS_IMG} -t ${BUILD_ARCH}/rtl_433:${BUILD_ID} -f Containerfile

echo sudo  podman tag ${BUILD_ARCH}/rtl_433:${BUILD_ID} ${BUILD_ARCH}/rtl_433:latest
sudo  podman tag ${BUILD_ARCH}/rtl_433:${BUILD_ID} ${BUILD_ARCH}/rtl_433:latest

if [ $? -eq 0 ]; then
  if [ ! -z "${PUSHREG}" ]; then
    echo sudo podman tag ${BUILD_ARCH}/rtl_433:${BUILD_ID} ${PUSHREG}/${BUILD_ARCH}/rtl_433:${BUILD_ID}
    sudo podman tag ${BUILD_ARCH}/rtl_433:${BUILD_ID} ${PUSHREG}/${BUILD_ARCH}/rtl_433:${BUILD_ID}
    echo sudo podman push ${PUSHREG}/${BUILD_ARCH}/rtl_433:${BUILD_ID}
    sudo podman push ${PUSHREG}/${BUILD_ARCH}/rtl_433:${BUILD_ID}
    echo sudo podman tag ${BUILD_ARCH}/rtl_433:${BUILD_ID} ${PUSHREG}/${BUILD_ARCH}/rtl_433:latest
    sudo podman tag ${BUILD_ARCH}/rtl_433:${BUILD_ID} ${PUSHREG}/${BUILD_ARCH}/rtl_433:latest
    echo sudo podman push ${PUSHREG}/${BUILD_ARCH}/rtl_433:latest
    sudo podman push ${PUSHREG}/${BUILD_ARCH}/rtl_433:latest
  fi
fi

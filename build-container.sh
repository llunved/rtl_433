#!/bin/bash

set +x

FEDORA_RELEASE=${FEDORA_RELEASE:-$(grep VERSION_ID /etc/os-release | cut -d '=' -f 2)}
FEDORA_IMAGE_RT=${FEDORA_IMAGE_BUILD:-"registry.fedoraproject.org/fedora"}
FEDORA_IMAGE_RT=${FEDORA_IMAGE_RT:-"registry.fedoraproject.org/fedora-minimal"}
BUILD_ID=${BUILD_ID:-`date +%s`}

echo sudo podman build --build-arg FEDORA_RELEASE=${FEDORA_RELEASE} --build-arg FEDORA_IMAGE_BUILD=${FEDORA_IMAGE_BUILD} --build-arg FEDORA_IMAGE_RT=${FEDORA_IMAGE_RT} -t llunved/zwave2mqtt:${BUILD_ID} -f Dockerfile.Fedora
sudo podman build --build-arg FEDORA_RELEASE=${FEDORA_RELEASE} --build-arg FEDORA_IMAGE_RT=${FEDORA_IMAGE_RT} -t llunved/zwave2mqtt:${BUILD_ID} -f Dockerfile.Fedora
echo sudo  podman tag llunved/zwave2mqtt:${BUILD_ID} llunved/zwave2mqtt:latest
sudo podman tag llunved/zwave2mqtt:${BUILD_ID} llunved/zwave2mqtt:latest


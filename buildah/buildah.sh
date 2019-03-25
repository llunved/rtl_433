#! /bin/bash

set -ex

PROJECT_NAME="rtl_433"
FED_RELEASE=29

basecontainer_name="${PROJECT_NAME}_fedora${FED_RELEASE}_base"
buildcontainer_name="${PROJECT_NAME}_fedora${FED_RELEASE}_build"
runtimecontainer_name="${PROJECT_NAME}_fedora${FED_RELEASE}_run"


RUNTIME_PACKAGES=(
    rtl-sdr
    )

DEV_PACKAGES=(
    gcc tar bzip2 xz rsync make automake gcc gcc-c++ cmake
    libtool libusb-devel rtl-sdr-devel doxygen
    )

IMAGE_UPDATED=false
    
if [ "`buildah images | grep ${basecontainer_name}`" == "" ]; then
    echo "Building Fedora container from scratch"
    basecontainer=$(buildah from scratch)
    basemnt=$(buildah mount $basecontainer)

    dnf install --installroot $basemnt --release ${FED_RELEASE} --setopt='tsflags=nodocs' --setopt install_weak_deps=false -y bash coreutils microdnf

    # Install Freshrpms
    #dnf install --installroot $basemnt --release ${FED_RELEASE} -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FED_RELEASE}.noarch.rpm

    #Copy rmpfusion key to host
    #cp ${basemnt}/etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-* /etc/pki/rpm-gpg/

    # Install packages      
    dnf install --installroot $basemnt --release ${FED_RELEASE}  -y --setopt install_weak_deps=false --setopt='tsflags=nodocs' ${RUNTIME_PACKAGES[@]}
    IMAGE_UPDATED=true

else

    basecontainer=$(buildah from --network=host --name=${basecontainer_name} localhost/${basecontainer_name})
    basemnt=$(buildah mount $basecontainer)

    if [ "`dnf check-update --installroot $basemnt --release ${FED_RELEASE} -y`" == "100" ] ; then
     	
        dnf upgrade --installroot $basemnt --release ${FED_RELEASE}  -y --setopt install_weak_deps=false --setopt='tsflags=nodocs'
        IMAGE_UPDATED=true
    fi
fi

if [ $IMAGE_UPDATED == true ]; then
    buildah config --author "Daniel Riek <riek@llnvd.io>" --label name=${basecontainer_name} $basecontainer
    buildah commit $basecontainer ${basecontainer_name}
    IMAGE_UPDATED=false
fi
buildah unmount $basecontainer
buildah rm $basecontainer

if [ "`buildah images | grep ${buildcontainer_name}`" == "" ]; then
    echo "Building in build container"
    buildcontainer=$(buildah from localhost/$basecontainer_name)
    buildmnt=$(buildah mount $buildcontainer)

    # Install Freshrpms
    #dnf install --installroot $buildmnt --release ${FED_RELEASE} -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FED_RELEASE}.noarch.rpm

    #Copy rmpfusion key to host
    #cp ${buildmnt}/etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-* /etc/pki/rpm-gpg/

    # Install packages      
    dnf install --installroot $buildmnt --release ${FED_RELEASE}  -y --setopt install_weak_deps=false --setopt='tsflags=nodocs' ${DEV_PACKAGES[@]}
else
    buildcontainer=$(buildah from --network=host --name=${buildcontainer_name} localhost/${buildcontainer_name})
    buildmnt=$(buildah mount $buildcontainer)

    if [ "`dnf check-update --installroot $buildmnt --release ${FED_RELEASE} -y`" == "100" ] ; then
        dnf upgrade --installroot $buildmnt --release ${FED_RELEASE}  -y --setopt install_weak_deps=false --setopt='tsflags=nodocs'
        IMAGE_UPDATED=true
    fi
    mkdir -p ${buildmnt}/build
fi

if [ $IMAGE_UPDATED == true ]; then
    buildah config --author "Daniel Riek <riek@llnvd.io>" --label name=${PROJECT_NAME}_fedora${FED_RELEASE}_build $buildcontainer
    buildah commit $buildcontainer $buildcontainer_name
    IMAGE_UPDATED=false
fi

rsync -aP --delete ./ ${buildmnt}/build/

buildah run ${buildcontainer} sh -c "cd /build && cmake . && make && make install" 

if [ "`buildah images | grep ${runtimecontainer_name}`" == "" ]; then
    echo "Creating runtime container"
    runtimecontainer=$(buildah from  --network=host --name=${runtimecontainer_name} localhost/$(basecontainer_name})
    runtimemnt=$(buildah mount $runtimecontainer)

    # Install Freshrpms
    #dnf install --installroot $runtimemnt --release ${FED_RELEASE} -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FED_RELEASE}.noarch.rpm

    #Copy rmpfusion key to host
    #cp ${runtimemnt}/etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-* /etc/pki/rpm-gpg/

    # Install packages      
    dnf install --installroot $runtimemnt --release ${FED_RELEASE}  -y --setopt install_weak_deps=false --setopt='tsflags=nodocs' ${RUNTIME_PACKAGES[@]}

else
    runtimecontainer=$(buildah from --network=host --name=${runtimecontainer_name} localhost/${runtimecontainer_name})
    runtimemnt=$(buildah mount $runtimecontainer)

    dnf upgrade --installroot $runtimemnt --release ${FED_RELEASE}  -y --setopt install_weak_deps=false --setopt='tsflags=nodocs'
fi

cp -pRv ${buildmnt}/usr/local/ ${runtimemnt}/usr/local/

buildah config --cmd "/usr/local/bin/rtl_433" --author "Daniel Riek <riek@llnvd.io>" --label name=${runtimecontainer_name} $runtimecontainer

buildah commit $runtimecontainer ${runtimecontainer_name}

#cleanup
buildah unmount $buildcontainer
buildah rm $buildcontainer

buildah unmount $runtimecontainer
buildah rm $runtimecontainer




#!/bin/bash
if [ ! $# -eq 2 ]; then
    echo "ERROR: 2 arguments are required."
    echo
    echo "Usage:"
    echo "  build.sh <os-name> <deb-pkg-version>"
    echo
    echo "example:"
    echo "  build.sh ubuntu2004 2"
    exit 1
fi

set -euo pipefail


# ---------------------------------
# install prerequisites
# ---------------------------------
sudo apt-get install -y libssl-dev

VERSION=1661
PKG_NAME=ibmswtpm2
PKG_SOURCE_URL=https://sourceforge.net/projects/ibmswtpm2/files/ibmtpm${VERSION}.tar.gz




# ---------------------------------
# build and install
# ---------------------------------
PKG_SOURCE_DIR=$(pwd)           #   .\script-package\tpm2-tools
cd $PKG_SOURCE_DIR/../../       #   .\
mkdir -p build                 
cd build                        #   .\build
BUILD_DIR=$(pwd)

mkdir -p source
cd source                       #   .\build\source

curl -L \
    -o ibmswtpm2.tar.gz \
    ${PKG_SOURCE_URL}
tar x --one-top-level=ibmswtpm2 -f ibmswtpm2.tar.gz
cd ibmswtpm2/


cd src/
make "-j$(nproc)"

DESTDIR=$BUILD_DIR/source/$PKG_NAME/package

mkdir -p $DESTDIR/usr/local/bin
 cp ./tpm_server $DESTDIR/usr/local/bin/tpm_server

# ---------------------------------
# build package
# ---------------------------------

# copies the PKG_SOURCE_DIR
 mkdir -p $BUILD_DIR/source/$PKG_NAME/package/DEBIAN
cd $BUILD_DIR/source/$PKG_NAME                                  #./build/source/tpm2-tss
 cp $PKG_SOURCE_DIR/control package/DEBIAN/control
 cp $PKG_SOURCE_DIR/postinst.sh package/DEBIAN/postinst
if [ $# -eq 0 ]
then
    PKG_OS="unknown"
else
    PKG_OS=$1
fi
# set package name, version, arch 
PKG_VER=${VERSION}-$2
PKG_ARCH=$(dpkg-architecture | grep 'DEB_TARGET_ARCH=' | cut -d = -f 2)
 sed -i "s#\(Package: \).*#\1${PKG_NAME}#g" package/DEBIAN/control
 sed -i "s#\(Version: \).*#\1${PKG_VER}#g" package/DEBIAN/control
 sed -i "s#\(Architecture: \).*#\1${PKG_ARCH}#g" package/DEBIAN/control
 chmod 555 package/DEBIAN/postinst
# build pkg
 dpkg-deb --build package
# copy to output dir
OUTPUT_DIR=$BUILD_DIR/out/${PKG_OS}_${PKG_ARCH}
 mkdir -p $OUTPUT_DIR
 cp package.deb $OUTPUT_DIR/${PKG_NAME}_${PKG_VER}_${PKG_OS}_${PKG_ARCH}.deb


# remove source code
# rm -rf $PRJ_ROOT/source
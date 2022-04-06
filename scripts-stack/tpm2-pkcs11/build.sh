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
sudo apt-get install -y libsqlite3-dev libyaml-dev python3-dev libffi-dev

sudo apt-get install -y git python3-pip 
sudo python3 -m pip install --upgrade pip

VERSION=1.6.0
PKG_NAME=tpm2-pkcs11
PKG_SOURCE_URL=https://github.com/tpm2-software/tpm2-pkcs11.git

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

# clone the source
git clone $PKG_SOURCE_URL $PKG_NAME
cd $PKG_NAME
git fetch --all --prune
git clean -xffd
git reset --hard
git checkout "${VERSION}"

# configure, build, install
./bootstrap

./configure \
    --enable-debug=info \
    --enable-esapi-session-manage-flags \
    --with-storedir=/opt/tpm2-pkcs11

make "-j$(nproc)"
make DESTDIR=$BUILD_DIR/source/$PKG_NAME/package install

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


# build python package
cd $BUILD_DIR/source/$PKG_NAME/tools           #   .\build\source/tpm2-pkcs11/tools
python3 setup.py sdist
cp dist/*.tar.gz $OUTPUT_DIR

# remove source code
# rm -rf $PRJ_ROOT/source
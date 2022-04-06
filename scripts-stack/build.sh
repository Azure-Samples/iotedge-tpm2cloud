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

echo ok

PKG_OS=$1
PKG_VER=$(printf "%02d" $2)

echo platform:              $PKG_OS
echo pkg version:           $PKG_VER

PKG_ARCH=$(dpkg-architecture | grep 'DEB_TARGET_ARCH=' | cut -d = -f 2)
echo detected architecture: $PKG_ARCH
echo

# clean
sudo rm -rf ../build/source

FOLDER="tpm2-tss"
echo
echo "building $FOLDER..."
cd $FOLDER
./build.sh $PKG_OS $PKG_VER
sudo dpkg -i ../../build/source/$FOLDER/package.deb
cd ..

FOLDER="tpm2-abrmd-ibmswtpm2"
echo
echo "building $FOLDER..."
cd $FOLDER
./build.sh $PKG_OS $PKG_VER
cd ..

FOLDER="tpm2-abrmd-hwtpm"
echo
echo "building $FOLDER..."
cd $FOLDER
./build.sh $PKG_OS $PKG_VER
cd ..

FOLDER="tpm2-tools"
echo
echo "building $FOLDER..."
cd $FOLDER
./build.sh $PKG_OS $PKG_VER
cd ..

FOLDER="tpm2-tss-engine"
echo
echo "building $FOLDER..."
cd $FOLDER
./build.sh $PKG_OS $PKG_VER
cd ..

FOLDER="tpm2-pkcs11"
echo
echo "building $FOLDER..."
cd $FOLDER
./build.sh $PKG_OS $PKG_VER
cd ..

FOLDER="ibmswtpm2"
echo
echo "building $FOLDER..."
cd $FOLDER
./build.sh $PKG_OS $PKG_VER
cd ..


#------------------
cd ../build/out/
tar cvzf iotedge-tpm2cloud_${PKG_VER}_${PKG_OS}_${PKG_ARCH}.tar.gz ${PKG_OS}_${PKG_ARCH}/

mkdir -p ../../packages
mv iotedge-tpm2cloud_${PKG_VER}_${PKG_OS}_${PKG_ARCH}.tar.gz ../../packages

rm -rf ${PKG_OS}_${PKG_ARCH}


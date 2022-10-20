#!/bin/bash
function showHelp {
    echo "install Azure IoT Edge"
    echo
    echo "usage:"
    echo "   iotedge-install.sh <platform>"
    echo 
    echo "example:"
    echo "   ./iotedge-install.sh ubuntu1804_amd64  # x86, ubuntu 18.04"
    echo "   ./iotedge-install.sh ubuntu2004_amd64  # x86, ubuntu 20.04"
    echo "   ./iotedge-install.sh debian11_armhf    # raspberry pi"
}

function ubuntu2004_amd64 {
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb -q > /dev/null
    sudo dpkg -i packages-microsoft-prod.deb > /dev/null
    rm packages-microsoft-prod.deb
}

function ubuntu1804_amd64 {
    wget https://packages.microsoft.com/config/ubuntu/18.04/multiarch/packages-microsoft-prod.deb -O packages-microsoft-prod.deb -q > /dev/null
    sudo dpkg -i packages-microsoft-prod.deb > /dev/null
    rm packages-microsoft-prod.deb
}

function debian11_armhf {
    wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb -q > /dev/null
    sudo dpkg -i packages-microsoft-prod.deb > /dev/null
    rm packages-microsoft-prod.deb
}

CWD=$(pwd)
mkdir -p ../install/tpm-administrator
cd ../install/tpm-administrator

echo "installing the latest IoT Edge packages ...."

case $1 in
    debian11_armhf)
        debian11_armhf
        ;;

    ubuntu2004_amd64)
        ubuntu2004_amd64
        ;;

    ubuntu1804_amd64)
        ubuntu1804_amd64
        ;;
    
    *)
        echo -n "unknown platform."
        showHelp
        exit 1
        ;;
esac

echo "apt-get update..."
sudo apt-get update > /dev/null

echo "install moby..."
sudo apt-get install -y moby-engine > /dev/null

echo "aziot-edge..."
sudo apt-get install -y aziot-edge > /dev/null

echo "done."
echo
cd $CWD
exit 0

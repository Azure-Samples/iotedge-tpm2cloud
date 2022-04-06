#!/bin/bash

function showHelp {
  echo "Install the TPM stack from pre-built .deb packages"
  echo
  echo "usage:"
  echo "  $0 <platform> <hw-or-sw-tpm>"
  echo
  echo "example:"
  echo
  echo "./tpm2-stack-install.sh debian11_armhf hwtpm        # raspberry pi, HW TPM"
  echo "./tpm2-stack-install.sh ubuntu2004_amd64 hwtpm      # x86, ubuntu 20.04, HW TPM"
  echo "./tpm2-stack-install.sh ubuntu1804_amd64 swtpm      # x86, ubuntu 18.04, SW TPM (ibmswtpm2)"
}

function printR {
    echo -e "\e[31m$1\e[0m"
}

function printG {
    echo -e "\e[32m$1\e[0m"
}

function printY {
    echo -e "\e[33m$1\e[0m"
}



CWD=$(pwd)
mkdir -p ../install/stack

PLATFORM=$1
TPM=$2

TAR_FILE=$(find ../packages/*${PLATFORM}.tar.gz | sort -n | head -1)

if [ ! -f "$TAR_FILE" ]; then
    echo "$TAR_FILE does not exist."
    exit 1
fi

echo "Extracting from archive '${TAR_FILE}'..."
tar xzvf $TAR_FILE -C ../install/stack --strip-components=1   #iotedge-tpm2cloud/ubuntu2004_amd64
cd ../install/stack

case $TPM in
    swtpm)
        echo install ibmswtpm2...
        sudo dpkg -i ibmswtpm2_*.deb > /dev/null
        ;;

    hwtpm)
        if test -e "/dev/tpm0"; then
            echo "OK, device '/dev/tpm0' found"
        else
            printR "WARNING, device '/dev/tpm0' not found. Is the TPM enabled?"
            exit 1
        fi
        ;;

    *)
        echo -n "Unknown TPM. Supported: swtpm, hwtpm"
        echo
        showHelp
        exit 1
        ;;
esac

# python pip
echo install python3, pip3...
sudo apt-get update > /dev/null
sudo apt-get install python3-pip -y > /dev/null
sudo python3 -m pip install --upgrade pip > /dev/null

# install deb packages
echo install tpm2-tss...
sudo dpkg -i tpm2-tss_*.deb > /dev/null

echo install tpm2-tools...
sudo dpkg -i tpm2-tools_*.deb > /dev/null

echo install tpm2-tss-egine...
sudo dpkg -i tpm2-tss-engine_*.deb > /dev/null

echo install tpm2-pkcs11...
sudo dpkg -i tpm2-pkcs11_*.deb > /dev/null

echo install tpm2-abrmd...
case $TPM in
    swtpm)
        sudo dpkg -i tpm2-abrmd-ibmswtpm2_*.deb > /dev/null
        ;;

    hwtpm)
        sudo dpkg -i tpm2-abrmd-hwtpm_*.deb > /dev/null
        ;;
esac

# install pkcs11 tools (python) for root
echo install tpm2-ptool...
sudo pip3 install tpm2-pkcs11-tools-1.33.7.tar.gz > /dev/null

echo
echo
echo "testing..."
echo "tpm2_getrandom"
tpm2_getrandom 4 | hexdump

echo "openssl-tss-engine"
openssl rand -engine tpm2tss -hex 8

# sudo systemctl status tpm2-abrmd
# dbus-send --system --dest=com.intel.tss2.Tabrmd --type=method_call --print-reply /com/intel/tss2/Tabrmd/Tcti org.freedesktop.DBus.Introspectable.Introspect

echo "done."
echo
cd $CWD
exit 0
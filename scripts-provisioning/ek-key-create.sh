#!/bin/bash

CWD=$(pwd)
mkdir -p ../install/tpm-manufacturer
cd ../install/tpm-manufacturer

function printR {
    echo -e "\e[31m$1\e[0m"
}

function printG {
    echo -e "\e[32m$1\e[0m"
}

function printY {
    echo -e "\e[33m$1\e[0m"
}

echo "creating EK at 0x81010001..."
tpm2_createek -c 0x81010001 -G rsa -u ek.pub > /dev/null

# echo "show persistent handles (you should see '0x81010001')..."
tpm2_getcap handles-persistent | grep 0x81010001

echo "done."
echo
cd $CWD
exit 0
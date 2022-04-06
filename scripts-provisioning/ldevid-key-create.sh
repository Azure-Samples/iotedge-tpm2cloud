#!/bin/bash

CWD=$(pwd)
mkdir -p ../install/tpm-administrator
cd ../install/tpm-administrator

rm -f ldevid.*

function printR {
    echo -e "\e[31m$1\e[0m"
}

function printG {
    echo -e "\e[32m$1\e[0m"
}

function printY {
    echo -e "\e[33m$1\e[0m"
}

echo "creating SRK at 0x81000001 in the SH..."
tpm2_createprimary -C o -g sha256 -G rsa -c srk.ctx > /dev/null
tpm2_evictcontrol -C o -c srk.ctx 0x81000001 > /dev/null

# create ldevid (SH, 0x81000002)
echo "creating ldevid key (under SRK) at 0x81000002 in the SH..."
tpm2_create -C 0x81000001 -g sha256 -G rsa -r ldevid.key -u ldevid.pub > /dev/null
tpm2_load -C 0x81000001 -r ldevid.key -u ldevid.pub -n ldevid.name -c ldevid.ctx > /dev/null
tpm2_evictcontrol -C o -c ldevid.ctx 0x81000002 > /dev/null

# echo
# echo "show persistent hadles..."
# echo "you should see '0x81020000' (SRK) and '0x81000002' (ldevid)..."
tpm2_getcap handles-persistent | grep 0x81000001
tpm2_getcap handles-persistent | grep 0x81000002

echo "done."
echo
cd $CWD
exit 0
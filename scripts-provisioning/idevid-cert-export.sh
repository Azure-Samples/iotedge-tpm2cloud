#!/bin/bash

CWD=$(pwd)
mkdir -p ../install/tpm-administrator
cd ../install/tpm-administrator

function printR {
    echo -e "\e[31m$1\e[0m"
}

function printG {
    echo -e "\e[32m$1\e[0m"
}

function printY {
    echo -e "\e[33m$1\e[0m"
}

echo "reading IDevID certificate from TPM's NV (0x1c90000)..."

# getting size 
DER_SIZE=$(tpm2_nvreadpublic 0x1c90000 | grep 'size:' | awk '{ print $2 }')

# extract
tpm2_nvread 0x01C90000 -C p -s $DER_SIZE -o idevid.der > /dev/null

#echo "converting to PEM..."
openssl x509 -inform der -in idevid.der -out idevid.pem > /dev/null

#echo "showing subject and issuer..."
ISSUER_CN=$(openssl x509 -in idevid.pem -issuer -noout | grep -o 'CN = [^,]*' | cut -d '=' -f 2)
echo "issuer CN:    $ISSUER_CN"
SUBJECT_CN=$(openssl x509 -in idevid.pem -subject -noout | grep -o 'CN = [^,]*' | cut -d '=' -f 2)
echo "subject CN:   $SUBJECT_CN"

echo "done."
echo
cd $CWD
exit 0
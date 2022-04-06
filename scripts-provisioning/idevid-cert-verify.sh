#!/bin/bash

function showHelp {
    echo "usage:"
    echo "    idevid-cert-verify.sh <est-fdqn>:<port> <expected-CN>"

    echo "example:"
    echo "    idevid-cert-verify.sh <my-est>.globalsign.com:443 123456"
}


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


if [ -z "$1" ]
then
    printR "ERROR: <est-fdqn>:<port> missing"
    showHelp
    exit 1
else
    EST_FQDN_PORT=$1
fi

if [ -z "$2" ]
then
    printR "ERROR: <expected-CN> missing"
    showHelp
    exit 1
else
    EXPECTED_CN=$2
fi

# get CAs from server
echo "downloading cacerts from EST..."
curl https://$EST_FQDN_PORT/.well-known/est/cacerts -o cacerts.p7 -s
openssl base64 -d -in cacerts.p7 | openssl pkcs7 -inform DER -outform PEM -print_certs | sed '/subject\|issuer\|^$/d' > cacerts.pem

echo "validating idevid certificate against root CA..."
ISSUER_CN=$(openssl x509 -in cacerts.pem -issuer -noout | grep -o 'CN = [^,]*' | cut -d '=' -f 2)
openssl verify -CAfile cacerts.pem idevid.pem > /dev/null
if [ $? -eq 0 ]; then
    echo "root CA validation successful (signed by ${ISSUER_CN})"
else
    printR "WARNING, validation failed!"
    exit 1
fi

echo "validating idevid CN..."
SUBJECT_CN=$(openssl x509 -in idevid.pem -subject -noout | grep -o 'CN = [^,]*' | cut -d '=' -f 2)
if [ $SUBJECT_CN = $EXPECTED_CN ]; then
    echo "CN validation successful"
else
    printR "WARNING, validation failed!"
    exit 1
fi

echo "done."
echo
cd $CWD
exit 0
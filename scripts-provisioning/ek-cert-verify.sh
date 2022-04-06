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

echo "checking if TPM is genuine..."


echo "reading the EK certificate from TPM NV..."
tpm2_getekcertificate -o RSA_EK_cert.bin -o ECC_EK_cert.bin
openssl x509 -inform der -in RSA_EK_cert.bin -outform pem > RSA_EK_cert.pem

ISSUER=$(openssl x509 -inform der -in RSA_EK_cert.bin -issuer -noout)
ISSUER_CN=$(echo $ISSUER | grep -o 'CN = [^,]*' | cut -d '=' -f 2)
echo "EK certificate issued by: ${ISSUER_CN}"

INFINEON_INT_CAXYZ=$(echo $ISSUER_CN | grep -o 'CA [^,]*' | cut -d ' ' -f 2)

echo "download TPM Manufacturer root and intermediate certificates..."
wget -O InfineonRsaRootCA.crt https://www.infineon.com/dgdl/Infineon-TPM_RSA_Root_CA-C-v01_00-EN.cer?fileId=5546d46253f6505701540496a5641d20 -q > /dev/null
openssl x509 -inform der -in InfineonRsaRootCA.crt -outform pem > InfineonRsaRootCA.pem
SUBJECT=$(openssl x509 -in InfineonRsaRootCA.pem -subject -noout | grep -o 'CN = [^,]*' | cut -d '=' -f 2)
# echo "  Root CA CN: $SUBJECT"

wget -O InfineonEccRootCA.crt https://www.infineon.com/dgdl/Infineon-TPM_ECC_Root_CA-C-v01_00-EN.cer?fileId=5546d46253f65057015404843f751cdc -q > /dev/null
openssl x509 -inform der -in InfineonEccRootCA.crt -outform pem > InfineonEccRootCA.pem

wget https://pki.infineon.com/OptigaRsaMfrCA${INFINEON_INT_CAXYZ}/OptigaRsaMfrCA${INFINEON_INT_CAXYZ}.crt -O OptigaRsaMfrCA.crt -q > /dev/null
openssl x509 -inform der -in OptigaRsaMfrCA.crt -outform pem > OptigaRsaMfrCA.pem
SUBJECT=$(openssl x509 -in OptigaRsaMfrCA.pem -subject -noout | grep -o 'CN = [^,]*' | cut -d '=' -f 2)
# echo "  INT CA CN: $SUBJECT"

wget https://pki.infineon.com/OptigaEccMfrCA042/OptigaEccMfrCA042.crt -O OptigaEccMfrCA.crt -q > /dev/null
openssl x509 -inform der -in OptigaEccMfrCA.crt -outform pem > OptigaEccMfrCA.pem

# echo
# chain root and intermediate certificates...
cat InfineonRsaRootCA.pem OptigaRsaMfrCA.pem > OptigaRsaMfrCA.chain.pem

# echo
echo "validating TPM certificate against Manufacturer chain..."
openssl verify -CAfile OptigaRsaMfrCA.chain.pem RSA_EK_cert.pem > /dev/null

if [ $? -eq 0 ]; then
    echo "validation successful (signed by ${ISSUER_CN})"
else
    printR "WARNING, validation failed!"
    exit 1
fi

echo "done."
echo
cd $CWD
exit 0
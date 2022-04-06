#!/bin/bash
function showHelp {
    echo " usage:"
    echo "   pkcs11-init-ldevid-link.sh <token> <so-pin> <user-pin> <store-path>"
    echo 
    echo " example:"
    echo "   ./pkcs11-init-ldevid-link.sh edge 1234 1234 /opt/tpm2-pkcs11"
}

CWD=$(pwd)
mkdir -p ../install/tpm-administrator
cd ../install/tpm-administrator

if [ "$#" -ne 4 ]; then
    echo "Illegal number of parameters"
    echo
    showHelp
    exit 1
fi

# init the PKCS11 store
TOKEN=$1
SO_PIN=$2
USER_PIN=$3
PKCS11_STORE=$4

TOKEN_PARAM="token=$TOKEN"

# create folder
echo "PKCS#11: creating store folder '$PKCS11_STORE' and assigning 'aziotks:aziotks' permissions..."
sudo rm -rf $PKCS11_STORE
sudo mkdir -p $PKCS11_STORE
sudo chown "aziotks:aziotks" $PKCS11_STORE -R
sudo chmod 0700 $PKCS11_STORE

# Create a primary object in a store compatible for this key
echo "PKCS#11: creating primary object linked to SRK (0x81000001)..."
pid="$(sudo -u aziotks -g aziotks tpm2_ptool init --primary-handle=0x81000001 --path $PKCS11_STORE | grep id | cut -d' ' -f 2-2)"

    # optionally view
    # sudo -u aziotks -g aziotks tpm2_ptool listprimaries --path=$PKCS11_STORE

# Create a token associated with the primary object
# Note: in production set userpin and sopin to other values.
echo "PKCS#11: creating token with label '$TOKEN'..."
sudo tpm2_ptool addtoken --pid=$pid --sopin=$SO_PIN --userpin=$USER_PIN --label=$TOKEN --path $PKCS11_STORE > /dev/null

    # optionally view
    # sudo -u aziotks -g aziotks tpm2_ptool listtokens --pid=$pid --path=$PKCS11_STORE

# Link the key
# Note: order of key pair objects does not matter
echo "PKCS#11: importing TPM's ldevid..."
sudo tpm2_ptool link --label=$TOKEN --userpin=$USER_PIN --key-label="ldevid" --path $PKCS11_STORE ldevid.pub ldevid.key > /dev/null

#echo
#echo "result:"
#echo "(you should see private and public key with label 'ldevid')"
#sudo tpm2_ptool listobjects --label=$TOKEN --path=$PKCS11_STORE

echo "done."
echo
cd $CWD
exit 0
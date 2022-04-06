TOKEN=$2
export USER_PIN=$3
export DPS_SCOPE=$4

# get device-id from certificate
#export DEVICE_ID=$(openssl x509 -inform pem -in ldevid.crt -noout -subject -nameopt sep_multiline | grep 'CN=' | awk -F'=' '{ print $2 }') # must match certificate's CN
export DEVICE_ID=$5


#!/bin/bash
# usage:
#   iotedge-configure.sh    dps         <pkcs11-token> <pkcs11-pin> <dps-scope> <device-id> <device-id-cert.pem> 
#   iotedge-configure.sh    est-ba      <pkcs11-token> <pkcs11-pin> <dps-scope> <device-id> <est-fqdn>:<port> <est-username> <est-password>
#   iotedge-configure.sh    est-mtls    <pkcs11-token> <pkcs11-pin> <dps-scope> <device-id> <est-fqdn>:<port>
#
# example:
#   ./iotedge-configure.sh  dps      token-edge 1234 0ne0028xxxx mydeviceid /path/to/device-id-cert.pem  
#   ./iotedge-configure.sh  est-ba   token-edge 1234 0ne0028xxxx mydeviceid my-est.globalsign.com:443 myusername mypassword
#   ./iotedge-configure.sh  est-mtls token-edge 1234 0ne0028xxxx mydeviceid my-est.globalsign.com:443

function est-get-server-ca {
    EST_FQDN_PORT=$1

    # get server CA
    echo "Q" | openssl s_client -showcerts -verify 5 -connect $EST_FQDN_PORT | awk '/BEGIN/ { i++; } /BEGIN/, /END/ { print > "cert-" i ".crt" }'
    # cert-3.crt --> root
    # cert-2.crt --> intermediate
    # cert-1.crt --> leaf
    # build root + intermediate chain
    
    # get GlobalSign Root CA - R3
    wget -O Root-R3.der https://secure.globalsign.net/cacert/Root-R3.crt -q
    openssl x509 -inform DER -in Root-R3.der -outform PEM -out Root-R3.pem > /dev/null

    # build est chain
    cat Root-R3.pem cert-2.crt > est-chain.pem
}

function est-get-cacerts {
    EST_FQDN_PORT=$1

    # get CAs from server
    curl https://$EST_FQDN_PORT/.well-known/est/cacerts -o cacerts.p7 -s
    openssl base64 -d -in cacerts.p7 | openssl pkcs7 -inform DER -outform PEM -print_certs | sed '/subject\|issuer\|^$/d' > cacerts.pem
    #openssl x509 -in cacerts.pem -noout -subject -issuer
    # THIS MUST BE UPLOADED TO DPS
}

function dps {
    export CERT_PATH=$1
    
    cat config.toml.dps.template | envsubst > config.toml
}

function est-ba {
    export EST_FQDN_PORT=$1
    export EST_USERNAME=$2
    export EST_PASSWORD=$3

    export EST_SERVER_CA=/etc/aziot/est-chain.pem

    # gets server CA and writes it to est-chain.pem
    est-get-server-ca $EST_FQDN_PORT
    
    # gets server cacerts and writes it to cacerts.pem
    est-get-cacerts $EST_FQDN_PORT
    
    # expand env vars
    cat config.toml.est-ba.template | envsubst > config.toml

    # copy to /etc/aziot
    sudo cp est-chain.pem /etc/aziot
    sudo cp config.toml /etc/aziot
}

function est-mtls {
    export EST_FQDN_PORT=$1

    export EST_SERVER_CA=/etc/aziot/est-chain.pem

    export EST_KEY_ID=ldevid
    export EST_CERT_PATH=/etc/aziot/est-id.pem

    # gets server CA and writes it to est-chain.pem
    est-get-server-ca $EST_FQDN_PORT
    
    # gets server cacerts and writes it to cacerts.pem
    est-get-cacerts $EST_FQDN_PORT
    
    # expand env vars
    cat config.toml.est-mtls.template | envsubst > config.toml

    # copy to /etc/aziot
    sudo cp ldevid.crt /etc/aziot/est-id.pem
    sudo cp est-chain.pem /etc/aziot
    sudo cp config.toml /etc/aziot
}

function apply {
    sudo iotedge config apply
}


CWD=$(pwd)
mkdir -p ../install/tpm-administrator
cp config.toml.*.template ../install/tpm-administrator
cd ../install/tpm-administrator

echo "configuring the Azure IoT edge (config.toml)..."

export TOKEN=$2
export USER_PIN=$3
export DPS_SCOPE=$4

# get device-id from certificate
#export DEVICE_ID=$(openssl x509 -inform pem -in ldevid.crt -noout -subject -nameopt sep_multiline | grep 'CN=' | awk -F'=' '{ print $2 }') # must match certificate's CN
export DEVICE_ID=$5

export KEY_ID=ldevid

case $1 in
    dps)
        dps $6 
        ;;

    est-ba)
        # EST_FQDN_PORT EST_USERNAME EST_PASSWORD
        est-ba $6 $7 $8
        ;;

    est-mtls)
        est-mtls $6
        ;;
    
    *)
        echo -n "unknown provider"
        exit 1
        ;;
esac

apply

echo "done."
echo
cd $CWD
exit 0
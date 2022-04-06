#!/bin/bash
set -e
function showHelp {
  echo "usage:"
  echo "  $0 <rg-name> <rg-location> <est-fqdn>:<port>"
  echo
  echo "example:"
  echo "  $0 debian11_armhf hwtpm"
  echo "  $0 ubuntu2004_amd64 swtpm"
}

function downloadCaCerts {
    EST_FQDN_PORT=$1

    echo "downloading cacerts from EST..."
    curl https://$EST_FQDN_PORT/.well-known/est/cacerts -o cacerts.p7 -s
    openssl base64 -d -in cacerts.p7 | openssl pkcs7 -inform DER -outform PEM -print_certs | sed '/subject\|issuer\|^$/d' > cacerts.pem
}

CWD=$(pwd)
mkdir -p ../install/deploy
cd ../install/deploy

if [ -z "$1" ]; then
  echo "No resource group name provided"
  showHelp
  exit 1
else
  RG_NAME=$1
fi

if [ -z "$2" ]; then
  echo "No resource group location provided"
  showHelp
  exit 1
else
  RG_LOCATION=$2
fi

if [ -z "$3" ]; then
  echo "No EST fqdn:port provided"
  showHelp
  exit 1
else
  EST_FQDN_PORT=$3
fi

echo "creating resource group '$RG_NAME' in '$RG_LOCATION'..."
az group create --name $RG_NAME --location $RG_LOCATION > /dev/null

echo "deploying IoT Hub and DPS..."
az deployment group create -n app-deployment -g ${RG_NAME} \
  --template-file $CWD/main.bicep > /dev/null


DPS_NAME=$(az iot dps list -g $RG_NAME --query [0].name -o tsv) 

downloadCaCerts $EST_FQDN_PORT

echo "uploading cacerts to DPS..."
az iot dps certificate create --dps-name $DPS_NAME --resource-group $RG_NAME \
    --name est-cacerts --path ./cacerts.pem --verified > /dev/null

echo "creating group enrollment..."
az iot dps enrollment-group create --dps-name $DPS_NAME --resource-group $RG_NAME \
    --enrollment-id iotedge-tpm2cloud --ca-name est-cacerts > /dev/null

echo "getting the DPS scope..."

DPS_SCOPE_ID=$(az iot dps show --name $DPS_NAME --resource-group $RG_NAME --query properties.idScope -o tsv)
echo "SCOPE ID: $DPS_SCOPE_ID"

echo "done."
echo
cd $CWD
exit 0
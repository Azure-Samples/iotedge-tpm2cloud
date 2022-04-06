function printR {
    echo -e "\e[31m$1\e[0m"
}

function GetDeviceInfo {
    export DEVICE_MODEL=$(cat /proc/cpuinfo | grep Model | cut -d ':' -f 2 | tr -d ' ')
    echo "Device Model:         $DEVICE_MODEL"

    export DEVICE_SN=$(cat /proc/cpuinfo | grep Serial | cut -d ':' -f 2 | tr -d ' ')
    echo "Device Serial:        $DEVICE_SN"

    export DEVICE_MAC=$(cat /sys/class/net/eth0/address)
    echo "Device MAC Address:   $DEVICE_MAC"

    echo

    export DEVICE_STRING="MODEL=${DEVICE_MODEL},SN=${DEVICE_SN},MAC=${DEVICE_MAC}"
    echo "Device String:        $DEVICE_STRING"

    export DEVICE_STRING_HASH="$(echo $DEVICE_STRING | sha256sum | cut -d ' ' -f 1)"
    echo "--> SHA256:           $DEVICE_STRING_HASH"
}

function ask {
    while true; do
        echo
        read -p "$1 [yn] " yn
        
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    clear
}

function header {
    echo
    echo
    echo "$1"
    echo "-----------------------------------------------"
    echo
}

header "Configuration"

echo "PLATFORM:"
if [ -z "$PLATFORM_OS_ARCH" ]
then
    printR "ERROR: PLATFORM_OS_ARCH environment variable is not set"
    exit 1
else
    echo "  PLATFORM_OS_ARCH=$PLATFORM_OS_ARCH"
fi

if [ -z "$TPM_HW_SW" ]
then
    printR "ERROR: TPM_HW_SW environment variable is not set"
    exit 1
else
    echo "  TPM_HW_SW=$TPM_HW_SW"
fi

echo 
echo "Device Identity (IDevID):"
if [ -z "$IDEVID_CA_EST_FQDN_PORT" ]
then
  printR "ERROR: IDEVID_CA_EST_FQDN_PORT environment variable is not set"
  exit 1
else
    echo "  IDEVID_CA_EST_FQDN_PORT=$IDEVID_CA_EST_FQDN_PORT"
fi

if [ -z "$IDEVID_CA_EST_USER" ]
then
  printR "ERROR: IDEVID_CA_EST_USER environment variable is not set"
  exit 1
else
    echo "  IDEVID_CA_EST_USER=$IDEVID_CA_EST_USER"
fi

if [ -z "$IDEVID_CA_EST_PASSWORD" ]
then
  printR "ERROR: IDEVID_CA_EST_PASSWORD environment variable is not set"
  exit 1
else
    echo "  IDEVID_CA_EST_PASSWORD=$IDEVID_CA_EST_PASSWORD"
fi

echo 
echo "Customer Identity (LDevID):"
if [ -z "$LDEVID_CA_EST_FQDN_PORT" ]
then
  printR "ERROR: LDEVID_CA_EST_FQDN_PORT environment variable is not set"
  exit 1
else
    echo "  LDEVID_CA_EST_FQDN_PORT=$LDEVID_CA_EST_FQDN_PORT"
fi

if [ -z "$LDEVID_CA_EST_USER" ]
then
  printR "ERROR: LDEVID_CA_EST_USER environment variable is not set"
  exit 1
else
    echo "  LDEVID_CA_EST_USER=$LDEVID_CA_EST_USER"
fi

if [ -z "$LDEVID_CA_EST_PASSWORD" ]
then
  printR "ERROR: LDEVID_CA_EST_PASSWORD environment variable is not set"
  exit 1
else
    echo "  LDEVID_CA_EST_PASSWORD=$LDEVID_CA_EST_PASSWORD"
fi

echo 
echo "Operational Identity:"
if [ -z "$OPERATIONAL_CA_FQDN_PORT" ]
then
  printR "ERROR: OPERATIONAL_CA_FQDN_PORT environment variable is not set"
  exit 1
else
    echo "  OPERATIONAL_CA_FQDN_PORT=$OPERATIONAL_CA_FQDN_PORT"
fi

echo 
echo "Azure DPS:"
if [ -z "$DPS_SCOPE_ID" ]
then
  printR "ERROR: DPS_SCOPE_ID environment variable is not set"
  exit 1
else
    echo "  DPS_SCOPE_ID=$DPS_SCOPE_ID"
fi

header "Device HW Info extracted from (/proc/cpuinfo):"
GetDeviceInfo

header "Certificate Common Names (CN)s will be set to:"
echo "Device Certificate (IDevID) CN    --> SHA256 hash of Device HW Info ($DEVICE_STRING_HASH)"

if [ -z "$1" ]
then
    printR "ERROR: command line parameter <LDEVID_CN> is missing"
    echo "Usage:"
    echo "  ./provision-tpm2cloud.sh <LDEVID-CN>"
    exit 1
else
    export LDEVID_CN=$1
fi


echo "Customer Certificate (LDevID) CN  --> command line parameter <LDEVID_CN> ($LDEVID_CN)"
echo "Operational Certificate CN        --> command line parameter <LDEVID_CN> ($LDEVID_CN)"

ask "Is the configuration correct? Do you want to proceed?"

# # grab the scripts
# sudo apt-get install -y git
# git clone https://github.com/arlotito/iotedge-tpm2cloud.git
# cd iotedge-tpm2cloud/scripts-provisioning

echo
echo "*******************************************************************"
echo "* PLATFORM DEVELOPMENT (Device Identity - IDevID)                 *"
echo "* --------------------------------------------------------------- *"
echo "*  1) install TPM2 stack and PKCS#11                              *"
echo "*  2) install Azure IoT Edge 1.2                                  *"
echo "*                                                                 *"
echo "*******************************************************************"

header "1) install TPM2 stack and PKCS#11"
./tpm2-stack-install.sh $PLATFORM_OS_ARCH $TPM_HW_SW

header "2) install Azure IoT Edge 1.2"
./iotedge-install.sh $PLATFORM_OS_ARCH

ask "Do you want to move to the next step?"

echo
echo "*******************************************************************"
echo "* PLATFORM MANUFACTURING (Device Identity - IDevID)               *"
echo "* --------------------------------------------------------------- *"
echo "*  1) install TPM2 stack and PKCS#11                              *"
echo "*  2) validate EK certificate to attest the TPM is genuine        *"
echo "*  3) create Endorsement Key (EK)                                 *"
echo "*  4) create IDevID key                                           *"
echo "*  5) request the IDevID cert and store it in the TPM's NV        *"
echo "*                                                                 *"
echo "*******************************************************************"
echo "NOTES:"
echo "- IDevID CN is set to a (random) unique Serial Number"

header "1) install TPM2 stack and PKCS#11"
echo "already done."

header "2) validate EK certificate to attest the TPM is genuine"
./ek-cert-verify.sh

header "3) create Endorsement Key (EK)"
./ek-key-create.sh

header "4) create IDevID key"
./idevid-key-create.sh  

export IDEVID_CN=$RANDOM
echo "random Serial Number: $IDEVID_CN"

header "5) request the IDevID cert and store it in the TPM's NV"
./cert-create.sh idevid est-ba $IDEVID_CN $IDEVID_CA_EST_FQDN_PORT $IDEVID_CA_EST_USER $IDEVID_CA_EST_PASSWORD

ask "Do you want to move to the next step?"

echo
echo "*******************************************************************"
echo "* PLATFORM ADMINISTRATION (Customer Identity - LDevID)            *"
echo "* --------------------------------------------------------------- *"
echo "*  1) read IDevID cert from TPM's NV                              *"
echo "*  2) validate IDevID certificate to attest the DEVICE is genuine *"
echo "*  3) create Customer Key (LDevID)                                *"
echo "*  4) init PKCS11 store and import LDevID key                     *"
echo "*  5) request the LDevID cert and store it in the file-system     *"
echo "*  6) Azure IoT Edge configuration                                *"
echo "*                                                                 *"
echo "*******************************************************************"


header "1) read IDevID cert from TPM's NV"
./idevid-cert-export.sh

header "2) validate IDevID certificate to attest the DEVICE is genuine"
./idevid-cert-verify.sh $IDEVID_CA_EST_FQDN_PORT $IDEVID_CN

header "3) create Customer Key (LDevID)"
./ldevid-key-create.sh 

header "4) init PKCS11 store and import LDevID key"
./pkcs11-init-ldevid-link.sh edge 1234 1234 /opt/tpm2-pkcs11

header "5) request the LDevID cert and store it in the file-system"
./cert-create.sh ldevid est-ba $LDEVID_CN $LDEVID_CA_EST_FQDN_PORT $LDEVID_CA_EST_USER $LDEVID_CA_EST_PASSWORD

# configure IoT Edge for the Operational Identity
# (ldevid is used as onboarding identity to authenticate the device to the EST server)
header "6) Azure IoT Edge configuration"
export OPERATIONAL_CN=$LDEVID_CN
export DPS_DEVICE_ID=$OPERATIONAL_CN 
./iotedge-configure.sh est-mtls edge 1234 $DPS_SCOPE_ID $DPS_DEVICE_ID $OPERATIONAL_CA_FQDN_PORT
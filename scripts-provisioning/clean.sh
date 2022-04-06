rm -rf ~/iotedge-tpm2cloud/install
sudo rm -rf /var/lib/aziot/certd/certs
tpm2_clear
tpm2_nvundefine 0x1c90000 -C p

tpm2_getcap handles-persistent
tpm2_getcap handles-nv-index


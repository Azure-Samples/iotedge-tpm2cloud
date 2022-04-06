#!/bin/bash
function printR {
    echo -e "\e[31m$1\e[0m"
}

function printG {
    echo -e "\e[32m$1\e[0m"
}

function printY {
    echo -e "\e[33m$1\e[0m"
}

function showHelp {
    echo " usage:"
    echo "   cert-create.sh <ldevid-or-idevid> ca <ldevid-CN> <ca-crt> <ca-key>"
    echo "   cert-create.sh <ldevid-or-idevid> est-secret <ldevid-CN> <est-fqdn>:<port> <est-secret>"
    echo "   cert-create.sh <ldevid-or-idevid> est-ba <ldevid-CN> <est-fqdn>:<port> <est-username> <est-password>"
    echo "   cert-create.sh <ldevid-or-idevid> est-mtls <ldevid-CN> <est-fqdn>:<port> <cert.pem> <private-key-handle>"
    echo 
    echo " examples:"
    echo
    echo "   To create Device Identity (idevid):"
    echo "      ./cert-create.sh idevid ca 567890 ../ca/ca.crt ../ca/ca.key"
    echo "      ./cert-create.sh idevid est-secret 567890 microsoft-id.est.edge.dev.globalsign.com:443 dMbuhylQvv9CuiXSgJkV"
    echo "      ./cert-create.sh idevid est-ba 567890 microsoft-ba-id.est.edge.dev.globalsign.com:443 user dMbuhylQvv9CuiXSgJkV"
    echo
    echo "   To create Customer Identity (ldevid):"
    echo "      ./cert-create.sh ldevid ca 567890 ../ca/ca.crt ../ca/ca.key"
    echo "      ./cert-create.sh ldevid est-secret 567890 microsoft-id.est.edge.dev.globalsign.com:443 dMbuhylQvv9CuiXSgJkV"
    echo "      ./cert-create.sh ldevid est-ba 567890 microsoft-ba-id.est.edge.dev.globalsign.com:443 user dMbuhylQvv9CuiXSgJkV"
    echo "      ./cert-create.sh ldevid est-mtls art444 microsoft-ldevid.est.edge.dev.globalsign.com:443 idevid.pem 0x81020000"
}

function ca {
    # sign csr with CA
    echo "signing CSR with CA..."
    openssl x509 -req -days 365 -in $KEY_ID.csr -CA $1 -CAkey $2 -out $KEY_ID.crt -CAcreateserial > /dev/null

        # optionally verify
        # openssl verify -CAfile ../ca/ca.crt ldevid.crt

        # optionally view the cert
        openssl x509 -in $KEY_ID.crt -subject -issuer -subject -noout
}

function est-secret {
    EST_FQDN_AND_PORT=$1             
    EST_SECRET=$2               
    
    SECRET_VALUE_CURL="Secret-Value: $EST_SECRET"

    # sign csr with CA
    echo "signing CSR with CA..."
    curl -X POST --data-binary "@$KEY_ID.csr" \
        -H "Content-Transfer-Encoding:base64" \
        -H "$SECRET_VALUE_CURL" \
        -H "Content-Type:application/pkcs10" \
        https://$EST_FQDN_AND_PORT/.well-known/est/simpleenroll > cert.p7b

    # response in not PEM, but the base64 encoded DER
    cat cert.p7b | openssl base64 -d -a | openssl pkcs7 -inform der -print_certs | sed '/subject\|issuer\|^$/d' > $KEY_ID.crt

        # optionally verify
        # openssl verify -CAfile ../ca/ca.crt $KEY_ID.crt

        # optionally view the cert
        openssl x509 -in $KEY_ID.crt -subject -issuer -subject -noout
}

function est-ba {
    EST_FQDN_AND_PORT=$1             
    EST_USERNAME=$2             
    EST_PASSWORD=$3             
    
    # sign csr with CA
    # echo "signing CSR with CA..."
    curl -X POST --data-binary "@$KEY_ID.csr" \
        -H "Content-Transfer-Encoding:base64" \
        -u $EST_USERNAME:$EST_PASSWORD \
        -H "Content-Type:application/pkcs10" \
        https://$EST_FQDN_AND_PORT/.well-known/est/simpleenroll \
        -s > cert.p7b

    # response in not PEM, but the base64 encoded DER
    cat cert.p7b | openssl base64 -d -a | openssl pkcs7 -inform der -print_certs | sed '/subject\|issuer\|^$/d' > $KEY_ID.crt

        # optionally verify
        # openssl verify -CAfile ../ca/ca.crt $KEY_ID.crt

        # optionally view the cert
        # openssl x509 -in $KEY_ID.crt -subject -issuer -subject -noout
}

function est-mtls {
    EST_FQDN_AND_PORT=$1
    EST_MTLS_CERT=$2
    EST_MTLS_KEY_HANDLE=$3            
      
    echo $EST_FQDN_AND_PORT
    echo $EST_MTLS_KEY_HANDLE
    echo $EST_MTLS_CERT

    CSR=$KEY_ID.csr           
    
cat > request <<EOF
POST /.well-known/est/simpleenroll HTTP/1.1
Host: $EST_FQDN_AND_PORT
Content-Type: application/pkcs10
Content-Transfer-Encoding: base64
Connection: close
EOF

    PEM_SIZE=$(wc -c $CSR | awk '{ print $1 }')
    echo "Content-Length: $PEM_SIZE" >> request
    echo  >> request
    cat $CSR >> request
    echo  >> request
    echo  >> request

    cat request | \
    openssl s_client \
        -nocommands \
        -ign_eof \
        -msgfile out.txt \
        -quiet \
        -keyform engine \
        -engine tpm2tss \
        -cert $EST_MTLS_CERT \
        -key $EST_MTLS_KEY_HANDLE \
        -connect $EST_FQDN_AND_PORT \
        -quiet \
        -s > response

    cat response | sed '/HTTP\|Content\|Strict\|Date\|Connection\|^$/d' > cert.p7b

    # response in not PEM, but the base64 encoded DER
    cat cert.p7b | openssl base64 -d -a | openssl pkcs7 -inform der -print_certs | sed '/subject\|issuer\|^$/d' > $KEY_ID.crt
}

function write_nv {
	# write certificate to NV
	echo "storing idevid cert at 0x01C90000 of Platform Hierarchy (PH)..."
	openssl x509 -outform der -in idevid.crt -out idevid.der > /dev/null
	DER_SIZE=$(wc -c idevid.der | awk '{ print $1 }')
	tpm2_nvdefine 0x01C90000 -C p -s $DER_SIZE -a "ppread|ppwrite|platformcreate|write_stclear" > /dev/null
	tpm2_nvwrite 0x01C90000 -C p -i idevid.der > /dev/null


	#echo
	#echo "showing objects in the NV (you should see '0x01C90000'):"
	#tpm2_nvreadpublic
}

case $1 in
    ldevid)
    	WORKING_FOLDER=tpm-administrator
    	KEY_ID=ldevid
        KEY_HANDLE=0x81000002
        ;;

    idevid)
    	WORKING_FOLDER=tpm-manufacturer
    	KEY_ID=idevid
        KEY_HANDLE=0x81020000
        ;;

    *)
        echo -n "error"
	echo
	showHelp
        exit 1
        ;;
esac

CWD=$(pwd)
mkdir -p ../install/$WORKING_FOLDER
cp $KEY_ID.cnf.template ../install/$WORKING_FOLDER
cd ../install/$WORKING_FOLDER

# substitues CN in .cnf
export DEVICE_ID=$3
cat $KEY_ID.cnf.template | envsubst > $KEY_ID.cnf

echo "requesting '$1' certificate with CN=$DEVICE_ID..."
openssl req -new -key $KEY_HANDLE -engine tpm2tss -keyform engine -out $KEY_ID.csr -config $KEY_ID.cnf > /dev/null

case $2 in
    ca)
        ca $4 $5
        ;;

    est-secret)
        est-secret $4 $5
        ;;

    est-ba)
        est-ba $4 $5 $6
        ;;

    est-mtls)
        est-mtls $4 $5 $6
        ;;
    
    *)
        echo -n "unknown provider"
        exit 1
        ;;
esac

echo 
echo "got a certificate:"
openssl x509 -in $KEY_ID.crt -noout -issuer -subject

if [ "$KEY_ID" == "idevid" ]
then
    write_nv
fi

echo "done."
echo
cd $CWD
exit 0
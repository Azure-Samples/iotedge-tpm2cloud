#!/bin/bash

CWD=$(pwd)
mkdir -p ../install/ca
cp ca.cnf ../install/ca
cd ../install/ca

openssl genrsa -out ca.key 2048

openssl req -x509 -new -nodes \
    -key ca.key -sha256 \
    -config ca.cnf \
    -days 1825 -out ca.crt

cd $CWD
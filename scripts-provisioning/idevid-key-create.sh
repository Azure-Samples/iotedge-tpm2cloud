#!/bin/bash

CWD=$(pwd)
mkdir -p ../install/tpm-manufacturer
cd ../install/tpm-manufacturer

rm -f idevid.*
rm -f session.ctx

function printR {
    echo -e "\e[31m$1\e[0m"
}

function printG {
    echo -e "\e[32m$1\e[0m"
}

function printY {
    echo -e "\e[33m$1\e[0m"
}

echo "creating idevid key (under EK)..."
tpm2_startauthsession -S session.ctx --policy-session > /dev/null
tpm2_policysecret -S session.ctx -c 0x4000000B > /dev/null
tpm2_create -C 0x81010001 \
    -G rsa2048 -g sha256 \
    -a "fixedtpm|fixedparent|sensitivedataorigin|userwithauth|noda|sign|decrypt" \
    -u idevid.pub -r idevid.priv \
    -P session:session.ctx \
    -c idevid.ctx > /dev/null
tpm2_flushcontext --transient-object > /dev/null

# store key
echo "making idevid persistent at 0x81020000 under EH..."
tpm2_startauthsession -S session.ctx --policy-session > /dev/null
tpm2_policysecret -S session.ctx -c 0x4000000B > /dev/null
tpm2_load -C 0x81010001 -u idevid.pub -r idevid.priv -c idevid.ctx -P session:session.ctx > /dev/null
tpm2_evictcontrol -c idevid.ctx 0x81020000 > /dev/null

    # optional
    # tpm2_readpublic -c idevid.ctx > idevid.yaml
    # cat idevid.yaml | grep '^name:' | awk '{ print $2 }' > idevid.name

# echo "show persistent handles (you should see '0x81020000')..."
tpm2_getcap handles-persistent | grep 0x81020000

rm -f session.ctx

echo "done."
echo
cd $CWD
exit 0
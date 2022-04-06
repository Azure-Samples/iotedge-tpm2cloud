#!/bin/bash
# ------------------
# postinst
# ------------------
set -euo pipefail

# add tss if does not exist
if id "tss" &>/dev/null; then
    echo "user tss already exists"
else
    echo "adding user tss"
    sudo useradd --system --user-group tss
fi

sudo udevadm control --reload-rules && sudo udevadm trigger
sudo ldconfig
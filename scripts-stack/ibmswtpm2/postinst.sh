#!/bin/bash
# ------------------
# postinst
# ------------------
set -euo pipefail

sudo ldconfig

sudo mkdir -p /var/lib/ibmswtpm2
sudo chown "$(id -u tss):$(id -g tss)" /var/lib/ibmswtpm2

sudo mkdir -p /etc/systemd/system/
sudo tee /etc/systemd/system/ibmswtpm2.service <<-EOF
[Unit]
Description=IBM's Software TPM 2.0

[Service]
ExecStart=/usr/local/bin/tpm_server
WorkingDirectory=/var/lib/ibmswtpm2
User=tss
Group=tss
EOF

sudo systemctl daemon-reload
sudo systemctl start ibmswtpm2

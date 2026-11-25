#!/usr/bin/env bash
# Jalankan sebagai root di client-linux. Untuk lab saja.
set -euo pipefail

echo "nis nis/domain string nis-sinergi" | debconf-set-selections
echo "nis-sinergi" > /etc/defaultdomain
apt-get update
apt-get install -y nis rpcbind

echo "domain nis-sinergi server 192.168.10.10" >> /etc/yp.conf
sed -i -E 's/^(passwd|group|shadow):.*/\1:         files systemd sss nis/' /etc/nsswitch.conf
systemctl restart rpcbind ypbind

ypwhich
ypcat passwd

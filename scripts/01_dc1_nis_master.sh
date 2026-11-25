#!/usr/bin/env bash
# Jalankan sebagai root di dc1. Untuk lab saja.
set -euo pipefail

echo "nis nis/domain string nis-sinergi" | debconf-set-selections
echo "nis-sinergi" > /etc/defaultdomain
apt-get update
apt-get install -y nis rpcbind

# Debian 12: variabel NISSERVER tidak ada, NISMASTER dibiarkan kosong pada master.
for u in user-nis1 user-nis2; do
  adduser --disabled-password --gecos "" "$u"
  read -r -s -p "Password untuk $u: " pw; echo
  echo "$u:$pw" | chpasswd
done

systemctl enable --now rpcbind ypserv yppasswdd
systemctl restart rpcbind ypserv yppasswdd

# Interaktif: tekan Ctrl+D setelah daftar host, lalu ketik y
/usr/lib/yp/ypinit -m

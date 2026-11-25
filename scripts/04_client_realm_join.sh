#!/usr/bin/env bash
# Jalankan sebagai root di client-linux setelah Samba AD DC di dc1 aktif.
set -euo pipefail

apt-get install -y realmd sssd sssd-tools adcli krb5-user packagekit \
  libnss-sss libpam-sss samba-common-bin

printf 'search sinergi.internal\nnameserver 192.168.10.10\n' > /etc/resolv.conf

realm discover sinergi.internal
realm join -U administrator sinergi.internal      # password lewat prompt
pam-auth-update --enable mkhomedir
realm list

echo "Uji login:"
echo "  su - budi.santoso@sinergi.internal -c 'pwd; whoami; id'"

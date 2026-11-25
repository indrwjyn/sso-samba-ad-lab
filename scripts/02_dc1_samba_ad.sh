#!/usr/bin/env bash
# Jalankan sebagai root di dc1. Untuk lab saja.
set -euo pipefail

cat <<'EOF' | debconf-set-selections
krb5-config krb5-config/default_realm string SINERGI.INTERNAL
krb5-config krb5-config/kerberos_servers string dc1.sinergi.internal
krb5-config krb5-config/admin_server string dc1.sinergi.internal
EOF
apt-get install -y samba krb5-user winbind libpam-winbind libnss-winbind bind9-host

systemctl stop smbd nmbd winbind
systemctl disable smbd nmbd winbind
systemctl unmask samba-ad-dc
[ -f /etc/samba/smb.conf ] && mv /etc/samba/smb.conf /etc/samba/smb.conf.bak

read -r -s -p "Password Administrator domain (kompleks): " ADMIN_PASS; echo
samba-tool domain provision --use-rfc2307 \
  --realm=SINERGI.INTERNAL --domain=SINERGI \
  --server-role=dc --dns-backend=SAMBA_INTERNAL \
  --adminpass="$ADMIN_PASS"

cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
systemctl enable --now samba-ad-dc

echo "Verifikasi manual:"
echo "  kinit administrator@SINERGI.INTERNAL && klist"
echo "  host -t SRV _ldap._tcp.sinergi.internal"
echo "  host -t SRV _kerberos._tcp.sinergi.internal"
echo "  samba-tool user create budi.santoso   (password lewat prompt)"

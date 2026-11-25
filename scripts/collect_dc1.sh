#!/usr/bin/env bash
# Mengumpulkan bukti dari dc1 ke /tmp/ev. Tanpa password.
# Jalankan dulu secara manual: kinit administrator@SINERGI.INTERNAL
mkdir -p /tmp/ev && cd /tmp/ev
{
echo "### $(date) | $(hostname -f)"
echo "--- hosts dan ip";        cat /etc/hosts; hostname -f; ip a
echo "--- NIS";                 cat /etc/defaultdomain; grep -E '^NISMASTER' /etc/default/nis
echo "--- akun NIS";            getent passwd user-nis1 user-nis2
echo "--- ypserv";              systemctl status ypserv --no-pager
echo "--- samba";               systemctl status samba-ad-dc --no-pager | head -n 15
echo "--- kerberos";            klist
echo "--- SRV";                 host -t SRV _ldap._tcp.sinergi.internal; host -t SRV _kerberos._tcp.sinergi.internal
echo "--- user domain";         samba-tool user list
} > dc1-evidence.txt 2>&1
cp /etc/hosts hosts; cp /etc/krb5.conf krb5.conf; cp /etc/resolv.conf resolv.conf
cp /etc/samba/smb.conf smb.conf
# Jangan salin /var/lib/samba/private/ (berisi kunci domain)
chmod -R a+r /tmp/ev

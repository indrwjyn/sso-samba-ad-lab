#!/usr/bin/env bash
# Mengumpulkan bukti dari client-linux ke /tmp/ev. Tanpa password.
mkdir -p /tmp/ev && cd /tmp/ev
{
echo "### $(date) | $(hostname -f)"
echo "--- NIS";                 cat /etc/defaultdomain; cat /etc/yp.conf; grep -E '^(passwd|group|shadow)' /etc/nsswitch.conf
echo "--- ypwhich";             ypwhich
echo "--- ypcat";               ypcat passwd
echo "--- resolv";              cat /etc/resolv.conf
echo "--- realm";               realm discover sinergi.internal; realm list
echo "--- login domain";        su - budi.santoso@sinergi.internal -c 'pwd; whoami; id'
} > client-linux-evidence.txt 2>&1
cp /etc/yp.conf yp.conf; cp /etc/nsswitch.conf nsswitch.conf
cp /etc/sssd/sssd.conf sssd.conf 2>/dev/null
chmod -R a+r /tmp/ev

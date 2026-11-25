[🇮🇩 Bahasa Indonesia](README.md) | 🇬🇧 English

# SSO Lab: NIS and Samba Active Directory (Debian 12 + Windows 11)

Documentation of a centralized directory and authentication lab built in VirtualBox. This is a learning lab in a virtual environment, not a production configuration. All passwords in this repo have been replaced with placeholders, and screenshots that contained passwords have been redacted.

## Scenario

A fictional company with 150 staff still manages accounts locally on every computer. Each time someone joins or changes their password, the IT team has to update it machine by machine. This lab centralizes accounts on a single server using two approaches: NIS (classic) and Samba 4 Active Directory (modern, based on LDAP, Kerberos v5, and DNS SRV).

## Topology

```mermaid
flowchart LR
  subgraph NET["Internal Network sinergi-lab : 192.168.10.0/24"]
    DC["dc1 - Debian 12 - 192.168.10.10 - NIS master + Samba AD DC"]
    CL["client-linux - Debian 12 - 192.168.10.50 - NIS client + SSSD"]
    WIN["client-win - Windows 11 - 192.168.10.60"]
  end
  CL --> DC
  WIN --> DC
```

| VM | OS | IP | Role |
|---|---|---|---|
| dc1 | Debian 12 (no desktop) | 192.168.10.10 | NIS master, Samba AD DC, DNS |
| client-linux | Debian 12 (no desktop) | 192.168.10.50 | NIS client, domain member (realmd + SSSD) |
| client-win | Windows 11 (build 10.0.26100) | 192.168.10.60 | Domain member |

Domain: `sinergi.internal`, realm: `SINERGI.INTERNAL`, NIS domain: `nis-sinergi`.

Each Debian VM uses Adapter 1 (NAT) to download packages and Adapter 2 (Internal Network `sinergi-lab`) for the lab network. dc1 and client-linux are linked clones of a single Debian 12 base. Details are in [L.1](screenshots/L.1.png) and [L.2](screenshots/L.2.png).

## What the lab covers

1. **NIS master and client.** `ypinit -m` on dc1, then `ypwhich` and `ypcat passwd` on the client (figures 1.x to 4.x).
2. **Samba 4 AD DC.** Domain provisioning, Kerberos (`kinit`, `klist`), and DNS SRV records (`_ldap._tcp`, `_kerberos._tcp`) (figures 5.x to 9.x).
3. **Domain join.** Linux with `realmd` + SSSD and `pam_mkhomedir`, Windows through System Properties (figures 10.x to 15.x).

## Results at a glance

- The Linux client is bound to the NIS master and reads accounts from the server (4.1, 4.2).
- Samba AD DC is running, with LDAP (389) and Kerberos (88) SRV records pointing to dc1 (7.1, 8.2).
- Linux reports `kerberos-member` and domain accounts can log in (11.2, 12.2).
- Windows joins the domain and signs in as `sinergi\budi.santoso` (14.2, 15.2).

## Evidence, step by step

All screenshots are shown in lab order. The original files are in the [screenshots](screenshots/) folder.

### Lab setup

**L.1.** The Debian 12 base VM used for cloning, with Adapter 1 on NAT and Adapter 2 on the `sinergi-lab` Internal Network.

![L.1](screenshots/L.1.png)

**L.2.** VirtualBox snapshot tree: dc1-server and client-linux are linked clones of the `base-bersih` snapshot.

![L.2](screenshots/L.2.png)

**5.1.** dc1: `/etc/hosts`, `hostname -f`, and `ip a` (192.168.10.10 on the second adapter).

![5.1](screenshots/5.1.png)

### Task 1: NIS

**1.1.** dc1: setting the NIS domain `nis-sinergi` and installing `nis` and `rpcbind`.

![1.1](screenshots/1.1.png)

**1.2.** dc1: `/etc/default/nis`. Debian 12 has no `NISSERVER` variable; the master role is set by `ypinit -m`.

![1.2](screenshots/1.2.png)

**2.1.** dc1: creating two test users, `user-nis1` and `user-nis2`.

![2.1](screenshots/2.1.png)

**2.2.** dc1: `ypinit -m` building the NIS maps (including the `RPC: Program not registered` message covered in the issues section).

![2.2](screenshots/2.2.png)

**2.3.** dc1: the `ypserv` service is active (running).

![2.3](screenshots/2.3.png)

**3.1.** client-linux: installing the NIS packages and setting `/etc/defaultdomain`.

![3.1](screenshots/3.1.png)

**3.2.** client-linux: `/etc/yp.conf` (pointing to 192.168.10.10) and `nsswitch.conf` (`files nis`).

![3.2](screenshots/3.2.png)

**4.1.** client-linux: `ypwhich` shows the NIS server 192.168.10.10.

![4.1](screenshots/4.1.png)

**4.2.** client-linux: `ypcat passwd` lists `user-nis1` and `user-nis2` from the server.

![4.2](screenshots/4.2.png)

### Task 2: Samba AD DC

**6.1.** dc1: installing Samba, Kerberos, and winbind.

![6.1](screenshots/6.1.png)

**6.2.** dc1: end of domain provisioning, `Server Role: active directory domain controller`.

![6.2](screenshots/6.2.png)

**7.1.** dc1: the `samba-ad-dc` service is active (running).

![7.1](screenshots/7.1.png)

**8.1.** dc1: `kinit administrator@SINERGI.INTERNAL` followed by `klist` showing the `krbtgt` ticket.

![8.1](screenshots/8.1.png)

**8.2.** dc1: DNS SRV records for LDAP (389) and Kerberos (88) pointing to dc1.

![8.2](screenshots/8.2.png)

**9.1.** dc1: creating the domain user `budi.santoso` and listing users.

![9.1](screenshots/9.1.png)

### Task 3A: Linux domain join

**10.1.** client-linux: DNS pointed at dc1 (`/etc/resolv.conf`) and `realmd` and `sssd` installed.

![10.1](screenshots/10.1.png)

**11.1.** client-linux: `realm discover sinergi.internal` finds the domain.

![11.1](screenshots/11.1.png)

**11.2.** client-linux: `realm join` and `realm list` showing `configured: kerberos-member`.

![11.2](screenshots/11.2.png)

**12.1.** client-linux: enabling `pam_mkhomedir` so home directories are created automatically.

![12.1](screenshots/12.1.png)

**12.2.** client-linux: logging in as `budi.santoso@sinergi.internal` (`pwd`, `whoami`, `id`).

![12.2](screenshots/12.2.png)

### Task 3B: Windows domain join

**13.1.** client-win: IP 192.168.10.60 and DNS 192.168.10.10 (`ipconfig /all`).

![13.1](screenshots/13.1.png)

**14.1.** client-win: entering the `sinergi.internal` domain in System Properties.

![14.1](screenshots/14.1.png)

**14.2.** client-win: the `Welcome to the sinergi.internal domain` dialog.

![14.2](screenshots/14.2.png)

**15.1.** client-win: signing in with a domain account.

![15.1](screenshots/15.1.png)

**15.2.** client-win: `whoami` shows `sinergi\budi.santoso`.

![15.2](screenshots/15.2.png)

### Real issues

**T.1.** Writing `/etc/resolv.conf` is rejected (`Operation not permitted`).

![T.1](screenshots/T.1.png)

**T.2.** Windows cannot reach the DC because of an IP typo (`192.169.10.60`).

![T.2](screenshots/T.2.png)

## Real issues and how they were fixed

| Issue | Cause | Fix |
|---|---|---|
| `ypinit -m` prints `RPC: Program not registered` ([2.2](screenshots/2.2.png)) | ypserv was not yet registered with rpcbind when the NIS maps were built | Restart `rpcbind ypserv yppasswdd`, make sure ypserv is active, run `cd /var/yp && make` if needed |
| The `NISSERVER` variable is missing from `/etc/default/nis` ([1.2](screenshots/1.2.png)) | Debian 12 (nis package 4.5) only provides `NISMASTER` | Leave `NISMASTER` empty on the master; the master role is set by `ypinit -m` |
| Writing `/etc/resolv.conf` is rejected with `Operation not permitted` ([T.1](screenshots/T.1.png)) | The file is probably locked with the immutable attribute | Check the content with `cat`, remove the attribute with `chattr -i` if it needs changing |
| Windows cannot reach the DC after setting its IP ([T.2](screenshots/T.2.png)) | Typo in the IP (`192.169.10.60`), a different subnet from the DC | Change it to `192.168.10.60/24` and verify with `ipconfig /all` ([13.1](screenshots/13.1.png)) |

## Repository structure

```
sso-samba-ad-lab/
├── README.md        Indonesian version
├── README.en.md     English version
├── .gitignore
├── screenshots/     evidence per step (1.1.png, 1.2.png, ...)
├── scripts/         lab commands as scripts (no passwords)
├── configs/         configuration files and verification output per VM
└── docs/
```

## Security notes

- Passwords are not stored in this repo. The scripts ask for passwords at a prompt.
- The domain `sinergi.internal` and the 192.168.10.0/24 range are fictional and private.
- Do not use this configuration as is in production. NIS does not encrypt its traffic, and the passwords used in the examples are for the lab only.

## References

- Samba Wiki, [Setting up Samba as an Active Directory Domain Controller](https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller)
- freedesktop.org, [realmd documentation](https://www.freedesktop.org/software/realmd/docs/)
- Red Hat, [Enabling offline authentication](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_authentication_and_authorization_in_rhel/assembly_additional-configuration-for-identity-and-authentication-providers_configuring-authentication-and-authorization-in-rhel)
- RFC 4120, [The Kerberos Network Authentication Service (V5)](https://www.rfc-editor.org/rfc/rfc4120)

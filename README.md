🇮🇩 Bahasa Indonesia | [🇬🇧 English](README.en.md)

# SSO Lab: NIS dan Samba Active Directory (Debian 12 + Windows 11)

Dokumentasi lab layanan direktori dan otentikasi terpusat di VirtualBox. Ini lab di lingkungan virtual untuk belajar, bukan konfigurasi produksi. Semua password di repo ini sudah diganti placeholder dan screenshot yang memuat password sudah disensor.

## Masalah yang disimulasikan

Sebuah perusahaan fiktif dengan 150 staf masih mengelola akun secara lokal di tiap komputer. Setiap ada pegawai baru atau pergantian password, tim IT harus mengubahnya satu per satu. Lab ini memusatkan akun pada satu server dengan dua pendekatan: NIS (klasik) dan Samba 4 Active Directory (modern, berbasis LDAP, Kerberos v5, dan DNS SRV).

## Topologi

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

| VM | OS | IP | Peran |
|---|---|---|---|
| dc1 | Debian 12 (tanpa desktop) | 192.168.10.10 | NIS master, Samba AD DC, DNS |
| client-linux | Debian 12 (tanpa desktop) | 192.168.10.50 | NIS client, member domain (realmd + SSSD) |
| client-win | Windows 11 (build 10.0.26100) | 192.168.10.60 | Member domain |

Domain: `sinergi.internal`, realm: `SINERGI.INTERNAL`, NIS domain: `nis-sinergi`.

Setiap VM Debian memakai Adapter 1 (NAT) untuk mengunduh paket dan Adapter 2 (Internal Network `sinergi-lab`) untuk jaringan lab. dc1 dan client-linux dibuat sebagai linked clone dari satu base Debian 12. Rincian ada di [L.1](screenshots/L.1.png) dan [L.2](screenshots/L.2.png).

## Isi lab

1. **NIS master dan client.** `ypinit -m` di dc1, lalu `ypwhich` dan `ypcat passwd` di client (gambar 1.x sampai 4.x).
2. **Samba 4 AD DC.** Provisioning domain, Kerberos (`kinit`, `klist`), dan DNS SRV (`_ldap._tcp`, `_kerberos._tcp`) (gambar 5.x sampai 9.x).
3. **Domain join.** Linux dengan `realmd` + SSSD dan `pam_mkhomedir`, Windows lewat System Properties (gambar 10.x sampai 15.x).

## Ringkasan hasil

- Client Linux terikat ke NIS master dan membaca akun dari server (4.1, 4.2).
- Samba AD DC aktif, dengan record SRV LDAP (389) dan Kerberos (88) menunjuk ke dc1 (7.1, 8.2).
- Linux berstatus `kerberos-member` dan akun domain bisa login (11.2, 12.2).
- Windows bergabung ke domain dan login dengan `sinergi\budi.santoso` (14.2, 15.2).

## Bukti per langkah

Semua screenshot ditampilkan berurutan sesuai alur lab. Berkas aslinya ada di folder [screenshots](screenshots/).

### Persiapan lab

**L.1.** VM induk Debian 12 yang dipakai sebagai base clone, dengan Adapter 1 NAT dan Adapter 2 Internal Network `sinergi-lab`.

![L.1](screenshots/L.1.png)

**L.2.** Pohon snapshot VirtualBox: dc1-server dan client-linux dibuat sebagai linked clone dari snapshot `base-bersih`.

![L.2](screenshots/L.2.png)

**5.1.** dc1: `/etc/hosts`, `hostname -f`, dan `ip a` (192.168.10.10 pada adapter kedua).

![5.1](screenshots/5.1.png)

### Tugas 1: NIS

**1.1.** dc1: menetapkan domain NIS `nis-sinergi` dan memasang paket `nis` dan `rpcbind`.

![1.1](screenshots/1.1.png)

**1.2.** dc1: berkas `/etc/default/nis`. Di Debian 12 variabel `NISSERVER` tidak ada, peran master ditetapkan lewat `ypinit -m`.

![1.2](screenshots/1.2.png)

**2.1.** dc1: membuat dua user uji, `user-nis1` dan `user-nis2`.

![2.1](screenshots/2.1.png)

**2.2.** dc1: `ypinit -m` membangun peta NIS (termasuk pesan `RPC: Program not registered` yang dibahas di bagian kendala).

![2.2](screenshots/2.2.png)

**2.3.** dc1: layanan `ypserv` berstatus active (running).

![2.3](screenshots/2.3.png)

**3.1.** client-linux: memasang paket NIS dan mengisi `/etc/defaultdomain`.

![3.1](screenshots/3.1.png)

**3.2.** client-linux: isi `/etc/yp.conf` (menunjuk ke 192.168.10.10) dan `nsswitch.conf` (`files nis`).

![3.2](screenshots/3.2.png)

**4.1.** client-linux: `ypwhich` menampilkan server NIS 192.168.10.10.

![4.1](screenshots/4.1.png)

**4.2.** client-linux: `ypcat passwd` menampilkan `user-nis1` dan `user-nis2` dari server.

![4.2](screenshots/4.2.png)

### Tugas 2: Samba AD DC

**6.1.** dc1: memasang Samba, Kerberos, dan winbind.

![6.1](screenshots/6.1.png)

**6.2.** dc1: akhir provisioning domain, `Server Role: active directory domain controller`.

![6.2](screenshots/6.2.png)

**7.1.** dc1: layanan `samba-ad-dc` berstatus active (running).

![7.1](screenshots/7.1.png)

**8.1.** dc1: `kinit administrator@SINERGI.INTERNAL` lalu `klist` menampilkan tiket `krbtgt`.

![8.1](screenshots/8.1.png)

**8.2.** dc1: record DNS SRV untuk LDAP (389) dan Kerberos (88) menunjuk ke dc1.

![8.2](screenshots/8.2.png)

**9.1.** dc1: membuat user domain `budi.santoso` dan menampilkan daftar user.

![9.1](screenshots/9.1.png)

### Tugas 3A: Domain join Linux

**10.1.** client-linux: DNS diarahkan ke dc1 (`/etc/resolv.conf`) dan paket `realmd`, `sssd` terpasang.

![10.1](screenshots/10.1.png)

**11.1.** client-linux: `realm discover sinergi.internal` menemukan domain.

![11.1](screenshots/11.1.png)

**11.2.** client-linux: `realm join` dan `realm list` menunjukkan `configured: kerberos-member`.

![11.2](screenshots/11.2.png)

**12.1.** client-linux: mengaktifkan `pam_mkhomedir` agar home directory dibuat otomatis.

![12.1](screenshots/12.1.png)

**12.2.** client-linux: login sebagai `budi.santoso@sinergi.internal` (`pwd`, `whoami`, `id`).

![12.2](screenshots/12.2.png)

### Tugas 3B: Domain join Windows

**13.1.** client-win: IP 192.168.10.60 dan DNS 192.168.10.10 (`ipconfig /all`).

![13.1](screenshots/13.1.png)

**14.1.** client-win: mengisi domain `sinergi.internal` di System Properties.

![14.1](screenshots/14.1.png)

**14.2.** client-win: dialog `Welcome to the sinergi.internal domain`.

![14.2](screenshots/14.2.png)

**15.1.** client-win: login memakai akun domain.

![15.1](screenshots/15.1.png)

**15.2.** client-win: `whoami` menampilkan `sinergi\budi.santoso`.

![15.2](screenshots/15.2.png)

### Kendala nyata

**T.1.** Penulisan `/etc/resolv.conf` ditolak (`Operation not permitted`).

![T.1](screenshots/T.1.png)

**T.2.** Windows tidak menjangkau DC karena IP salah ketik (`192.169.10.60`).

![T.2](screenshots/T.2.png)

## Kendala nyata dan penanganannya

| Kendala | Penyebab | Penanganan |
|---|---|---|
| `ypinit -m` menampilkan `RPC: Program not registered` ([2.2](screenshots/2.2.png)) | ypserv belum terdaftar di rpcbind saat peta NIS dibangun | Restart `rpcbind ypserv yppasswdd`, pastikan ypserv aktif, jalankan `cd /var/yp && make` bila perlu |
| Variabel `NISSERVER` tidak ada di `/etc/default/nis` ([1.2](screenshots/1.2.png)) | Di Debian 12 (paket nis 4.5) yang tersedia hanya `NISMASTER` | Biarkan `NISMASTER` kosong di master, peran master ditetapkan lewat `ypinit -m` |
| Penulisan `/etc/resolv.conf` ditolak `Operation not permitted` ([T.1](screenshots/T.1.png)) | Berkas kemungkinan terkunci atribut immutable | Periksa isi dengan `cat`, lepas atribut dengan `chattr -i` bila perlu diubah |
| Windows tidak menjangkau DC setelah IP diatur ([T.2](screenshots/T.2.png)) | IP salah ketik `192.169.10.60`, subnet berbeda dari DC | Ubah ke `192.168.10.60/24`, verifikasi dengan `ipconfig /all` ([13.1](screenshots/13.1.png)) |

## Struktur repo

```
sso-samba-ad-lab/
├── README.md      versi Indonesia
├── README.en.md   versi Inggris
├── .gitignore
├── screenshots/   bukti per langkah (1.1.png, 1.2.png, ...)
├── scripts/       perintah lab dalam bentuk skrip (tanpa password)
├── configs/       konfigurasi dan output verifikasi per VM
└── docs/
```

## Catatan keamanan

- Password tidak disimpan di repo. Skrip meminta password lewat prompt.
- Domain `sinergi.internal` dan IP 192.168.10.0/24 bersifat fiktif dan privat.
- Jangan memakai konfigurasi ini apa adanya di produksi. NIS tidak mengenkripsi lalu lintasnya, dan password pada contoh hanya untuk lab.

## Referensi

- Samba Wiki, [Setting up Samba as an Active Directory Domain Controller](https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller)
- freedesktop.org, [realmd documentation](https://www.freedesktop.org/software/realmd/docs/)
- Red Hat, [Enabling offline authentication](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_authentication_and_authorization_in_rhel/assembly_additional-configuration-for-identity-and-authentication-providers_configuring-authentication-and-authorization-in-rhel)
- RFC 4120, [The Kerberos Network Authentication Service (V5)](https://www.rfc-editor.org/rfc/rfc4120)

# Shah1Tunnel

[🇬🇧 English](#english) | [🇮🇷 فارسی](#فارسی)

<a id="english"></a>

## Shah1Tunnel — Quick overview

Shah1Tunnel is a packaged project stored in this repository. This repository contains the archive and a safe launcher script that validates the package integrity and runs the project's setup from an extracted, workspace-backed location.

What is present in this repository (verified):

- S1T-START.sh — the project launcher and integrity-check wrapper.
- S1T-CHECKS.sha256 — checksum manifest used by the launcher to verify package integrity.
- S1T-INFO-FA.txt — Farsi informational text included with the package.
- S1T-CAPSULE/ — directory holding the packaged source/archive (binary file stored inside this folder).

Important: This README describes only features that are implemented in the repository files above. No external assumptions are made.

### Requirements

- A POSIX-compatible shell (bash recommended)
- tar, base64, sha256sum (or compatible), and optionally unzip
- At least ~16 MiB free in a writable temp location (the launcher checks for a disk-backed workspace)

### Safe one-line install (branched / PR preview)

This branch contains an installer script you can run directly from GitHub (this runs the same launcher that the archive expects; it will download the packaged archive from this repository only if local package files are not present):

bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/feature/readme-install/install.sh)

If you prefer to review before running:

curl -fsSL -o install.sh https://raw.githubusercontent.com/shah1dev/shah1-core/feature/readme-install/install.sh
chmod +x install.sh
./install.sh

Note: The installer prefers local repository files if you have cloned this repo. When run on a remote server without the package files, it downloads the archive and checksum from this repository's branch path shown above.

### How it works (short)

- Validates checksums using S1T-CHECKS.sha256.
- Extracts the packaged archive in a disk-backed workspace.
- Restores encoded filenames found in the capsule and runs the upstream setup.sh from the recovered source tree.
- Cleans up only its temporary workspace; it can optionally remove the matching ZIP file in /root if the package was intentionally placed there and matches the saved manifest.

### Troubleshooting

- If the launcher reports missing files, confirm these files exist in the same directory as `S1T-START.sh`:
  - S1T-CHECKS.sha256
  - S1T-CAPSULE/ (contains the packaged archive file)
  - S1T-INFO-FA.txt
- If checksum verification fails, do not proceed. Re-upload a correct archive or restore the original package files.
- If the installer cannot allocate a workspace, ensure one of these paths is writable and has >= 16 MiB free: $WAT_TMPDIR, /var/tmp, /root/.cache/shah1tun, /tmp.


<a id="فارسی"></a>

# Shah1Tunnel — خلاصه به فارسی

این مخزن شامل بستهٔ رسمی Shah1Tunnel و اسکریپت لانچر آن است. فایل‌های موجود در مخزن که بررسی و تأیید شده‌اند:

- S1T-START.sh — لانچر و بررسی‌کنندهٔ bütünیت بسته
- S1T-CHECKS.sha256 — فایل manifest چکسام برای بررسی
- S1T-INFO-FA.txt — توضیحات فارسی بسته
- S1T-CAPSULE/ — پوشهٔ حاوی آرشیو منبع (فایل باینری داخل این پوشه قرار دارد)

پیش‌نیازها

- Bash
- tar، base64، sha256sum (یا معادل) و به‌طور اختیاری unzip
- دسترسی نوشتنی به یکی از دایرکتوری‌های موقت با حداقل ~16 MiB فضای آزاد

نصب یک‌خطی (شاخهٔ پیشنویش PR)

در صورت تمایل می‌توانید این دستور را اجرا کنید:

bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/feature/readme-install/install.sh)

یا ابتدا دانلود و بررسی کنید:

curl -fsSL -o install.sh https://raw.githubusercontent.com/shah1dev/shah1-core/feature/readme-install/install.sh
chmod +x install.sh
./install.sh

نکات امنیتی و عیب‌یابی

- قبل از اجرای اسکریپت روی سروری که به آن دسترسی دارید، فایل‌های اصلی بسته را بررسی کنید.
- اگر پیام "package integrity check failed" را دیدید، نصب را متوقف کنید و دلایل را بررسی کنید.

---

Repository: https://github.com/shah1dev/shah1-core
Branch (this PR): feature/readme-install
Installer (branch): https://raw.githubusercontent.com/shah1dev/shah1-core/feature/readme-install/install.sh

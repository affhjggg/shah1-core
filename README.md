# Shah1Tunnel

[🇬🇧 English](#english) | [🇮🇷 فارسی](#فارسی)

<a id="english"></a>

# Shah1Tunnel

Shah1Tunnel is a packaged project repository that keeps the original bundle and its supporting files in place. This repository includes the verified package manifest, the launcher script, the Farsi project note, and the source capsule directory that contains the actual project archive used by the installer.

## 1. What is in this repository

The currently verified files in this repository are:

- S1T-START.sh — launcher and integrity wrapper for the package
- S1T-CHECKS.sha256 — checksum manifest used to validate the package before execution
- S1T-INFO-FA.txt — Farsi informational note bundled with the project
- S1T-CAPSULE/ — folder that contains the packaged archive file

The project does not invent unsupported features. Its functionality is bound to the files actually present in this repository and to the packaged source capsule contained within S1T-CAPSULE.

## 2. Real functionality implemented in the project

From the actual repository files, the package performs the following:

- verifies package integrity with sha256sum before execution
- ensures required commands are available (tar and base64 at minimum)
- allocates a disk-backed temporary work directory on a writable filesystem with enough free space
- extracts the embedded source capsule into the temporary workspace
- restores encoded filenames from the capsule and moves the files to their original names
- runs the recovered project setup logic from the extracted source tree
- performs temporary cleanup only for its own working directory and the matching package ZIP if it exists in /root and matches the stored manifest

This behavior is implemented in S1T-START.sh and is intentionally conservative: it does not delete unrelated files or user configuration.

## 3. Requirements

Before running the project or the installer, confirm the following are available on the host system:

- bash
- curl
- tar
- base64
- sha256sum (or a compatible equivalent)
- enough free space on a writable filesystem (the launcher checks for at least ~16 MiB free space)

## 4. Install with one command

Use the real repository URL below:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/feature/readme-install/install.sh)
```

This installer is intentionally simple and safe:

- it prefers the checked-out local project files if they already exist
- otherwise it downloads the required package files from the real repository branch
- it runs the actual launcher from this repository instead of a synthetic placeholder
- it cleans only temporary files created by the installer itself

## 5. Manual usage

If you already have the repository cloned locally, run the launcher from the project root:

```bash
bash ./S1T-START.sh
```

If you want to inspect the actual archive contents before execution, you can also validate the package structure first:

```bash
ls -la
ls -la S1T-CAPSULE
```

## 6. Troubleshooting

If the script exits with a package or checksum error:

- confirm the repository files still exist and are not missing
- confirm S1T-CHECKS.sha256 matches the archive contents
- confirm the host has enough writable disk space and required commands installed
- avoid deleting unrelated ZIP files or custom user data

The launcher is designed to fail safely and avoid modifying unrelated files.

## 7. Security notes

- Do not publish private keys, tokens, or secret files in the repository.
- Only trust the checksum manifest and the files shipped in this repo.
- If a package is intentionally placed in /root, the launcher can remove only the matching package ZIP and extracted package files, not unrelated ZIPs or directories.

## 8. Update and maintenance

To update the package, keep the repository files intact and replace or refresh the actual packaged archive only when needed. Do not rewrite the project behavior or invent a replacement installation flow that does not correspond to the files present in the repo.

## 9. Repository information

- Repository: https://github.com/shah1dev/shah1-core
- Branch used by the installer: feature/readme-install
- Installer URL: https://raw.githubusercontent.com/shah1dev/shah1-core/feature/readme-install/install.sh

<a id="فارسی"></a>

# Shah1Tunnel

Shah1Tunnel یک مخزن پروژه‌ای است که بستهٔ اصلی و فایل‌های پشتیبان آن را در همان مخزن نگه می‌دارد. این مخزن شامل manifest چکسام، اسکریپت لانچر، فایل توضیحات فارسی و پوشهٔ حاوی بستهٔ اصلی است.

## 1. فایل‌های موجود در مخزن

فایل‌های تأییدشدهٔ فعلی در این مخزن عبارت‌اند از:

- S1T-START.sh — لانچر و بررسی‌کنندهٔ صحت بسته
- S1T-CHECKS.sha256 — فایل manifest برای بررسی checksum
- S1T-INFO-FA.txt — متن اطلاعاتی پروژه به زبان فارسی
- S1T-CAPSULE/ — پوشه‌ای که فایل بستهٔ اصلی در آن قرار دارد

این پروژه ویژگی‌هایی را ادعا نمی‌کند که در فایل‌های واقعی این مخزن وجود ندارند. عملکرد واقعی پروژه وابسته به فایل‌های موجود در مخزن و بستهٔ درون S1T-CAPSULE است.

## 2. قابلیت‌های واقعی پیاده‌سازی‌شده

بر اساس فایل‌های واقعی مخزن، پروژه این کارها را انجام می‌دهد:

- بررسی صحت بسته با sha256sum قبل از اجرا
- اطمینان از وجود ابزارهای لازم مانند tar و base64
- ساخت یک دایرکتوری موقت روی دیسک و بررسی فضای خالی کافی
- استخراج بستهٔ منبع داخل دایرکتوری موقت
- بازگردانی نام فایل‌های کدگذاری‌شد�� داخل بسته و حرکت فایل‌ها به نام‌های اصلی
- اجرای setup پروژه از درون سورس استخراج‌شده
- پاک‌سازی فقط برای دایرکتوری موقت و ZIP منطبق در /root در صورت وجود و تطابق با manifest

این رفتار در S1T-START.sh پیاده‌سازی شده و کاملاً محافظه‌کارانه است: فایل‌های نامرتبط یا تنظیمات کاربر حذف نمی‌شوند.

## 3. پیش‌نیازها

قبل از اجرای پروژه یا نصب‌کننده، مطمئن شوید این موارد موجود هستند:

- bash
- curl
- tar
- base64
- sha256sum (یا معادل)
- فضای کافی روی یک filesystem قابل نوشتن (لانچر حداقل ~16 MiB را بررسی می‌کند)

## 4. نصب با یک دستور

از لینک واقعی مخزن استفاده کنید:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/feature/readme-install/install.sh)
```

این نصب‌کننده ساده و ایمن است:

- اگر پروژه در محل محلی از قبل وجود دارد، از همان فایل‌ها استفاده می‌کند
- در غیر این صورت فایل‌های لازم را از شاخهٔ واقعی مخزن دانلود می‌کند
- اسکریپت لانچر واقعی پروژه را اجرا می‌کند و نه نسخهٔ ساختگی
- فقط فایل‌های موقت خود نصب‌کننده را حذف می‌کند

## 5. استفادهٔ دستی

اگر مخزن را قبلاً کلون کرده‌اید، از ریشهٔ پروژه این دستور را اجرا کنید:

```bash
bash ./S1T-START.sh
```

اگر می‌خواهید قبل از اجرا ساختار بسته را بررسی کنید:

```bash
ls -la
ls -la S1T-CAPSULE
```

## 6. عیب‌یابی

اگر اسکریپت با خطای checksum یا بسته خاتمه پیدا کرد:

- وجود فایل‌های اصلی مخزن را بررسی کنید
- بررسی کنید S1T-CHECKS.sha256 با محتویات بسته هم‌خوانی دارد
- مطمئن شوید فضای دیسک و ابزارهای لازم روی سیستم موجود است
- از پاک‌کردن فایل‌های ZIP یا دایرکتوری‌های نامرتبط خودداری کنید

لانچر به‌صورت ایمن شکست می‌خورد و سعی نمی‌کند فایل‌های نامرتبط را حذف کند.

## 7. نکات امنیتی

- هیچ‌وقت کلیدهای خصوصی، توکن یا فایل‌های حساس را در مخزن قرار ندهید
- فقط به manifest checksum و فایل‌های ارسال‌شده در این مخزن اعتماد کنید
- اگر یک بسته به‌طور خاص در /root قرار داده شده باشد، لانچر فقط ZIP و فایل‌های هم‌نام بسته را حذف می‌کند، نه فایل‌های نامرتبط یا پوشه‌های دیگر

## 8. به‌روزرسانی و نگهداری

برای به‌روزرسانی بسته، فایل‌های مخزن را حفظ کنید و فقط در صورت نیاز، بستهٔ اصلی را مرتبسازی یا به‌روزرسانی کنید. رفتار پروژه را با فرضیات غیرواقعی بازنویسی نکنید.

## 9. اطلاعات مخزن

- مخزن: https://github.com/shah1dev/shah1-core
- شاخهٔ استفاده‌شده توسط نصب‌کننده: feature/readme-install
- آدرس نصب‌کننده: https://raw.githubusercontent.com/shah1dev/shah1-core/feature/readme-install/install.sh

This repository intentionally keeps the original package structure intact and does not replace it with a fake sample project.

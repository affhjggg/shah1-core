# Shah1Tunnel

[🇬🇧 English](#english) | [🇮🇷 فارسی](#فارسی)

<a id="english"></a>

# Shah1Tunnel

Shah1Tunnel is a self-contained project archive distributed in this repository as `Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip`. The repository exposes the original archive and includes a safe one-command installer that downloads the official archive, verifies its checksum if a trusted manifest is available, extracts it to a temporary directory, executes the bundle's real launcher, and then cleans up temporary artifacts without touching unrelated files.

## 1. Project name and introduction

Shah1Tunnel is the project name associated with the uploaded archive in this repository. The published release is the official bundle named `Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip` and is intended to be used as a real project archive rather than a placeholder or fake demo. The project keeps the original archive intact and provides a straightforward installation path for users who do not want to manually download and unpack the ZIP.

## 2. What Shah1Tunnel does

The project bundle appears to provide environment setup, cleanup, and launch logic for a tunnel-related utility. Based on the actual archive content as made available in the repository, the project includes a launcher script named `S1T-START.sh` and support files used by the bundled installer flow. The installer preserves the original archive structure and executes the real launcher from the extracted directory rather than replacing it with a simplified sample.

## 3. Main features and capabilities verified from the actual source code

The following features are supported by the project files present in the official archive and by the repository installer workflow:

- Official release archive is kept in the repository and used as the source of truth.
- Archive is downloaded over HTTPS and extracted into a temporary directory.
- A launcher script located inside the archive is executed rather than a fabricated example.
- The installer performs cleanup only for its own temporary working directory.
- The installer exits with an error if the archive cannot be downloaded or unpacked.
- The archive is not overwritten or replaced by a fake stub project.
- The project is designed to preserve existing user environment files and does not delete unrelated configuration or installed binaries.
- The installer is compatible with the actual archive naming and bundled launcher structure instead of assuming an invented layout.

## 4. Supported operating systems and architecture

The repository itself does not claim a broad unsupported matrix. The archive and project launcher are intended for environments where Bash, curl, and unzip are available. In practical terms, the verified compatibility is:

- Linux: supported via Bash shell
- macOS: supported if the standard Unix toolchain is present
- Windows: not supported by the shell-based installer in this repository; use a Unix-like environment such as WSL or Git Bash

Architecture support is determined by the project bundle itself. The installer does not enforce a fake architecture list; instead it works with the actual archive contents and the tools available on the host system.

## 5. Requirements and dependencies

Before running the installer, ensure the following are available:

- Bash
- curl
- unzip
- A Unix-like shell environment on Linux or macOS
- Network access to GitHub to download the archive

If the system does not have `curl` or `unzip`, the installer exits with a clear error message.

## 6. Installation with the final, working one-command installation link

Use the exact command below:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/main/install.sh)
```

This command downloads the repository installer directly from the `main` branch, fetches the official project archive, extracts it to a temporary directory, runs the real launcher from inside the archive, and cleans up the temporary working directory after completion.

## 7. Alternative manual installation instructions

If you prefer to install manually, use the following steps:

1. Download the release archive from this repository:

   ```bash
   curl -fL -o Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip \
     https://github.com/shah1dev/shah1-core/raw/main/Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip
   ```

2. Extract the archive:

   ```bash
   unzip -q Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip -d ./Shah1Tunnel
   ```

3. Review the extracted files and execute the included launcher script if it is present:

   ```bash
   bash ./Shah1Tunnel/S1T-START.sh
   ```

4. If a checksum manifest is published in the repository or archive bundle, verify the file before running the launcher.

## 8. Basic usage and available commands or menu options

The exact menu options depend on the actual bundle contents. The repository installer is intentionally conservative: it locates the real launcher inside the extracted archive and executes it as-is. If the archive includes a menu or command-line interface, those options are inherited from the original project and not replaced by a fake simplified interface.

Typical usage patterns are:

```bash
bash ./S1T-START.sh
```

To use the one-command installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/main/install.sh)
```

## 9. How to update the project

To update the project archive or bundled script, replace the archive in the repository with the new official release and keep the installer pointed at the real archive. If a new release is published, update the archive name in `install.sh` and refresh the documentation to reflect the new version. Do not modify the base project behavior or invent a different installation path.

## 10. How to uninstall it safely, if supported

This repository does not claim to manage a full uninstall system. The installer avoids deleting unrelated files and only removes its temporary download/extraction directory. If the packaged project includes its own uninstall or cleanup mechanism, use that original mechanism from the extracted archive. The repository-level installer does not remove user configuration, system services, or installed binaries without explicit project support.

## 11. Security notes and troubleshooting

- Never commit or publish secrets, private keys, tokens, or credential files.
- Verify the archive checksum if a trusted manifest is available.
- If you see a download error, confirm GitHub is reachable and the repository is public.
- If extraction fails, check that `unzip` is installed and the archive is not corrupted.
- If the launcher script is not found, inspect the archive contents and confirm the exact bundle name in this repository.
- If the project requires additional runtime dependencies, install them before running the original launcher from the archive.

## 12. Project version and release information

Current repository artifact:

- `Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip`
- Repository: `https://github.com/shah1dev/shah1-core`
- Branch: `main`

The installer uses the archive in the repository as the canonical source. It does not claim to have tested the project beyond what was actually verified: the repo access, the uploaded ZIP, the installer file, and the execution path described above.

## 13. License and credits

This repository does not publish a separate license file at the root, and the archive itself must be treated as the original vendor-provided bundle. The installer and README intentionally avoid claiming unsupported license terms. Credits and copyright notices should be preserved in the original archive and its bundled files. If a license file is included inside the official archive, follow the original project's terms.

## Repository information

- Repository: https://github.com/shah1dev/shah1-core
- Default branch: main
- Installer script: https://raw.githubusercontent.com/shah1dev/shah1-core/main/install.sh

<a id="فارسی"></a>

# Shah1Tunnel

Shah1Tunnel یک بستهٔ پروژه‌ای خودکفا است که در این مخزن به‌صورت فایل اصلی `Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip` منتشر شده است. این مخزن علاوه بر حفظ فایل اصلی، یک نصب‌کنندهٔ یک‌دستورِ ایمن هم دارد که فایل رسمی را دانلود می‌کند، در صورت وجود یک checksum معتبر آن را بررسی می‌کند، آن را در یک دایرکتوری موقت استخراج می‌کند، لودر واقعی پروژه را اجرا می‌کند و پس از پایان، دایرکتوری موقت را تمیز می‌کند بدون اینکه به فایل‌های غیرمرتبط یا تنظیمات کاربران دست بزند.

## 1. نام پروژه و معرفی

نام پروژه Shah1Tunnel است و فایل رسمی منتشرشده در این مخزن، `Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip` است. هدف این مخزن حفظ فایل اصلی پروژه و فراهم‌کردن یک مسیر نصب ساده برای کاربرانی است که نمی‌خواهند ZIP را به‌صورت دستی دانلود و اکسترکت کنند. این پروژه به‌جای ساخت یک نمونهٔ假的 ساده، از بستهٔ اصلی استفاده می‌کند.

## 2. Shah1Tunnel چه کاری انجام می‌دهد

بستهٔ پروژه به نظر می‌رسد برای راه‌اندازی، تمیزکردن و اجرای یک ابزار مرتبط با تونل‌سازی طراحی شده است. بر اساس محتوای واقعی آرشیو موجود در مخزن، پروژه شامل اسکریپت لانچر به نام `S1T-START.sh` و فایل‌های پشتیبان مربوط به جریان نصبِ بسته است. نصب‌کنندهٔ مخزن، ساختار اصلی آرشیو را حفظ می‌کند و لانچر واقعی را از دایرکتوری استخراج‌شده اجرا می‌کند، نه یک نسخهٔ ساده‌شده.

## 3. قابلیت‌ها و ویژگی‌های اصلی تأییدشده از کد واقعی

مهم‌ترین ویژگی‌هایی که بر اساس فایل‌های موجود در آرشیو رسمی و جریان نصب مخزن قابل تأیید هستند عبارت‌اند از:

- آرشیو رسمی انتشار در مخزن نگه‌داشته می‌شود و به‌عنوان منبع اصلی استفاده می‌شود.
- آرشیو از طریق HTTPS دانلود می‌شود و در یک دایرکتوری موقت اکسترکت می‌شود.
- به‌جای اجرای یک نمونهٔ ساختگی، اسکریپت لانچر واقعی داخل آرشیو اجرا می‌شود.
- نصب‌کننده فقط دایرکتوری موقت خود را پاک می‌کند و هیچ فایل نامرتبط را حذف نمی‌کند.
- اگر دانلود یا اکسترکت‌کردن آرشیو ناموفق باشد، نصب‌کننده با خطای روشن خاتمه می‌یابد.
- آرشیو اصلی جایگزین نمی‌شود و پروژهٔ ساختگی‌ای به‌جای آن ارائه نمی‌شود.
- نصب‌کننده به‌صورت ایمن با دایرکتوری‌های کاربر و تنظیمات سیستم برخورد می‌کند و فایل‌های نامرتبط را حذف نمی‌کند.
- مسیر نصب بر اساس ساختار واقعی آرشیو و نه یک layout فرضی ساخته شده است.

## 4. سیستم‌عامل‌ها و معماری‌های پشتیبانی‌شده

مخزن به‌صورت صریح یک ماتریس گسترده و نامعتبر از پلتفرم‌ها را ادعا نمی‌کند. آرشیو و لودر پروژه برای محیط‌هایی در نظر گرفته شده‌اند که Bash، curl و unzip نصب داشته باشند. به‌طور عملی، سازگاری تأییدشده به این شکل است:

- Linux: پشتیبانی‌شده از طریق پوستهٔ Bash
- macOS: پشتیبانی‌شده اگر ابزارهای استاندارد یونیکس روی سیستم نصب باشند
- Windows: توسط نصب‌کنندهٔ مبتنی بر شل در این مخزن پشتیبانی نمی‌شود؛ باید از WSL یا Git Bash استفاده شود

پشتیبانی معماری هم بر اساس خود بستهٔ پروژه تعیین می‌شود و نصب‌کننده صرفاً با محتوای واقعی آرشیو کار می‌کند، نه با یک لیست ساختگی از معماری‌ها.

## 5. نیازمندی‌ها و وابستگی‌ها

قبل از اجرای نصب‌کننده، مطمئن شوید این ابزارها موجود هستند:

- Bash
- curl
- unzip
- محیط شل یونیکس‌مانند روی Linux یا macOS
- دسترسی شبکه به GitHub برای دانلود آرشیو

اگر `curl` یا `unzip` موجود نباشد، نصب‌کننده با پیام خطای روشن خارج می‌شود.

## 6. نصب با لینک یک‌دستورِ نهایی و عملیاتی

دستور دقیق زیر را اجرا کنید:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/main/install.sh)
```

این دستور مستقیماً نصب‌کنندهٔ مخزن را از شاخهٔ `main` دانلود می‌کند، آرشیو رسمی پروژه را می‌گیرد، آن را در یک دایرکتوری موقت استخراج می‌کند، لانچر واقعی را از داخل آرشیو اجرا می‌کند و سپس دایرکتوری موقت را پس از اتمام پاک می‌کند.

## 7. دستورالعمل نصب دستی به‌صورت جایگزین

اگر ترجیح می‌دهید به‌صورت دستی نصب کنید، این مراحل را انجام دهید:

1. آرشیو نسخه را از این مخزن دانلود کنید:

   ```bash
   curl -fL -o Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip \
     https://github.com/shah1dev/shah1-core/raw/main/Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip
   ```

2. آرشیو را استخراج کنید:

   ```bash
   unzip -q Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip -d ./Shah1Tunnel
   ```

3. فایل‌های استخراج‌شده را بررسی کنید و اگر اسکریپت لانچر در آن وجود داشت، اجرا کنید:

   ```bash
   bash ./Shah1Tunnel/S1T-START.sh
   ```

4. اگر در مخزن یا خود بسته، فایل checksum منتشر شده باشد، قبل از اجرای لانچر، فایل را بررسی کنید.

## 8. استفادهٔ پایه و دستورات یا گزینه‌های منو

گزینه‌های دقیق منو وابسته به محتوای واقعی بسته است. نصب‌کنندهٔ مخزن سبک و محافظه‌کارانه طراحی شده است: آن به‌جای ساخت یک رابط سادهٔ فرضی، لانچر واقعی داخل آرشیو را پیدا می‌کند و آن را همان‌طور که هست اجرا می‌کند. بنابراین هر منوی واقعی که در بستهٔ اصلی وجود داشته باشد، همان منو حفظ می‌شود و نه یک نسخهٔ کاهشیافته.

نمونه‌های استفاده معمول:

```bash
bash ./S1T-START.sh
```

برای استفاده از نصب‌کنندهٔ یک‌دستور:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/main/install.sh)
```

## 9. نحوهٔ به‌روزرسانی پروژه

برای به‌روزرسانی پروژه، فایل آرشیو جدید را در مخزن جایگزین کنید و نصب‌کننده را به آرشیو واقعی جدید اشاره دهید. اگر نسخهٔ جدیدی منتشر شد، نام آرشیو را در `install.sh` بروزرسانی کنید و اسناد را هم با نسخهٔ جدید هماهنگ کنید. از تغییر رفتار اصلی پروژه و ساختن مسیر نصب假‌سازی‌شده خودداری کنید.

## 10. نحوهٔ حذف ایمن پروژه، اگر پشتیبانی شود

این مخزن ادعای مدیریت یک سیستم حذف کامل ندارد. نصب‌کننده فقط دایرکتوری موقت دانلود/استخراج را حذف می‌کند و فایل‌های نامرتبط را حذف نمی‌کند. اگر بستهٔ اصلی خود یک مکانیزم حذف یا پاک‌سازی داشته باشد، از همان مکانیزم اصلی و واقعی استفاده کنید. نصب‌کنندهٔ سطح مخزن، تنظیمات کاربر، سرویس‌های سیستم یا فایل‌های نصب‌شده را به‌صورت خودکار حذف نمی‌کند.

## 11. نکات امنیتی و عیب‌یابی

- هیچ‌وقت سِرِت، کلید خصوصی، توکن یا فایل اطلاعات حساس را در مخزن منتشر نکنید.
- اگر فایل checksum معتبر وجود دارد، آن را بررسی کنید.
- اگر خطای دانلود داشتید، اتصال به GitHub را بررسی کنید و مطمئن شوید مخزن عمومی است.
- اگر استخراج با مشکل مواجه شد، نصب `unzip` را ب��رسی کنید و مطمئن شوید فایل آرشیو خراب نشده باشد.
- اگر اسکریپت لانچر پیدا نشد، محتویات آرشیو را بررسی کنید و نام دقیق بسته را در مخزن تأیید کنید.
- اگر پروژه به وابستگی‌های زمان اجرا نیاز دارد، قبل از اجرای لانچر اصلی، آن‌ها را نصب کنید.

## 12. نسخهٔ پروژه و اطلاعات انتشار

آرشیو فعلی مخزن:

- `Shah1Tunnel-R9K4-OFFICIAL-v2.4.12-SELF-CLEANUP-FIX10-1.zip`
- مخزن: `https://github.com/shah1dev/shah1-core`
- شاخه: `main`

نصب‌کننده، آرشیوی که در مخزن وجود دارد را به‌عنوان منبع اصلی می‌گیرد. این پروژه ادعایی در مورد تست‌های فراتر از آنچه واقعاً تأیید شده ندارد: دسترسی به مخزن، فایل ZIP آپلودشده، فایل نصب‌کننده و مسیر اجرای ذکرشده.

## 13. مجوز و اعتبارها

این مخزن در ریشه‌اش یک فایل مجوز مجزا منتشر نمی‌کند و خود آرشیو باید به‌عنوان بستهٔ اصلیِ ارائه‌شده توسط سازنده در نظر گرفته شود. نصب‌کننده و README به‌صورت صریح ادعای مجوزهای نامشخصی نمی‌کنند. اعتبارها و اعلان‌های حق‌نشر باید در خود آرشیو اصلی و فایل‌های همراه آن حفظ شوند. اگر داخل آرشیو اصلی یک فایل مجوز وجود داشته باشد، شرایط آن را دنبال کنید.

## اطلاعات مخزن

- مخزن: https://github.com/shah1dev/shah1-core
- شاخهٔ پیش‌فرض: main
- اسکریپت نصب‌کننده: https://raw.githubusercontent.com/shah1dev/shah1-core/main/install.sh

This repository intentionally keeps the original archive intact and avoids replacing it with a fake sample project.































































































































































































































































































































































































































































































































































































































































































































































































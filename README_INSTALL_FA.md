# Shah1Tunnel installer information (Persian)

این فایل توضیحات نصب Shah1Tunnel را به زبان فارسی می‌دهد.

دستور یک‌خطی نصب (پس از ادغام این شاخه و قرار گرفتن فایل install.sh در شاخه‌ی feature/installer-farsi):

bash <(curl -fsSL https://raw.githubusercontent.com/shah1dev/shah1-core/feature/installer-farsi/install.sh)

توضیحات:
- اسکریپت نصب در ابتدا بستهٔ ZIP را از شاخهٔ main مخزن دانلود می‌کند.
- استخراج در یک دایرکتوری موقت انجام می‌شود و سپس فایل‌ها به /opt/shah1tunnel-<timestamp> منتقل می‌شوند.
- اگر نصب قبلی وجود داشته باشد، به صورت خودکار پشتیبان گرفته می‌شود.
- فایل‌های موقت و آرشیو دانلودشده پاک می‌شوند و لاگ نصب در /var/log/shah1tunnel/install.log ذخیره می‌گردد.

در صورت نیاز به بررسی بیشتر یا درخواست تغییر، لطفاً اطلاع دهید.

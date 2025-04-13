#!/bin/bash

# Script untuk menyiapkan crontab untuk refresh konten otomatis
# Jika menggunakan GitHub Pages, ini mungkin tidak diperlukan
# karena kita bisa menggunakan GitHub Actions

# Pastikan crontab ada
command -v crontab >/dev/null 2>&1 || { echo "Error: crontab not installed."; exit 1; }

# Dapatkan direktori saat ini
CURRENT_DIR=$(pwd)

# Buat pekerjaan cron untuk menjalankan refresh_content.sh setiap jam (pada menit 0)
# Tambahkan ke crontab user saat ini
(crontab -l 2>/dev/null || echo "") | grep -v "refresh_content.sh" | \
{ cat; echo "0 * * * * cd $CURRENT_DIR && ./refresh_content.sh >> $CURRENT_DIR/cron.log 2>&1"; } | \
crontab -

echo "Crontab has been set up to run refresh_content.sh every hour."
echo "To view current crontab, run: crontab -l"
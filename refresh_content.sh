#!/bin/bash

# Script untuk meregenerate konten secara otomatis setiap jam
# Untuk digunakan dengan Cloudflare Workers atau sistem cron lainnya

# Direktori tempat situs Jekyll berada
SITE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SITE_DIR"

echo "===== Memulai refresh konten pada $(date) ====="

# Jalankan database manager untuk mengambil konten baru dan menyimpannya ke database
echo "Mengambil data dari GameMonetize API dan menyimpan ke database..."
python3 db_manager.py

# Generate konten dari database
echo "Memulai regenerasi konten dari database..."
bundle exec jekyll build

echo "Refresh konten selesai pada $(date)"
echo "----------------------------------------"

# Informasi tentang penggunaan cron untuk refresh otomatis
# Pada Cloudflare Pages, kamu bisa menjalankan script ini melalui cron job
# dengan menambahkan entri berikut di dashboard Cloudflare:
#
# Nama: Refresh Content
# Cron: 0 * * * *  (setiap jam)
# Command: ./refresh_content.sh
#
# Untuk menggunakan di sistem lain, tambahkan ke crontab:
# 0 * * * * cd /path/to/site && ./refresh_content.sh >> /path/to/logfile.log 2>&1
#
# Keuntungan menggunakan database:
# - Menyimpan riwayat artikel lama bahkan jika sudah tidak ada di feed
# - Mencatat statistik dan tren game populer
# - Memungkinkan fitur pencarian yang lebih baik
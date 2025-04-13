#!/bin/bash

# Script untuk meregenerate konten secara otomatis setiap jam
# Untuk digunakan dengan Cloudflare Workers atau sistem cron lainnya

# Direktori tempat situs Jekyll berada
SITE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SITE_DIR"

echo "===== Memulai refresh konten pada $(date) ====="

# Hapus cache data lama
echo "Menghapus cache data lama..."
rm -f _data/game_monetize.yml

# Generate konten baru
echo "Memulai regenerasi konten..."
bundle exec jekyll build

echo "Refresh konten selesai pada $(date)"
echo "----------------------------------------"

# Perintah tambahan untuk Cloudflare Pages
# Pada Cloudflare Pages, kamu bisa menjalankan script ini melalui cron job
# dengan menambahkan entri berikut di dashboard Cloudflare:
#
# Nama: Refresh Content
# Cron: 0 * * * *  (setiap jam)
# Command: ./refresh_content.sh
#
# Untuk menggunakan di sistem lain, tambahkan ke crontab:
# 0 * * * * cd /path/to/site && ./refresh_content.sh >> /path/to/logfile.log 2>&1
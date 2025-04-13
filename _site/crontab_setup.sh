#!/bin/bash

# Script untuk mengatur cron job agar menjalankan refresh content setiap 40 menit
# dan deploy ke GitHub Pages

CURRENT_PATH=$(pwd)

# Buat temporary crontab file
echo "# GameMonetize Jekyll Site Cron Jobs" > /tmp/gamecron
echo "# Regenerasi konten setiap 40 menit" >> /tmp/gamecron
echo "*/40 * * * * cd $CURRENT_PATH && bash $CURRENT_PATH/refresh_content.sh > $CURRENT_PATH/logs/refresh_$(date +\%Y\%m\%d).log 2>&1" >> /tmp/gamecron
echo "# Deploy ke GitHub Pages setiap 40 menit, 5 menit setelah regenerasi konten" >> /tmp/gamecron
echo "5,45 * * * * cd $CURRENT_PATH && bash $CURRENT_PATH/deploy.sh > $CURRENT_PATH/logs/deploy_$(date +\%Y\%m\%d).log 2>&1" >> /tmp/gamecron

# Buat direktori logs jika belum ada
mkdir -p $CURRENT_PATH/logs

# Install crontab
echo "Mengatur cron job untuk regenerasi konten setiap 40 menit..."
crontab /tmp/gamecron

# Cek status crontab
echo "Cron job yang telah diatur:"
crontab -l

# Hapus file temporary
rm /tmp/gamecron

echo "Cron job berhasil diatur!"
echo "Konten akan diregenerasi otomatis setiap 40 menit dan dideploy ke GitHub Pages."
echo "Log dapat dilihat di folder $CURRENT_PATH/logs"
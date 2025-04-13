#!/bin/bash

# Script untuk refresh konten secara otomatis
# Script ini akan dijalankan oleh cron job atau GitHub Actions

# Load database environment
if [ -z "$DATABASE_URL" ]; then
  echo "Error: DATABASE_URL environment variable is not set."
  exit 1
fi

echo "Starting content refresh..."

# Jalankan Python script untuk mengambil data dari API
python db_manager.py

echo "Content refresh completed."
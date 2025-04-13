#!/bin/bash

# Script untuk melakukan build dan deploy ke GitHub Pages

# Verifikasi git tersedia
if ! command -v git &> /dev/null; then
    echo "Git tidak terinstal. Silakan install git terlebih dahulu."
    exit 1
fi

# Verifikasi berada di direktori repo git
if [ ! -d ".git" ]; then
    echo "Tidak berada di direktori repo git. Silakan jalankan script ini dari root direktori repo."
    exit 1
fi

# Verifikasi cabang utama (main atau master)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo "Anda tidak berada di cabang main atau master. Silakan checkout ke cabang utama."
    echo "Gunakan: git checkout main"
    exit 1
fi

# Pastikan perubahan terbaru sudah di-commit dan push
if [ -n "$(git status --porcelain)" ]; then
    echo "Ada perubahan yang belum di-commit. Silakan commit perubahan terlebih dahulu."
    exit 1
fi

# Update konten
echo "Memperbarui konten dari API..."
./refresh_content.sh

# Build site
echo "Building site with Jekyll..."
JEKYLL_ENV=production bundle exec jekyll build

# Deploy ke GitHub Pages (cabang gh-pages)
echo "Deploying ke GitHub Pages..."
if [ -d "_site" ]; then
    if git show-ref --verify --quiet refs/heads/gh-pages; then
        git checkout gh-pages
    else
        git checkout --orphan gh-pages
        git rm -rf .
        echo "Cabang gh-pages dibuat."
    fi

    # Salin konten _site ke root direktori cabang gh-pages
    cp -R _site/* .
    
    # Hapus _site karena sudah tidak diperlukan
    rm -rf _site

    # Tambahkan semua file ke git
    git add .
    
    # Commit perubahan
    git commit -m "Site build at $(date)"
    
    # Push perubahan ke GitHub
    git push origin gh-pages
    
    # Kembali ke cabang utama
    git checkout "$CURRENT_BRANCH"
    
    echo "Deploy selesai! Situs Anda sekarang tersedia di https://username.github.io/reponame/"
else
    echo "Direktori _site tidak ditemukan. Build Jekyll gagal?"
    exit 1
fi
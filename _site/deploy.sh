#!/bin/bash

# Script untuk deploy otomatis ke GitHub Pages
# Dijalankan setiap 40 menit via cron

SITE_REPO_PATH=$(pwd)
DEPLOY_REPO_PATH="$SITE_REPO_PATH/_deploy"
DEPLOY_BRANCH="gh-pages"
GITHUB_REPO_URL=${GITHUB_REPO_URL:-"https://github.com/yourusername/yourgamerepo.git"}

echo "===== Memulai deploy pada $(date) ====="

# Pertama, refresh konten dari GameMonetize API
bash refresh_content.sh

# Buat folder deploy jika belum ada
if [ ! -d "$DEPLOY_REPO_PATH" ]; then
    echo "Membuat folder deploy baru..."
    mkdir -p "$DEPLOY_REPO_PATH"
    cd "$DEPLOY_REPO_PATH"
    git init
    git remote add origin $GITHUB_REPO_URL
    git checkout -b $DEPLOY_BRANCH
    cd "$SITE_REPO_PATH"
else
    echo "Menggunakan folder deploy yang sudah ada..."
    cd "$DEPLOY_REPO_PATH"
    git fetch origin
    git checkout $DEPLOY_BRANCH
    cd "$SITE_REPO_PATH"
fi

# Membangun situs dengan Jekyll
echo "Membangun situs dengan Jekyll..."
JEKYLL_ENV=production bundle exec jekyll build

# Menyalin hasil build ke folder deploy
echo "Menyalin hasil build ke folder deploy..."
rsync -av --delete "$SITE_REPO_PATH/_site/" "$DEPLOY_REPO_PATH/"

# Membuat CNAME file jika perlu
if [ ! -z "$CUSTOM_DOMAIN" ]; then
    echo "$CUSTOM_DOMAIN" > "$DEPLOY_REPO_PATH/CNAME"
    echo "CNAME diatur ke $CUSTOM_DOMAIN"
fi

# Buat file .nojekyll untuk menghindari proses Jekyll di GitHub Pages
touch "$DEPLOY_REPO_PATH/.nojekyll"

# Membuat commit dan push ke GitHub
cd "$DEPLOY_REPO_PATH"
git add -A
git commit -m "Deploy otomatis pada $(date)"

# Push jika ada perubahan dan kredensial GitHub tersedia
if [ $? -eq 0 ]; then
    if [ ! -z "$GITHUB_TOKEN" ]; then
        echo "Menggunakan GITHUB_TOKEN untuk autentikasi..."
        git remote set-url origin "https://x-access-token:$GITHUB_TOKEN@${GITHUB_REPO_URL#https://}"
    fi
    
    echo "Mempush perubahan ke branch $DEPLOY_BRANCH..."
    git push origin $DEPLOY_BRANCH
    
    echo "Situs berhasil di-deploy pada $(date)"
else
    echo "Tidak ada perubahan untuk di-deploy"
fi

cd "$SITE_REPO_PATH"
echo "===== Deploy selesai pada $(date) ====="
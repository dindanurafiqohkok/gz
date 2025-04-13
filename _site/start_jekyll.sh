#!/bin/bash
set -e

echo "Installing jekyll and dependencies..."
gem install jekyll webrick jekyll-sitemap jekyll-feed

echo "Creating necessary directories..."
mkdir -p _gameposts _site

echo "Starting Jekyll server..."
jekyll serve --host=0.0.0.0 --port=5000
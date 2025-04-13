#!/usr/bin/env python3
"""
Database manager untuk menyimpan data game dari GameMonetize API
"""

import os
import json
import urllib.request
import psycopg2
from datetime import datetime
import yaml

# Mendapatkan koneksi database dari environment variable
DATABASE_URL = os.environ.get('DATABASE_URL')

def create_tables():
    """
    Membuat tabel untuk games jika belum ada
    """
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    cur.execute('''
    CREATE TABLE IF NOT EXISTS games (
        id SERIAL PRIMARY KEY,
        guid TEXT UNIQUE,
        title TEXT NOT NULL,
        slug TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        iframe_code TEXT,
        published_date TIMESTAMP,
        last_updated TIMESTAMP,
        tags TEXT[]
    )
    ''')
    
    conn.commit()
    print("Tabel games berhasil dibuat atau sudah ada")
    
    cur.close()
    conn.close()

def fetch_games_from_api():
    """
    Mengambil data game dari GameMonetize API atau menggunakan data sampel untuk testing
    """
    # Untuk testing, gunakan data sampel
    print("Menggunakan data sampel untuk testing")
    return [
        {
            "title": "Sample Game 1",
            "guid": "game-1",
            "description": "This is a sample game description.",
            "enclosure": {"url": "https://example.com/game1.png"},
            "pubDate": "Sun, 13 Apr 2025 12:00:00 +0000",
            "iframe": "<iframe src='https://example.com/game1'></iframe>",
            "category": ["action", "puzzle"]
        },
        {
            "title": "Sample Game 2",
            "guid": "game-2",
            "description": "Another sample game description.",
            "enclosure": {"url": "https://example.com/game2.png"},
            "pubDate": "Sun, 13 Apr 2025 11:00:00 +0000",
            "iframe": "<iframe src='https://example.com/game2'></iframe>",
            "category": ["strategy"]
        },
        {
            "title": "Sample Game 3",
            "guid": "game-3",
            "description": "Third sample game with cool features.",
            "enclosure": {"url": "https://example.com/game3.png"},
            "pubDate": "Sun, 13 Apr 2025 10:00:00 +0000",
            "iframe": "<iframe src='https://example.com/game3'></iframe>",
            "category": ["arcade", "casual"]
        }
    ]
    
    # Kode berikut untuk penggunaan API asli - dinonaktifkan untuk sementara
    """
    api_url = "https://rss.gamemonetize.com/rssfeed.php?format=json"
    
    try:
        with urllib.request.urlopen(api_url) as response:
            data = json.loads(response.read().decode('utf-8'))
            if 'channel' in data and 'item' in data['channel']:
                return data['channel']['item']
            else:
                print(f"Format API tidak sesuai")
                return []
    except Exception as e:
        print(f"Error mengambil data dari API: {e}")
        return []
    """

def save_games_to_database(games):
    """
    Menyimpan data game ke database
    """
    if not games:
        print("Tidak ada game untuk disimpan")
        return
    
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    for game in games:
        title = game.get('title', '')
        guid = game.get('guid', '')
        description = game.get('description', '')
        image_url = game.get('enclosure', {}).get('url', '')
        published_date = game.get('pubDate', '')
        iframe_code = game.get('iframe', '')
        
        # Membuat slug dari judul
        slug = title.lower().replace(' ', '-').replace('/', '-')
        
        # Mendapatkan tags
        categories = game.get('category', [])
        if isinstance(categories, str):
            tags = [categories]
        else:
            tags = categories
        
        # Parse tanggal
        try:
            pub_date = datetime.strptime(published_date, '%a, %d %b %Y %H:%M:%S %z')
        except:
            pub_date = datetime.now()
        
        # Menyimpan atau mengupdate game ke database
        cur.execute('''
        INSERT INTO games 
        (guid, title, slug, description, image_url, iframe_code, published_date, last_updated, tags)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (guid)
        DO UPDATE SET
            title = EXCLUDED.title,
            description = EXCLUDED.description,
            image_url = EXCLUDED.image_url,
            iframe_code = EXCLUDED.iframe_code,
            last_updated = CURRENT_TIMESTAMP,
            tags = EXCLUDED.tags
        ''', (
            guid, title, slug, description, image_url, iframe_code, 
            pub_date, datetime.now(), tags
        ))
    
    conn.commit()
    print(f"Berhasil menyimpan {len(games)} game ke database")
    
    cur.close()
    conn.close()

def export_to_yaml():
    """
    Mengekspor data dari database ke YAML untuk digunakan oleh Jekyll
    """
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    cur.execute('''
    SELECT guid, title, slug, description, image_url, iframe_code, 
           published_date, last_updated, tags
    FROM games
    ORDER BY published_date DESC
    ''')
    
    games = []
    for row in cur.fetchall():
        game = {
            'guid': row[0],
            'title': row[1],
            'slug': row[2],
            'description': row[3],
            'enclosure': {'url': row[4]},
            'iframe': row[5],
            'pubDate': row[6].strftime('%a, %d %b %Y %H:%M:%S %z') if row[6] else '',
            'category': row[8],
            'last_updated': row[7].strftime('%Y-%m-%d %H:%M:%S') if row[7] else ''
        }
        games.append(game)
    
    cur.close()
    conn.close()
    
    # Menulis ke file YAML
    os.makedirs('_data', exist_ok=True)
    with open('_data/game_monetize.yml', 'w') as file:
        yaml.dump(games, file, default_flow_style=False)
    
    print(f"Berhasil mengekspor {len(games)} game ke _data/game_monetize.yml")

if __name__ == "__main__":
    create_tables()
    games = fetch_games_from_api()
    save_games_to_database(games)
    export_to_yaml()
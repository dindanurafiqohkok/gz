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
    Mengambil data game dari GameMonetize API
    """
    api_url = "https://rss.gamemonetize.com/rssfeed.php?format=json&category=All&type=html5&popularity=newest&company=All&amount=All"
    
    try:
        print(f"Mengambil data dari API: {api_url}")
        with urllib.request.urlopen(api_url) as response:
            raw_data = response.read().decode('utf-8')
            
            # Sebelum mencoba parsing JSON, cetak sebagian kecil dari respon mentah
            # untuk membantu debug format API
            print(f"Contoh data API (50 karakter pertama): {raw_data[:50]}...")
            
            try:
                data = json.loads(raw_data)
                
                # Handle berbagai kemungkinan format data JSON
                if isinstance(data, dict):
                    # Format 1: {"channel": {"item": [...]}}
                    if 'channel' in data and 'item' in data['channel']:
                        items = data['channel']['item']
                        print(f"Format RSS JSON standar ditemukan, {len(items)} game ditemukan")
                        return items
                    
                    # Format 2: {"rss": {"channel": {"item": [...]}}}
                    elif 'rss' in data and isinstance(data['rss'], dict) and 'channel' in data['rss']:
                        items = data['rss']['channel']['item']
                        print(f"Format RSS/channel ditemukan, {len(items)} game ditemukan")
                        return items
                    
                    # Format 3: {"items": [...]} or {"games": [...]}
                    elif 'items' in data and isinstance(data['items'], list):
                        print(f"Format items array ditemukan, {len(data['items'])} game ditemukan")
                        return data['items']
                    elif 'games' in data and isinstance(data['games'], list):
                        print(f"Format games array ditemukan, {len(data['games'])} game ditemukan")
                        return data['games']
                    
                    # Format tak dikenal, coba cari kunci yang berisi data game
                    else:
                        print(f"Format tidak dikenal, kunci yang tersedia: {list(data.keys())}")
                        # Coba temukan kunci yang berisi array
                        for key, value in data.items():
                            if isinstance(value, list) and len(value) > 0:
                                print(f"Mencoba gunakan array dari kunci '{key}', {len(value)} item")
                                return value
                        
                        print("Tidak dapat menemukan array game, gunakan data sampel")
                        return generate_sample_games()
                
                # Format 4: Langsung array dari game
                elif isinstance(data, list):
                    print(f"Respon adalah array langsung dengan {len(data)} game")
                    return data
                
                else:
                    print(f"Respons tidak dikenali (tipe: {type(data)}), gunakan data sampel")
                    return generate_sample_games()
                    
            except json.JSONDecodeError as je:
                print(f"Format JSON tidak valid: {je}")
                
                # Coba deteksi format XML yang dikirim sebagai JSON
                if "<rss" in raw_data or "<channel>" in raw_data:
                    print("Respon tampaknya dalam format XML bukan JSON. Gunakan data sampel.")
                return generate_sample_games()
                
    except Exception as e:
        print(f"Error mengambil data dari API: {e}")
        return generate_sample_games()

def generate_sample_games():
    """
    Membuat data sampel untuk development saat API tidak tersedia
    """
    print("Menggunakan data sampel untuk testing")
    return [
        {
            "title": "Stunt Car Extreme",
            "guid": "game-1",
            "description": "Drive through challenging tracks and perform stunts with your car in this exciting racing game.",
            "enclosure": {"url": "https://img.gamemonetize.com/xzpnmtfpd1vgzv3xsu5yctge2bq2q2ck/512x384.jpg"},
            "pubDate": "Sun, 13 Apr 2025 12:00:00 +0000",
            "iframe": """<iframe frameborder="0" src="https://games.gamemonetize.com/xzpnmtfpd1vgzv3xsu5yctge2bq2q2ck/" width="100%" height="100%" scrolling="no"></iframe>""",
            "category": ["racing", "action", "stunts"]
        },
        {
            "title": "Tower Defense Kingdom Wars",
            "guid": "game-2",
            "description": "Defend your kingdom against waves of enemies by strategically placing towers and upgrading your defenses.",
            "enclosure": {"url": "https://img.gamemonetize.com/ynt0ucvk4pneq7ehfmrxhgvvwgz5k4u9/512x384.jpg"},
            "pubDate": "Sun, 13 Apr 2025 11:00:00 +0000",
            "iframe": """<iframe frameborder="0" src="https://games.gamemonetize.com/ynt0ucvk4pneq7ehfmrxhgvvwgz5k4u9/" width="100%" height="100%" scrolling="no"></iframe>""",
            "category": ["strategy", "tower defense", "war"]
        },
        {
            "title": "Monster Blocks",
            "guid": "game-3",
            "description": "Connect matching monster blocks to clear the board and progress through increasingly challenging puzzles.",
            "enclosure": {"url": "https://img.gamemonetize.com/7aa5trtga3mgqn8nt3xlzr19zqqvzbtw/512x384.jpg"},
            "pubDate": "Sun, 13 Apr 2025 10:00:00 +0000",
            "iframe": """<iframe frameborder="0" src="https://games.gamemonetize.com/7aa5trtga3mgqn8nt3xlzr19zqqvzbtw/" width="100%" height="100%" scrolling="no"></iframe>""",
            "category": ["puzzle", "casual", "blocks"]
        }
    ]

def save_games_to_database(games, limit=20):
    """
    Menyimpan data game ke database dengan batas jumlah yang diproses
    
    Args:
        games: List game dari API
        limit: Jumlah maksimum game yang akan diproses (default: 20)
    """
    if not games:
        print("Tidak ada game untuk disimpan")
        return
    
    # Batasi jumlah game yang diproses untuk menghindari timeout
    limited_games = games[:limit]
    print(f"Membatasi proses hingga {limit} game dari total {len(games)} game")
    
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    for game in limited_games:
        # Handle berbagai format field sesuai dengan API
        title = game.get('title', '')
        
        # ID bisa dalam beberapa format berbeda dari API
        guid = game.get('guid', '') or game.get('id', '') or str(hash(title))
        
        description = game.get('description', '')
        
        # Coba beberapa kemungkinan lokasi URL gambar
        image_url = None
        if game.get('enclosure') and isinstance(game.get('enclosure'), dict):
            image_url = game.get('enclosure', {}).get('url', '')
        elif game.get('image_url'):
            image_url = game.get('image_url')
        elif game.get('thumb'):
            image_url = game.get('thumb')
        elif game.get('thumbnail'):
            image_url = game.get('thumbnail')
        
        # Coba beberapa kemungkinan format tanggal
        published_date = game.get('pubDate', '') or game.get('published_date', '') or game.get('date', '') or datetime.now().strftime('%a, %d %b %Y %H:%M:%S')
        
        # Buat iframe code jika tidak ada di API
        if game.get('iframe') or game.get('iframe_code') or game.get('embed'):
            iframe_code = game.get('iframe', '') or game.get('iframe_code', '') or game.get('embed', '')
        elif game.get('url'):
            # Buat iframe dari URL game
            game_url = game.get('url')
            width = game.get('width', '800')
            height = game.get('height', '600')
            iframe_code = f'<iframe frameborder="0" src="{game_url}" width="100%" height="100%" scrolling="no" allow="autoplay" allowfullscreen></iframe>'
        else:
            iframe_code = ""
            
        # Membuat slug dari judul
        slug = title.lower().replace(' ', '-').replace('/', '-').replace('?', '').replace('&', 'and')
        
        # Tangani tags - prioritaskan field tags yang ada di API GameMonetize
        if game.get('tags'):
            # API GameMonetize mengirim tags sebagai string yang dipisahkan koma
            if isinstance(game.get('tags'), str):
                tags = [tag.strip() for tag in game.get('tags').split(',')]
            else:
                tags = game.get('tags')
        # Jika tidak ada tags, gunakan category
        elif game.get('category'):
            # Kategori bisa berupa string atau array
            if isinstance(game.get('category'), str):
                tags = [game.get('category')]
            else:
                tags = game.get('category')
        else:
            tags = []
        
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
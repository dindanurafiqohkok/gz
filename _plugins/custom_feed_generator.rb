require 'date'

module Jekyll
  class CustomFeedGenerator < Generator
    safe true
    priority :low
    
    # Menghasilkan file feed.xml yang sesuai dengan spesifikasi
    def generate(site)
      @site = site
      
      # Tetapkan config default jika kosong
      @site.config['url'] ||= 'https://yourdomain.com'
      @site.config['title'] ||= 'Game Monetize Portal'
      @site.config['description'] ||= 'Your source for HTML5 games and gaming content'
      
      # Membuat feed
      feed_content = generate_feed_content
      
      # Menambahkan feed ke file statis situs
      site.static_files << FeedFile.new(site, site.source, "", "feed.xml", feed_content)
    end
    
    # Membuat konten feed dengan XML manual
    def generate_feed_content
      feed = %Q{<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>#{xml_escape(@site.config['title'])}</title>
    <description>#{xml_escape(@site.config['description'])}</description>
    <link>#{@site.config['url']}</link>
    <atom:link href="#{@site.config['url']}/feed.xml" rel="self" type="application/rss+xml"/>
    <pubDate>#{Time.now.rfc822}</pubDate>
    <lastBuildDate>#{Time.now.rfc822}</lastBuildDate>
    <generator>Jekyll Game Monetize Feed Generator</generator>
    <language>en-us</language>
}
      
      # Menambahkan item untuk setiap post game
      @site.collections['gameposts'].docs.each do |post|
        # Set URL tanpa archive date - langsung ke title
        title_slug = post.data['title'].downcase.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-')
        post_url = "#{@site.config['url']}/#{title_slug}/"
        
        # Menggunakan tanggal publikasi jika ada, jika tidak gunakan waktu saat ini
        pub_date = post.data['date'] ? post.data['date'].rfc822 : Time.now.rfc822
        
        # Menambahkan item ke feed
        feed += %Q{    <item>
      <title>#{xml_escape(post.data['title'])}</title>
      <description>#{xml_escape(post.data['description'] || '')}</description>
      <pubDate>#{pub_date}</pubDate>
      <link>#{post_url}</link>
      <guid isPermaLink="false">#{post.data['guid'] || post.id}</guid>
}
        
        # Menambahkan gambar jika tersedia
        if post.data['featured_image']
          feed += %Q{      <enclosure url="#{post.data['featured_image']}" length="0" type="image/jpeg"/>
}
        end
        
        # Menambahkan kategori/tag
        if post.data['tags'] && !post.data['tags'].empty?
          post.data['tags'].each do |tag|
            feed += %Q{      <category>#{xml_escape(tag)}</category>
}
          end
        end
        
        feed += %Q{    </item>
}
      end
      
      feed += %Q{  </channel>
</rss>}
      
      feed
    end
    
    # Helper untuk XML escape
    def xml_escape(input)
      input.to_s.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;').gsub(/"/, '&quot;').gsub(/'/, '&apos;')
    end
  end
  
  # Custom Feed File class
  class FeedFile < Jekyll::StaticFile
    def initialize(site, base, dir, name, content)
      super(site, base, dir, name)
      @content = content
    end
    
    def write(dest)
      dest_path = File.join(dest, @name)
      FileUtils.mkdir_p(File.dirname(dest_path))
      File.open(dest_path, 'w') { |f| f.write(@content) }
      true
    end
  end
end
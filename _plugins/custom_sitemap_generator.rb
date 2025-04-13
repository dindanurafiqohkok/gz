require 'date'

module Jekyll
  class CustomSitemapGenerator < Generator
    safe true
    priority :low
    
    # Menghasilkan file sitemap.xml yang sederhana tanpa archive date
    def generate(site)
      @site = site
      
      # Tetapkan config default jika kosong
      @site.config['url'] ||= 'https://yourdomain.com'
      
      # Membuat sitemap
      sitemap_content = generate_sitemap_content
      
      # Menambahkan sitemap ke file statis situs
      site.static_files << SitemapFile.new(site, site.source, "", "sitemap.xml", sitemap_content)
    end
    
    # Membuat konten sitemap
    def generate_sitemap_content
      sitemap = <<~SITEMAP
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      SITEMAP
      
      # Halaman utama
      sitemap += url_entry(@site.config['url'] + '/', '1.0')
      
      # Halaman statis (about, privacy, terms, dll)
      @site.pages.each do |page|
        next if page.name =~ /\.(xml|txt|md)$/ # Skip file selain html
        next if page.name =~ /^(404)\./ # Skip 404
        
        page_url = @site.config['url'] + page.url
        sitemap += url_entry(page_url, '0.8')
      end
      
      # Post game
      @site.collections['gameposts'].docs.each do |post|
        post_url = @site.config['url'] + '/' + post.data['title'].downcase.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-')
        sitemap += url_entry(post_url, '0.9')
      end
      
      # Tag pages
      all_tags = []
      @site.collections['gameposts'].docs.each do |post|
        tags = post.data['tags'] || []
        all_tags.concat(tags)
      end
      
      all_tags.uniq.each do |tag|
        tag_slug = tag.downcase.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').gsub(/-+/, '-')
        tag_url = @site.config['url'] + '/tags/' + tag_slug
        sitemap += url_entry(tag_url, '0.7')
      end
      
      sitemap += "</urlset>"
      sitemap
    end
    
    # Format URL entry for sitemap
    def url_entry(url, priority = '0.5')
      <<~URL
      <url>
        <loc>#{url}</loc>
        <priority>#{priority}</priority>
      </url>
      URL
    end
  end
  
  # Custom Sitemap File class
  class SitemapFile < Jekyll::StaticFile
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
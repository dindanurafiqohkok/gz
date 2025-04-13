require 'json'
require 'date'
require 'yaml'

module Jekyll
  class GameMonetizeGenerator < Generator
    safe true
    priority :high

    def generate(site)
      # Load data from YAML file created by db_manager.py
      yaml_data = load_from_yaml(site)
      
      # Process the data
      process_game_data(site, yaml_data)
    end
    
    private
    
    def load_from_yaml(site)
      # Check if _data/game_monetize.yml exists and load it
      yaml_path = File.join(site.source, '_data', 'game_monetize.yml')
      
      begin
        if File.exist?(yaml_path)
          Jekyll.logger.info "GameMonetizeGenerator:", "Loading data from _data/game_monetize.yml"
          games = YAML.load_file(yaml_path)
          return games
        else
          # If YAML file doesn't exist, use sample data
          Jekyll.logger.warn "GameMonetizeGenerator:", "No _data/game_monetize.yml found, using sample data"
          return sample_games
        end
      rescue => e
        Jekyll.logger.error "GameMonetizeGenerator:", "Error loading YAML file: #{e.message}"
        return sample_games
      end
    end
    
    def sample_games
      # Sample data as fallback
      [
        {
          "title" => "Stunt Car Extreme",
          "guid" => "game-1",
          "description" => "Drive through challenging tracks and perform stunts with your car in this exciting racing game.",
          "enclosure" => {"url" => "https://img.gamemonetize.com/xzpnmtfpd1vgzv3xsu5yctge2bq2q2ck/512x384.jpg"},
          "pubDate" => Time.now.to_s,
          "iframe" => "<iframe frameborder=\"0\" src=\"https://games.gamemonetize.com/xzpnmtfpd1vgzv3xsu5yctge2bq2q2ck/\" width=\"100%\" height=\"100%\" scrolling=\"no\"></iframe>",
          "category" => ["racing", "action", "stunts"]
        },
        {
          "title" => "Tower Defense Kingdom Wars",
          "guid" => "game-2",
          "description" => "Defend your kingdom against waves of enemies by strategically placing towers and upgrading your defenses.",
          "enclosure" => {"url" => "https://img.gamemonetize.com/ynt0ucvk4pneq7ehfmrxhgvvwgz5k4u9/512x384.jpg"},
          "pubDate" => (Time.now - 86400).to_s,
          "iframe" => "<iframe frameborder=\"0\" src=\"https://games.gamemonetize.com/ynt0ucvk4pneq7ehfmrxhgvvwgz5k4u9/\" width=\"100%\" height=\"100%\" scrolling=\"no\"></iframe>",
          "category" => ["strategy", "tower defense", "war"]
        },
        {
          "title" => "Monster Blocks",
          "guid" => "game-3",
          "description" => "Connect matching monster blocks to clear the board and progress through increasingly challenging puzzles.",
          "enclosure" => {"url" => "https://img.gamemonetize.com/7aa5trtga3mgqn8nt3xlzr19zqqvzbtw/512x384.jpg"},
          "pubDate" => (Time.now - 172800).to_s,
          "iframe" => "<iframe frameborder=\"0\" src=\"https://games.gamemonetize.com/7aa5trtga3mgqn8nt3xlzr19zqqvzbtw/\" width=\"100%\" height=\"100%\" scrolling=\"no\"></iframe>",
          "category" => ["puzzle", "casual", "blocks"]
        }
      ]
    end
    
    def process_game_data(site, games)
      # If games is a nested structure, try to extract the items
      if games.is_a?(Hash) && games["rss"] && games["rss"]["channel"] && games["rss"]["channel"]["item"]
        # Extract from rss->channel->item structure
        games = games["rss"]["channel"]["item"]
      elsif games.is_a?(Hash) && games["channel"] && games["channel"]["item"]
        # Extract from channel->item structure
        games = games["channel"]["item"]
      end
      
      # Ensure we have an array of games
      if !games.is_a?(Array)
        Jekyll.logger.warn "GameMonetizeGenerator:", "Games data is not an array. Type: #{games.class}"
        games = [games].compact
      end
      
      if games.nil? || games.empty?
        Jekyll.logger.warn "GameMonetizeGenerator:", "No games found in the data source"
        return
      end
      
      Jekyll.logger.info "GameMonetizeGenerator:", "Processing #{games.size} games from GameMonetize API"
      
      # Create a collection for game posts if it doesn't exist
      site.collections["gameposts"] ||= Collection.new(site, "gameposts")
      
      # Track all tags for later use
      all_tags = []
      
      # Process each game item
      games.each do |game|
        begin
          # Extract data from the game object - handle both standard and YAML import formats
          title = game["title"] || "Untitled Game"
          link = game["link"] || ""
          description = game["description"] || ""
          pub_date = game["pubDate"] || Time.now.to_s
          guid = game["guid"] || ""
          
          # Handle YAML format from db_manager.py which uses enclosure hash and iframe
          if game["enclosure"] && game["enclosure"].is_a?(Hash) && game["enclosure"]["url"]
            image = game["enclosure"]["url"]
          else
            image = game["image"] || ""
          end
          
          # Handle iframe code with priority to iframe field from YAML
          iframe_code = game["iframe"] || game["iframe_code"] || ""
          
          # Extract and clean up tags
          categories = game["category"]
          tags = if categories.is_a?(Array)
                  categories.map(&:to_s).map(&:strip).reject(&:empty?)
                elsif categories.is_a?(String)
                  categories.split(',').map(&:strip).reject(&:empty?)
                else
                  []
                end
          
          # Add to all tags list
          all_tags.concat(tags)
          
          # Create a slug from the title
          slug = slugify(title)
          
          # Parse the date
          date = parse_date(pub_date)
          
          # Create document
          doc = Document.new(
            File.join(site.source, "_gameposts", "#{slug}.md"),
            site: site,
            collection: site.collections["gameposts"]
          )
          
          # Set document content and front matter
          # Siapkan konten dengan deskripsi dan tag
          content = <<~CONTENT
            #{description}

            {% if page.tags.size > 0 %}
            <div class="post-tags-section">
              <h3>Game Tags:</h3>
              <ul class="post-tags-list">
                {% for tag in page.tags %}
                  <li><a href="{{ site.baseurl }}/tags/{{ tag | slugify }}">{{ tag }}</a></li>
                {% endfor %}
              </ul>
            </div>
            {% endif %}
          CONTENT

          doc.content = content
          doc.data["title"] = title
          doc.data["date"] = date
          doc.data["permalink"] = "/#{slug}/"
          doc.data["description"] = description
          doc.data["tags"] = tags
          doc.data["featured_image"] = image
          doc.data["iframe_code"] = iframe_code
          doc.data["layout"] = "post"
          doc.data["guid"] = guid
          doc.data["last_modified_at"] = Time.now
          
          # Add the document to the collection
          site.collections["gameposts"].docs << doc
        rescue => e
          Jekyll.logger.error "GameMonetizeGenerator:", "Error processing game: #{e.message}"
        end
      end
      
      # Generate tag pages
      all_tags.uniq.each do |tag|
        site.pages << TagPage.new(site, site.source, "tags", tag)
      end
      
      # Save to data file for reference
      save_to_data_file(site.source, games)
      
      Jekyll.logger.info "GameMonetizeGenerator:", "Generated #{site.collections["gameposts"].docs.size} game posts"
    end
    
    def slugify(title)
      title.downcase.strip.gsub(/[^\w\s-]/, '').gsub(/\s+/, '-').gsub(/-+/, '-')
    end
    
    def parse_date(date_str)
      begin
        DateTime.parse(date_str).to_time
      rescue
        Time.now
      end
    end
    
    def save_to_data_file(source, games)
      data_dir = File.join(source, "_data")
      Dir.mkdir(data_dir) unless Dir.exist?(data_dir)
      
      File.open(File.join(data_dir, "game_monetize.yml"), "w") do |file|
        file.write(games.to_yaml)
      end
    end
  end
  
  # Class to generate tag pages
  class TagPage < Page
    def initialize(site, base, dir, tag)
      @site = site
      @base = base
      @dir = dir
      @name = "#{tag.downcase.gsub(' ', '-')}.html"
      
      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag.html')
      self.data['tag'] = tag
      self.data['title'] = "Games tagged with #{tag}"
    end
  end
end

require 'json'
require 'date'
require 'yaml'

module Jekyll
  class GameMonetizeGenerator < Generator
    safe true
    priority :high

    def generate(site)
      # Use sample data for development purposes
      # In production, we would fetch from the API
      json_data = sample_data
      
      # Process the data
      process_game_data(site, json_data)
    end
    
    private
    
    def sample_data
      # Sample data structure for development
      {
        "rss" => {
          "channel" => {
            "item" => [
              {
                "title" => "Pixel Adventure",
                "link" => "https://example.com/games/pixel-adventure",
                "description" => "An exciting pixel art adventure game where you explore mysterious worlds.",
                "pubDate" => Time.now.to_s,
                "guid" => "game-001",
                "image" => "https://via.placeholder.com/300x200/00CED1/FFFFFF?text=Pixel+Adventure",
                "iframe_code" => "<iframe src='https://via.placeholder.com/800x600/00CED1/FFFFFF?text=Pixel+Adventure+Game' width='800' height='600' frameborder='0' allowfullscreen></iframe>",
                "category" => ["Adventure", "Arcade", "Pixel Art"]
              },
              {
                "title" => "Space Shooter",
                "link" => "https://example.com/games/space-shooter",
                "description" => "Defend your space station from waves of alien invaders in this action-packed shooter.",
                "pubDate" => (Time.now - 86400).to_s,
                "guid" => "game-002",
                "image" => "https://via.placeholder.com/300x200/FF5733/FFFFFF?text=Space+Shooter",
                "iframe_code" => "<iframe src='https://via.placeholder.com/800x600/FF5733/FFFFFF?text=Space+Shooter+Game' width='800' height='600' frameborder='0' allowfullscreen></iframe>",
                "category" => ["Action", "Shooter", "Sci-Fi"]
              },
              {
                "title" => "Puzzle Master",
                "link" => "https://example.com/games/puzzle-master",
                "description" => "Test your logical thinking with increasingly difficult puzzles.",
                "pubDate" => (Time.now - 172800).to_s,
                "guid" => "game-003",
                "image" => "https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Puzzle+Master",
                "iframe_code" => "<iframe src='https://via.placeholder.com/800x600/4CAF50/FFFFFF?text=Puzzle+Master+Game' width='800' height='600' frameborder='0' allowfullscreen></iframe>",
                "category" => ["Puzzle", "Strategy", "Brain Teaser"]
              }
            ]
          }
        }
      }
    end
    
    def process_game_data(site, json_data)
      games = json_data["rss"]["channel"]["item"] rescue []
      
      if games.nil? || games.empty?
        Jekyll.logger.warn "GameMonetizeGenerator:", "No games found in the API response"
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
          # Extract data from the game object
          title = game["title"] || "Untitled Game"
          link = game["link"] || ""
          description = game["description"] || ""
          pub_date = game["pubDate"] || Time.now.to_s
          guid = game["guid"] || ""
          image = game["image"] || ""
          iframe_code = game["iframe_code"] || ""
          
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
          doc.content = description
          doc.data["title"] = title
          doc.data["date"] = date
          doc.data["permalink"] = "/#{slug}/"
          doc.data["description"] = description
          doc.data["tags"] = tags
          doc.data["featured_image"] = image
          doc.data["iframe_code"] = iframe_code
          doc.data["layout"] = "post"
          doc.data["guid"] = guid
          
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

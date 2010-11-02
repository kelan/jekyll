module Jekyll
  
  class TagIndexPage < Page
    attr_accessor :tagname
    
    # Initialize a new Page.
    #   +site+ is the Site
    #   +tag+ is the name of the tag
    #
    # Returns <TagIndexPage>
    def initialize(site, tagname)
      super(site, "", File.join("_layouts", site.layouts['tag_index'].name))
      
      @tagname = tagname
      
      # self.raw_content = site.layouts['tag_index'].raw_content
      # self.ext = site.layouts['tag_index'].ext
      
      # Make sure the output dir exists
      FileUtils.mkdir_p File.join(site.dest, "tagged")
      
    end
    
    def render
      super({
        "posts" => self.site.tags[@tagname],
        "tag" => self.tagname
        
      })
    end
    
    def template
      "/tagged/#{@tagname}.html"
    end
    
  end # class TagPage
  
  class TagPagesGenerator < Generator
    safe true

    # Make tag pages from a special layout called "tag_layout"
    def generate(site)
      # Only makes these pages if the option is set in _config.yml
      return unless site.config['generate_tag_pages']
      
      unless site.layouts.key? 'tag_index'
        puts "Error: Need a tag_index layout from which to make tag index pages."
      else
        site.tags.keys.each do |tag|
          tip = TagIndexPage.new(site, tag)
          tip.render
          tip.write(site.dest)
        end
      end
      
      # tag_dir = File.join(site.config['destination'], "tagged")
      # FileUtils.mkdir_p tag_dir
      # site.tags.each_pair do |tag_name, pages_with_tag|
      #   tag_index_page = TagIndexPage.new(site, site.source, tag_name)
      #   
      #   site.pages << tag_index_page
      #   # File.open(File.join(tag_dir, sanitize_tag_name(tag_name)+'.html'), 'w') do |f|
      #   #   f.puts "tag page:"
      #   #   tagged_pages.each { |page| f.puts page.title }
      #   # end
      # end
    end
    
    # def sanitize_tag_name(tag_name)
    #   return tag_name.downcase.gsub(/ /, '_')
    # end
    
  end # class TagPagesGenerator
  
end # module Jekyll

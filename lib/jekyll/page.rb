module Jekyll

  class Page
    attr_accessor :site, :pager
    attr_accessor :name, :ext, :basename, :dir
    attr_accessor :data, :raw_content, :output

    # Initialize a new Page.
    #   +site+ is the Site
    #   +dir+ is the String path between <source> and the file
    #   +name+ is the String filename of the file
    #
    # Returns <Page>
    def initialize(site, dir, name)
      @site = site
      @base = site.source
      @dir  = dir
      @name = name
      self.process_name
      
      self.read_yaml
    end

    # Extract information from the post filename
    #
    # Returns nothing
    def process_name
      self.ext = File.extname(self.name)
      self.basename = File.basename(@name, self.ext)
    end
    
    # Read the YAML frontmatter
    #
    # Returns nothing
    def read_yaml()
      self.raw_content = File.read(File.join(@base, @dir, @name))

      if self.raw_content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
        self.raw_content = self.raw_content[($1.size + $2.size)..-1]

        self.data = YAML.load($1)
      end

      self.data ||= {}
    end

    # The generated directory into which the page will be placed
    # upon generation. This is derived from the permalink or, if
    # permalink is absent, set to '/'
    #
    # Returns <String>
    def dir
      url[-1, 1] == '/' ? url : File.dirname(url)
    end
    
    def method_missing(symbol, *args)
      # For rendering as haml, pass on any data values we have
      data = self.to_liquid
      if data.has_key? symbol
        data[symbol]
      else
        super(symbol, args)
      end
    end
    
    # The post title
    #
    # Returns <String>
    def title
      @title ||= (self.data && self.data["title"])
    end

    # The full path and filename of the post.
    # Defined in the YAML of the post body
    # (Optional)
    #
    # Returns <String>
    def permalink
      self.data && self.data['permalink']
    end

    def template
      if self.site.permalink_style == :pretty && !index? && html?
        "/:basename/"
      else
        "/:basename:output_ext"
      end
    end

    # The generated relative url of this page
    # e.g. /about.html
    #
    # Returns <String>
    def url
      return permalink if permalink

      @url ||= {
        "basename"   => self.basename,
        "output_ext" => self.output_ext,
      }.inject(template) { |result, token|
        result.gsub(/:#{token.first}/, token.last)
      }.gsub(/\/\//, "/")
    end

    # Determine the extension depending on content_type
    #
    # Returns the extensions for the output file
    def output_ext
      self.converter.output_ext(self.ext)
    end
    
    # Determine which converter to use based on our extension
    def converter
      @converter ||= self.site.converters.find { |c| c.matches(self.ext) }
    end
    
    # Converts the page and does layout as necessary
    #   +context+ is the data passed to the converter (such as the site_payload data)
    #
    # Returns rendered output as <String>
    def render(context={})
      context = {
        "page" => self,
        "site" => self.site,
        "pygments_prefix" => converter.pygments_prefix,
        "pygments_suffix" => converter.pygments_suffix,
        "pageinator" => pager.to_liquid,
      }.merge(context)
      
      # Figure out all the converters that should be used (by name)
      converters = [
        self.data["pre_converters"],
        self.converter.name,
        self.data["post_converters"],
      ].flatten.delete_if { |c| not c }
      
      self.output = self.raw_content
      converters.each do |converter_name|
        converter = self.site.converters.find { |c| c.name == converter_name }
        self.output = converter.convert(self.output, context) if converter
      end
      
      if layout = self.site.layouts[self.data["layout"]]
        context = context.deep_merge({"content" => self.output})
        self.output = layout.render(context)
      end
      self.output
    end
    
    def to_liquid
      self.data.deep_merge({
        "url"        => File.join(@dir, self.url),
      })
    end
    
    # Write the generated page file to the destination directory.
    #   +dest_prefix+ is the String path to the destination dir
    #   +dest_suffix+ is a suffix path to the destination dir
    #
    # Returns nothing
    def write(dest_prefix, dest_suffix = nil)
      dest = File.join(dest_prefix, @dir)
      dest = File.join(dest, dest_suffix) if dest_suffix
      FileUtils.mkdir_p(dest)

      # The url needs to be unescaped in order to preserve the correct filename
      path = File.join(dest, CGI.unescape(self.url))
      if self.url =~ /\/$/
        FileUtils.mkdir_p(path)
        path = File.join(path, "index.html")
      end

      File.open(path, 'w') do |f|
        f.write(self.output)
      end
    end

    def inspect
      "#<Jekyll::Page @name=#{self.name.inspect}>"
    end

    def html?
      output_ext == '.html'
    end

    def index?
      basename == 'index'
    end

  end

end

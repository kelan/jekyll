module Jekyll

  class Post < Page
    include Comparable

    class << self
      attr_accessor :lsi
    end

    MATCHER = /^(.+\/)*(\d+-\d+-\d+(?:_\d+-\d+)?)-(.*)(\.[^.]+)$/

    # Post name validator. Post filenames must be like:
    #   2008-11-05-my-awesome-post.textile
    # or:
    #   2008-11-05_12-45-my-awesome-post.textile
    #
    # Returns <Bool>
    def self.valid?(name)
      name =~ MATCHER
    end

    attr_accessor :site
    attr_accessor :data, :content, :output, :ext
    attr_accessor :date, :slug, :published, :tags, :categories

    # Initialize this Post instance.
    #   +site+ is the Site
    #   +base+ is the String path to the dir containing the post file
    #   +name+ is the String filename of the post file
    #   +categories+ is an Array of Strings for the categories for this post
    #
    # Returns <Post>
    def initialize(site, dir, name)
      super(site, File.join(dir, '_posts'), name)
      
      self.categories = dir.split('/').reject { |x| x.empty? }

      #If we've added a date and time to the yaml, use that instead of the filename date
      #Means we'll sort correctly.
      if self.data.has_key?('date')
        # ensure Time via to_s and reparse
        self.date = Time.parse(self.data["date"].to_s)
      end
      if self.data.key?("time")
        time = Time.parse(self.data["time"])
        self.date = Time.mktime(self.date.year, self.date.month, self.date.day, time.hour, time.min)
      end
      

      if self.data.has_key?('published') && self.data['published'] == false
        self.published = false
      else
        self.published = true
      end

      self.tags = self.data.pluralized_array("tag", "tags")

      if self.categories.empty?
        self.categories = self.data.pluralized_array('category', 'categories')
      end
    end
    
    def read_yaml
      self.data = site.post_defaults.dup # first get the post_default values
      super # now let the yaml data supersede it
    end

    # Extract information from the post filename
    #
    # Returns nothing
    def process_name
      super
      m, cats, date, slug, ext = *name.match(MATCHER)
      date = date.sub(/_(\d+)-(\d+)\Z/, ' \1:\2')  # Make optional time part parsable.
      self.date = Time.parse(date)
      self.slug = slug
      self.ext = ext
    end

    # Spaceship is based on Post#date, slug
    #
    # Returns -1, 0, 1
    def <=>(other)
      cmp = self.date <=> other.date
      if 0 == cmp
       cmp = self.slug <=> other.slug
      end
      return cmp
    end

    # The generated directory into which the post will be placed
    # upon generation. This is derived from the permalink or, if
    # permalink is absent, set to the default date
    # e.g. "/2008/11/05/" if the permalink style is :date, otherwise nothing
    #
    # Returns <String>
    def dir
      File.dirname(url)
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
      case self.site.permalink_style
      when :pretty
        "/:categories/:year/:month/:day/:title/"
      when :none
        "/:categories/:title.html"
      when :date
        "/:categories/:year/:month/:day/:title.html"
      else
        self.site.permalink_style.to_s
      end
    end

    # The generated relative url of this post
    # e.g. /2008/11/05/my-awesome-post.html
    #
    # Returns <String>
    def url
      return permalink if permalink

      @url ||= {
        "year"       => date.strftime("%Y"),
        "month"      => date.strftime("%m"),
        "day"        => date.strftime("%d"),
        "title"      => CGI.escape(slug),
        "i_day"      => date.strftime("%d").to_i.to_s,
        "i_month"    => date.strftime("%m").to_i.to_s,
        "categories" => categories.join('/'),
        "output_ext" => self.output_ext
      }.inject(template) { |result, token|
        result.gsub(/:#{Regexp.escape token.first}/, token.last)
      }.gsub(/\/\//, "/")
    end

    # The post title
    #
    # Returns <String>
    def title
      @title ||= begin
        (self.data && self.data["title"]) ||
        self.slug.split('-').select {|w| w.capitalize! || w }.join(' ')
      end
    end

    # The UID for this post (useful in feeds)
    # e.g. /2008/11/05/my-awesome-post
    #
    # Returns <String>
    def id
      File.join(self.dir, self.slug)
    end
    
    # The path to the post file.
    #
    # Returns <String>
    def path
      File.expand_path(File.join(@base, @name))
    end

    # Calculate related posts.
    #
    # Returns [<Post>]
    def related_posts(posts)
      return [] unless posts.size > 1

      if self.site.lsi
        self.class.lsi ||= begin
          puts "Running the classifier... this could take a while."
          lsi = Classifier::LSI.new
          posts.each { |x| $stdout.print(".");$stdout.flush;lsi.add_item(x) }
          puts ""
          lsi
        end

        related = self.class.lsi.find_related(self.content, 11)
        related - [self]
      else
        (posts - [self])[0..9]
      end
    end

    # Write the generated post file to the destination directory.
    #   +dest+ is the String path to the destination dir
    #
    # Returns nothing
    def write(dest)
      FileUtils.mkdir_p(File.join(dest, dir))

      # The url needs to be unescaped in order to preserve the correct filename
      path = File.join(dest, CGI.unescape(self.url))

      if template[/\.html$/].nil?
        FileUtils.mkdir_p(path)
        path = File.join(path, "index.html")
      end

      File.open(path, 'w') do |f|
        f.write(self.output)
      end
    end

    # Convert this post into a Hash for use in Liquid templates.
    #
    # Returns <Hash>
    def to_liquid
      super.deep_merge({
        "title"      => self.title,
        "date"       => self.date,
        "id"         => self.id,
        "categories" => self.categories,
        "next"       => self.next,
        "previous"   => self.previous,
        "tags"       => self.tags,
      })
    end

    def inspect
      "<Jekyll::Post: #{self.id}>"
    end

    def next
      pos = self.site.posts.index(self)

      if pos && pos < self.site.posts.length-1
        self.site.posts[pos+1]
      else
        nil
      end
    end

    def previous
      pos = self.site.posts.index(self)
      if pos && pos > 0
        self.site.posts[pos-1]
      else
        nil
      end
    end
  end

end

module Jekyll

  class TextileConverter < Converter
    safe true

    pygments_prefix '<notextile>'
    pygments_suffix '</notextile>'

    def setup
      require 'redcloth'
    rescue LoadError
      STDERR.puts 'You are missing a library required for Textile. Please run:'
      STDERR.puts '  $ [sudo] gem install RedCloth'
      raise FatalException.new("Missing dependency: RedCloth")
    end

    def matches(ext)
      ext =~ /textile/i
    end

    def output_ext(ext)
      ".html"
    end

    def convert(content, context)
      self.do_setup_once
      RedCloth.new(content).to_html
    end
  end

end

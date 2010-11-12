require 'haml'

# Add a haml filter for highlighting
# It will look for a "@lang-name"  hint on the first line of the
# code block.
module Haml::Filters::Highlight
  include Haml::Filters::Base
  def render(text)
    # Check for a language type
    lang = ""
    firstline = text.split.first
    if firstline =~ /\s*@(\w+)\s*$/
      lang = $1
      text.sub! firstline+"\n", ''
    end
    options = {}
    colorized = Albino.new(text, lang).to_s(options)
    # Add nested <code> tags to code blocks
    colorized.sub!(/<pre>/,'<pre><code class="' + lang + '">')
    colorized.sub!(/<\/pre>/,"</code></pre>")
    colorized
  end
end

module Jekyll
  
  # Some default helper functions that can be useful in haml pages
  module HamlHelpers
    def h(text)
      CGI.escapeHTML(text)
    end
    
    def link_to(text, url, attributes = {})
      attributes = { :href => url }.merge(attributes)
      attributes = attributes.map {|key, value| %{#{key}="#{h value}"} }.join(" ")
      "<a #{attributes}>#{text}</a>"
    end
  end
  
  
  class HamlConverter < Converter
    safe false
    priority :low
    
    def setup
      require 'ostruct'
      # You can add per-site helpers in a _helpers.rb file at the
      # root of your site, in a Helpers module.
      helpers = File.join(@config['source'], '_helpers.rb')
      require helpers if File.exist?(helpers)
    end

    def matches(ext)
      ext =~ /haml/i
    end

    def output_ext(ext)
      ".html"
    end

    def convert(content, context)
      self.do_setup_once
      begin
        engine = Haml::Engine.new(content, :attr_wrapper => %{"})
        
        # helpers has methods that will be called, and context has local variables
        helpers = OpenStruct.new(context)
        helpers.extend(HamlHelpers)
        
        helpers.extend(::Helpers) if defined?(::Helpers) # add helpers from the _helpers.rb file
        
        engine.render(helpers)
        
      rescue StandardError => e
          puts "!!! HAML Error: " + e.message
      end
    end
    
  end

end
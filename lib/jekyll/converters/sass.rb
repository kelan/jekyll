# from: https://gist.github.com/528642/9910ee5d3bbfe94df340be867f55906e077c7508

module Jekyll
  require 'sass'
  
  class SassConverter < Converter
    safe true
    priority :low

     def matches(ext)
      ext =~ /sass/i
    end

    def output_ext(ext)
      ".css"
    end

    def convert(content, context)
      begin
        engine = Sass::Engine.new(content)
        engine.render
      rescue StandardError => e
        puts "!!! SASS Error: " + e.message
      end
    end
  end
  
end
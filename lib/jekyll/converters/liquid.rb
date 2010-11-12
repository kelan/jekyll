module Jekyll

  class LiquidConverter < Converter
    safe true
    priority :low
    
    def setup
      return if @setup
      @filters = [Jekyll::Filters]
      @setup = true
    end

    def matches(ext)
      ext =~ /(html|xml)/i
    end

    def output_ext(ext)
      ext
    end

    def convert(content, context)
      setup
      info = { :filters => @filters, :registers => { :site => context['site'] } }
      Liquid::Template.parse(content).render(context, info)
    end

  end

end

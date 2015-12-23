module Jekyll
  module SanitizeStringFilter
    def sanitize_string(input)
    	unless input.nil?
        input = input.downcase
        input = input.gsub(/[^\w\s_-]+/, '-')
        input = input.gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
        input = input.gsub(/\s+/, '-')
        input = input.gsub(/.,?!/, '-')
        input = input.gsub(/\//, '-')
        input = input.gsub(/\\/, '-')        
        input = input.gsub(/\-+/, '-')
        input = input[0..50]       
        input = input.gsub(/\-+$/, '')
	    end
    end
  end
end

Liquid::Template.register_filter(Jekyll::SanitizeStringFilter)
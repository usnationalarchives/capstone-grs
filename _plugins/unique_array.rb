# this method returns an array of unique values
module Jekyll
  module UniqueArrayFilter
    def unique_array(array)    	
    	array.uniq
    end
  end
end

Liquid::Template.register_filter(Jekyll::UniqueArrayFilter)
module Jekyll
  module MapToJsonFilter
    def map_to_json(array, index)     	
    	new_array = []    
    	array.each do |hash|
    	  unless hash[index].nil?
          new_array.push({ index => hash[index] })    		    		
        end
      end      
      new_array.uniq {|e| e[index] }
    end
  end
end

Liquid::Template.register_filter(Jekyll::MapToJsonFilter)
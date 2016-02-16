# this method sorts an array, deleting nil values in the process
module Jekyll
  module SortArrayFilter
    def sort_array(array) 
    	array = array.delete_if {|x| x.nil? }   	
    	array.sort
    end
  end
end

Liquid::Template.register_filter(Jekyll::SortArrayFilter)
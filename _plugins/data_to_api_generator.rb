module Jekyll
  require 'csv'

  class DataToApiPage < Page    
    def initialize(site, base, dir, template, filename)      
      @site = site
      @base = base
      @dir = dir
      @name = filename      
      
      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), template)
      self.data[filename] = ""
    end
  end

  class DataToApiGenerator < Jekyll::Generator
    safe true
    priority :normal
    
    def generate(site)      
      dir = '_data'
      base = File.join(site.source, dir)

      # # get list of all csv files in data directory
      # file_names = Dir.chdir(base) { Dir["*.csv"] }            
      # file_names.each do |filename|        
      #   path = File.join(site.source, dir, filename)
        
      #   file_data = CSV.read(path, :headers => true)
      #   data = Hash.new
      #   data['keys'] = file_data.headers.map { |key|
      #     sanitize_string(key)
      #   }
      #   data['content'] = file_data.to_a[1..-1]
        
      #   create_pages(site, filename, data)
      # end

      site.data.each do |key, data|
        unless data.empty?
          dat = Hash.new
          headers = data.map(&:keys)  
          dat['keys'] = headers[0].map { |key|
            sanitize_string(key)
          }
          dat['content'] = data.map(&:values)        

          create_pages(site, dat, key)
        end
      end
    end

    def create_pages(site, data, filename)
      sanitized_filename = sanitize_string(base_filename(filename))
      
      data['keys'].each do |key|
        if key
          site.pages << DataToApiPage.new(site, site.source, 
            File.join('api', sanitized_filename),
            "column_request.json", "#{key}.json")
          site.pages << DataToApiPage.new(site, site.source, 
            File.join('api', sanitized_filename),
            "column_request.html", "#{key}.html")            
        end
      end

      data['content'].each do |row|
        row.each_index do |index|
          unless row[index].nil?
            site.pages << DataToApiPage.new(site, site.source, 
            File.join('api', sanitized_filename, sanitize_string(data['keys'][index])),
            "element_request.json", "#{ sanitize_string(row[index]) }.json")  

            site.pages << DataToApiPage.new(site, site.source, 
            File.join('api', sanitized_filename, sanitize_string(data['keys'][index])),
            "element_request.html", "#{ sanitize_string(row[index]) }.html")  
          end
        end
      end        

      # create json file
      site.pages << DataToApiPage.new(site, site.source, 'api', 
        "root_request.json", "#{sanitized_filename}.json")              

      # create html file
      site.pages << DataToApiPage.new(site, site.source, 'api', 
        "root_request.html", "#{sanitized_filename}.html")

    end    

    # this can be cleaned up into one or two regex's
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
        input = input.gsub(/\-+$/,'')
      else
        ""
      end
    end
    
    def base_filename(name)
      extn = File.extname(name)
      name = File.basename(name, extn)
    end

  end
end
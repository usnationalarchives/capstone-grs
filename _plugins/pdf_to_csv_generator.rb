module Jekyll
  require 'csv'
  require 'yaml'
  require 'origami'
  include Origami

  class PdfToCsvGenerator < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      # set directory csv data will come from
      forms_dir = "forms"
      data_dir = "_data"
      base = File.join(site.source, forms_dir)

      # get a list of all pdf files in forms directory
      file_names = Dir.chdir(base) { Dir["*.pdf"] }
      
      # get the form template that specifies the pdf structure and parse tokens
      form_template = YAML.load_file(File.join(site.source, 'form_template.yml'))

      # create array to store csv data of all files
      data = []

      # add header row to the generated csv data
      data << form_template.map { |key, item| item['column-name'] }

      # go through all pdf files, extract data, and add to the csv
      file_names.each do |filename|        
        begin
          puts "[Debug] Attempting to process #{filename}"
          # reset offset 
          offset = 0

          # create array to store this file's CSV row data
          csv_row = []

          # get full path of the pdf filename
          path = File.join(site.source, forms_dir, filename)

          # convert pdf to readable text
          # pdf_text = Yomu.new(File.join(base, filename)).text
          pdf = Origami::PDF.read(File.join(base, filename))        
          o = pdf.grep("xfa\:datasets")
          pdf_text = o.last.data.gsub(/\n/, '')

          # look for each item specified in the form template
          form_template.each do |key, item|
            # reset found_item to empty string
            found_item = ""
            item_type = item['type']
            if item_type == 'text' 
              found_item, offset = get_text_input(item, offset, pdf_text)
            elsif item_type == 'number'
              found_item, offset = get_text_input(item, offset, pdf_text)              
            elsif item_type == 'text-multi-row'
              found_item, offset = get_multi_text_input(item, offset, pdf_text)
            elsif item['type'] == 'checkbox'
              found_item, offset = get_checkbox_input(item['labels'], offset, pdf_text)
            end          
            # add the item found to the csv row
            csv_row << found_item.gsub(".00000000", "")       
          end

          # add generated csv row to the csv data
          data << csv_row
        rescue
          puts "[ERROR] Processing of #{filename} failed"
        end
      end

      # save the csv as a file in the data_dir directory
      # save_to_csv_file(site, data_dir, data)

      # save the csv to site.data instead of creating a file
      save_to_site_data(site, data)      
    end

    def save_to_csv_file(site, data_dir, data)            
      CSV.open(File.join(site.source, data_dir, "forms.csv"), "wb") do |csv|
        data.each do |row|
          csv << row
        end
      end  
    end

    def save_to_site_data(site, data)
     # site.data['fo'] = []
      # site.data['fo'] << data.map(&:to_hash)

      csv_string = CSV.generate do |csv|
        data.each do |row|
          csv << row
        end
      end

      table = CSV.parse(csv_string, { :headers => true })
      site.data['forms'] = {}
      site.data['forms'] = table.map(&:to_hash)
    end

    def find_index(target_string, offset, text)
      escaped_target_string = Regexp.escape(target_string)
      target_string_regexp = Regexp.new(escaped_target_string)      
      index = text.index(target_string_regexp, offset)
      return index
    end

    def get_text_input(item, offset, pdf_text)
      found_item = ""
      index_start = find_index(item['before'], offset, pdf_text)
      offset = index_start.nil? ? offset : index_start
      index_end = (find_index(item['after'], index_start, pdf_text)) unless index_start.nil?

      if index_start && index_end
        # increment offset so we don't search the same text again
        offset = index_end

        index_start = index_start + item['before'].length
        length = index_end - index_start
        found_item = pdf_text.slice(index_start, length)     
      end

      if found_item.nil?
        found_item = ""
      else
        found_item = found_item.gsub("&#xD;", ", ")
      end

      return found_item, offset
    end

    def get_multi_text_input(item, offset, pdf_text)
      found_rows = ""      
      fields = item['fields']
      
      index_start = find_index(item['begin'], offset, pdf_text)
      index_end = find_index(item['end'], offset, pdf_text)            
      length = index_end - index_start
      pdf_section = pdf_text.slice(index_start, length)    
      
      offset = 0
      
      # go through each row
      next_item_index = true      
      while !next_item_index.nil?
        found_row = ""
        # go through each field in the row
        fields.each do |field|                    
          found_item, offset = get_text_input(field, offset, pdf_section)
          found_row = (found_row.split(", ") << found_item).join(", ")          
        end        
        found_rows = (found_rows.split(";") << found_row).join("; ")
        next_item_index = find_index(fields.first['before'], offset, pdf_section)
      end

      return found_rows, index_start
    end

    def get_checkbox_input(checkboxes, offset, pdf_text) 
      found_item = ""           
      
      checkboxes.each do |label|
        label = label['label']
        index_start = find_index(label['before'], offset, pdf_text)
        index_end = find_index(label['after'], index_start, pdf_text)
        
        if index_start && index_end
          offset = index_end

          index_start = index_start + label['before'].length          
          length = index_end - index_start
          value = pdf_text.slice(index_start, length)

          unless value.nil?
            if value == "1" || value == "On"
              found_item = (found_item.split(",") << label['label-name']).join(", ")
            elsif value.empty? || value == "Off"
              # not checked
            end
          end

        end
      end
      return found_item, offset
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
        input = input.gsub(/\-+$/, '')
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
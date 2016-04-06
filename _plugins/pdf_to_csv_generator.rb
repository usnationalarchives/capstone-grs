# this class extracts data from PDF forms and stores it in site.data
module Jekyll
  require 'csv'
  require 'yaml'
  require 'origami'
  require 'crack' # for xml and json
  require 'crack/json' # for just json
  require 'crack/xml' # for just xml
  require 'hashie'

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

          # create array to store this file's CSV row data
          csv_row = []

          # get full path of the pdf filename
          path = File.join(site.source, forms_dir, filename)

          # convert pdf to readable text
          # pdf_text = Yomu.new(File.join(base, filename)).text
          pdf = Origami::PDF.read(File.join(base, filename))        
          o = pdf.grep("xfa\:datasets")
          pdf_text = o.last.data.gsub(/\n/, '')

          pdf_mash = Hashie::Mash.new(Crack::XML.parse(pdf_text))
          pdf_mash = pdf_mash['xfa:datasets']['xfa:data']
          pdf_mash.extend Hashie::Extensions::DeepFind

          # look for each item specified in the form template
          form_template.each do |key, item|
            # reset found_item to empty string
            found_item = ""
            item_type = item['type']
            if item_type == 'text' 
              found_item = get_text_input(item, pdf_mash)
            elsif item_type == 'number'
              found_item = get_text_input(item, pdf_mash)              
            elsif item_type == 'text-multi-row'
              found_item = get_multi_text_input(item, pdf_mash)
            elsif item['type'] == 'checkbox'
              found_item = get_checkbox_input(item['labels'], pdf_mash)
            end          
            # add the item found to the csv row
            csv_row << found_item.gsub(".00000000", "")       
          end

          # add generated csv row to the csv data
          data << csv_row
        rescue Exception => e
          puts "[ERROR] Processing of #{filename} failed, #{e}"
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
      csv_string = CSV.generate do |csv|
        data.each do |row|
          csv << row
        end
      end

      table = CSV.parse(csv_string, { :headers => true })
      site.data['forms'] = {}
      site.data['forms'] = table.map(&:to_hash)
    end

    def get_text_input(item, pdf_mash)
      found_item = pdf_mash.deep_find(item['match'])
      found_item = "" if found_item.nil? 
      return found_item
    end

    def get_multi_text_input(item, pdf_mash)      
      found_rows = ""      
      fields = item['fields']
      field_set = pdf_mash.deep_find(item['match'])

      field_set.extend(Hashie::Extensions::DeepLocate)
      mash_fields = field_set.deep_locate("TextField11")

      mash_fields.each do |m|
        found_row = ""
        fields.each do |field|           
          m.extend Hashie::Extensions::DeepFind         
          found_item = get_text_input(field, m)
          found_row = (found_row.split(", ") << found_item).join(", ")          
        end        
        found_rows = (found_rows.split(";") << found_row).join("; ")        
      end

      return found_rows
    end

    def get_checkbox_input(checkboxes, pdf_mash) 
      found_item = ""           
      
      checkboxes.each do |label|
        label = label['label']
        value = get_text_input(label, pdf_mash)

        unless value.nil?
          if value == "1" || value == "On"
            found_item = (found_item.split(",") << label['label-name']).join(", ")
          elsif value.empty? || value == "Off"
            # not checked
          end
        end
      end
      return found_item
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
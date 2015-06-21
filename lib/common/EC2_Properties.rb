require 'rubygems'

class EC2_Properties 

  def initialize
  end 
  def index(folder)
    dir = "#{$ec2_main.settings.get_system('ENV_PATH')}/#{folder}"
    puts "Checking for folder #{dir}"
    items = Array.new
    items_hashs = Array.new
    if File.directory? dir
      items = Dir.entries(dir)
    end
    items.delete(".")
    items.delete("..")
    items.each_index do |i|
      if items[i][-11..-1] == '.properties'
        items[i] = items[i][0..-12]
      end 
    end
    return items
  end
  def all(folder)
    items = self.index(folder)
    items_hash = Array.new
    items.each_index do |i|
      items_hash[i] = get(folder, items[i])
    end 
    return items_hash
  end
  def exists(folder, item)
    exists = false
    fn = $ec2_main.settings.get_system('ENV_PATH')+"/#{folder}/#{item}.properties"
    if File.exists?(fn)
      exists = true
    end
    return exists
  end   
  def get(folder, item)
    properties ={}
    fn = $ec2_main.settings.get_system('ENV_PATH')+"/#{folder}/#{item}.properties"
    if File.exists?(fn)
      File.open(fn, 'r') do |properties_file|
        properties_file.read.each_line do |line|
          line.strip!
          if (line[0] != ?# and line[0] != ?=)
            i = line.index('=')
            if (i)
              properties[line[0..i - 1].strip] = line[i + 1..-1].strip
            else
              properties[line] = ''
            end   
          end
        end
      end
    end
    return properties
  end   
  def save(folder, item, properties = {})
    response = false
    doc = ""
    properties.each_pair do |key, value|
      if value != nil 
        puts "#{key}=#{value}\n"
        doc = doc + "#{key}=#{value}\n"
      end 
    end
    dir = "#{$ec2_main.settings.get_system('ENV_PATH')}/#{folder}"
    puts "Checking for folder #{dir}"
    if !File.directory? dir
      puts "creating....#{dir}"
      Dir.mkdir(dir)
    end     
    fn = $ec2_main.settings.get_system('ENV_PATH')+"/#{folder}/#{item}.properties"
    begin
      File.open(fn, "w") do |f|
        f.write(doc)
      end
      puts "#{fn} save sucessful"
      response = true
    rescue
      puts "#{fn} save failed" 
      response = true
    end    
    return response 
  end

  def delete(folder, item)
    response = false
    fn = $ec2_main.settings.get_system('ENV_PATH')+"/#{folder}/#{item}.properties"
    begin
      File.delete(fn)
      response = true
    rescue
      puts "#{fn} delete failed"
      response = false      
    end       
    return response 
  end


end

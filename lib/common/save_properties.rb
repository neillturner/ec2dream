def save_properties(properties, file_name) 
  doc = ""
  properties.each_pair do |key, value|
    puts "#{key}=#{value}"
    doc = doc + "#{key}=#{value}\n"
  end
  File.open(file_name, "w") do |f|
    f.write(doc)
    f.close
  end
end

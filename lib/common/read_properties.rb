def read_properties(file_name,set_env=false)
  p = {}
  File.open(file_name, 'r') do |f|
    f.read.each_line do |line|
      line.strip!
      if (line[0] != ?# and line[0] != ?=)
        i = line.index('=')
        if (i)
          key = line[0..i - 1].strip
          p[key] = line[i + 1..-1].strip
          if set_env and key.index("EC2_")==0 or key.index("AMAZON_")==0 or key.index("S3_")==0
            ENV[key]=p[key]
          end
        else
          p[line] = ''
        end
      end
    end
  end
  p
end
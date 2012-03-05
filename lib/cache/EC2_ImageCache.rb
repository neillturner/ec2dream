
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'fileutils'

include Fox  

class EC2_ImageCache 

 def initialize(owner)
    @ec2_main = owner
    @image_all = Array.new
    @image_small = Array.new
    @image_large = Array.new
    @image_ebs = Array.new
    @image_ebs_small = Array.new
    @image_ebs_large = Array.new   
    @image_instance = Array.new
    @image_instance_small = Array.new
    @image_instance_large = Array.new   
    @status = "empty"
 end 
 
 def load
           ec2 = @ec2_main.environment.connection
           if ec2 != nil
              @status = "loading"
              env_name = @ec2_main.environment.env
              cache_filename = ENV['EC2DREAM_HOME']+"/env/"+env_name+"/image_cache.txt"
              if File.exist?(cache_filename)
                 answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Existing Cache","Do you wish to use the existing cache?")
                 if answer == MBOX_CLICKED_NO
                    File.delete(cache_filename)
                 end
              end   
              if !File.exist?(cache_filename)
                  puts "*********************************************************************"
                  puts "*** ImageCache Loading this could take a few minutes              ***"
                  puts "*** but once loading it will be much quicker searching for images ***"
                  puts "*********************************************************************"
                  puts "Creating Image Cache File #{cache_filename}...."
                  doc = "" 
                  ec2.describe_images_by_executable_by("all").each do |r|
                     doc = doc + "#{r[:aws_id]},#{r[:aws_architecture]},#{r[:root_device_type]},#{r[:aws_location]}\n" 
                  end
     	          File.open( cache_filename, "w") do |f|
    	             f.write(doc)
    	             f.close
                  end 
              end
              cache_file = File.new(cache_filename, "r")
              puts "Reading Image Cache File #{cache_filename}...."
              while (line = cache_file.gets)
                 sa = (line).split","
                 r = {}
                 r[:aws_id] = sa[0]
                 r[:aws_architecture] = sa[1]
                 r[:root_device_type] = sa[2]
                 r[:aws_location] = sa[3]
                 @image_all.push(r[:aws_location]+"  ("+r[:aws_id]+")")
                 if r[:aws_architecture] == "i386"
                    @image_small.push(r[:aws_location]+"  ("+r[:aws_id]+")")
                 else
                    @image_large.push(r[:aws_location]+"  ("+r[:aws_id]+")")
                 end
                 if r[:root_device_type] == "ebs"
                    @image_ebs.push(r[:aws_location]+"  ("+r[:aws_id]+")")
                    if r[:aws_architecture] == "i386"
                       @image_ebs_small.push(r[:aws_location]+"  ("+r[:aws_id]+")")
                    else
                       @image_ebs_large.push(r[:aws_location]+"  ("+r[:aws_id]+")")
                    end                   
                 else
                    @image_instance.push(r[:aws_location]+"  ("+r[:aws_id]+")")
                    if r[:aws_architecture] == "i386"
                       @image_instance_small.push(r[:aws_location]+"  ("+r[:aws_id]+")")
                    else
                       @image_instance_large.push(r[:aws_location]+"  ("+r[:aws_id]+")")
                    end                    
                 end                 
              end
              cache_file.close                 
              @image_all = @image_all.sort
              @image_ebs = @image_ebs.sort
              @image_instance = @image_instance.sort
              @image_small = @image_small.sort
              @image_large = @image_large.sort
              @image_ebs_small = @image_ebs_small.sort
              @image_ebs_large = @image_ebs_large.sort
              @image_instance_small = @image_instance_small.sort
              @image_instance_large = @image_instance_large.sort              
 	     @status = "loaded" 

 	     puts "ImageCache Loaded"
 	     puts "#{@image_all.size} All Images"
 	     puts "#{@image_ebs.size} Ebs Images"
 	     puts "#{@image_instance.size} Instance Images"
 	     puts "#{@image_small.size} All Small Images"
 	     puts "#{@image_large.size} All Large Images"
 	     puts "#{@image_ebs_small.size} Ebs Small Images"
 	     puts "#{@image_ebs_large.size} Ebs Large Images"
  	     puts "#{@image_instance_small.size} Instance Small Images"
 	     puts "#{@image_instance_large.size} Instance Large Images"	     
           end
 end

 def get(search,arch,root_device=nil)
   while @status != "loaded"
     sleep 10
   end 
   if (root_device == nil or root_device == "")
      return build(search,arch,@image_all,@image_small,@image_large)
   elsif (root_device == "ebs")
      return build(search,arch,@image_ebs,@image_ebs_small,@image_ebs_large)
   else   
      return build(search,arch,@image_instance,@image_instance_small,@image_instance_large)
   end
 end 
 
  def build(search,arch,image_all,image_small,image_large)
    if (search == nil or search == "")
          if arch == "i386"
             return image_small
          else
             if arch == "x86_64"
                return image_large
             else
                puts "return image all"
                return image_all
             end
          end
     else
          image_locs = Array.new
          if arch == "i386"
             image_small.each do |t|
                if t.index(search) != nil
                   image_locs.push(t)
                end   
             end
          elsif arch == "x86_64"
 	       image_large.each do |t|
 	          if t.index(search) != nil
 	             image_locs.push(t)
 	          end   
                end
          else 
  	       image_all.each do |t|
                   if t.index(search) != nil
                      image_locs.push(t)
                   end   
               end
          end
    end
    return image_locs
  end    
 
 def status
    @status
 end
 
end
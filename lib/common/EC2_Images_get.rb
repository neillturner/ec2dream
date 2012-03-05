require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

require 'common/EC2_ResourceTags'

class EC2_Images_get 

  def initialize(owner)
    @ec2_main = owner
    @error_message = ""
  end    

  def get_images(type, platform, root, search, filter)
          owner = ""
          executable = ""
          arch = ""
          search = search.downcase
          root_device=root
          image_locs = Array.new
          @tags_filter = filter
          if platform == "Small(i386)"
            arch = "i386"
          end  
          if platform == "Large(x86_64)"
            arch = "x86_64"
          end
          case type 
             when "Owned By Me"
                owner = "self"
             when "Amazon Images"
                owner = "amazon"
             when "Public Images"
                executable = "all"
                #if @tags_filter[:image] == nil or  @tags_filter[:image].empty?
                #   @title.text = "Images (Cached)"
                #end   
             when "Private Images"
                executable = "self"
             else
                search = type.downcase
     	        type = "Public Images"
                executable = "all"
                #if @tags_filter[:image] == nil or  @tags_filter[:image].empty?
                #   @title.text = "Images (Cached)"
                #end  
          end
          if @tags_filter[:image] != nil and !@tags_filter[:image].empty?
             i=0
             ec2 = @ec2_main.environment.connection
             begin
              ec2.describe_images(:filters => @tags_filter[:image]).each do |r|
                 if search != nil and search != ""
                   loc = r[:aws_location].downcase
                   if loc.index(search) != nil
                      if arch == nil or  arch == "" or arch == r[:aws_architecture]
                         if root_device == nil or  root_device == "" or root_device == r[:root_device_type]
                            if r[:aws_is_public] == nil or r[:aws_is_public]
                               r[:aws_is_public]="Public"                           
                            else
                               r[:aws_is_public]="Private"
                            end
                            t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil) 
                            n = t.nickname
			    if n != "" and n != nil
			       r[:aws_id] = n+"/"+ r[:aws_id]
                            end
			    r[:tags] = t
			    puts r[:aws_id]
                            image_locs[i] = r
                            i = i+1
                         end   
                      end                    
                   end
                else
                   if arch == nil or  arch == "" or arch == r[:aws_architecture]
                      if root_device == nil or  root_device == "" or root_device == r[:root_device_type]
                         if r[:aws_is_public] == nil or r[:aws_is_public]
                            r[:aws_is_public]="Public"                           
                         else
                            r[:aws_is_public]="Private"
                         end
                         t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil) 
                         n = t.nickname
			 if n != "" and n != nil
			    r[:aws_id] = n+"/"+ r[:aws_id]
                         end
			 r[:tags] = t                
                         image_locs[i] = r
                         i = i+1
                      end   
                   end   
                end
             end
            rescue 
	      @error_message = "Image Listing Error #{$!.to_s}"
              image_locs = Array.new             
            end             
          else
           if owner != ""
             i=0
             ec2 = @ec2_main.environment.connection
             ec2.describe_images_by_owner(owner).each do |r|
                if search != nil and search != ""
                   loc = r[:aws_location].downcase
                   if loc.index(search) != nil
                      if arch == nil or  arch == "" or arch == r[:aws_architecture]
                         if root_device == nil or  root_device == "" or root_device == r[:root_device_type]
                            if r[:aws_is_public] == nil or r[:aws_is_public]
                               r[:aws_is_public]="Public"                           
                            else
                               r[:aws_is_public]="Private"
                            end
                            t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil) 
                            n = t.nickname
			    if n != "" and n != nil
			       r[:aws_id] = n+"/"+ r[:aws_id]
                            end
			    r[:tags] = t
                            image_locs[i] = r
                            i = i+1
                         end   
                      end                    
                   end
                else
                   if arch == nil or  arch == "" or arch == r[:aws_architecture]
                      if root_device == nil or  root_device == "" or root_device == r[:root_device_type]
                         if r[:aws_is_public] == nil or r[:aws_is_public]
                            r[:aws_is_public]="Public"                           
                         else
                            r[:aws_is_public]="Private"
                         end
                         t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil) 
                         n = t.nickname
			 if n != "" and n != nil
			    r[:aws_id] = n+"/"+ r[:aws_id]
                         end
			 r[:tags] = t                 
                         image_locs[i] = r
                         i = i+1
                      end   
                   end   
                end
             end
          else
           if executable == "all"
              status = @ec2_main.imageCache.status
              if status == "loading"
                 error_message("Public Images","Public Images currently are loading")
                 image_locs = Array.new
                 return image_locs
              end
              if status == "empty"
                 @ec2_main.imageCache.load
              end
              
              image_list = @ec2_main.imageCache.get(search,arch,root_device)
              if image_list != nil 
                 i = 0
  	       image_list.each do |e|
  	          r = {}
  	          sa = e.split("(")
                    if sa.size>1
                       j = 0
                       r[:aws_location] = ""
                       while j < sa.size-1
                          r[:aws_location] = r[:aws_location] + sa[j]
                          j = j+1
                       end   
                       l = sa[sa.size-1]
                       r[:aws_id] = l[0,l.length-1]
                       r[:root_device_type] = root_device
                       r[:aws_is_public]="Public"
                       image_locs[i] = r
                       i = i+1
                    end
                 end   
              end
             else 
                i=0
                ec2 = @ec2_main.environment.connection
                ec2.describe_images_by_executable_by(executable).each do |r|
                   if search != nil and search != ""
                      loc = r[:aws_location].downcase
                      if loc.index(search) != nil
                         if arch == nil or  arch == "" or arch == r[:aws_architecture]
                            if root_device == nil or  root_device == "" or root_device == r[:root_device_type]
                               if r[:aws_is_public] == nil or r[:aws_is_public]
                                  r[:aws_is_public]="Public"                           
                               else
                                  r[:aws_is_public]="Private"
                               end
                               t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil) 
                               n = t.nickname
			       if n != "" and n != nil
			          r[:aws_id] = n+"/"+ r[:aws_id]
                               end
			       r[:tags] = t                       
                               image_locs[i] = r
                               i = i+1
                            end   
                         end                    
                      end
                   else
                      if arch == nil or  arch == "" or arch == r[:aws_architecture]
                         if root_device == nil or  root_device == "" or root_device == r[:root_device_type] or r[:root_device_type] == nil
                            if r[:aws_is_public] == nil or r[:aws_is_public]
                               r[:aws_is_public]="Public"                           
                            else
                               r[:aws_is_public]="Private"
                            end
                            t = EC2_ResourceTags.new(@ec2_main,r[:tags],nil) 
                            n = t.nickname
			    if n != "" and n != nil
			       r[:aws_id] = n+"/"+ r[:aws_id]
                            end
			    r[:tags] = t          
                            image_locs[i] = r
                            i = i+1
                         end   
                      end   
                   end
                end   
              end
             end
          end
          return image_locs
  end
  
  
  def error_message
     @error_message
  end 
  
  end 

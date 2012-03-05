
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'fileutils'
require 'rexml/document'

include Fox

class EC2_ImageDeleteDialog < FXDialogBox

  def initialize(owner,image)
    @ec2_main = owner
    sa = (image).split("/")
    sel_image = image 
    if sa.size>1
       sel_image = sa[1].rstrip
    end    
    @ec2 = @ec2_main.environment.connection
    @s3 = @ec2_main.environment.s3_connection
    @s3_bucket = nil
    @manifest_file = ""
    @file_folder = ""
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm","Confirm Delete and Deregister of Image "+sel_image)
    if answer == MBOX_CLICKED_YES
        manifest = find_manifest(sel_image)
        image_files = find_image_files(manifest)
        if @ec2 != nil
  	   begin
              @ec2.deregister_image(sel_image)
           rescue
             error_message("DeRegister of Image failed",$!.to_s)
             return
           end
           delete_image_files(image_files)
           @deleted = true
        else
      	   puts "***Error: No EC2 Connection"
        end
    end    
  end 
   
   def find_image_files(manifest)
      image_files = Array.new
      sa = manifest.split"/"
      bucket = sa[0]
      @manifest_file = ""
      @file_folder = ""
      i = 1
      while i < sa.size
         if @manifest_file == ""
            @manifest_file = sa[i]
         else
            @file_folder = @manifest_file
            @manifest_file = @manifest_file + "/" + sa[i]
         end
         i = i+1
      end
      if @s3 != nil
        begin
         @s3_bucket = RightAws::S3::Bucket.create(@s3, bucket)
         manifest_key = RightAws::S3::Key.create(@s3_bucket, @manifest_file)
         manifest_data = manifest_key.data
         doc = REXML::Document.new(manifest_data)
         i = 0
         REXML::XPath.each( doc, "//filename") do |element|
            if @file_folder != nil and @file_folder != ""
               image_files[i] = @file_folder + "/"+ element.text
            else
               image_files[i] = element.text
            end
            i = i+1
         end
        rescue
          error_message("Could not find Image files",$!.to_s)
        end
      else
         puts "***Error: No S3 Connection"
      end
      return image_files
   end   

   def delete_image_files(image_files)
     begin 
      i = 0
      while i < image_files.length
         image_key = RightAws::S3::Key.create(@s3_bucket, image_files[i])
         puts "delete #{image_files[i]}"
         image_key.delete
         i = i+1
      end
      puts "delete #{@manifest_file}"
      manifest_key = RightAws::S3::Key.create(@s3_bucket, @manifest_file)
      manifest_key.delete
     rescue
      error_message("Error Deleting Image files",$!.to_s)
     end 
   end
   
   def deleted 
      @deleted
   end 
   
   
   def find_manifest(image_id)
       @manifest_file = "" 
       if @ec2 != nil
          if image_id != nil and image_id != ""
            begin 
             @ec2.describe_images([image_id]).each do |r|
               @manifest_file = r[:aws_location]
             end
            rescue
             puts "**Error Image not found"
             error_message("Error","Delete Image: Image Id not found")
            end
          end   
       else
      	  puts "***Error: No EC2 Connection"
       end
       return @manifest_file 
   end
  
   def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
   end
    
end

require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'fileutils'
require 'rexml/document'

include Fox

class EC2_ImageEBSDeleteDialog < FXDialogBox

  def initialize(owner,image)
    @ec2_main = owner
    sa = (image).split("/")
    sel_image = image 
    if sa.size>1
       sel_image = sa[1].rstrip
    end        
    @ec2 = @ec2_main.environment.connection
    @s3_bucket = nil
    @manifest_file = ""
    @file_folder = ""
    snapshot_id = ""
    @deleted = false
    r = get_image(sel_image)
    if r[:root_device_name] != nil
       root_device = r[:root_device_name]
       snapshot_id = ""
       if r[:block_device_mappings] != nil 
	   r[:block_device_mappings].each do |m|
	      if m[:device_name] == root_device
	         snapshot_id = m[:ebs_snapshot_id]	
	      end
	   end   
       end
    end   
       answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm","Confirm Deregister of Image "+sel_image+" and Delete of Snapshot "+snapshot_id)
       if answer == MBOX_CLICKED_YES
        if @ec2 != nil
  	   begin
              @ec2.deregister_image(sel_image)
           rescue
             error_message("DeRegister of Image failed",$!.to_s)
             return
           end
           if snapshot_id != nil and snapshot_id != "" 
              delete_snapshot(snapshot_id)
           end   
           @deleted = true
        else
      	   puts "***Error: No EC2 Connection"
        end
       end    
  end 
   
  def get_image(image_id)
        r = {}
        ec2 = @ec2_main.environment.connection
        if ec2 != nil
  	   begin
              a = ec2.describe_images([image_id])
              r = a[0]
           rescue
             error_message("Image not found",$!.to_s)
           end
        else
      	   puts "***Error: No EC2 Connection"
        end  
        return r 
  end 
  
  def delete_snapshot(snapshot_id)
      ec2 = @ec2_main.environment.connection
      if ec2 != nil
  	 begin 
            ec2.delete_snapshot(snapshot_id)
         rescue
            error_message("EBS Snapshot Deletion failed",$!.to_s)
         end   
      end
  end     
   
   def deleted 
      @deleted
   end 
   
   def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
   end
    
end
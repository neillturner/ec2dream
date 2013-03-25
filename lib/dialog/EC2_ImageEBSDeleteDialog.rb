require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fileutils'
require 'rexml/document'
require 'common/error_message'

include Fox

class EC2_ImageEBSDeleteDialog < FXDialogBox

  def initialize(owner,image)
    @ec2_main = owner
    sa = (image).split("/")
    sel_image = image 
    if sa.size>1
       sel_image = sa[1].rstrip
    end        
    @s3_bucket = nil
    @manifest_file = ""
    @file_folder = ""
    snapshot_ids = []
    snapshots = ""
    @deleted = false
    r = get_image(sel_image)
    begin 
       if r['rootDeviceName'] != nil
          root_device = r['rootDeviceName']
           if r['blockDeviceMapping'] != nil 
	     r['blockDeviceMapping'].each do |m|
	        puts "snapshot #{m['snapshotId']}"
	        if m['snapshotId'] != nil and m['snapshotId'] != ""
                   snapshot_ids.push(m['snapshotId'])
                   if snapshots == nil or snapshots == ""
                      snapshots = m['snapshotId']
                   else
                      snapshots = "#{snapshots},#{m['snapshotId']}"
                   end   
                end 
	     end
	  end    
       end
    rescue
       puts "ERROR processing snapshots"
       return
    end 
    if  @ec2_main.settings.openstack
       answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm","Confirm Delete of Image #{sel_image}")
       if answer == MBOX_CLICKED_YES
          delete_image(sel_image)
       end
    else
       answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm","Confirm Deregister of Image #{sel_image} and Delete of Snapshot(s) #{snapshots}")
       if answer == MBOX_CLICKED_YES
          begin
             @ec2_main.environment.images.deregister_image(sel_image)
          rescue
             error_message("DeRegister of Image failed",$!)
             return
          end
          sleep 10
          snapshot_ids.each {|s| delete_snapshot(s) }
          @deleted = true
       end   
    end    
  end 
   
  def get_image(image_id)
        r = {}
  	   begin
              r = @ec2_main.environment.images.get(image_id)
           rescue
             error_message("Image not found",$!)
           end
        return r 
  end 
  
  def delete_image(image_id)
      if image_id != nil and image_id != "" 
            begin 
              @ec2_main.environment.images.delete_image(image_id)
              @deleted = true
           rescue
              error_message("Image Deletion failed","The Snapshot might still be registered as an image. #{$!}")
           end   
      end  
  end     
  
  def delete_snapshot(snapshot_id)
    if snapshot_id != nil and snapshot_id != "" 
          begin 
            @ec2_main.environment.snapshots.delete_snapshot(snapshot_id)
         rescue
            error_message("Snapshot Deletion failed",$!)
         end   
    end  
  end     
   
   def deleted 
      @deleted
   end 
 
   def success 
    @deleted
   end
   
end
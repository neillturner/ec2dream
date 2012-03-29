require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

require 'common/EC2_Images_get'

include Fox

class EC2_ImageDialog < FXDialogBox

  def initialize(owner)
       puts "ImageDialog.initialize"
       @ec2_main = owner
       @curr_img = ""
       image_type = "Owned By Me"
       image_platform = "All Platforms"
       image_root_device = ""
       super(owner, "Select Image", :opts => DECOR_ALL, :width => 800, :height => 450)
       page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
       frame1 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
       FXLabel.new(frame1, "Viewing:" )
       type = FXComboBox.new(frame1, 55,
  	      :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
       type.numVisible = 14
       type.appendItem("Owned By Me");
       type.appendItem("Amazon Images");
       type.appendItem("Public Images");
       type.appendItem("Private Images");
       type.appendItem("alfresco");
       type.appendItem("alestic");
       type.appendItem("bitnami");
       type.appendItem("Canonical");
       type.appendItem("Elastic-Server");
       type.appendItem("JumpBox");
       type.appendItem("RBuilder");
       type.appendItem("rightscale");
       type.appendItem("windows");       
       type.connect(SEL_COMMAND) do |sender, sel, data|
          image_type = data
	  sa = (image_type).split"("
	  if sa.size>1
	     @curr_img = sa[1].chomp(")")
	     self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
	  end          
       end
       platform = FXComboBox.new(frame1, 13,
  	      :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
       platform.numVisible = 3
       platform.appendItem("All Architectures");
       platform.appendItem("Small(i386)");
       platform.appendItem("Large(x86_64)");
       platform.connect(SEL_COMMAND) do |sender, sel, data|
          image_platform = data
       end
       root_device = FXComboBox.new(frame1, 12, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
       root_device.numVisible = 2
       root_device.appendItem("instance-store");
       root_device.appendItem("ebs");
       root_device.connect(SEL_COMMAND) do |sender, sel, data|
          image_root_device = data
       end       
       search = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
       frame1a = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
       FXLabel.new(frame1a, "   " )
       search_button = FXButton.new(frame1a, "   &Search   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
       search_button.connect(SEL_COMMAND) do |sender, sel, data|
          if image_type != "Owned By Me" and image_type != "Amazon Images" and image_type != "Public Images" and image_type != "Private Images" and image_type != "EBS Images"and image_type != "Instance-Store Images"
             search.text = ""
          end
          populate_images(image_type, image_platform, image_root_device, search.text)
       end
       FXLabel.new(frame1a, "   " )
       frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
       @imglist = FXList.new(frame2, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
       @imglist.setNumVisible(20)
       @imglist.connect(SEL_COMMAND) do |sender, sel, data|
         selected_item = ""
         @imglist.each do |item|
           selected_item = item.text if item.selected?
         end
         puts "item "+selected_item
         if selected_item != "***Loading***" and selected_item != "***No Images Found***"
            puts image_type 
            sa = (selected_item).split"("
	    if sa.size>1
	       @curr_img = sa[1].chomp(")")
	    else
	       @curr_img =""
	    end
            puts "image "+@curr_img
            self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end   
       end
       populate_images(image_type, image_platform, image_root_device, search.text)
  end
  
  
  def populate_images(type, platform, root, search)
  
       	 image_get = EC2_Images_get.new(@ec2_main)
       	 image_locs = image_get.get_images(type, platform, root, search, {})
    	 if image_locs.empty?
    	     image_error_message = image_get.error_message
    	     if image_error_message != nil and image_error_message != ""
    	         error_message("Error",image_error_message)    
    	      end
  	 end 
         @imglist.clearItems
         if image_locs != nil 
            image_locs.each do |r|
               @imglist.appendItem("#{r[:aws_location]}  (#{r[:aws_id]})")
            end
            if image_locs.size == 0
               status = @ec2_main.imageCache.status
               if status == "loading"
                  @imglist.appendItem("***Loading***")
               else   
                  @imglist.appendItem("***No Images Found***")
               end   
            end
         else
            status = @ec2_main.imageCache.status
            if status == "loading"
               @imglist.appendItem("***Loading***")
            else   
               @imglist.appendItem("***No Images Found***")
            end
         end
  end
  
 def selected
     sa = (@curr_img).split("/")
     sel_image = @curr_img 
     if sa.size>1
        sel_image = sa[1].rstrip
     end 
    return sel_image
  end  
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end


            


require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'


include Fox

class EC2_ImageAttributeDialog < FXDialogBox

  def initialize(owner, image)
        puts "ImageAttributeDialog.initialize"
        @ec2_main = owner
        sa = (image).split("/")
        image_id = image 
        if sa.size>1
	   image_id = sa[1].rstrip
        end
        super(owner, "Image Attributes", :opts => DECOR_ALL, :width => 600, :height => 550)
	page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)        
        frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
 	FXLabel.new(frame1, "Image Id" )
 	aws_id = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
	aws_id.text = image_id
	aws_id_button = FXButton.new(frame1, " ",:opts => BUTTON_TOOLBAR|LAYOUT_LEFT)
	aws_id_icon = @ec2_main.makeIcon("cloudmarket.png")
	aws_id_icon.create
	aws_id_button.icon = aws_id_icon
	aws_id_button.tipText = "  CloudMarket Info  "
	aws_id_button.connect(SEL_COMMAND) do |sender, sel, data|
           @ec2_main.environment.browser("http://thecloudmarket.com/image/#{aws_id.text}")
	end 	
 	FXLabel.new(frame1, "Location" )
 	aws_location = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
 
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Name" )
	ami_name = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
	
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Description" )
	description = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
	
 	FXLabel.new(frame1, "" )  	
 	FXLabel.new(frame1, "Owner" )
 	frame1a = FXHorizontalFrame.new(frame1, LAYOUT_FILL, :padding => 0)
 	aws_owner = FXTextField.new(frame1a, 21, nil, 0, :opts => TEXT_READONLY)
 	
 	FXLabel.new(frame1a, "Image Owner Alias" )
	image_owner_alias = FXTextField.new(frame1a, 21, nil, 0, :opts => TEXT_READONLY)
	
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Visibility" )
 	visibility = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
  
 	FXLabel.new(frame1, "" )  	
 	FXLabel.new(frame1, "Architecture" )
 	aws_architecture = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
 	
 	FXLabel.new(frame1, "" ) 	
 	FXLabel.new(frame1, "Image Type" )
 	aws_image_type = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
 	
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Kernel Id" )
 	frame1c = FXHorizontalFrame.new(frame1, LAYOUT_FILL, :padding => 0)
 	aws_kernel_id = FXTextField.new(frame1c, 24, nil, 0, :opts => TEXT_READONLY)
 	
 	FXLabel.new(frame1c, "RamDisk Id" )
 	aws_ramdisk_id = FXTextField.new(frame1c, 24, nil, 0, :opts => TEXT_READONLY)
 	
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "State" )
 	aws_state = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
 	
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Product Codes" )
 	aws_product_codes = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)

 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "launch Permission Groups" )
 	launch_permission_groups = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)

 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "launch Permission Users" )
 	launch_permission_users = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)

 	FXLabel.new(frame1, "" ) 	
 	FXLabel.new(frame1, "Platform" )
	platform = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
	
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Code" )
	code = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
	
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Message" )
	message = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
	
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Root Device Type" )
 	frame1e = FXHorizontalFrame.new(frame1, LAYOUT_FILL, :padding => 0)
 	root_device_type = FXTextField.new(frame1e, 21, nil, 0, :opts => TEXT_READONLY)
 	
 	FXLabel.new(frame1e, "Root Device Name" )
 	root_device_name = FXTextField.new(frame1e, 21, nil, 0, :opts => TEXT_READONLY)

 	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "Block Devices")
	block_devices = FXText.new(frame1, :height => 60, :opts => LAYOUT_FIX_HEIGHT|TEXT_WORDWRAP|LAYOUT_FILL|TEXT_READONLY, :padding => 0)

        frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
        return_button = FXButton.new(frame2, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
        return_button.connect(SEL_COMMAND) do |sender, sel, data|
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
        end
        r = get_image(image_id)
        a = get_image_launch_permissions(image_id)
 	if r != nil 
 	   description.text = r[:description]
 	   aws_owner.text = r[:aws_owner]
 	   aws_location.text = r[:aws_location]
 	   ami_name.text = r[:ami_name]
 	   image_owner_alias.text = r[:image_owner_alias]
  	   if r[:aws_is_public]
 	      visibility.text = "Public"
 	   else
 	      visibility.text = "Private"
 	   end 	   
 	   aws_architecture.text = r[:aws_architecture]   
 	   aws_image_type.text = r[:aws_image_type]   
 	   aws_kernel_id.text = r[:aws_kernel_id]   
 	   aws_ramdisk_id.text = r[:aws_ramdisk_id]   
 	   aws_state.text = r[:aws_state]  
 	   pc = r[:aws_product_codes]
 	   if pc != nil 
 	      pc.each do |p|
 	         if aws_product_codes.text == nil or aws_product_codes.text == ""
 	            aws_product_codes.text = p
 	         else   
 	            aws_product_codes.text = "#{aws_product_codes.text},#{p}"
 	         end
 	      end   
 	   end 	   
 	   platform.text = r[:platform]
 	   code.text = r[:state_reason_code].to_s
 	   message.text = r[:state_reason_message]
 	   root_device_type.text = r[:root_device_type]
 	   root_device_name.text = r[:root_device_name]
	   if r[:block_device_mappings] != nil 
	     r[:block_device_mappings].each do |m|
	      d = m[:ebs_delete_on_termination] ? 'true' : 'false'	
	      if block_devices.text==""
	         block_devices.text="#{m[:device_name]},#{m[:ebs_snapshot_id]},#{m[:ebs_volume_size]},#{d}\n"
	      else
	         block_devices.text="#{block_devices.text} #{m[:device_name]},#{m[:ebs_snapshot_id]},#{m[:ebs_volume_size]},#{d}\n"
	      end
	     end   
          end
       end  
 	if a != nil
 	   lp = a[:groups]
 	   if lp != nil 
 	      lp.each do |p|
 	         if launch_permission_groups.text == nil or launch_permission_groups.text == ""
 	            launch_permission_groups.text = p
 	         else   
 	            launch_permission_groups = "#{launch_permission_groups.text},#{p}"
 	         end   
 	      end
 	   end   
 	   lp = a[:users]
 	   if lp != nil 
 	      lp.each do |p|
 	         if launch_permission_users.text == nil or launch_permission_users.text == ""
 	            launch_permission_users.text = p
 	         else   
 	            launch_permission_users = "#{launch_permission_users.text},#{p}"
 	         end   
 	      end
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
             puts "Image not found"
             r = nil
           end
        else
      	   puts "***Error: No EC2 Connection"
        end  
        return r 
  end
  
  def get_image_launch_permissions(image_id)
        r = {}
        ec2 = @ec2_main.environment.connection
        if ec2 != nil
  	   begin
              r = ec2.describe_image_attribute(image_id)
           rescue
             puts "describe_image_attribute #{$!.to_s}"
             r = nil 
             #error_message("Image Attributes not found",$!.to_s)
           end
        else
      	   puts "***Error: No EC2 Connection"
        end  
        return r 
  end  
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
 
end
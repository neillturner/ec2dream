require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'dialog/EC2_TagsEditDialog'

include Fox

class EC2_ImageCreateDialog < FXDialogBox

  def initialize(owner, instance, img_name, tags=nil)
    puts "ImageCreateDialog.initialize"
    @ec2_main = owner
    @created = false
    @image_id = ""
    resource_tags = nil
    if tags != nil
       resource_tags=EC2_ResourceTags.new(@ec2_main, tags)
    end
    super(owner, "Create Image", :opts => DECOR_ALL, :width => 500, :height => 200)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Instance Id" )
    instance_id = FXTextField.new(frame1, 30, nil, 0, :opts => TEXTFIELD_READONLY)
    instance_id.text = instance
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Image Name" )
    image_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN)
    image_name.text = img_name
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Tags" )
    tags = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    @edit = @ec2_main.makeIcon("application_edit.png")
    @edit.create
    tags_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    tags_button.icon = @edit
    tags_button.tipText = "Edit Tags"
    tags_button.connect(SEL_COMMAND) do
       dialog = EC2_TagsEditDialog.new(@ec2_main, "EBS Volume", resource_tags)
       dialog.execute
       if dialog.saved
	  resource_tags = dialog.resource_tags
	  tags.text = resource_tags.show
       end   
    end
    FXLabel.new(frame1, "Description" )
    description = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "No Reboot" )
    no_reboot = FXComboBox.new(frame1, 15,:opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    no_reboot.numVisible = 2      
    no_reboot.appendItem("false")	
    no_reboot.appendItem("true")
    no_reboot.setCurrentItem(0)
    FXLabel.new(frame1, "" )    
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if image_name.text == nil or image_name.text == ""
         error_message("Error","Image Name not specified")
       else
         reboot_value = "false"
         if no_reboot.itemCurrent?(1)
            reboot_value = "true"
         end
         di=Thread.new do
            create_image(instance_id.text, image_name.text, description.text, reboot_value, resource_tags)
         end 
         self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end  
    end
  end 
  
  def create_image(instance_id, image_name, description, no_reboot, tags)
     ec2 = @ec2_main.environment.connection
     options = {}
     options[:name] = image_name
     options[:description] = description
     options[:no_reboot] = no_reboot
     if ec2 != nil
      begin 
       @image_id = ec2.create_image(instance_id, options)
       @created = true
      rescue
        puts("Create Image Failed #{$!.to_s}")
        return
      end
      begin 
         if tags != nil and tags != ""
            tags.assign(@image_id)
         end   
      rescue
         error_message("Create Tags Failed",$!.to_s)
         return
      end
     end
  end 
  
  def created
     @created
  end
  
  def image_id
     @image_id
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end

end

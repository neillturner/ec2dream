require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'dialog/EC2_TagsEditDialog'
require 'common/error_message'

include Fox

class EC2_ImageCreateDialog < FXDialogBox

  def initialize(owner, instance, img_name, tags=nil)
    puts "ImageCreateDialog.initialize"
    @ec2_main = owner
    @created = false
    @image_id = ""
    reboot_value = "false"
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
    if  !@ec2_main.settings.openstack
       FXLabel.new(frame1, "Tags" )
       tags = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
       @edit = @ec2_main.makeIcon("application_edit.png")
       @edit.create
       tags_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
       tags_button.icon = @edit
       tags_button.tipText = "Edit Tags"
       tags_button.connect(SEL_COMMAND) do
          dialog = EC2_TagsEditDialog.new(@ec2_main, "Volume", resource_tags)
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
     else   
        FXLabel.new(frame1, "Image Type" )
        image_type = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN)
        FXLabel.new(frame1, "" )
        FXLabel.new(frame1, "Image Version" )
        image_version = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN)
        FXLabel.new(frame1, "" )
    end
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if image_name.text == nil or image_name.text == ""
         error_message("Error","Image Name not specified")
       else
         reboot_value = "false"
         if  !@ec2_main.settings.openstack
            description_value = description.text 
            if no_reboot.itemCurrent?(1)
               reboot_value = "true"
            end
            di=Thread.new do
               create_image(instance_id.text, image_name.text, description.text, reboot_value, resource_tags)
            end             
         else 
           di=Thread.new do
	      create_image_ops(instance_id.text, image_name.text, image_type.text, image_version.text)
           end 
         end   
         self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end  
    end
  end 
  
  def create_image(instance_id, image_name, description, no_reboot, tags)
     options = {}
     options[:name] = image_name
     options[:description] = description
     options[:no_reboot] = no_reboot
      begin 
       @image_id = @ec2_main.environment.images.create_image(instance_id, options)
       @created = true
      rescue
         message = $!
          if message.class.to_s.start_with?("Excon::Errors::")
            message = message.response.body.to_s
         elsif message.class.to_s.end_with?("::ServiceError")
            message = message.response_data.to_s
         elsif message.class.to_s.end_with?("::BadRequest")
            message = message.response_data.to_s   
         end         
         puts("ERROR: Create Image Failed #{message}")
         return
      end
      if tags != nil and tags != ""
         begin 
            sleep 5
            tags.assign(@image_id)
         rescue
            error_message("Create Tags Failed",$!)
         end
      end
  end 
  
  def create_image_ops(instance_id, image_name, image_type, image_version)
     options = {}
     options[:name] = image_name
     options[:image_type] = image_type
     options[:image_version] = image_version
     begin 
        @image_id = @ec2_main.environment.images.create_image(instance_id, options)
        @created = true
     rescue
         message = $!
         #puts "*** error message class #{message.class}" 
         if message.class.to_s.start_with?("Excon::Errors::")
            message = message.response.body.to_s
         elsif message.class.to_s.end_with?("::ServiceError")
            message = message.response_data.to_s
         end         
         puts("Create Image Failed #{message}")
        return
     end
  end   
 
  def saved
     @created
  end
 
  def created
     @created
  end
  
  def success
     @created
  end
  
  def image_id
     @image_id
  end

end

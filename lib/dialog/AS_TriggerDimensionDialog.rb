
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class AS_TriggerDimensionDialog < FXDialogBox

  def initialize(owner, resource, dims={})
    puts "TiggerDimensionDialog.initialize"
    @ec2_main = owner
    @resource_id = resource 
    @saved = false
    @dimensions = nil
    @key = []
    @value = []
    super(owner, "Edit Trigger Dimensions", :opts => DECOR_ALL, :width => 450, :height => 250)
    frame1 = FXMatrix.new(self, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Dimension",:opts => LAYOUT_CENTER_X)
    FXLabel.new(frame1, "Value",:opts => LAYOUT_CENTER_X)
 
    @key[0] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    @value[0] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
   
    @key[1] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    @value[1] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[2] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    @value[2] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    
    @key[3] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    @value[3] = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
   
    @key[0].text="ImageId"
    @key[1].text="AutoScalingGroupName"
    @key[2].text="InstanceId"
    @key[3].text="InstanceType"

    i = 0
    puts dims
    if dims != nil
       dims.each_pair do |k,v|
         case k 
          when "ImageId" 
             @value[0].text = v
          when "AutoScalingGroupName" 
             @value[1].text = v
          when "InstanceId" 
             @value[2].text = v
          when "InstanceType" 
             @value[3].text = v
          end
       end
    end
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    save_button = FXButton.new(frame1, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    save_button.connect(SEL_COMMAND) do |sender, sel, data|
       save_dims
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    exit_button = FXButton.new(frame1, "   &Exit   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    exit_button.connect(SEL_COMMAND) do |sender, sel, data|
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end

  end 
  
  def save_dims
    @dimensions = {}
    for i in 0..3 do
      if @value[i].text != nil and @value[i].text != ""
        @dimensions["#{@key[i].text}"] = @value[i].text
      end
    end
    puts "save_dims #{@dimensions}"
    @saved = true
  end   
  
  def dimensions
     @dimensions
  end

  def saved
     @saved
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end

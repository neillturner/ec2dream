require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'
require 'dialog/CFY_SystemServiceDialog'

include Fox

class CFY_ServiceCreateDialog < FXDialogBox

  def initialize(owner)
    puts "CFY_ServiceCreateDialog.initialize"
    @ec2_main = owner
    @created = false
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create    
    super(owner, "Create Service", :opts => DECOR_ALL, :width => 400, :height => 100)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Name" )
    name = FXTextField.new(frame1, 35, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "System Service" )
    system_service = FXTextField.new(frame1, 35, nil, 0, :opts => FRAME_SUNKEN)
    system_service_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    system_service_button.icon = @magnifier
    system_service_button.tipText = "Select System Service"
    system_service_button.connect(SEL_COMMAND) do
      dialog = CFY_SystemServiceDialog.new(@ec2_main)
      dialog.execute
      selected = dialog.selected
      if selected != nil and selected != ""
        system_service.text = selected
      end   
    end 	
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
      if name.text == nil or name.text == ""
        error_message("Error","Name not specified")    
      elsif system_service.text == nil or system_service.text == ""
        error_message("Error","System Service not specified")
      else
        create_service(name.text, system_service.text)
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end  
    end
    cancel = FXButton.new(frame2, "   &Cancel   ", nil, self, ID_CANCEL, FRAME_RAISED|LAYOUT_CENTER_X|LAYOUT_SIDE_BOTTOM)
    cancel.connect(SEL_COMMAND) do |sender, sel, data|
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end  
  end 
  def create_service(name, system_service)
    begin
      r = @ec2_main.environment.cfy_service.create(name, system_service)
      @created = true
    rescue
      error_message("Create Service Failed",$!)
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

end

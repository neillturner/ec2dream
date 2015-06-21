
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'
require 'dialog/CFY_ServiceDialog'

include Fox

class CFY_ServiceEditDialog < FXDialogBox

  def initialize(owner,name,function="",parm="")
    puts "CFY_ServiceEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create    
    var_name=parm
    if function=="unbind"
      @title = "Unbind Service"
      @button = "Unbind"
    else
      @title = "Bind Service"
      @button = "Bind"
    end
    @saved = false
    super(owner, @title, :opts => DECOR_ALL, :width => 350, :height => 100)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "App Name" )
    @name = FXTextField.new(frame1, 30, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" ) 
    FXLabel.new(frame1, "Service" )
    @var_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @var_name_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @var_name_button.icon = @magnifier
    @var_name_button.tipText = "Select Service"
    @var_name_button.connect(SEL_COMMAND) do
      dialog = CFY_ServiceDialog.new(@ec2_main)
      dialog.execute
      selected = dialog.selected
      if selected != nil and selected != ""
        @var_name.text = selected
      end   
    end
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame1, "   &#{@button}   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
      var_name = @var_name.text
      if function=="unbind"
        begin
          r = @ec2_main.environment.cfy_app.unbind_service(name, var_name)
          @saved = true
        rescue
          error_message("Unbind Service Failed",$!)
        end      
      else
        begin
          r = @ec2_main.environment.cfy_app.bind_service(name, var_name)
          @saved = true
        rescue
          error_message("Bind Service Failed",$!)
        end      
      end   
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    @name.text = name
    @var_name.text = var_name
    if @title == "Unbind Service"
      @var_name.enabled = false
    end    
  end
  def saved
    @saved
  end
  def success
    @saved
  end
end

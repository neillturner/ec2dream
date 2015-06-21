
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class CFY_EnvEditDialog < FXDialogBox

  def initialize(owner,name,function="",parm="")
    puts "CFY_EnvEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    var_name=""
    var_value=""    
    sa = (parm).split('=')
    if sa.size>1
      var_name=sa[0]
      var_value=sa[1..-1].join('=') 
    end
    @button = "Set"    
    if function=="unset"
      @title = "UnSet Environment Variable"
      @button = "UnSet"
    elsif parm == nil or parm == "" 
      @title = "Set Environment Variable"
    else
      @title = "Modify Environment Variable"
    end
    @saved = false
    super(owner, @title, :opts => DECOR_ALL, :width => 400, :height => 175)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "App Name" )
    @name = FXTextField.new(frame1, 30, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" ) 
    FXLabel.new(frame1, "Environment Variable Name" )
    @var_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Environment Variable Value" )
    @var_value = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    restart_value = "true"
    FXLabel.new(frame1, "Restart" )
    @restart = FXComboBox.new(frame1, 20, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
    @restart.numVisible = 2
    @restart.appendItem("true")
    @restart.appendItem("false")
    @restart.connect(SEL_COMMAND) do |sender, sel, data|
      restart_value = data
    end	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame1, "   &#{@button}   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
      var_name = @var_name.text
      var_value = @var_value.text
      if function=="unset"
        begin
          r = @ec2_main.environment.cfy_app.unset_var(name, var_name, restart_value)
          @saved = true
        rescue
          error_message("UnSet Environment Variable Failed",$!)
        end      
      else
        begin
          r = @ec2_main.environment.cfy_app.set_var(name, var_name, var_value, restart_value)
          @saved = true
        rescue
          error_message("Set Environment Variable Failed",$!)
        end      
      end   
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    @name.text = name
    @var_name.text = var_name
    @var_value.text = var_value
    if @title == "UnSet Environment Variable"
      @var_name.enabled = false
      @var_value.enabled = false
    elsif @title == "Modify Environment Variable"
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

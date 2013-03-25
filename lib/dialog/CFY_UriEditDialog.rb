
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class CFY_UriEditDialog < FXDialogBox

  def initialize(owner,name,function="",parm="")
    puts "CFY_UriEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    var_name = parm.to_s
    if function=="unmap"
       @title = "Unmap URI"
       @button = "Unmap"
    else
       @title = "Map URI"
       @button = "Map"
    end
    @saved = false
    super(owner, @title, :opts => DECOR_ALL, :width => 350, :height => 100)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "App Name" )
    @name = FXTextField.new(frame1, 30, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" ) 
    FXLabel.new(frame1, "URI" )
    @var_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame1, "   &#{@button}   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
       var_name = @var_name.text
       if function=="unmap"
           begin
             r = @ec2_main.environment.cfy_app.unmap_url(name, var_name)
             @saved = true
          rescue
             error_message("Unmap URI Failed",$!)
          end      
       else
          begin
             r = @ec2_main.environment.cfy_app.map_url(name, var_name)
             @saved = true
          rescue
             error_message("Map URI Failed",$!)
          end      
       end   
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    @name.text = name
    @var_name.text = var_name if var_name != nil and var_name != ""
    if @title == "Unmap URI"
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

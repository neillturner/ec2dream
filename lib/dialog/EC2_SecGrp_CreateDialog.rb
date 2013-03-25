require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_SecGrp_CreateDialog < FXDialogBox

  def initialize(owner, type='linux')
    puts "SecGrpDialog.initialize"
    @ec2_main = owner
    @curr_env = ""
    @created = false
    @type = type
    @win = false
    @ec2_platform = @ec2_main.settings.get('EC2_PLATFORM')

    super(owner, "Create Security Group", :opts => DECOR_ALL, :width => 500, :height => 150)    
     
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Security Group Type" )
    
    frame2 = FXHorizontalFrame.new(frame1,LAYOUT_CENTER_X, :padding => 0)
         
    @radio1 = FXRadioButton.new(frame2, "Linux")
    @radio1.connect(SEL_COMMAND) {
       @type = "linux"
       @radio2.checkState = false
    }
 
    @radio2 = FXRadioButton.new(frame2, "Windows")
    @radio2.connect(SEL_COMMAND) {
       @type = "windows"
       @radio1.checkState = false
    }
       
    @radio1.checkState = true
    
    
    FXLabel.new(frame1, "" )
    
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" ) 

    FXLabel.new(frame1, "Security Group Name" )
    @sec_grp = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame1, "" )
    
    FXLabel.new(frame1, "Description" )
    @sec_desc = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame1, "" )
    
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )    
    create.connect(SEL_COMMAND) do |sender, sel, data|
       create_secgrp(@sec_grp.text, @type, @sec_desc.text)
       if @created == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end  
    end
  end 
  
  def create_secgrp(sg, type, desc)
     puts sg,type,desc
     if desc == nil or desc == ""
       desc = sg
     end  
     if sg == nil or sg == ""
        error_message("Error","Security Group not specified")
        return
     end
     if sg.include? "/"
        error_message("Error","Security Group cannot contain a /")
        return
     end
     @created = false
     puts "creating security group #{sg}"
     r = @ec2_main.environment.security_group.create(sg,desc)
     if r != nil 
       begin
        if type == "windows"
	   @ec2_main.environment.security_group.create_security_group_rule(r["id"], 'tcp', 3389, 3389,  '0.0.0.0/0', sg, sg)        
	 else
	   @ec2_main.environment.security_group.create_security_group_rule(r["id"], 'tcp', 22, 22,  '0.0.0.0/0', sg, sg)
        end
       rescue 
          error_message("Create Security Group failed",$!)
          return
       end
     end   
     if r != nil
        @created = true 
		@ec2_main.treeCache.refresh
     else
        error_message("Error","Security Group Creation failed")                
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
  
  def type 
      @type
  end 
  
  def sec_grp 
      @sec_grp.text
  end 

end

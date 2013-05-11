require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'
require 'dialog/EC2_VpcDialog'

include Fox

class EC2_SecGrp_CreateDialog < FXDialogBox

  def initialize(owner, type='linux')
    puts "SecGrp_CreateDialog.initialize"
    @ec2_main = owner
    @curr_env = ""
    @created = false
    @type = type
    @win = false
    @ec2_platform = @ec2_main.settings.get('EC2_PLATFORM')
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    
    super(owner, "Create Security Group", :opts => DECOR_ALL, :width => 500, :height => 175) 
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
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
    @sec_grp = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    
    FXLabel.new(frame1, "Description" )
    @sec_desc = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    
    FXLabel.new(frame1, "VPC Id" )
    frame1a = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    @vpc_id = FXTextField.new(frame1a, 30, nil, 0, :opts => FRAME_SUNKEN)
    @vpc_id_button = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR)
    @vpc_id_button.icon = @magnifier
    @vpc_id_button.tipText = "  Select VPC Id  "
    @vpc_id_button.connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = EC2_VpcDialog.new(owner)
	   dialog.execute
	   if dialog.selected != nil and dialog.selected != ""
	      @vpc_id.text = dialog.selected
	   end	
    end	
    @vpc_id_button.connect(SEL_UPDATE) do |sender, sel, data|
	sender.enabled = true
    end	
    FXLabel.new(frame1, "" )
    
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       create_secgrp(@sec_grp.text, @type, @sec_desc.text, @vpc_id.text)
       if @created == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end  
    end
  end 
  
  def create_secgrp(sg, type, desc, vpc_id)
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
     vpc_id = nil if vpc_id != nil and vpc_id == ""
     vpc_id = nil if !@ec2_main.settings.amazon
     r = @ec2_main.environment.security_group.create(sg,desc,vpc_id)
      if r != nil 
       begin
        if type == "windows"
           if r['groupId'] != nil 
              @ec2_main.environment.security_group.create_security_group_rule( r['groupId'], 'tcp', 3389, 3389,  '0.0.0.0/0', r['groupId'], sg)
           else 
	      @ec2_main.environment.security_group.create_security_group_rule(r["id"], 'tcp', 3389, 3389,  '0.0.0.0/0', nil, sg)
	   end
	 else
	   if r['groupId'] != nil
	      @ec2_main.environment.security_group.create_security_group_rule(sg, 'tcp', 22, 22,  '0.0.0.0/0', r['groupId'], sg)
	   else
	      @ec2_main.environment.security_group.create_security_group_rule(r["id"], 'tcp', 22, 22,  '0.0.0.0/0', nil, sg)
	   end   
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
  
  def vpc 
      @vpc_id.text
  end 

end

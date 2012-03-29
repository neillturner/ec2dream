
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_SecGrpDialog < FXDialogBox

  def initialize(owner, type='linux')
    puts "SecGrpDialog.initialize"
    @ec2_main = owner
    @curr_env = ""
    @created = false
    @type = type
    @win = false
    @rds_url = @ec2_main.settings.get('RDS_URL') 
    @ec2_platform = @ec2_main.settings.get('EC2_PLATFORM')

    super(owner, "Create Security Group", :opts => DECOR_ALL, :width => 500, :height => 150)    
     
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Security Group Type" )
    
    frame2 = FXHorizontalFrame.new(frame1,LAYOUT_CENTER_X, :padding => 0)
         
    @radio1 = FXRadioButton.new(frame2, "Linux")
    @radio1.connect(SEL_COMMAND) {
       @type = "linux"
       @radio2.checkState = false
       if @rds_url != nil and @rds_url != ""
          @radio3.checkState = false
       end   }
 
    @radio2 = FXRadioButton.new(frame2, "Windows")
    @radio2.connect(SEL_COMMAND) {
       @type = "windows"
       @radio1.checkState = false
       if @rds_url != nil and @rds_url != ""
          @radio3.checkState = false
       end }
       
    if @rds_url != nil and @rds_url != ""
       @radio3 = FXRadioButton.new(frame2, "Database")
       @radio3.connect(SEL_COMMAND) { 
          @type = "database"
          @radio1.checkState = false
          @radio2.checkState = false }
    end
    if @type == "database"
       @radio3.checkState = true
    else
       @radio1.checkState = true
    end   
    
    
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
       if @type != "database"
          create_secgrp(@sec_grp.text, @type, @sec_desc.text)
       else
          create_db_secgrp(@sec_grp.text, @sec_desc.text)
       end
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
        error_message(@ec2_main,"Error","Security Group not specified")
        return
     end
     if sg.include? "/"
        error_message(@ec2_main,"Error","Security Group cannot contain a /")
        return
     end
     @created = false
     ec2 = @ec2_main.environment.connection
     if ec2 != nil
      if @ec2_main.settings.get("EC2_PLATFORM") != "openstack" 
         begin 
            r = ec2.create_security_group(sg,desc)
            puts "return from create sec group "
            puts r
            if r[:return]
            # give it time for security group to be created
               puts "return from create sec group is true"
              #g_id = r[:group_id]
              if type == "windows"
                 ec2.authorize_security_group_IP_ingress(sg, 3389, 3389, 'tcp', '0.0.0.0/0')        
              else
                 ec2.authorize_security_group_IP_ingress(sg, 22, 22, 'tcp', '0.0.0.0/0')
              end  
              @created = true
            else
               error_message(@ec2_main,"Error","Security Group Creation failed")
            end
         rescue
              error_message(@ec2_main,"Security Group already exists or permission changes failed",$!.to_s)
         end 
      else
        puts "creating security group #{sg}"
        response = @ec2_main.serverCache.ops_secgrp.create(sg,desc)
        puts "created security group response #{response}"
        if response
           @created = true   
        else
           error_message(@ec2_main,"Error","Security Group Creation failed")                
        end
      end  
     end 
  end
  
  def create_db_secgrp(sg, desc)
       @created = false
       r = nil
       rds = @ec2_main.environment.rds_connection
       if rds != nil
        begin
         r = rds.create_db_security_group(sg,desc)
         #if r != true
         #  error_message(@ec2_main,"Error","DB Security Group Creation failed")
         #else   
           @created = true
         #end  
        rescue
         error_message(@ec2_main,"Security Group Creation failed",$!.to_s)
        end 
       end
  end 
  
  def created
      return @created
  end
  
  def type 
      return @type
  end 
  
  def sec_grp 
        return  @sec_grp.text
  end 
  
  def error_message(owner,title,message)
           FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
 
end

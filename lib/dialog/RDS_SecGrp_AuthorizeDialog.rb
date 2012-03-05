
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_SecGrp_AuthorizeDialog < FXDialogBox

  def initialize(owner, current_group)
    puts "RDSSecGrp_AuthorizeDialog.initialize"
    @ec2_main = owner
    @current_group = current_group
    sg_group = ""
    sg = Array.new
    @created = false
    super(owner, "DBSecurity Group Authorization", :opts => DECOR_ALL, :width => 275, :height => 225)
    mainFrame = FXVerticalFrame.new(self,LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
    frame1 = FXMatrix.new(mainFrame, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
      
    FXLabel.new(frame1, "IP Address" )
    ip_address = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1,"")
    ip_address.text="0.0.0.0/0"
    
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    
    FXHorizontalSeparator.new(frame1, LAYOUT_FILL_X|SEPARATOR_GROOVE|LAYOUT_SIDE_BOTTOM)
    FXHorizontalSeparator.new(frame1, LAYOUT_FILL_X|SEPARATOR_GROOVE|LAYOUT_SIDE_BOTTOM)
    FXLabel.new(frame1,"")
    
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    
    FXLabel.new(frame1, "Group" )
    group = FXComboBox.new(frame1, 20, :opts => COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
    
    r = @ec2_main.serverCache.securityGrps()
    i=0
    while i<r.length
       puts r[i]
       sg[i] = r[i]
       i = i+1
    end
    i=0
    group.appendItem("No Group");
    while i<sg.length
       group.appendItem(sg[i]);
       i = i+1
    end 
    group.numVisible = 9
    group.connect(SEL_COMMAND) do |sender, sel, data|
       sg_group = data
    end	
    FXLabel.new(frame1,"")
    
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    
    FXHorizontalSeparator.new(frame1, LAYOUT_FILL_X|SEPARATOR_GROOVE|LAYOUT_SIDE_BOTTOM)
    FXHorizontalSeparator.new(frame1, LAYOUT_FILL_X|SEPARATOR_GROOVE|LAYOUT_SIDE_BOTTOM)
    FXLabel.new(frame1,"")
    
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    
    FXLabel.new(frame1, "Group Owner Id" )
    group_owner_id = FXTextField.new(frame1, 20, nil, 0, :opts => TEXTFIELD_INTEGER|LAYOUT_RIGHT)
    FXLabel.new(frame1,"")
    id = @ec2_main.settings.get('AMAZON_ACCOUNT_ID')
    if id != nil and id != ""
       group_owner_id.text = id
    end

    FXLabel.new(frame1, "Group" )
    group_spec_name = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1,"")
     
    bottomFrame = FXVerticalFrame.new(mainFrame,LAYOUT_SIDE_BOTTOM|LAYOUT_FILL)
    FXLabel.new(bottomFrame, "" )    
    create = FXButton.new(bottomFrame, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(bottomFrame, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
      if sg_group == nil or  sg_group == "" or sg_group == "No Group"
         if group_spec_name.text == nil or  group_spec_name.text == "" 
            if ip_address.text == nil or ip_address.text == ""
	       error_message("Error","IP Address not specified")
	    else
	       auth_ip(ip_address)
            end
         else 
           auth(group_owner_id.text,group_spec_name.text) 
         end  
      else
         auth(id, sg_group)
      end
      if @created == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end 
  end 
  
  def auth_ip(ip_address)
     puts "auth ip #{ip_address}"
     rds = @ec2_main.environment.rds_connection
     if rds != nil
	params = {}
      params[:cidrip] = ip_address
      begin
         r = rds.authorize_db_security_group_ingress(@current_group, params)
         @created = true
      rescue
        error_message("Invalid IP Address",$!.to_s)
      end 
     end
  end
  
  def auth(owner_id, group)
       puts "auth #{owner_id} #{group}"
       rds = @ec2_main.environment.rds_connection
       if rds != nil
        params = {}
        params[:ec2_security_group_name] = group
        params[:ec2_security_group_owner] = owner_id
        begin
         r = rds.authorize_db_security_group_ingress(@current_group, params)
         @created = true
        rescue
          error_message("Security Group Authorization failed",$!.to_s)
        end 
       end
  end
  
  def created
      @created
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
 
end

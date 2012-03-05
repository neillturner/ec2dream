
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_SecGrp_AuthorizeDialog < FXDialogBox

  def initialize(owner, current_group)
    puts "SecGrp_AuthorizeDialog.initialize"
    @ec2_main = owner
    @current_group = current_group
    sg_protocol = "tcp"
    sg_group = ""
    sg = Array.new    
    @created = false
    super(owner, "Security Group Authorization", :opts => DECOR_ALL, :width => 250, :height => 200)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Protocol" )
    protocol = FXComboBox.new(frame1, 5, :opts => COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
    protocol.numVisible = 3
    protocol.appendItem("tcp");
    protocol.appendItem("udp");
    protocol.appendItem("icmp");
    protocol.connect(SEL_COMMAND) do |sender, sel, data|
       sg_protocol = data
    end
    FXLabel.new(frame1,"")
    
    FXLabel.new(frame1, "From Port" )
    from_port = FXTextField.new(frame1, 20, nil, 0, :opts => TEXTFIELD_INTEGER|LAYOUT_RIGHT)
    FXLabel.new(frame1,"")
    
    FXLabel.new(frame1, "To Port" )
    to_port = FXTextField.new(frame1, 20, nil, 0, :opts => TEXTFIELD_INTEGER|LAYOUT_RIGHT)
    FXLabel.new(frame1,"")
    
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
    ec2 = @ec2_main.environment.connection
    if ec2 != nil
       r = ec2.describe_security_groups()
       i=0
       while i<r.length
          x = r[i]
          sg[i] = x[:aws_group_name]
          i = i+1
       end
       sg = sg.sort
       i=0
       group.appendItem("No Group");
       while i<sg.length
          group.appendItem(sg[i]);
          i = i+1
       end 
    end
    group.numVisible = 9
    group.connect(SEL_COMMAND) do |sender, sel, data|
       sg_group = data
    end	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
      if sg_group == nil or  sg_group == "" or sg_group == "No Group" 
         if from_port.text == nil or from_port.text == ""
	    error_message("Error","From Port Not specified")
	 else
	    p = (from_port.text).to_i
	    if p <1 or p >= 65535
	       error_message("Error","Ports must be between 1 and 65535") 	
            else
               p = (to_port.text).to_i
	       if p <1 or p >= 65535
	          error_message("Error","Ports must be between 1 and 65535") 	
               else
	          if to_port.text == nil or to_port.text == ""
	             error_message("Error","To Port Not specified")
	          else
	             if ip_address.text == nil or ip_address.text == ""
	    	        error_message("Error","IP Address Not specified")
	             else
	                auth_ip(protocol, from_port, to_port, ip_address)
	             end   
	          end   
               end
            end
         end
      else
         auth(sg_group)
      end
      if @created == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end 
  end 
  
  def auth_ip(protocol, from_port, to_port, ip_address)
     @created = false
     ec2 = @ec2_main.environment.connection
     if ec2 != nil
      begin
       r = ec2.authorize_security_group_IP_ingress(@current_group, from_port, to_port, protocol, ip_address)
       @created = true
      rescue
        error_message("Invalid IP Address",$!.to_s)
      end 
     end
  end
  
  def auth(group)
       @created = false
       ec2 = @ec2_main.environment.connection
       if ec2 != nil
        id = @ec2_main.settings.get('AMAZON_ACCOUNT_ID')
        begin
         r = ec2.authorize_security_group_named_ingress(@current_group, id ,group)
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

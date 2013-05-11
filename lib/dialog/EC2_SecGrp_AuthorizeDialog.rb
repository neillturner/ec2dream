
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_SecGrp_AuthorizeDialog < FXDialogBox

  def initialize(owner, current_group, vpc=nil )
    puts "SecGrp_AuthorizeDialog.initialize"
    @ec2_main = owner
    @current_group = current_group
    @current_group_id = 0
    sg_protocol = "tcp"
    sg_group = ""
    sg = Array.new 
    sg_id = {}
    @created = false
    @filter = nil 
    @filter = {'vpc-id' => vpc} if vpc != nil and vpc != ""
    super(owner, "Security Group Authorization", :opts => DECOR_ALL, :width => 250, :height => 250)
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
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXHorizontalSeparator.new(frame1, LAYOUT_FILL_X|SEPARATOR_GROOVE|LAYOUT_SIDE_BOTTOM)
    FXHorizontalSeparator.new(frame1, LAYOUT_FILL_X|SEPARATOR_GROOVE|LAYOUT_SIDE_BOTTOM)
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
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
       i=0
       @ec2_main.environment.security_group.all(@filter).each do |x|
          if vpc == x[:vpc_id] or !@ec2_main.settings.amazon
             sg[i] = x[:aws_group_name]
             sg_id[x[:aws_group_name]] = x[:group_id]
             if x[:aws_group_name] == current_group
                @current_group_id = x[:group_id]
              end
             i = i+1
          end   
       end
       sg = sg.sort
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
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
      #
         if (from_port.text == nil or from_port.text == "") and (@ec2_main.settings.openstack or @ec2_main.settings.eucalyptus or @ec2_main.settings.cloudstack)
            auth(sg_group,sg_id[sg_group])
         elsif from_port.text == nil or from_port.text == ""      
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
	             if sg_group == nil or  sg_group == "" or sg_group == "No Group" 
	                if ip_address.text == nil or ip_address.text == ""
	    	           error_message("Error","IP Address Not specified")
	                else
	                   auth_ip(protocol.text, from_port.text, to_port.text, ip_address.text, nil, nil)
	                end
	             else 
	                auth_ip(protocol.text, from_port.text, to_port.text, "", sg_group, sg_id[sg_group] )
	             end
	          end   
               end
            end
         end
      #else
      #   auth(sg_group,sg_id[sg_group])
      #end
      if @created == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end 
  end 
  
  def auth_ip(protocol, from_port, to_port, ip_address, group_auth, group_auth_id)
     @created = false
     begin
        @ec2_main.environment.security_group.create_security_group_rule(@current_group, protocol, from_port, to_port, ip_address, @current_group_id, @current_group, group_auth, group_auth_id)     
        @created = true
     rescue
        error_message("Invalid IP Address or Group not found",$!)
     end        
  end
  
  def auth(group,group_id)
       @created = false
        id = @ec2_main.settings.get('AMAZON_ACCOUNT_ID')
        begin
         r = @ec2_main.environment.security_group.authorize_security_group_named_ingress(@current_group, id ,group, @current_group_id, group_id)
         @created = true
        rescue
          error_message("Security Group Authorization failed",$!)
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

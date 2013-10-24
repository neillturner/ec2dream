require 'rubygems'
require 'fox16'
require 'common/EC2_Properties'
require 'common/error_message'

include Fox

class LOC_EditDialog < FXDialogBox

  def initialize(owner, curr_item)
    puts " LOC_EditDialog.initialize"
    @saved = false
    @ec2_main = owner
    super(@ec2_main, "Edit Local Server", :opts => DECOR_ALL, :width => 450, :height => 560)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Server" )
    server = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Address" )
    address = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Address Port" )
    address_port = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "(Default 22)" )    

    FXLabel.new(frame1, "SSH User" )
    ssh_user = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "SSH Password" )
    ssh_password = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "SSH key" )
    ssh_key = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    ssh_key_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    ssh_key_button.icon = @magnifier
    ssh_key_button.tipText = "Browse..."
    ssh_key_button.connect(SEL_COMMAND) do
       dialog = FXFileDialog.new(frame1, "Select pem file")
       dialog.patternList = [
          "Pem Files (*.pem)"
       ]
       dialog.selectMode = SELECTFILE_EXISTING
       if dialog.execute != 0
          ssh_key.text = dialog.filename
       end
    end
    FXLabel.new(frame1, "Putty Key" )
    putty_key = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    putty_key_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    putty_key_button.icon = @magnifier
    putty_key_button.tipText = "Browse..."
    putty_key_button.connect(SEL_COMMAND) do
       dialog = FXFileDialog.new(frame1, "Select pem file")
       dialog.patternList = [
          "Pem Files (*.ppk)"
       ]
       dialog.selectMode = SELECTFILE_EXISTING
       if dialog.execute != 0
          putty_key.text = dialog.filename
       end
    end
    FXLabel.new(frame1, "Chef Node" )
    chef_node = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Puppet Manifest" )
    puppet_manifest = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Puppet Roles" )
    puppet_roles = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )		
    FXLabel.new(frame1, "Windows Server" )
    windows_server = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    windows_server.numVisible = 2      
    windows_server.appendItem("true")	
    windows_server.appendItem("false")
    windows_server.setCurrentItem(1)    
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Tunnelling - Bastion Host" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Local Port" )
    local_port = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Bastion Host" )
    bastion_host = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Bastion Port" )
    bastion_port = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Bastion User" )
    bastion_user = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )  
    FXLabel.new(frame1, "Bastion Passwoird" )
    bastion_password = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" ) 	
    FXLabel.new(frame1, "Bastion SSH key" )
    bastion_ssh_key = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    bastion_ssh_key_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    bastion_ssh_key_button.icon = @magnifier
    bastion_ssh_key_button.tipText = "Browse..."
    bastion_ssh_key_button.connect(SEL_COMMAND) do
       dialog = FXFileDialog.new(frame1, "Select pem file")
       dialog.patternList = [
          "Pem Files (*.pem)"
       ]
       dialog.selectMode = SELECTFILE_EXISTING
       if dialog.execute != 0
          bastion_ssh_key.text = dialog.filename
       end
    end
    FXLabel.new(frame1, "Bastion Putty Key" )
    bastion_putty_key = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    bastion_putty_key_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    bastion_putty_key_button.icon = @magnifier
    bastion_putty_key_button.tipText = "Browse..."
    bastion_putty_key_button.connect(SEL_COMMAND) do
       dialog = FXFileDialog.new(frame1, "Select pem file")
       dialog.patternList = [
          "Pem Files (*.ppk)"
       ]
       dialog.selectMode = SELECTFILE_EXISTING
       if dialog.execute != 0
          bastion_putty_key.text = dialog.filename
       end
    end    
    #FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if server.text == nil or server.text == ""
         error_message("Error","Server not specified")
       else
         windows_server_value = "false"
         if windows_server.itemCurrent?(0)
	    windows_server_value = true
         end
         save_local_server(server.text,address.text,address_port.text,chef_node.text,puppet_manifest.text,puppet_roles.text,ssh_user.text,ssh_password.text,ssh_key.text,putty_key.text,local_port.text,bastion_host.text,bastion_port.text,bastion_user.text,bastion_password.text,bastion_ssh_key.text,bastion_putty_key.text,windows_server_value)
         if @saved == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end
       end  
    end
    r = get_local_server(curr_item)
    if r['server'] != nil and r['server'] != ""
       server.text = r['server']
       address.text = r['address']
       address_port.text = r['address_port']
       chef_node.text = r['chef_node']
       puppet_manifest.text = r['puppet_manifest']
	   puppet_roles.text = r['puppet_roles']
       ssh_user.text = r['ssh_user']
       ssh_password.text = r['ssh_password']
       ssh_key.text = r['ssh_key']
       putty_key.text = r['putty_key']
       local_port.text = r['local_port']
       bastion_host.text = r['bastion_host']
       bastion_port.text = r['bastion_port']
       bastion_user.text = r['bastion_user']
	   bastion_password.text = r['bastion_password']
       bastion_ssh_key.text = r['bastion_ssh_key']
       bastion_putty_key.text = r['bastion_putty_key']
       windows_server.setCurrentItem(1)
       if r['windows_server'] == 'true'
          windows_server.setCurrentItem(0)
       end
    end
  end 
  
  def get_local_server(server)
       folder = "loc_server"
       properties = {}
       loc = EC2_Properties.new
       if loc != nil
          properties = loc.get(folder, server)
       end
       return properties
  end 

  def save_local_server(server,address,address_port,chef_node,puppet_manifest,puppet_roles,ssh_user,ssh_password,ssh_key,putty_key,local_port,bastion_host, bastion_port,bastion_user,bastion_password,bastion_ssh_key,bastion_putty_key,windows_server)  
     folder = "loc_server"
     loc = EC2_Properties.new
     if loc != nil
      begin 
        properties = {}
        properties['server']=server
        properties['address']=address
        properties['address_port']=address_port
        properties['chef_node']=chef_node
        properties['puppet_manifest']=puppet_manifest
		properties['puppet_roles']=puppet_roles
        properties['windows_server']=windows_server
        properties['ssh_user']=ssh_user
        properties['ssh_password']=ssh_password
        properties['ssh_key']=ssh_key
        properties['putty_key']=putty_key
        properties['local_port']=local_port
        properties['bastion_host']=bastion_host
        properties['bastion_port']=bastion_port
        properties['bastion_user']=bastion_user
		properties['bastion_password']=bastion_password
        properties['bastion_ssh_key']=bastion_ssh_key
        properties['bastion_putty_key']=bastion_putty_key
        
        @saved = loc.save(folder, server, properties)
        if @saved == false
           error_message("Update Local Server Failed","Update Local Server Failed")
           return
        end   
      rescue
        error_message("Update Local Server",$!)
        return
      end
     end
  end 

  def saved
    @saved
  end

  def success
     @saved
  end
  
end

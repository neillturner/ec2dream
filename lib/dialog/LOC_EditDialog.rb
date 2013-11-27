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
	@magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
	@loc_server = {}
    super(@ec2_main, "Edit Local Server", :opts => DECOR_ALL, :width => 550, :height => 660)
    @frame5 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(@frame5, "Server" )
    @loc_server['server'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "Address" )
    @loc_server['address'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "Address Port" )
    @loc_server['address_port'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "(Default 22)" )    
    FXLabel.new(@frame5, "SSH User" )
    @loc_server['ssh_user'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "SSH Password" )
    @loc_server['ssh_password'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "SSH key" )
    @loc_server['ssh_key'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @loc_server['ssh_key_button'] = FXButton.new(@frame5, "", :opts => BUTTON_TOOLBAR)
    @loc_server['ssh_key_button'].icon = @magnifier
    @loc_server['ssh_key_button'].tipText = "Browse..."
    @loc_server['ssh_key_button'].connect(SEL_COMMAND) do
       dialog = FXFileDialog.new(@frame5, "Select pem file")
       dialog.patternList = [
          "Pem Files (*.pem)"
       ]
       dialog.selectMode = SELECTFILE_EXISTING
       if dialog.execute != 0
          @loc_server['ssh_key'].text = dialog.filename
       end
    end
    FXLabel.new(@frame5, "Putty Key" )
    @loc_server['putty_key'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @loc_server['putty_key_button'] = FXButton.new(@frame5, "", :opts => BUTTON_TOOLBAR)
    @loc_server['putty_key_button'].icon = @magnifier
    @loc_server['putty_key_button'].tipText = "Browse..."
    @loc_server['putty_key_button'].connect(SEL_COMMAND) do
       dialog = FXFileDialog.new(@frame5, "Select pem file")
       dialog.patternList = [
          "Pem Files (*.ppk)"
       ]
       dialog.selectMode = SELECTFILE_EXISTING
       if dialog.execute != 0
          @loc_server['putty_key'].text = dialog.filename
       end
    end
    FXLabel.new(@frame5, "Chef Node" )
    @loc_server['chef_node'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "Puppet Manifest" )
    @loc_server['puppet_manifest'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "Puppet Roles" )
    @loc_server['puppet_roles'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )		
    FXLabel.new(@frame5, "Windows Server" )
    @loc_server['windows_server'] = FXComboBox.new(@frame5, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    @loc_server['windows_server'].numVisible = 2      
    @loc_server['windows_server'].appendItem("true")	
    @loc_server['windows_server'].appendItem("false")
    @loc_server['windows_server'].setCurrentItem(1)    
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )    
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "Tunnelling - Bastion Host" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "Local Port" )
    @loc_server['local_port'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "Bastion Host" )
    @loc_server['bastion_host'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "Bastion Port" )
    @loc_server['bastion_port'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "Bastion User" )
    @loc_server['bastion_user'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" )  
    FXLabel.new(@frame5, "Bastion Passwoird" )
    @loc_server['bastion_password'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(@frame5, "" ) 	
    FXLabel.new(@frame5, "Bastion SSH key" )
    @loc_server['bastion_ssh_key'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @loc_server['bastion_ssh_key_button'] = FXButton.new(@frame5, "", :opts => BUTTON_TOOLBAR)
    @loc_server['bastion_ssh_key_button'].icon = @magnifier
    @loc_server['bastion_ssh_key_button'].tipText = "Browse..."
    @loc_server['bastion_ssh_key_button'].connect(SEL_COMMAND) do
       dialog = FXFileDialog.new(@frame5, "Select pem file")
       dialog.patternList = [
          "Pem Files (*.pem)"
       ]
       dialog.selectMode = SELECTFILE_EXISTING
       if dialog.execute != 0
          @loc_server['bastion_ssh_key'].text = dialog.filename
       end
    end
    FXLabel.new(@frame5, "Bastion Putty Key" )
    @loc_server['bastion_putty_key'] = FXTextField.new(@frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @loc_server['bastion_putty_key_button'] = FXButton.new(@frame5, "", :opts => BUTTON_TOOLBAR)
    @loc_server['bastion_putty_key_button'].icon = @magnifier
    @loc_server['bastion_putty_key_button'].tipText = "Browse..."
    @loc_server['bastion_putty_key_button'].connect(SEL_COMMAND) do
       dialog = FXFileDialog.new(@frame5, "Select pem file")
       dialog.patternList = [
          "Pem Files (*.ppk)"
       ]
       dialog.selectMode = SELECTFILE_EXISTING
       if dialog.execute != 0
          @loc_server['bastion_putty_key'].text = dialog.filename
       end
    end    
    #FXLabel.new(@frame5, "" )    
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    FXLabel.new(@frame5, "" )
    create = FXButton.new(@frame5, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(@frame5, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if server.text == nil or server.text == ""
         error_message("Error","Server not specified")
       else
         save_local_server()
         if @saved == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end
       end  
    end
    r = get_local_server(curr_item)
    if r['server'] != nil and r['server'] != ""
       @loc_server['server'].text = r['server']
       @loc_server['address'].text = r['address']
       @loc_server['address_port'].text = r['address_port']
       @loc_server['chef_node'].text = r['chef_node']
       @loc_server['puppet_manifest'].text = r['puppet_manifest']
	   @loc_server['puppet_roles'].text = r['puppet_roles']
       @loc_server['ssh_user'].text = r['ssh_user']
       @loc_server['ssh_password'].text = r['ssh_password']
       @loc_server['ssh_key'].text = r['ssh_key']
       @loc_server['putty_key'].text = r['putty_key']
       @loc_server['local_port'].text = r['local_port']
       @loc_server['bastion_host'].text = r['bastion_host']
       @loc_server['bastion_port'].text = r['bastion_port']
       @loc_server['bastion_user'].text = r['bastion_user']
	   @loc_server['bastion_password'].text = r['bastion_password']
       @loc_server['bastion_ssh_key'].text = r['bastion_ssh_key']
       @loc_server['bastion_putty_key'].text = r['bastion_putty_key']
       @loc_server['windows_server'].setCurrentItem(1)
       if r['windows_server'] == 'true'
          @loc_server['windows_server'].setCurrentItem(0)
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

  def save_local_server  
     folder = "loc_server"
     loc = EC2_Properties.new
     if loc != nil
      begin 
        properties = {}
        properties['server']=@loc_server['server']
        properties['address']=@loc_server['address']
        properties['address_port']=@loc_server['address_port']
        properties['chef_node']=@loc_server['chef_node']
        properties['puppet_manifest']=@loc_server['puppet_manifest']
		properties['puppet_roles']=@loc_server['puppet_roles']
		windows_server_value = "false"
        if @loc_server['windows_server'].itemCurrent?(0)
	       windows_server_value = true
        end
        properties['windows_server']=windows_server_value
        properties['ssh_user']=@loc_server['ssh_user']
        properties['ssh_password']=@loc_server['ssh_password']
        properties['ssh_key']=@loc_server['ssh_key']
        properties['putty_key']=@loc_server['putty_key']
        properties['local_port']=@loc_server['local_port']
        properties['bastion_host']=@loc_server['bastion_host']
        properties['bastion_port']=@loc_server['bastion_port']
        properties['bastion_user']=@loc_server['bastion_user']
		properties['bastion_password']=@loc_server['bastion_password']
        properties['bastion_ssh_key']=@loc_server['bastion_ssh_key']
        properties['bastion_putty_key']=@loc_server['bastion_putty_key']
        
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

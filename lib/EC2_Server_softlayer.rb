class EC2_Server

  #
  #  softlayer methods
  #

  def softlayer_clear_panel
    @type = ""
    softlayer_clear('Instance_ID')
    ENV['EC2_INSTANCE'] = ""
    softlayer_clear('Name')
    softlayer_clear('Fqdn')
    softlayer_clear('Created_At')
    softlayer_clear('Tags')
    softlayer_clear('Image_Id')
    softlayer_clear('Flavor_Id')
    softlayer_clear('Os_Code')
    softlayer_clear('Key_Pairs')
    softlayer_clear('Admin_Password')
    softlayer_clear('Public_IP_Address')
    softlayer_clear('Private IP_Address')
    if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("mingw") == nil
      softlayer_clear('SSH_Private_Key')
    else
      softlayer_clear('Putty_Private_Key')
    end
    softlayer_clear('EC2_SSH_User')
    softlayer_clear('Network_Components')
    softlayer_clear('Disks')
   # softlayer_clear('Provision_Script')
   # @softlayer_server['Metadata'].setVisibleRows(5)
   # @softlayer_server['Metadata'].setText("")
    @frame1.hide()
    @page1.width=300
    @frame4.hide()
    @frame5.hide()
    @frame3.hide()
    @frame6.hide()
    @frame7.show()
    @server_status = ""
    @secgrp = ""
  end

  def softlayer_clear(key)
    @softlayer_server[key].text = ""
  end

  def softlayer_load(instance_id)
    puts "server.softlayer_load "+instance_id
    @type = "softlayer"
    @frame1.hide()
    @page1.width=300
    @frame4.hide()
    @frame5.hide()
    @frame3.hide()
    @frame6.hide()
    @frame7.show()
    @softlayer_server['Instance_ID'].text = instance_id
    $ec2_main.launch.load(instance_id)
    ENV['EC2_INSTANCE'] = instance_id
    #puts "instance id #{instance_id}"
    r = @ec2_main.environment.servers.get_softlayer_server(instance_id)
    puts "Found softlayer server #{r}"
    if r != nil
      if r['id'] == nil
        return
      end

      @softlayer_server['Name'].text = r['hostname']
      @softlayer_server['Fqdn'].text = r['fullyQualifiedDomainName']
      @softlayer_server['Created_At'].text = r['createDate']
      @softlayer_server['Tags'].text = r['tags']
 # doesn't show these
 #     @softlayer_server['Image_Id'].text = r['image_id'].to_s
 #     @softlayer_server['Flavor_Id'].text = r['flavor_id']
      @softlayer_server['Os_Code'].text = r['operatingSystem'].to_s
      @softlayer_server['Key_Pairs'].text = r['sshKeys'].to_s
      @softlayer_server['Public_IP_Address'].text = r['primaryIpAddress']
      @softlayer_server['Private_IP_Address'].text = r['primaryBackendIpAddress']

      @softlayer_server['Network_Components'].text = r['backendNetworkComponents'].to_s
      @softlayer_server['Disks'].text = r['blockDevices'].to_s
 # doesn't show this
 #     @softlayer_server['Provision_Script'].text = r['provision_script']
      if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("mingw") == nil
        @softlayer_server['SSH_Private_Key'].text = get_pk
      else
        @softlayer_server['Putty_Private_Key'].text =  @ec2_main.settings.get('PUTTY_PRIVATE_KEY')  # get_ppk #
      end
      @softlayer_server['EC2_SSH_User'].text = ""
      ssh_u = @ec2_main.launch.softlayer_get('EC2_SSH_User')
      if ssh_u != nil and ssh_u != ""
        @softlayer_server['EC2_SSH_User'].text = ssh_u
      else
        @softlayer_server['EC2_SSH_User'].text = @ec2_main.settings.get('EC2_SSH_USER')
      end
# doesn't show this
#      if @softlayer_admin_pw[instance_id] != nil and @softlayer_admin_pw[instance_id] != ""
#        @softlayer_server['Admin_Password'].text = @softlayer_admin_pw[instance_id]
#      else
#        if @ec2_main.launch.softlayer_get('Name') == r[:name]
#          @softlayer_server['Admin_Password'].text = @ec2_main.launch.softlayer_get('Admin_Password')
#        else
#          @softlayer_server['Admin_Password'].text = ""
#        end
#      end
#      if r[:password] != nil
#        @softlayer_server['Admin_Password'].text =  r[:password]
#      end
    end
    @ec2_main.app.forceRefresh
  end

  def softlayer_terminate
    instance_id = @softlayer_server['Instance_ID'].text
    instance = @softlayer_server['Name'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Termination","Confirm Termination of Server Instance "+instance)
    if answer == MBOX_CLICKED_YES
      begin
        r = @ec2_main.environment.servers.delete_server(instance_id)
      rescue
        error_message("Terminate Instance Failed",$!)
      end
    end
  end

end

class EC2_Server

  #
  #  cloudfoundry methods
  #

  def cfy_clear_panel
    @type = ""
    cfy_clear('name')
    cfy_clear('state')
    cfy_clear('model')
    cfy_clear('stack')
    cfy_load_table(@cfy_server['uris'],"URIs",[])
    cfy_clear('instances')
    cfy_clear('runningInstances')
    cfy_clear('memory')
    cfy_clear('disk')
    cfy_clear('fds')
    cfy_load_table(@cfy_server['services'],"Service",[])
    cfy_clear('version')
    cfy_load_table(@cfy_server['env'],"Environment Variable",[])
    cfy_clear('meta')
    @frame1.hide()
    @frame3.hide()
    @frame5.hide()
    @frame6.hide()
    @frame4.show()
    @page1.width=300
    @server_status = ""
    @secgrp = ""
  end

  def cfy_clear(key)
    @cfy_server[key].text = ""
  end

  def cfy_refresh(app_name)
    @ec2_main.treeCache.refresh
    cfy_load(app_name)
  end

  def cfy_load(app_name)
    puts "server.cfy_load "+app_name
    @type = "cfy"
    @frame1.hide()
    @frame3.hide()
    @frame5.hide()
    @frame6.hide()
    @frame4.show()
    @page1.width=300
    @appname = app_name
    r = @ec2_main.serverCache.instance(app_name)
    if r != nil
      @cfy_server['name'].text = r[:name]
      @cfy_server['state'].text = r[:state]
      @cfy_server['model'].text = r[:staging][:model]
      @cfy_server['stack'].text = r[:staging][:stack]
      cfy_load_table(@cfy_server['uris'],"URI",r[:uris])
      @cfy_server['instances'].text = r[:instances].to_s
      @cfy_server['runningInstances'].text = r[:runningInstances].to_s
      @cfy_server['memory'].text = r[:resources][:memory].to_s
      @cfy_server['disk'].text = r[:resources][:disk].to_s
      @cfy_server['fds'].text = r[:resources][:fds].to_s
      cfy_load_table(@cfy_server['services'],"Service",r[:services])
      @cfy_server['version'].text = r[:version]
      cfy_load_table(@cfy_server['env'],"Environment Variable",r[:env])
      @cfy_server['meta'].text  = r[:meta].to_s
    end
    @ec2_main.app.forceRefresh
  end

  def cfy_load_table(field,title,env=[])
    if env == nil
      env = []
    end
    field.clearItems
    field.rowHeaderWidth = 0
    field.setTableSize(env.size, 1)
    field.setColumnText(0, title)
    field.setColumnWidth(0,360)
    i = 0
    env.each do |j|
      if j!= nil
        field.setItemText(i, 0, "#{j}")
        field.setItemJustify(i, 0, FXTableItem::LEFT)
        i = i+1
      end
    end
  end


  def cfy_start
    name = @cfy_server['name'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Start","Confirm Start of App "+name)
    if answer == MBOX_CLICKED_YES
      begin
        puts "*****************************************************"
        puts "*** Starting app #{name} this can take a few minutes"
        puts "*****************************************************"
        r = @ec2_main.environment.cfy_app.start(name)
      rescue
        error_message("Start App Failed",$!)
      end
    end
  end

  def cfy_stop
    name = @cfy_server['name'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Stop","Confirm Stop of App "+name)
    if answer == MBOX_CLICKED_YES
      begin
        r = @ec2_main.environment.cfy_app.stop(name)
      rescue
        error_message("Stop App Failed",$!)
      end
    end
  end

  def cfy_restart
    name = @cfy_server['name'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Restart","Confirm Restart of App "+name)
    if answer == MBOX_CLICKED_YES
      begin
        r = @ec2_main.environment.cfy_app.restart(name)
      rescue
        error_message("Restart App Failed",$!)
      end
    end
  end

  def cfy_delete
    name = @cfy_server['name'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Delete","Confirm Delete of App "+name)
    if answer == MBOX_CLICKED_YES
      begin
        r = @ec2_main.environment.cfy_app.delete(name)
      rescue
        error_message("Delete App Failed",$!)
      end
    end
  end
end

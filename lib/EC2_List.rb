require 'rubygems'
require 'fox16'
require 'fog'
require 'net/http'
require 'resolv'
require 'date'
require 'pathname'

require 'dialog/EC2_SecGrp_CreateDialog'

require 'dialog/EC2_EBSCreateDialog'
require 'dialog/EC2_EBSDeleteDialog'
require 'dialog/EC2_EBSAttachDialog'
require 'dialog/EC2_EBSDetachDialog'

require 'dialog/EC2_SnapVolumeDialog'
require 'dialog/EC2_SnapDeleteDialog'
require 'dialog/EC2_SnapSelectDialog'
require 'dialog/EC2_SnapRegisterDialog'

require 'dialog/EC2_EIPCreateDialog'
require 'dialog/EC2_EIPDeleteDialog'
require 'dialog/EC2_EIPAssociateDialog'
require 'dialog/EC2_EIPDisassociateDeleteDialog'

require 'dialog/EC2_KeypairCreateDialog'
require 'dialog/EC2_KeypairDeleteDialog'

require 'dialog/EC2_ImageRegisterDialog'
require 'dialog/EC2_ImageDeRegisterDialog'
require 'dialog/EC2_ImageEBSDeleteDialog'
require 'dialog/EC2_ImageSelectDialog'
require 'dialog/EC2_ImageAttributeDialog'

require 'dialog/EC2_CSVDialog'

require 'dialog/EC2_SpotRequestCancelDialog'

require 'dialog/EC2_TagsAssignDialog'
require 'dialog/EC2_TagsFilterDialog'

require 'common/EC2_ResourceTags'
require 'common/EC2_FilterTags'
require 'common/button_config'

require 'dialog/ELB_CreateDialog'
require 'dialog/ELB_DeleteDialog'
require 'dialog/ELB_AvailZoneDialog'
require 'dialog/ELB_HealthDialog'
require 'dialog/ELB_PolicyDialog'
require 'dialog/ELB_InstancesDialog'

require 'dialog/AS_CapacityDialog'
require 'dialog/AS_LaunchConfigurationDeleteDialog'
require 'dialog/AS_InstancesDialog'
require 'dialog/AS_GroupDialog'
require 'dialog/AS_GroupCreateDialog'
require 'dialog/AS_GroupEditDialog'
require 'dialog/AS_GroupDeleteGroupDialog'
require 'dialog/AS_GroupResumeDialog'
require 'dialog/AS_GroupSuspendDialog'
require 'dialog/AS_GroupEnableMetricsDialog'
require 'dialog/AS_GroupDisableMetricsDialog'
require 'dialog/AS_ScheduledActionCreateDialog'
require 'dialog/AS_ScheduledActionEditDialog'
require 'dialog/AS_ScheduledActionDeleteDialog'
require 'dialog/AS_PolicyCreateDialog'
require 'dialog/AS_PolicyEditDialog'
require 'dialog/AS_PolicyDeleteDialog'
require 'dialog/AS_PolicyExecuteDialog'
require 'dialog/AS_AlarmCreateDialog'
require 'dialog/AS_AlarmEditDialog'
require 'dialog/AS_AlarmDeleteDialog'

require 'dialog/CFY_ServiceCreateDialog'
require 'dialog/CFY_ServiceDeleteDialog'

require 'dialog/LOC_CreateDialog'

require 'dialog/KIT_LogSelectDialog'
require 'dialog/KIT_PathCreateDialog'

require 'dialog/VAG_CreateDialog'
require 'dialog/VAG_DeleteDialog'
require 'dialog/VAG_UpDialog'
require 'dialog/VAG_DestroyDialog'

require 'dialog/GOG_AddressCreateDialog'
require 'dialog/GOG_AddressDeleteDialog'
require 'dialog/GOG_NetworkCreateDialog'
require 'dialog/GOG_NetworkDeleteDialog'
require 'dialog/GOG_ZoneOperationDeleteDialog'
require 'dialog/GOG_GlobalOperationDeleteDialog'
require 'dialog/GOG_SnapDiskDialog'
require 'dialog/GOG_SnapDeleteDialog'
require 'dialog/GOG_DiskCreateDialog'
require 'dialog/GOG_DiskDeleteDialog'
require 'dialog/GOG_DiskAttachDialog'
require 'dialog/GOG_DiskDetachDialog'
require 'dialog/GOG_FirewallCreateDialog'
require 'dialog/GOG_FirewallDeleteDialog'

require 'dialog/CF_CreateDialog'
require 'dialog/CF_EditDialog'
require 'dialog/CF_DeleteDialog'
require 'dialog/CF_StackDialog'
require 'dialog/CF_GetTemplateDialog'
require 'dialog/CF_StackDeleteDialog'
require 'dialog/CF_ValidateDialog'
require 'common/EC2_Properties'
require 'common/browser'
require 'common/chef'
require 'common/edit'
require 'common/scp'
require 'common/ssh'
require 'common/ssh_tunnel'
require 'common/remote_desktop'
require 'common/error_message'
require 'common/convert_time'
require 'common/kitchen_cmd'

class EC2_List

  def initialize(owner, app)
        @ec2_main=$ec2_main
        @loaded = false
        @type = ""
        @curr_sort = ""
        @dialog_options = {}
        @config = {}
        @tags_filter = nil
        @image_search = ""
        @image_type = "Owned By Me"
        @image_platform = "All Platforms"
        @image_root = ""
	@search_search = ""
        @search_type = "Owned By Me"
        @search_platform = "All Platforms"
        @search_root = ""
	@connection = "Compute"
	@snap_owner = "self"
	@db_parm_grp = ""
	@as_group = ""
	@application_name = ""
	@template_file = ""
	@cf_parameters = ""
	@stack_name = ""
	@group_name = ""
	@role_name = ""
	@user_name = ""
	@group_id = ""
	@cdn_distribution = ""
	@curr_association_id = nil
	@arrow_refresh = @ec2_main.makeIcon("arrow_redo.png")
	@arrow_refresh.create
	@create = @ec2_main.makeIcon("new.png")
	@create.create
	@csv = @ec2_main.makeIcon("doc_excel_csv.png")
	@csv.create
	@magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
        @market_icon = @ec2_main.makeIcon("cloudmarket.png")
	@market_icon.create
	@monitor = @ec2_main.makeIcon("monitor.png")
	@monitor.create
	@chef_icon = @ec2_main.makeIcon("chef.png")
	@chef_icon.create
	@zones = @ec2_main.makeIcon("zones.png")
	@zones.create
	@rocket = @ec2_main.makeIcon("rocket.png")
	@rocket.create
	@tag_blue = @ec2_main.makeIcon("tag_blue.png")
	@tag_blue.create
        @tag_red = @ec2_main.makeIcon("tag_red.png")
	@tag_red.create
        @funnel = @ec2_main.makeIcon("funnel.png")
	@funnel.create
	@events = @ec2_main.makeIcon("events.png")
	@events.create
	@delete_icon = @ec2_main.makeIcon("kill.png")
	@delete_icon.create
	@disconnect = @ec2_main.makeIcon("disconnect.png")
	@disconnect.create
	@delete = @ec2_main.makeIcon("kill.png")
	@delete.create
	@stop_icon = @ec2_main.makeIcon("cancel.png")
	@stop_icon.create
	@start_icon = @ec2_main.makeIcon("arrow_right.png")
	@start_icon.create
	@viewstack = @ec2_main.makeIcon("viewstack.png")
	@viewstack.create
        @put = @ec2_main.makeIcon("application_put.png")
	@put.create
	@rocket = @ec2_main.makeIcon("rocket.png")
	@rocket.create
	@mon = @ec2_main.makeIcon("dashboard.png")
	@mon.create
	@unmon = @ec2_main.makeIcon("dashboard_stop.png")
	@unmon.create
	@time = @ec2_main.makeIcon("time.png")
	@time.create
	@edit = @ec2_main.makeIcon("application_edit.png")
	@edit.create
	@edit_lightning = @ec2_main.makeIcon("application_lightning.png")
	@edit_lightning.create
	@view = @ec2_main.makeIcon("application_view_icons.png")
	@view.create
	@server = @ec2_main.makeIcon("server.png")
	@server.create
	@camera = @ec2_main.makeIcon("camera.png")
	@camera.create
	@link = @ec2_main.makeIcon("link.png")
	@link.create
	@script = @ec2_main.makeIcon("script.png")
	@script.create
	@script_edit = @ec2_main.makeIcon("script_edit.png")
	@script_edit.create
	@check = @ec2_main.makeIcon("spellcheck.png")
	@check.create
	@create_image_icon = @ec2_main.makeIcon("package.png")
	@create_image_icon.create
	@link_break = @ec2_main.makeIcon("link_break.png")
	@link_break.create
        @help = @ec2_main.makeIcon("help.png")
	@help.create
	@app_delete = @ec2_main.makeIcon("application_delete.png")
	@app_delete.create
	@chart = @ec2_main.makeIcon("chart_stock.png")
	@chart.create
        @puppet = @ec2_main.makeIcon("puppet.png")
	@puppet.create
	@tunnel = @ec2_main.makeIcon("tunnel.png")
	@tunnel.create

    tab1 = FXTabItem.new($ec2_main.tabBook, "  List  ")
  	page1 = FXVerticalFrame.new($ec2_main.tabBook, LAYOUT_FILL, :padding => 0)
   	page1a = FXHorizontalFrame.new(page1,LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(page1a, " ",:opts => LAYOUT_LEFT )

        @refresh_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@refresh_button.icon = @arrow_refresh
	@refresh_button.tipText = " Status Refresh "
	@refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
	   if @type == "Images"
	      @ec2_main.imageCache.set_status("empty")
	   end
	   load_sort(@type,@curr_sort,@connection)
	   if @type == "Cloud Formation Stacks"
	      @ec2_main.treeCache.refresh
	   end
	end
	@refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded
	       	sender.enabled = true
	   else
	       sender.enabled = false
           end
	end

	@create_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@create_button.icon = @create
	@create_button.connect(SEL_COMMAND) do |sender, sel, data|
	   case @type
        when "Images"
	       dialog = EC2_ImageSelectDialog.new(@ec2_main,@search_type,@search_platform,@search_root,@search_search)
	       dialog.execute
	       @image_search =  dialog.search
	       @image_type = dialog.type
               @image_platform = dialog.platform
               @image_root = dialog.root_device_type
	       @search_search =  dialog.search
	       @search_type = dialog.type
               @search_platform = dialog.platform
               @search_root = dialog.root_device_type
               if dialog.selected
                 load_sort(@type,@curr_sort,@connection)
               end
 	    when "Cloud Formation Stacks"
	      dialog = CF_StackDialog.new(@ec2_main)
              dialog.execute
              if dialog.stack_name != nil and dialog.stack_name != ""
                 @stack_name = dialog.stack_name
                 load_sort(@type,@curr_sort,"CloudFormation")
              end
         else
			  call_dialog(0)
            end
         end
	@create_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if   @config != nil and @config['icon'] != nil and @config['icon'][0] != ""
	        button_config(sender, eval(@config['icon'][0]), @config['tooltip'][0])
	       	sender.enabled = true
	   else
	       sender.enabled = false
           end
	end

        @delete_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@delete_button.icon = @delete
	@delete_button.connect(SEL_COMMAND) do |sender, sel, data|
           call_dialog(1)
         end
	@delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded and @config['icon'] != nil and @config['icon'][1] != ""
	        button_config(sender, eval(@config['icon'][1]), @config['tooltip'][1])
	       	sender.enabled = true
	   else
	       sender.enabled = false
           end
	end

        @link_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@link_button.icon = @link
	@link_button.connect(SEL_COMMAND) do |sender, sel, data|
	   case @type
          when "Snapshots"
	      dialog = EC2_SnapSelectDialog.new(@ec2_main,@snap_owner)
	      dialog.execute
	      if dialog.selected
	         @snap_owner = dialog.snap_owner
	         load_sort(@type,@curr_sort,@connection)
              end
           else
	      call_dialog(2)
           end
	end
	@link_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded and @config['icon'] != nil and @config['icon'][2] != ""
	        button_config(sender, eval(@config['icon'][2]), @config['tooltip'][2])
	       	sender.enabled = true
	   else
	       sender.enabled = false
           end
	end

	@link_break_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@link_break_button.icon = @link_break
	@link_break_button.connect(SEL_COMMAND) do |sender, sel, data|
	   call_dialog(3)
 	end
	@link_break_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded and @config['icon'] != nil and @config['icon'][3] != ""
	        button_config(sender, eval(@config['icon'][3]), @config['tooltip'][3])
	       	sender.enabled = true
	   else
	       sender.enabled = false
           end
	end

	@csv_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@csv_button.icon = @csv
	@csv_button.tipText = " csv data "
	@csv_button.connect(SEL_COMMAND) do |sender, sel, data|
	   csv_text = ""
	   @header1.each do |item|
	     t = ""
		 t = item.text if item != nil
	     csv_text = csv_text+",#{t}" if csv_text != ""
	     csv_text = "#{t}" if csv_text == ""
	   end
	   csv_text = csv_text +"\n"
	   @table.each_row do |items|
	     csv_line = ""
	     items.each do |item|
		    t = ""
		    t = item.text if item != nil
	        csv_line = csv_line+",#{t}" if csv_line != ""
	        csv_line = "#{t}" if csv_line == ""
         end
		 csv_text = csv_text + csv_line + "\n"
        end
        csvdialog = EC2_CSVDialog.new(@ec2_main,csv_text,@type)
        csvdialog.execute
	end
	@csv_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded == true
	       sender.enabled = true
	   else
	       sender.enabled = false
	   end
	end

	@launch_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@launch_button.icon = @rocket
	@launch_button.connect(SEL_COMMAND) do |sender, sel, data|
	   call_dialog(5)
	end
	@launch_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded and @config['icon'] != nil and @config['icon'][5] != ""
	        button_config(sender, eval(@config['icon'][5]), @config['tooltip'][5])
	       	sender.enabled = true
	   else
	       sender.enabled = false
           end
	end

	@attributes_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
      	@view = $ec2_main.makeIcon('application_view_icons.png')
      	@view.create
	@attributes_button.icon = @view
	@attributes_button.connect(SEL_COMMAND) do |sender, sel, data|
	   call_dialog(6)
 	end
	@attributes_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded and @config['icon'] != nil and @config['icon'][6] != ""
	        button_config(sender, eval(@config['icon'][6]), @config['tooltip'][6])
	       	sender.enabled = true
	   else
	       sender.enabled = false
           end
	end

	@tags_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@tags_button.icon = @tag_red
	@tags_button.connect(SEL_COMMAND) do |sender, sel, data|
 	   call_dialog(7)
 	end
	@tags_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded and @config['icon'] != nil and @config['icon'][7] != ""
	        button_config(sender, eval(@config['icon'][7]), @config['tooltip'][7])
	       	sender.enabled = true
	   else
	       sender.enabled = false
           end
	end

	@filter_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@filter_button.icon = @funnel
	@filter_button.connect(SEL_COMMAND) do |sender, sel, data|
	    case @type
          when "Images"
            # to do
           else
            if @config["dialog"][8] == "EC2_TagsFilterDialog"
               dialog = EC2_TagsFilterDialog.new(@ec2_main,@type,@tags_filter[@config["name"]])
               dialog.execute
	       if dialog.saved
		   @tags_filter[@config["name"]] = dialog.tag_filter
		   @ec2_main.settings.save_filter(@tags_filter)
		   load_sort(@type,@curr_sort,@connection)
               end
              else
                 call_dialog(8)
             end
            end
     end
	@filter_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded and @config['icon'] != nil and @config['icon'][8] != ""
	        button_config(sender, eval(@config['icon'][8]), @config['tooltip'][8])
	       	sender.enabled = true
	   else
	       sender.enabled = false
           end
	end

	@help_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_RIGHT)
	@help_button.icon = @help
	@help_button.tipText = " View Help "
	@help_button.connect(SEL_COMMAND) do |sender, sel, data|
	    case @type
            when "Templates"
	           browser("http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html")
            when "Spot Requests"
               browser("http://thecloudmarket.com/stats#/spot_prices")
            when "Auto Scaling Groups"
               browser("http://aws.amazon.com/documentation/autoscaling/")
            else
               browser("http://ec2dream.github.com/")
            end
	end
        @help_button.connect(SEL_UPDATE) do |sender, sel, data|
             case @type
	       when "Templates"
	          button_config(sender, @help, "  View Sample Templates  ")
               when "Spot Requests"
                  button_config(sender, @help, "  View Spot Prices  ")
               else
                  button_config(sender, @help, " View Help ")
               end
	end


        @title = FXLabel.new(page1a, "", nil,:opts => LAYOUT_RIGHT)
	@title.font = FXFont.new(app, "Arial", 11)

        contents = FXVerticalFrame.new(page1,LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y,
       :padLeft => 0, :padRight => 0, :padTop => 0, :padBottom => 0,
	       :hSpacing => 0, :vSpacing => 0)

	@table = FXTable.new(contents, :opts => LAYOUT_FILL|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|TABLE_READONLY  )
	@table.rowHeaderWidth = 0
	# Make header control
	@header1 = @table.columnHeader
	@header1.connect(SEL_COMMAND) do |sender, sel, which|
	     if @curr_type ==  @type and @curr_sort == sender.getItemText(which) and @curr_order == "down"
	        @curr_order = "up"
	     else
	        @curr_type = @type
	        @curr_sort = sender.getItemText(which)
	        @curr_order = "down"
	     end
	     load_sort_reload(@type,@curr_sort,false,@connection)
	end
	@table.connect(SEL_COMMAND) do |sender, sel, which|
	   #if which.col == 0
	      @curr_image_type = ""
	      @curr_size = ""
	      @curr_row = which.row
		  @table.selectRow(@curr_row)
	      @curr_item = @table.getItemText(which.row,0).to_s
		  puts "item selected #{@curr_item}  type #{@type}"
	      case @type
	       when "Images"
		    #  need find this.
	        # @curr_image_type = @table.getItemText(which.row,5).to_s
	       when "Volumes","IP Addresses"
		       @curr_instance = ""
			   if @ec2_main.settings.openstack
			      as = find_value('attachments',which.row)
				  if as != nil and as != ""
				     sa = as.split","
			         sa.each do |s|
			    	    @curr_instance=s[9..s.length-1] if s.start_with? ("serverId")
						@curr_instance=s[10..s.length-1] if s.start_with? ("server_id")
                     end
                  else
                     @curr_instance = find_value('instance_id',which.row)

                  end
			   elsif @ec2_main.settings.amazon
	              as = find_value('attachmentSet',which.row)
	              if as != nil and as != ""
				     sa = as.split","
			         sa.each do |s|
			            @curr_instance=s[11..s.length-1] if s.start_with? ("instanceId")
		             end
				  else
                     @curr_instance = find_value('instanceId',which.row)
                  end
				  @curr_association_id = find_value('associationId',which.row)
				  @curr_allocation_id = find_value('allocationId',which.row)
                  @curr_domain = find_value('domain',which.row)
  		      else
		        as = find_value('aws_instance_id',which.row)
				if as == nil or as == ""
				   as = find_value('instance_id',which.row)
				end
			        if as != nil and as != ""
		           @curr_instance = as
				end
			  end
		when "Security Groups"
		   @group_id = 	 find_value('groupId',which.row)
		   @curr_vpc_id =  find_value('vpcId',which.row)
	       when "Snapshots"
	         @volumeSize  =  find_value('volumeSize',which.row)
	       when "Load Balancers"
	        @curr_listeners  = find_value('ListenerDiscriptions',which.row)
	        @curr_policies  = find_value('Policies',which.row)
	        @curr_avail_zone  = find_value('AvailabilityZones',which.row)
	       when "Auto Scaling Groups"
	         @as_group = @curr_item
	         @curr_desired_capacity  = find_value('DesiredCapacity',which.row)
			when "Scheduled Actions","Auto Scaling Policies"
			  @as_group  = find_value('AutoScalingGroupName',which.row)
	       when "Templates"
		     @template_file  = find_value('template_file',which.row)
	         @cf_parameters = find_value('parameters',which.row)
           when "Stacks"
	         @stack_id  =  find_value('StackId',which.row)
			when "Distributions"
			 @cdn_distribution  = @curr_item
			when "Users"
			 @user_name =  @curr_item
			when "Vagrant"
	         @vagrant_file  =  find_value('Vagrantfile',which.row)
			when "Local Servers"
	         call_dialog(2)
			when "Test Kitchen"
			 @curr_driver = find_value('Driver',which.row)
			 @curr_provisioner = find_value('Provisioner',which.row)
			 @curr_last_action = find_value('Last-Action',which.row)
	         call_dialog(2)
 	      end
	  # else
	  #    @curr_row = nil
	  #    @curr_item = ""
	  #    @curr_image_type = ""
	  #    @curr_size = ""
	  # end
	end
  end

  def convert_to_array_of_hashs(a,name)
   x = []
   a.each do |e|
     x.push({name => e})
   end
   x
end

  def find_value(name,row)
   i=0
   j=nil
   while i < @table.numColumns
      if @table.getColumnText(i) == name
	     j = i
	  end
	i=i+1
   end
   if j != nil
      @table.getItemText(row,j).to_s
   else
      ""
   end
  end

  def call_dialog(i)
     name = @config['dialog'][i]
	 parms = @config['dialog_parm'][i]
	 type = @type
	 type = type[0..-2] if @type.end_with? ("s")
    if  !name.end_with?("Dialog")
	    if  name.include?("@curr_item")  and (@curr_item == nil or @curr_item == "")
           error_message("No #{type} selected","No #{type} selected to #{@config['action'][i]}")
		else
		   puts "#{name}"
           eval(name)
        end
     elsif (!name.end_with?("CreateDialog") and !name.end_with?("SelectDialog"))  and (@curr_item == nil or @curr_item == "")
        error_message("No #{type} selected","No #{type} selected to #{@config['action'][i]}")
     else
	   if name.end_with?("CreateDialog") or name.end_with?("SelectDialog")
	          if parms == nil or parms == ""
	             puts "#{name}.new(@ec2_main)"
                 dialog = eval(name).new(@ec2_main)
			  else
                 cmd = "#{name}.new(@ec2_main,#{parms})"
			     puts "#{cmd}"
			     dialog = eval(cmd)
              end
		else
		   if parms == nil or parms == ""
		      puts "#{name}.new(@ec2_main,#{@curr_item}"
              dialog = eval(name).new(@ec2_main,@curr_item)
		   else
              cmd = "#{name}.new(@ec2_main,@curr_item,#{parms})"
			  puts "#{cmd}"
			  dialog = eval(cmd)
            end
        end
        begin
           dialog.execute if !name.end_with?("DeleteDialog")
           if dialog.success
              load_sort(@type,@curr_sort,@connection)
           end
        rescue
          puts "call_dialog: Dialog already finished"
        end
     end
  end

  def clear
     @table.setTableSize(0,0)
     @table.rowHeaderWidth = 0
  end

  def load(type,connection="Compute")
     @connection = connection
     @tags_filter= @ec2_main.settings.load_filter()
     if type != "Images"
        @image_type = "Owned By Me"
        @image_platform = "All Platforms"
        @image_root = ""
        @image_search = ""
     end
     @curr_sort = ""
    load_sort(type,"",connection)
  end

  def load_sort(type,sort_col,connection="Compute")
     @connection = connection
     load_sort_reload(type,sort_col,true,connection)
  end


  def load_sort_reload(type,sort_col,reload,connection="Compute")
      @connection = connection
      @type = type
       @curr_item = ""
       if @type == "Images"
          status = $ec2_main.imageCache.status
          if status == "loaded"
             @title.text = @type + " (Cached)"
          else
             @title.text = @type + " (Cache not loaded)"
          end
       elsif @type == "Cloud Formation Stacks" or @type == "Cloud Formation Events"
          if @stack_name != nil and @stack_name != ""
             @title.text = @type + "(#{@stack_name})"
          else
             @title.text = @type + "    "
          end
       else
          @title.text = @type + "    "
       end
      puts "cloud.config['Cloud'][#{@connection}][#{@type}]"
      @config = $ec2_main.cloud.config["Cloud"][connection][@type]
      @data = []
      if @type == "Images"
  	   @data = @ec2_main.environment.images.get_images(@image_type, @image_platform, @image_root, @image_search, @tags_filter)
  	   if @data.empty?
  	      image_error_message = @ec2_main.environment.images.error_message
  	      if image_error_message != nil and image_error_message != ""
  	         error_message("Error",image_error_message)
  	      end
  	   end
  	#end
  	   if @tags_filter[:image] == nil or  @tags_filter[:image].empty?
 	     if @image_type == "Public Images"
              @title.text = "Images (Cached)"
         else
              if @image_type != "Private Images"
                 @title.text = "Images (Cached)"
              end
        end
       end
      elsif type == "Local Servers"
         loc = EC2_Properties.new
         if loc != nil
                if reload == true
                   @data = []
                   i = 0
                   loc.all("loc_server").each do |r|
                      @data[i] = r
                      i = i+1
                   end
                end
		end
      elsif type == "Test Kitchen"
         @data = kitchen_cmd("list")
         path = Pathname.new($ec2_main.settings.get("TEST_KITCHEN_PATH")).basename
         @title.text = "#{@type} - #{Pathname.new($ec2_main.settings.get("TEST_KITCHEN_PATH")).basename}"
      elsif type == "Vagrant"
             begin
                envs = Dir.entries($ec2_main.settings.get("VAGRANT_REPOSITORY"))
             rescue
                error_message("Vagrant Repository does not exist",$!)
				return
             end
             if reload == true
                @data = []
                envs.each do |r|
				   vf = "#{$ec2_main.settings.get('VAGRANT_REPOSITORY')}/#{r}/Vagrantfile"
                   @data.push({"server" => r, "Vagrantfile" => vf  }) if r != '.' and r != '..' and File.directory?("#{$ec2_main.settings.get('VAGRANT_REPOSITORY')}/#{r}")
                end
             end

      elsif type == "Templates"
         cf = EC2_Properties.new
         if cf != nil
                if reload == true
                   @data = Array.new
                   i = 0
                   cf.all("cf_templates").each do |r|
                      @data[i] = r
                      i = i+1
                   end
                end
		end
      else
        conn = $ec2_main.cloud.conn(connection)
        request = @config["request"]
        if conn != nil
           begin
              filter = @tags_filter[@config["name"]]
              if filter != nil and filter != ""
                 cmd = "conn.#{request}(filter)"
              else
                 cmd = "conn.#{request}"
              end
                  puts "CMD #{cmd}"
 	          response = eval(cmd)
 	           puts "RESPONSE.BODY #{response.body}"
			  if @ec2_main.settings.cloudfoundry
			    @data = response
			  else
				  if response.status == @config["response_code"]
                  if @type == "Servers" and (@ec2_main.settings.amazon  or @ec2_main.settings.eucalyptus or @ec2_main.settings.cloudstack)
                     response.body['reservationSet'].each do |r|
		               r['instancesSet'].each do |item|
		                  item['groupIds'] = r['groupIds']
		                  item['groupNames'] = r['groupSet']
		                end
		                @data = @data + r['instancesSet']
		             end
				 elsif @type == "Key Pairs" and @ec2_main.settings.openstack and !@ec2_main.settings.openstack_rackspace

		            d = eval(@config["response"])
		            @data = []
		            d.each do |v|
		              @data.push(v["keypair"])
		            end
                 else
                     @data = eval(@config["response"])
                 end
              end
			 end
           rescue
              puts "ERROR: #{request} #{$!}"
           end
        end
      end
	  @data = [] if @data == nil
      if  !@data.empty?  or @data.size>0
        @data_title = []
        @data.each do |r|
          r.each do |k, v|
		     k = k.to_s
		     if !@config['keys'].include?(k)
                @data_title.push(k) if !@data_title.include? k
             end
          end
        end
        table_size=@data_title.size+@config['keys'].size
        if @curr_sort != "" and @data[0][@curr_sort].class == String
            @data = @data.sort_by {|r| r[@curr_sort] || ""}
        end
        lists = create_lists(table_size)
         i=0
        j=0
        @max_data_size = {}
        @data.each do |r|
            j=0
            @config['keys'].each do |k|
 			  begin
			   rk = r[k] if r[k] != nil
			   rk = r[k.to_sym] if r[k.to_sym] != nil
               if rk != nil
                  item = ""
                  if rk.kind_of?(Array)
                     rk.each do |d|
                       if d.kind_of?(Hash)
                          x = ""
                          d.each do |y,z|
                             if x == ""
                                x = "#{y}=#{z}"
                             else
                                x = "#{x},#{y}=#{z}"
                             end
                          end
                          d = x
                        end
                        if item == ""
                           item = d.to_s
                        else
                           item = "#{item},#{d}"
                         end
                     end
                  elsif rk.kind_of?(Hash)
                     rk.each do |y,z|
                        if item == ""
                           item = "#{y}=#{z}"
                        else
                           item = "#{item},#{y}=#{z}"
                        end
                     end
                  elsif rk.kind_of?(EC2_ResourceTags)
                     item = rk.show
                  else
                     item = rk.to_s if (rk.class).to_s != "Fog::Time"
					 item = convert_time(rk) if (rk.class).to_s == "Fog::Time"
                  end
                  lists[j][i] = item
                  @max_data_size[k] = item.length if  @max_data_size[k] == nil or item.length >  @max_data_size[k]
                  j=j+1
               end
			  rescue
                puts "internal error parsing data in ec2_list #{$!}"
              end
            end
            r.each do |k, v|
               if !@config['keys'].include?(k)
                   begin
                     item = ""
                     if v.kind_of?(Array)
                        v.each do |d|
                          if d.kind_of?(Hash)
                             x = ""
                             d.each do |y,z|
                                if x == ""
                                   x = "#{y}=#{z}"
                                else
                                   x = "#{x},#{y}=#{z}"
                                end
                             end
                             d = x
                           end
                           if item == ""
                              item = d
                           else
                              item = "#{item},#{d}"
                           end
                        end
                     elsif v.kind_of?(Hash)
                        v.each do |y,z|
                           if item == ""
                              item = "#{y}=#{z}"
                           else
                              item = "#{item},#{y}=#{z}"
                           end
                        end
                     elsif v.kind_of?(EC2_ResourceTags)
                        item = v.show
                     else
                        #item = v.to_s
						item = v.to_s if (v.class).to_s != "Fog::Time"
					    item = convert_time(v) if (v.class).to_s == "Fog::Time"
                     end
                     data_index = @data_title.index(k.to_s)
                     if data_index != nil
                        lists[data_index+@config['keys'].size][i] = item
                        @max_data_size[k] = item.length if  @max_data_size[k] == nil or item.length >  @max_data_size[k]
                     end
                     j=j+1
                  rescue
                    puts "error processing  data for #{k} lists[#{j},#{i}] = #{v}"
                  end
               end
            end
            i=i+1
         end
         i = lists[0].length
         @table.setTableSize(i, table_size)
         set_table_titles(@data[0],@max_data_size)
         set_table_data(lists,table_size)
       else
         @table.setTableSize(0,0)
      end
      @loaded = true
   end

  def create_lists(list_size)
     lists = Array.new
     i =0
     while i < list_size
        lists[i] = Array.new
        i = i+1
     end
     return lists
  end

  def set_table_data(lists,table_size)
      i = lists[0].length
      if @curr_order == "" or @curr_order == "down"
         while i>0
            i = i-1
  	    k = 0
  	    #puts "*** table_data #{k} #{i} #{lists[k][i]}"
            while k < table_size
   	           @table.setItemText(i, k, lists[k][i].to_s)
    	       @table.setItemJustify(i, k, FXTableItem::LEFT)
    	       k = k+1
    	    end
         end
      else
         j = 0
         while i>0
            i = i-1
            k = 0
            #puts "*** table_data #{k} #{i} #{j} #{lists[k][j]}"
            while k < table_size
    	       @table.setItemText(i, k, lists[k][j].to_s)
    	       @table.setItemJustify(i, k, FXTableItem::LEFT)
    	       k = k+1
    	    end
            j = j+1
         end
      end
  end

  def set_table_titles(data,max)
   i=0
   @config['keys'].each do |k|
     begin
      @table.setColumnText(i,k)
       len = 0
      len = 10*k.size if k.size>15
      len = 7*max[k] if max[k]>15 and max[k]>k.size
      len = 500 if len >500
      @table.setColumnWidth(i,len)  if len>0
     rescue
     end
     i=i+1
   end
   @data_title.each do |k|
        begin
          @table.setColumnText(i,k)
         len = 0
         len = 10*k.size if k.size>15
         len = 7*max[k] if max[k]>15 and max[k]>k.size
         len = 500 if len >500
         @table.setColumnWidth(i,len)  if len>0
        rescue
        end
        i=i+1
    end
  end

 end



class EC2_List

  def initialize(owner, app)
        @ec2_main = owner
        @loaded = false
        @type = ""
        @curr_sort = 0
        @curr_item = ""
        @curr_row = nil
        @curr_type = ""
        @curr_image_type = ""
        @curr_order = ""
        @curr_size = ""
        @curr_avail_zone = ""
        @curr_listeners = ""
        @curr_policies = ""
	@curr_desired_capacity = ""  
        @image_search = ""
        @image_type = "Owned By Me"
        @image_platform = "All Platforms"
        @image_root = ""
        @data = Array.new
        @tags = Array.new
        @ebs_vols = {}
        @snap_owner = "self"
        @table = nil
        @image_locs = Array.new
        @db_parm_grp = ""
        @engine = ""
        @tags_filter = nil
        tab1 = FXTabItem.new(@ec2_main.tabBook, "Other")
  	page1 = FXVerticalFrame.new(@ec2_main.tabBook, LAYOUT_FILL, :padding => 0)
   	page1a = FXHorizontalFrame.new(page1,LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(page1a, " ",:opts => LAYOUT_LEFT )
        @refresh_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@arrow_refresh = @ec2_main.makeIcon("arrow_redo.png")
	@arrow_refresh.create
	@refresh_button.icon = @arrow_refresh
	@refresh_button.tipText = " Status Refresh "
	@refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
	load_sort(@type,@curr_sort)
	end
	@refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded == true
	       	sender.enabled = true
	   else
	       sender.enabled = false
           end
	end       
        
        @create_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@create = @ec2_main.makeIcon("new.png")
	@create.create
	@magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
        @market_icon = @ec2_main.makeIcon("cloudmarket.png")
	@market_icon.create
	@create_button.icon = @create
	@create_button.tipText = "  Create  "
	@create_button.connect(SEL_COMMAND) do |sender, sel, data|
	   case @type
	     when "EBS Volumes"
	      createdialog = EC2_EBSCreateDialog.new(@ec2_main)
              createdialog.execute
              if createdialog.created 
                 load_sort(@type,@curr_sort)
              end   
             when "EBS Snapshots"
	      if @curr_item == nil or @curr_item == ""
	         error_message("No Snapshot selected","No Snapshot selected to create EBS Volume")
              else             
	         createdialog = EC2_EBSCreateDialog.new(@ec2_main,@curr_item,@curr_size)
                 createdialog.execute
                 if createdialog.created 
                    load_sort(@type,@curr_sort)
                 end
              end   
             when "Elastic IPs"
  		ec2 = @ec2_main.environment.connection
	        if ec2 != nil
		   begin 
	              ec2.allocate_address({})
	              load_sort(@type,@curr_sort)
	           rescue
	             error_message("Allocate Elastic IP failed",$!.to_s)
	           end   
                end
            when "Key Pairs"
	      createdialog = EC2_KeypairCreateDialog.new(@ec2_main)
	      createdialog.execute
              if createdialog.created 
                 load_sort(@type,@curr_sort)
              end 
            when "Images"
	       createdialog = EC2_ImageSelectDialog.new(@ec2_main)
	       createdialog.execute
	       @image_search =  createdialog.search
	       @image_type = createdialog.type
               @image_platform = createdialog.platform
               @image_root = createdialog.root_device_type
               if createdialog.selected 
                 load_sort(@type,@curr_sort)
               end
            when "DB Snapshots"
              db_inst = @ec2_main.serverCache.db_instances
              if db_inst.size == 0 
                 error_message("No DB Instances Available","No DB Instances Available")
              else
	         createdialog = RDS_SnapCreateDialog.new(@ec2_main)
	         createdialog.execute
	         if createdialog.created 
	            load_sort(@type,@curr_sort)
	         end   
              end   
            when "DB Parameter Groups"
	      createdialog = RDS_ParmGrpCreateDialog.new(@ec2_main)
	      createdialog.execute
              if createdialog.created 
                 load_sort(@type,@curr_sort)
              end 
            when "Spot Requests"  
              @ec2_main.environment.browser("http://thecloudmarket.com/stats#/spot_prices")
            when "Load Balancers"
	        createdialog = ELB_CreateDialog.new(@ec2_main)
	        createdialog.execute
              if createdialog.created 
                 load_sort(@type,@curr_sort)
              end
      	    when "Launch Configurations"
		@ec2_main.launch.load_as
 		@ec2_main.tabBook.setCurrent(2)
   	    when "Auto Scaling Groups"
	        editdialog = AS_GroupEditDialog.new(@ec2_main)
                editdialog.execute
                if editdialog.saved 
                   load_sort(@type,@curr_sort)
                 end   
   	    when "Triggers"
		 editdialog = AS_TriggerEditDialog.new(@ec2_main, @as_group)
                 editdialog.execute
                 if editdialog.saved 
                    load_sort(@type,@curr_sort)
                 end   
           end              
        end
        @create_button.connect(SEL_UPDATE) do |sender, sel, data|
           if @loaded == true and @type != "Servers" and @type != "DB Events" and @type != "DB Parameters" 
	    sender.enabled = true
	    case @type
	      when "Images"
	       @create_button.icon = @magnifier
	       @create_button.tipText = "  Select Images  "
	      when "EBS Snapshots"
	       @create_button.icon = @create
	       @create_button.tipText = "  Create EBS Volume  "	       
              when "Spot Requests"
	       @create_button.icon = @market_icon
	       @create_button.tipText = "  CloudMarket Spot Prices "
	      when "Scaling Activities"
	       sender.enabled = false
	      else 
	       @create_button.icon = @create
	       @create_button.tipText = "  Create  "
	    end
	   else
	    sender.enabled = false
	   end 
	end
	@delete_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@delete = @ec2_main.makeIcon("kill.png")
	@delete.create
	@delete_button.icon = @delete
	@delete_button.tipText = "  Delete  "
	@delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	    case @type
	     when "EBS Volumes"
		if @curr_item == nil or @curr_item == ""
                  error_message("No EBS selected","No EBS volume selected to delete")
                else
	          deletedialog = EC2_EBSDeleteDialog.new(@ec2_main,@curr_item)
                  if deletedialog.deleted 
                     load_sort(@type,@curr_sort)
                  end	          
	        end  
            when "EBS Snapshots"
	        if @curr_item == nil or @curr_item == ""
	           error_message("No Snapshot selected","No Snapshot selected to delete")
                else
	           deletedialog = EC2_SnapDeleteDialog.new(@ec2_main,@curr_item)
                   if deletedialog.deleted 
                      load_sort(@type,@curr_sort)
                   end
	        end   
            when "Elastic IPs"
	       if @curr_item == nil or @curr_item == ""
	          error_message("No Elastic IP selected","No IP Address selected to delete")
               else
	          deletedialog = EC2_EIPDeleteDialog.new(@ec2_main,@curr_item)
                  if deletedialog.deleted 
                     load_sort(@type,@curr_sort)
                  end
	       end   
            when "Key Pairs"
	       if @curr_item == nil or @curr_item == ""
	          error_message("No Keypair selected","No Keypair selected to delete")
               else
	          deletedialog = EC2_KeypairDeleteDialog.new(@ec2_main,@curr_item)
                  if deletedialog.deleted 
                     load_sort(@type,@curr_sort)
                  end
   	       end   
            when "Images"
               if @curr_item == nil or @curr_item == ""
                  error_message("No AMI selected","No AMI selected to Delete and Deregister")
               else
                 puts "@curr_image_type #{@curr_image_type}" 
                 case @curr_image_type
                  when "instance-store"
                     deletedialog = EC2_ImageDeleteDialog.new(@ec2_main, @curr_item)
                     if deletedialog.deleted 
                        load_sort(@type,@curr_sort)
                     end
                  when "ebs"
                     deletedialog = EC2_ImageEBSDeleteDialog.new(@ec2_main, @curr_item)
                     if deletedialog.deleted 
                        load_sort(@type,@curr_sort)
                     end   
                  end
               end
            when "Spot Requests"
               if @curr_item == nil or @curr_item == ""
                  error_message("No Request ID selected","No Spot Request ID selected to Cancel")
               else
                  deletedialog = EC2_SpotRequestCancelDialog.new(@ec2_main, @curr_item)
                  if deletedialog.deleted 
                     load_sort(@type,@curr_sort)
                  end
               end               
            when "DB Parameter Groups"
	        if @curr_item == nil or @curr_item == ""
	           error_message("No DB Parameter Group selected","No DB Parameter Group selected to delete")
                else
	           deletedialog = RDS_ParmGrpDeleteDialog.new(@ec2_main,@curr_item)
                   if deletedialog.deleted 
                      load_sort(@type,@curr_sort)
                   end
	        end   
            when "DB Parameters"
	        if @curr_item == nil or @curr_item == ""
	           error_message("No DB Parameter selected","No DB Parameter selected to reset")
                else
                   am = "pending-reboot"
                   if @table.getItemText(@curr_row,3) == "dynamic"
                      am = "immediate"
                   end
	           deletedialog = RDS_ParmGrpResetDialog.new(@ec2_main,@db_parm_grp,@curr_item,am)
                   if deletedialog.deleted 
                      load_sort(@type,@curr_sort)
                   end
	        end   
            when "DB Snapshots"
	        if @curr_item == nil or @curr_item == ""
	           error_message("No DB Snapshot selected","No DB Snapshot selected to delete")
                else
	           deletedialog = RDS_SnapDeleteDialog.new(@ec2_main,@curr_item)
                   if deletedialog.deleted 
                      load_sort(@type,@curr_sort)
                   end
	        end
            when "Load Balancers"
               if @curr_item == nil or @curr_item == ""
                  error_message("No ELB selected","No ELB Name selected to Delete")
               else
                  deletedialog = ELB_DeleteDialog.new(@ec2_main, @curr_item)
                  if deletedialog.deleted 
                     load_sort(@type,@curr_sort)
                  end
               end
      	    when "Launch Configurations"
 	        if @curr_item == nil or @curr_item == ""
                  error_message("No Launch Configuration selected","No Launch Configuration selected to delete")
              else            
                  deletedialog = AS_LaunchConfigurationDeleteDialog.new(@ec2_main, @curr_item)
                  if deletedialog.deleted 
                     load_sort(@type,@curr_sort)
                  end
              end
      	    when "Auto Scaling Groups"
 	        if @curr_item == nil or @curr_item == ""
                  error_message("No Auto Scaling Group selected","No Auto Scaling Group selected to delete")
              else            
                  deletedialog = AS_GroupDeleteDialog.new(@ec2_main, @curr_item)
                  if deletedialog.deleted 
                     load_sort(@type,@curr_sort)
                  end
              end
	    when "Triggers"
		if @curr_item == nil or @curr_item == ""
                  error_message("No Trigger selected","No Trigger selected to delete")
                else            
                  deletedialog = AS_TriggerDeleteDialog.new(@ec2_main, @curr_item, @as_group)
                  if deletedialog.deleted 
                     load_sort(@type,@curr_sort)
                  end
                end
            end            
	end
	@delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded == true  and  @type != "Servers" and @type != "DB Events"
	       sender.enabled = true
	       if @type == "Images"
	       	  @delete_button.tipText = "  Delete and Deregister  "
	       elsif @type == "Spot Requests"
	          @delete_button.tipText = "  Cancel  "
	       elsif @type == "Scaling Activities"
	          sender.enabled = false
	       else
	          @delete_button.tipText = "  Delete  "
	       end	       
	   else
	       sender.enabled = false
	   end 
	end
	@link_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
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
	@link_button.icon = @link
	@link_button.connect(SEL_COMMAND) do |sender, sel, data|
	    case @type
	     when "EBS Volumes"
	       if @curr_item == nil or @curr_item == ""
                  error_message("No EBS selected","No EBS volume selected to attach")
               else
                  linkdialog = EC2_EBSAttachDialog.new(@ec2_main,@curr_item)
		  linkdialog.execute
                  if linkdialog.created 
                     load_sort(@type,@curr_sort)
                  end 
               end 	    
            when "Elastic IPs"
               if @curr_item == nil or @curr_item == ""
                  error_message("No Elastic IP selected","No Elastic IP selected to Associate")
               else	    
	          linkdialog = EC2_EIPAssociateDialog.new(@ec2_main, @curr_item)
	          linkdialog.execute
                  if linkdialog.created 
                     load_sort(@type,@curr_sort)
                  end
	       end   
            when "Images"
	       linkdialog = EC2_ImageRegisterDialog.new(@ec2_main)
	       linkdialog.execute
               if linkdialog.created 
                  load_sort(@type,@curr_sort)
               end
            when "DB Parameter Groups"
	      if @curr_item == nil or @curr_item == ""
	         error_message("No Parameter Group selected","No Parameter Group selected to modify")
              else
                 @db_parm_grp = @curr_item
                 load_db_parmeters(@curr_item,@table.getItemText(@curr_row,2))
                 #@type="DB Parameters"
                 #puts "pg #{@db_parm_grp}"
                 #load_sort(@type,@curr_sort)
              end
            when "EBS Snapshots"
	      dialog = EC2_SnapSelectDialog.new(@ec2_main,@snap_owner)
	      dialog.execute
	      if dialog.selected
	         @snap_owner = dialog.snap_owner
	         load_sort(@type,@curr_sort)
              end
	    when "Load Balancers"
                if @curr_item == nil or @curr_item == ""
                   error_message("No ELB selected","No Load Balancer selected to edit instances")
                else            
 	          dialog = ELB_InstancesDialog.new(@ec2_main,@curr_item)
 	          dialog.execute
 	          if dialog.updated 
		     load_sort(@type,@curr_sort)
                  end
                end	    
      	    when "Launch Configurations"
 	        if @curr_item == nil or @curr_item == ""
                  error_message("No Launch Configuration selected","No Launch Configuration selected to view")
              else 
                  @ec2_main.launch.load_as(@curr_item)
 		  @ec2_main.tabBook.setCurrent(2)
              end
            when "Auto Scaling Groups"
 	        if @curr_item == nil or @curr_item == ""
                  error_message("No Group selected","No Auto Scaling Group selected to update")
                else            
		  editdialog = AS_GroupEditDialog.new(@ec2_main, @curr_item)
                 editdialog.execute
                 if editdialog.saved 
                    load_sort(@type,@curr_sort)
                 end
              end
   	    when "Triggers"
 	        if @curr_item == nil or @curr_item == ""
                  error_message("No Trigger selected","No Trigger selected to edit")
                else            
		  editdialog = AS_TriggerEditDialog.new(@ec2_main, @as_group, @curr_item)
                 editdialog.execute
                 if editdialog.saved 
                    load_sort(@type,@curr_sort)
                 end
              end
           end  
	end
	@link_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded == true
	       sender.enabled = false
	       case @type
                when "EBS Volumes"
	          sender.enabled = true
                  @link_button.icon = @link
                  @link_button.tipText = " Attach EBS Volume "
                when "Elastic IPs"
	          sender.enabled = true
                  @link_button.icon = @link
                  @link_button.tipText = " Associate Elastic IP "
		when "EBS Snapshots"
	          sender.enabled = true
                  @link_button.icon = @magnifier
	          @link_button.tipText = " Select EBS Snapshots "
	        when "DB Parameter Groups"
	          sender.enabled = true
                  @link_button.icon = @view
	          @link_button.tipText = " List DB Parameters"
	   	when "Load Balancers"
	          sender.enabled = true
	          @link_button.icon = @server
	          @link_button.tipText = "  View Instances  "   
		when "Launch Configurations"
	          sender.enabled = true
	          @link_button.icon = @view 
	          @link_button.tipText = "  View Launch Configuration  " 
                when "Auto Scaling Groups"
    		  sender.enabled = true
	          @link_button.icon = @edit 
	          @link_button.tipText = "  Update Auto Scaling Group "
                when "Triggers"
    		  sender.enabled = true
	          @link_button.icon = @edit 
	          @link_button.tipText = "  Edit Triggers  "  
	       end   
	   else
	      sender.enabled = false
	   end
	end
	@link_break_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@script = @ec2_main.makeIcon("script.png")
	@script.create
	@create_image_icon = @ec2_main.makeIcon("package.png")
	@create_image_icon.create	
	@link_break = @ec2_main.makeIcon("link_break.png")
	@link_break.create
	@link_break_button.icon = @link_break
	@link_break_button.connect(SEL_COMMAND) do |sender, sel, data|
	    case @type
	     when "EBS Volumes"
               if @curr_item == nil or @curr_item == ""
                  error_message("No EBS selected","No EBS volume selected to detach")
               else
                  breakdialog = EC2_EBSDetachDialog.new(@ec2_main,@curr_item)
                  if breakdialog.deleted 
                     load_sort(@type,@curr_sort)
                  end
               end   	    	    
             when "Elastic IPs"
               if @curr_item == nil or @curr_item == ""
                  error_message("No AMI selected","No Elastic IP selected to Dis-Associate")
               else
                  breakdialog = EC2_EIPDisassociateDialog.new(@ec2_main,@curr_item)
                  if breakdialog.deleted 
                     load_sort(@type,@curr_sort)
                  end
               end   	    
            when "Images"
               if @curr_item == nil or @curr_item == ""
                  error_message("No AMI selected","No AMI selected to De-Register")
               else
                  breakdialog = EC2_ImageDeRegisterDialog.new(@ec2_main, @curr_item)
                  if breakdialog.deleted 
                     load_sort(@type,@curr_sort)
                  end   
               end   	    
            when "DB Parameters"
	       modifydialog = RDS_ParmGrpModifyDialog.new(@ec2_main, @db_parm_grp, @engine )
	       modifydialog.execute
	       if modifydialog.modified 
	          load_sort(@type,@curr_sort)
	       end
            when "EBS Snapshots"
               if @curr_item == nil or @curr_item == ""
                  error_message("No Snapshot selected","No Snapshot selected to Register as Image")
               else            
	          dialog = EC2_SnapRegisterDialog.new(@ec2_main,@curr_item)
	          dialog.execute
               end
            when "Load Balancers"
                if @curr_item == nil or @curr_item == ""
                   error_message("No ELB selected","No Load Balancer selected to edit policies")
                else            
 	          dialog = ELB_PolicyDialog.new(@ec2_main,@curr_item,@curr_policies,@curr_listeners)
 	          dialog.execute
 	          if dialog.updated 
		     load_sort(@type,@curr_sort)
                  end
                end
            when "Auto Scaling Groups"
	       if @curr_item == nil or @curr_item == ""
                  error_message("No Auto Scaling Group Selected","No Auto Scaling Group selected to list scaling activities")
               else 
                  @as_group = @curr_item
                  load("Scaling Activities")
               end            
            end
	end
	@link_break_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded == true
	       sender.enabled = false
	       case @type	
	         when "EBS Volumes","Elastic IPs","Images"
	            sender.enabled = true
	            @link_break_button.icon = @link_break
	         when "DB Parameters"
	            sender.enabled = true
                    @link_break_button.icon = @edit
	            @link_break_button.tipText = " Edit DB Parameters "
	         when "EBS Snapshots"
	            sender.enabled = true
                    @link_break_button.icon = @create_image_icon
	            @link_break_button.tipText = "Register Image"
	         when "Load Balancers"
	            sender.enabled = true
		    @link_break_button.icon = @script
	            @link_break_button.tipText = "Listeners and Polices"
                 when "Auto Scaling Groups"
    		    sender.enabled = true
	            @link_break_button.icon = @script 
	            @link_break_button.tipText = "  List Scaling Activities  " 
	       end   
	   else
	      sender.enabled = false
	   end
	end
	@csv_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@csv = @ec2_main.makeIcon("doc_excel_csv.png")
	@csv.create
	@csv_button.icon = @csv
	@csv_button.tipText = " csv data "
	@csv_button.connect(SEL_COMMAND) do |sender, sel, data|
	   no_cols = 0
	   case @type
	     when "EBS Volumes" 
	      csv_text = "Volume,Tags,Server,Created Date,Zone,Status,Size,Device,Snapshot\n"
	      no_cols = 9
	     when "EBS Snapshots" 
	      csv_text = "Snapshot,Tags,Server,Started Date,Volume,Status,Progress,Volume Size,Owner Id,Owner Alias\n"
	      no_cols = 10
	     when "Elastic IPs" 
	      csv_text = "Public IP,Server\n"
	      no_cols = 2
	     when "Key Pairs" 
	      csv_text = "Key Pair Name,Fingerprint\n"
	      no_cols = 2
	     when "Images" 
	      csv_text = "AMI,Manifest,Visibility,Root Device Type,Launch SecGrp\n"      	      
	      no_cols = 4
	     when "Spot Requests" 
	      csv_text = "Request Id,Tags,Spot Price,Image ID,Server,Instance Type,Status,Request Type,Valid From,Valid Until,Launch Group,Availability Zone,Avail Zone Group,SSH Key Name,Security Groups\n"
	      no_cols = 15	      
	     when "Servers" 
	      csv_text = "Server,Tags,Image Id,Launch Time,Key Name,Public DSN,Private DSN,Instance Type,Zone,State\n"
	      no_cols = 10
	     when "DB Snapshots" 
	      csv_text = "DB Snapshot Id, DB Instance Id,Create Time,Engine,Storage,Status,Port,Zone,Instance Create Time,Master Username\n"	      
	      no_cols = 10
	     when "DB Parameters" 
	      csv_text = "Parameter Name,Value,Source,Apply Type,Data Type,Allowed Values,Is Modifiable,Minimum Version,Description\n"
	      no_cols = 9
	     when "DB Parameter Groups" 
	      csv_text = "Parameter Group Name,Description,Family\n"
	      no_cols = 3
	     when "DB Events" 
	      csv_text = "Source Id,Source Type,Date,Message\n"
	      no_cols = 4
	     when "Launch Configurations"
    	    	csv_text = "Config Name,Created,Instance Type,Key Name,Image Id,User Data,Security Groups"
 		no_cols = 7
   	    when "Auto Scaling Groups"
    	    	csv_text = "Group Name,Config Name,Created,Min Size,Max Size,Desired,CoolDown,Instances,Availability Zones,Load Balancers"
     		no_cols = 10
   	    when "Scaling Activities"
    	    	csv_text = "Activity Id,Start Time,End Time,Progress,Status Code,Cause,Description"
	      no_cols = 7
   	    when "Triggers"
    	    	csv_text = "Trigger Name,Created,Status,Measure Name,Statistic,Period,Lower Threshold,Lower Breach Scale Increment,Upper Threshold,Upper Breach Scale Increment,Breach Duration,Unit,Dimensions"
		no_cols = 13
	   end
	   
	   i = 0
           while i<@table.numRows
              j=0
              csv_line = ""
              while j<no_cols
                 if @table.getItemText(i,j) != nil
                    csv_line =  csv_line + @table.getItemText(i,j) + ","
                 else 
                    csv_line = csv_line + ","
                 end   
                 j = j+1
              end
              csv_text = csv_text + csv_line[0,csv_line.length-1] + "\n"
              i = i+1
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
	@launch_button.icon = @rocket
	@launch_button.tipText = " Launch Server Instance "
	@launch_button.connect(SEL_COMMAND) do |sender, sel, data|
	    case @type
	     when "Images"
               if @curr_item == nil or @curr_item == ""
                  error_message("No AMI selected","No AMI selected")
               else
                  @ec2_main.launch.load_profile(@curr_item)
                  @ec2_main.tabBook.setCurrent(2)
               end   
              when "DB Snapshots"
               if @curr_item == nil or @curr_item == ""
                  error_message("No DB Snapshot selected","No DB Snapshot selected to restore from")
               else
                  params = {}
                  params[:instance_class]="db.m1.small"
                  params[:endpoint_port]=@table.getItemText(@curr_row,6)
                  params[:availability_zone]=@table.getItemText(@curr_row,7)
                  createdialog = RDS_SnapRestoreDialog.new(@ec2_main,@table.getItemText(@curr_row,0),@table.getItemText(@curr_row,1),params)
                  createdialog.execute
                  if createdialog.created
                     load_sort(@type,@curr_sort)
                  end   
               end
             when "Load Balancers"
                if @curr_item == nil or @curr_item == ""
                   error_message("No ELB selected","No Load Balancer selected to edit availability zone")
                else            
 	          dialog = ELB_AvailZoneDialog.new(@ec2_main,@curr_item,@curr_avail_zone)
 	          dialog.execute
 	          if dialog.updated 
		     load_sort(@type,@curr_sort)
                  end
                end
             when "Auto Scaling Groups"
                if @curr_item == nil or @curr_item == ""
                   error_message("No Auto Scaling Group selected","No Auto Scaling Group selected to list instances")
                else            
 	          dialog = AS_InstancesDialog.new(@ec2_main,@curr_item)
 	          dialog.execute
 	          if dialog.updated 
		     load_sort(@type,@curr_sort)
                  end
                end
            end            
	end
	@launch_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded == true
	       sender.enabled = false
	       case @type
                when "Images"
	          sender.enabled = true
                  @launch_button.icon = @rocket
	          @launch_button.tipText = " Launch Server Instance "
	        when "DB Snapshots"
	          sender.enabled = true
	          @launch_button.icon = @rocket
	          @launch_button.tipText = " Restore DB Instance "
	        when "Load Balancers"
	          sender.enabled = true
		  @launch_button.icon = @zones
	          @launch_button.tipText = "  Availability Zones  "
	        when "Auto Scaling Groups"
	          sender.enabled = true
		  @launch_button.icon = @server 
	          @launch_button.tipText = "  Instances  "
                else
	          sender.enabled = false
	       end   
	   else
	      sender.enabled = false
	   end
	end
	@attributes_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@attributes_button.icon = @view
	@attributes_button.tipText = "  Image Attributes  "
	@attributes_button.connect(SEL_COMMAND) do |sender, sel, data|
	    case @type
	     when "Images"
               if @curr_item == nil or @curr_item == "" 
                  error_message("No Image Selected","No Image selected to display Attributes")
               else
                  imagedialog = EC2_ImageAttributeDialog.new(@ec2_main,@curr_item)
                  imagedialog.execute
               end
             when "EBS Volumes"
               if @curr_item == nil or @curr_item == ""
                  error_message("No EBS selected","No EBS volume selected to snapshot")
               else
                  dialog = EC2_SnapCreateDialog.new(@ec2_main,@curr_item)
                  dialog.execute
               end
             when "EBS Snapshots"
               if @curr_item == nil or @curr_item == ""
                  error_message("No Snapshot Selected","No Snapshot selected to display Attributes")
               else
                  dialog = EC2_SnapAttributeDialog.new(@ec2_main,@curr_item)
                  dialog.execute
               end
             when "Load Balancers"
	       if @curr_item == nil or @curr_item == ""
                  error_message("No Load Balancer Selected","No Load Balancer selected to edit Health Check Parameters")
               else
                  dialog =  ELB_HeathDialog.new(@ec2_main,@curr_item)
                  dialog.execute
               end
            when "Auto Scaling Groups"
	       if @curr_item == nil or @curr_item == ""
                  error_message("No Auto Scaling Group Selected","No Auto Scaling Group selected to set Desired Capacity")
               else
                  dialog =  AS_CapacityDialog.new(@ec2_main,@curr_item,@curr_desired_capacity)
                  dialog.execute
			if dialog.updated 
		        load_sort(@type,@curr_sort)
                  end
               end
            end
	end
	@attributes_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded == true
	       sender.enabled = false
	       case @type 
	         when "Images"
	            @attributes_button.icon = @view
	            @attributes_button.tipText = "  Image Attributes  "
	            sender.enabled = true
	         when "EBS Volumes"
	            @attributes_button.icon = @camera
	            @attributes_button.tipText = "  Create Snapshot  "
	            sender.enabled = true
	         when "EBS Snapshots"
	            @attributes_button.icon = @view
	            @attributes_button.tipText = "  EBS Snapshots Attributes "
	            sender.enabled = true
	         when "Load Balancers"
	            @attributes_button.icon = @view
	            @attributes_button.tipText = "  Load Balancer Health Check "
	            sender.enabled = true
	        when "Auto Scaling Groups"
	            sender.enabled = true
		    @attributes_button.icon = @view 
	            @attributes_button.tipText = "  Set Desired Capacity  "
	       end
	   else
             sender.enabled = false
	   end 
	end
	@tags_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@tags_button.connect(SEL_COMMAND) do |sender, sel, data|
	    case @type
	     when "Images"
               if @curr_item == nil or @curr_item == "" 
                  error_message("No Image Selected","No Image selected to edit tags")
               else
                 t = nil
                 @image_locs.each do |r|
                     if r[:aws_id] == @curr_item
                        t = r[:tags]
                     end
                  end               
                  dialog = EC2_TagsAssignDialog.new(@ec2_main,@curr_item,t)
                  dialog.execute
                  if dialog.saved
	             load_sort(@type,@curr_sort)
	          end   
               end
             when "EBS Volumes"
               if @curr_item == nil or @curr_item == ""
                  error_message("No EBS selected","No EBS volume selected to edit tags")
               else
                  t = nil
                  @data.each do |r|
                     if r[:aws_id] == @curr_item
                        t = r[:tags]
                     end
                  end   
                  dialog = EC2_TagsAssignDialog.new(@ec2_main,@curr_item,t)
                  dialog.execute
                   if dialog.saved
	             load_sort(@type,@curr_sort)
	          end                 
               end
             when "EBS Snapshots"
               if @curr_item == nil or @curr_item == ""
                  error_message("No Snapshot Selected","No Snapshot selected to edit tags")
               else
                  t = nil
                  @data.each do |r|
                     if r[:aws_id] == @curr_item
                        t = r[:tags]
                     end
                  end                
                  dialog = EC2_TagsAssignDialog.new(@ec2_main,@curr_item,t)
                  dialog.execute
                  if dialog.saved
	             load_sort(@type,@curr_sort)
	          end                  
               end
             when "Servers"
	       if @curr_item == nil or @curr_item == ""
                  error_message("No Instance Selected","No Server Instance selected to edit tags")
               else
                  t = nil
                  @data.each do |r|
                     if r[:aws_instance_id] == @curr_item
                        t = r[:tags]
                     end
                  end                
                  dialog =  EC2_TagsAssignDialog.new(@ec2_main,@curr_item,t)
                  dialog.execute
                  if dialog.saved
	             load_sort(@type,@curr_sort)
	          end                  
               end
            when "Spot Requests"
	       if @curr_item == nil or @curr_item == ""
                  error_message("No Spot Request Selected","No Spot Request selected to edit tags")
               else
                  t = nil
                  @data.each do |r|
                     if r[:spot_instance_request_id] == @curr_item
                        t = r[:tags]
                     end
                  end                
                  dialog =  EC2_TagsAssignDialog.new(@ec2_main,@curr_item,t)
                  dialog.execute
		  if dialog.saved 
		     load_sort(@type,@curr_sort)
                  end
               end
            when "Auto Scaling Groups"
	       if @curr_item == nil or @curr_item == ""
                  error_message("No Auto Scaling Group Selected","No Auto Scaling Group selected to list Trigger")
               else 
                  @as_group = @curr_item
                  load("Triggers")
               end   
            end

	end
	@tags_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded == true
	       sender.enabled = false
	       @tags_button.icon = @tag_red
	       @tags_button.tipText = "  Edit Tags  "
	       case @type 
	         when "Images"
	            sender.enabled = true
	         when "EBS Volumes"
	            sender.enabled = true
	         when "EBS Snapshots"
	            sender.enabled = true
	         when "Servers"
	            sender.enabled = true
	         when "Spot Requests"
	            sender.enabled = true
                when "Auto Scaling Groups"
    		  sender.enabled = true
	          @tags_button.icon = @edit_lightning
	          @tags_button.tipText = "  List Triggers  "
	       end
	   else
             sender.enabled = false
	   end 
	end

	@filter_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@filter_button.icon = @funnel
	@filter_button.tipText = "  Filter by Tags  "
	@filter_button.connect(SEL_COMMAND) do |sender, sel, data|
	    case @type
	     when "Images"
                  dialog = EC2_TagsFilterDialog.new(@ec2_main,@type,@tags_filter[:image])
                  dialog.execute
		  if dialog.saved
		     @tags_filter[:image] = dialog.tag_filter
		     @ec2_main.settings.save_filter(@tags_filter)
		     if @tags_filter[:image] == nil or @tags_filter[:image].empty?
        		@image_search = ""
        		@image_type = "Owned By Me"
        		@image_platform = "All Platforms"
        		@image_root = ""
                     end    
		     load_sort(@type,@curr_sort)
                  end
             when "EBS Volumes"
                  dialog = EC2_TagsFilterDialog.new(@ec2_main,@type,@tags_filter[:volume])
                  dialog.execute
		  if dialog.saved
		     @tags_filter[:volume] = dialog.tag_filter
		     @ec2_main.settings.save_filter(@tags_filter)
		     load_sort(@type,@curr_sort)
                  end
             when "EBS Snapshots"
                  dialog = EC2_TagsFilterDialog.new(@ec2_main,@type,@tags_filter[:snapshot])
                  dialog.execute
		  if dialog.saved
		     @tags_filter[:snapshot] = dialog.tag_filter
		     @ec2_main.settings.save_filter(@tags_filter)
		     load_sort(@type,@curr_sort)
                  end
             when "Servers"
                  dialog = EC2_TagsFilterDialog.new(@ec2_main,@type,@tags_filter[:instance])
                  dialog.execute
		  if dialog.saved
		     @tags_filter[:instance] = dialog.tag_filter
		     @ec2_main.settings.save_filter(@tags_filter)
		     load_sort(@type,@curr_sort)
                  end
             when "Spot Requests"
                  dialog = EC2_TagsFilterDialog.new(@ec2_main,@type,@tags_filter[:spot_instances_request])
                  dialog.execute
		  if dialog.saved
		     @tags_filter[:spot_instances_request] = dialog.tag_filter
                     @ec2_main.settings.save_filter(@tags_filter)
		     load_sort(@type,@curr_sort)
                  end
            end
	end
	@filter_button.connect(SEL_UPDATE) do |sender, sel, data|
	   if @loaded == true
	       sender.enabled = false
	       case @type 
	         when "Images"
	            sender.enabled = true
	         when "EBS Volumes"
	            sender.enabled = true
	         when "EBS Snapshots"
	            sender.enabled = true
	         when "Servers"
	            sender.enabled = true
	         when "Spot Requests"
	            sender.enabled = true
	        end
	   else
             sender.enabled = false
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
	     if @curr_type ==  @type and @curr_sort == which and @curr_order == "down"
	        @curr_order = "up"
	     else   
	        @curr_type = @type 
	        @curr_sort = which
	        @curr_order = "down"
	     end   
	     load_sort_reload(@type,which,false)
	end
	@table.connect(SEL_COMMAND) do |sender, sel, which|
	   if which.col == 0
	      @curr_row = which.row
	      @curr_item = @table.getItemText(which.row,0).to_s
	      case @type
	       when "Images"
	         @curr_image_type = @table.getItemText(which.row,4).to_s
	       when "EBS Snapshots"
	         @curr_size  = @table.getItemText(which.row,7).to_s
	       when "Load Balancers"
	         @curr_listeners  = @table.getItemText(which.row,4).to_s
	         @curr_policies  = @table.getItemText(which.row,5).to_s
	         @curr_avail_zone  = @table.getItemText(which.row,6).to_s
	       when "Auto Scaling Groups"
	         @curr_desired_capacity  = @table.getItemText(which.row,5).to_s
	      end 	         
	   else
	      @curr_row = nil
	      @curr_item = ""
	      @curr_image_type = ""
	      @curr_size = ""
	   end 
	end 
  end 
  
  def load_db_parmeters(item, item_2)
    @db_parm_grp = item
    @engine = item_2
    load_sort("DB Parameters",0)
  end  
  
  def load(other_type)
     @tags_filter= @ec2_main.settings.load_filter()
     if other_type != "Images"
        @image_type = "Owned By Me"
        @image_platform = "All Platforms"     
        @image_root = ""
        @image_search = ""
     end 
    load_sort(other_type,0)
  end
  
  def load_sort(other_type,sort_col)
     #if @tags_filter == nil 
     #   @tags_filter = @ec2_main.settings.load_filter
     #end
     load_sort_reload(other_type,sort_col,true)
  end 
  
  
  def load_sort_reload(other_type,sort_col,reload)
       @curr_item = ""
       if other_type == "Images" 
          status = @ec2_main.imageCache.status
          if status == "loaded" 
             @title.text = other_type + " (Cached)"
          else 
             @title.text = other_type + " (Cache not loaded)"
          end
       else   
          @title.text = other_type + "    "
       end   
       tzone = @ec2_main.settings.get_system('TIMEZONE')
       env = @ec2_main.environment.env
       if env != nil and env != ""
          instances = @ec2_main.server.instances
          @type = other_type
          case @type
           when "EBS Volumes"
             load_ebs(sort_col,reload) 
           when "EBS Snapshots"
             load_ebs_snapshot(sort_col,reload)
           when "Elastic IPs"      
	     load_elastic_ips(sort_col,reload)
           when "Key Pairs"
             load_keypairs(sort_col,reload)
           when "Images"
             load_images(sort_col,reload)
           when "Spot Requests"
             load_spot_requests(sort_col,reload)
           when "Servers"
             load_servers(sort_col,reload)
           when "DB Parameter Groups"
             load_db_parameter_groups(sort_col,reload)
           when "DB Parameters"
             load_db_parameters(sort_col,reload)
           when "DB Snapshots"
             load_db_snapshots(sort_col,reload)
           when "DB Events"
             load_db_events(sort_col,reload)
           when "Load Balancers"
             load_elb(sort_col,reload)
	   when "Launch Configurations"
	     load_launch_configurations(sort_col,reload)	
	   when "Auto Scaling Groups" 
	     load_auto_scaling_groups(sort_col,reload)
	   when "Scaling Activities"
           load_scaling_activities(sort_col,reload)
	   when "Triggers"
           load_triggers(sort_col,reload)
          end              
       end
       @ec2_main.app.forceRefresh
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
            while k < table_size
   	       @table.setItemText(i, k, lists[k][i])
    	       @table.setItemJustify(i, k, FXTableItem::LEFT)
    	       k = k+1
    	    end                        
         end
      else
         j = 0
         while i>0
            i = i-1
            k = 0 
            while k < table_size
    	       @table.setItemText(i, k, lists[k][j])
    	       @table.setItemJustify(i, k, FXTableItem::LEFT)
    	       k = k+1
    	    end
            j = j+1
         end
      end
  end                
  
  def set_table_titles(type)
       case type 
          when "EBS Volumes"
             @table.setColumnText(0,"Volume")
      	     @table.setColumnWidth(0,150)
      	     @table.setColumnText(1,"Tags")
     	     @table.setColumnWidth(1,150)
      	     @table.setColumnText(2,"Server")
      	     @table.setColumnWidth(2,150)
      	     @table.setColumnText(3,"Created Date")
      	     @table.setColumnWidth(3,150)
      	     @table.setColumnText(4,"Zone")
      	     @table.setColumnText(5,"Status")
      	     @table.setColumnText(6,"Size")
      	     @table.setColumnText(7,"Device")
    	     @table.setColumnText(8,"Snapshot")
    	when "EBS Snapshots"    
             @table.setColumnText(0,"Snapshot")
             @table.setColumnWidth(0,150)
      	     @table.setColumnText(1,"Tags")
     	     @table.setColumnWidth(1,150)
             @table.setColumnText(2,"Description")
             @table.setColumnWidth(2,400)
    	     @table.setColumnText(3,"Started Date")
    	     @table.setColumnWidth(3,120)
    	     @table.setColumnText(4,"Volume")
    	     @table.setColumnWidth(4,150)
    	     @table.setColumnText(5,"Status")
    	     @table.setColumnText(6,"Progress")
             @table.setColumnText(7,"Volume Size")
             @table.setColumnWidth(7,70)
             @table.setColumnText(8,"Owner Id")
             @table.setColumnText(9,"Owner Alias")    	     
    	when "Elastic IPs"      
    	     @table.setColumnText(0, "Public IP")
  	     @table.setColumnText(1, "Server")
             @table.setColumnWidth(1,150)
  	when "Key Pairs"
             @table.setColumnText(0, "Key Pair Name")
             @table.setColumnText(1, "Fingerprint")
             @table.setColumnWidth(1,350)	
  	when "Images"
    		@table.setColumnText(0,"AMI")
    		@table.setColumnWidth(0,150)
    		@table.setColumnText(1,"Manifest")
    		@table.setColumnWidth(1,420)
      	        @table.setColumnText(2,"Tags")
     	        @table.setColumnWidth(2,150)    		
    		@table.setColumnText(3,'Visibility')
    		@table.setColumnWidth(3,50)
    		@table.setColumnText(4,'Root Device Type')
    		@table.setColumnText(5,"Launch - SecGrp")
    		@table.setColumnWidth(5,150)
  	when "Spot Requests"
    	    	@table.setColumnText(0,"Request ID")
      	        @table.setColumnText(1,"Tags")
     	        @table.setColumnWidth(1,150)
    		@table.setColumnText(2,"Spot Price")
    		@table.setColumnText(3,"Image ID")
    		@table.setColumnText(4,"Server")
    		@table.setColumnWidth(4,150)
    		@table.setColumnText(5,"Instance Type")
     		@table.setColumnText(6,"Status")
                @table.setColumnText(7,"Request Type")   
                @table.setColumnText(8,"Valid From")
                @table.setColumnText(9,"Valid Until")
                @table.setColumnText(10,"Launch Group")
                @table.setColumnText(11,"Availability Zone")
                @table.setColumnText(12,"Avail Zone Group")
                @table.setColumnText(13,"SSH Key Name")
                @table.setColumnText(14,"Security Groups")     		
  	when "Servers"
    	    	@table.setColumnText(0,"Server")
    	    	@table.setColumnWidth(0,150)
      	        @table.setColumnText(1,"Tags")
     	        @table.setColumnWidth(1,150)
    		@table.setColumnText(2,"Image ID")
    		@table.setColumnWidth(2,100)
    		@table.setColumnText(3,"Launch Time")
    		@table.setColumnWidth(3,150)
    		@table.setColumnText(4,"Key Name")
    		@table.setColumnText(5,"Public DSN")
    		@table.setColumnWidth(5,250)
    		@table.setColumnText(6,"Private DSN")
    		@table.setColumnWidth(6,250)
    		@table.setColumnText(7,"Instance Type")
    		@table.setColumnText(8,"Zone")
    		@table.setColumnText(9,"State")
    	when "DB Parameter Groups"
    	    	@table.setColumnText(0,"DB Parameter Group Name")
    	    	@table.setColumnWidth(0,150)
    		@table.setColumnText(1,"Description")
    		@table.setColumnWidth(1,200)
    		@table.setColumnText(2,"Family")
    		@table.setColumnWidth(2,100)
  	when "DB Parameters"
    	    	@table.setColumnText(0,"DB Parameter Name")
    	    	@table.setColumnWidth(0,160)
    		@table.setColumnText(1,"Value")
    		@table.setColumnWidth(1,200)
    		@table.setColumnText(2,"Source")
    		@table.setColumnText(3,"Apply Type")
    		@table.setColumnText(4,"Data Type")
    		@table.setColumnWidth(4,75)
    		@table.setColumnText(5,"Allowed Values")
    		@table.setColumnWidth(5,200)
    		@table.setColumnText(6,"Is Modifiable")
    		@table.setColumnWidth(6,75)
    		@table.setColumnText(7,"Minimum Version")
    		@table.setColumnWidth(7,75)    		
    		@table.setColumnText(8,"Description")
    		@table.setColumnWidth(8,350)		
  	when "DB Snapshots"
    	    	@table.setColumnText(0,"DB Snapshot Id")
    	    	@table.setColumnWidth(0,150)
    		@table.setColumnText(1,"DB Instance Id")
    		@table.setColumnWidth(1,100)
    		@table.setColumnText(2,"Create Time")
    		@table.setColumnWidth(2,200)
    		@table.setColumnText(3,"Engine")
    		@table.setColumnText(4,"Engine Version")    		
    		@table.setColumnText(5,"Storage")
    		@table.setColumnText(6,"Status")
    		@table.setColumnText(7,"Port")
    		@table.setColumnText(8,"Zone")
    		@table.setColumnText(9,"Instance Create Time")
    		@table.setColumnWidth(9,200)
    		@table.setColumnText(10,"Master Username")
  	when "DB Events"
    	    	@table.setColumnText(0,"Source Id")
    	    	@table.setColumnWidth(0,150)
    		@table.setColumnText(1,"Source Type")
    		@table.setColumnWidth(1,100)
    		@table.setColumnText(2,"Date")
    		@table.setColumnWidth(2,150)
    		@table.setColumnText(3,"Message")
    		@table.setColumnWidth(3,600)
   	when "Load Balancers"
    	    	@table.setColumnText(0,"LB Name")
    		@table.setColumnText(1,"DNS Name")
    		@table.setColumnWidth(1,300)
    		@table.setColumnText(2,"Created")
    		@table.setColumnWidth(2,150)
    		@table.setColumnText(3,"Instances")
    		@table.setColumnWidth(3,150)
    		@table.setColumnText(4,"Listeners")
    		@table.setColumnWidth(4,150)
                @table.setColumnText(5,"Policies")
    		@table.setColumnWidth(5,150)    		
     		@table.setColumnText(6,"Availability Zones")
     		@table.setColumnWidth(6,150)
   	when "Launch Configurations"
    	    	@table.setColumnText(0,"Config Name")
    		@table.setColumnText(1,"Created")
    		@table.setColumnWidth(1,150)
    		@table.setColumnText(2,"Instance Type")
    		@table.setColumnWidth(2,350)
    		@table.setColumnText(3,"Key Name")
    		@table.setColumnWidth(3,150)
    		@table.setColumnText(4,"Image Id")
    		@table.setColumnWidth(4,150)
                @table.setColumnText(5,"User Data")
    		@table.setColumnWidth(5,150)    		
     		@table.setColumnText(6,"")
     		@table.setColumnWidth(6,150)
   	when "Auto Scaling Groups"
    	    	@table.setColumnText(0,"Group Name")
    		@table.setColumnText(1,"Config Name")
    		@table.setColumnWidth(1,150)
    		@table.setColumnText(2,"Created")
    		@table.setColumnWidth(2,150)
    		@table.setColumnText(3,"Min Size")
    		@table.setColumnText(4,"Max Size")
    		@table.setColumnText(5,"Desired")
    		@table.setColumnText(6,"CoolDown")
    		@table.setColumnText(7,"Instances")
     		@table.setColumnWidth(7,250)
     		@table.setColumnText(8,"Availability Zones")
     		@table.setColumnWidth(8,150)
     		@table.setColumnText(9,"Load Balancers")
     		@table.setColumnWidth(9,150)
   	when "Scaling Activities"
    	    	@table.setColumnText(0,"Activity Id")
    	    	@table.setColumnWidth(0,240)
    		@table.setColumnText(1,"Start Time")
    		@table.setColumnWidth(1,110)
    		@table.setColumnText(2,"End Time")
    		@table.setColumnWidth(2,110)
    		@table.setColumnText(3,"Progress")
    		@table.setColumnWidth(3,60)
    		@table.setColumnText(4,"Status")
    		@table.setColumnWidth(4,60)
    		@table.setColumnText(5,"Cause")
		@table.setColumnWidth(5,900)
    		@table.setColumnText(6,"Description")
		@table.setColumnWidth(6,900)
   	when "Triggers"
     		@table.setColumnText(0,"Trigger Name")
     		@table.setColumnWidth(0,150)     		
    		@table.setColumnText(1,"Created")
    		@table.setColumnWidth(1,150)
     		@table.setColumnText(2,"Status")    		
    	    	@table.setColumnText(3,"Measure Name")
    	    	@table.setColumnText(4,"Statistic")
		@table.setColumnText(5,"Period")
    		@table.setColumnText(6,"Lower Threshold")		
    		@table.setColumnText(7,"Lower Breach Scale Increment")
		@table.setColumnWidth(7,175)
     		@table.setColumnText(8,"Upper Threshold")
    		@table.setColumnText(9,"Upper Breach Scale Increment")
		@table.setColumnWidth(9,175)
		@table.setColumnText(10,"Breach Duration")
     		@table.setColumnText(11,"Unit")
     		@table.setColumnText(12,"Dimensions")
     		@table.setColumnWidth(12,400)
       end
  end
  
  def convert_time(t)
   if t == nil 
      return ""
   else   
     tzone = @ec2_main.settings.get_system('TIMEZONE')
     if tzone != "UTC"
        tz = TZInfo::Timezone.get(tzone)
        t = tz.utc_to_local(DateTime.new(t[0,4].to_i,t[5,2].to_i,t[8,2].to_i,t[11,2].to_i,t[14,2].to_i,t[17,2].to_i)).to_s
     end
     k = t.index("T")
     if k != nil and k> 0
        t[k] = " "
     end
     k = t.index("Z")
     if k != nil and k> 0
        t[k] = " "
     end
     return t
   end   
  end
  
  def pad(i)
     if i < 10
        p = "0#{i}"
     else
        p = "#{i}"
     end
     return p
  end 
  
  def error_message(title,message)
     FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end


end 